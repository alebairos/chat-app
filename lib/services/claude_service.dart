import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ai_personas_app/config/config_loader.dart';

import 'system_mcp_service.dart';
import '../utils/activity_detection_utils.dart';
import '../utils/logger.dart';
import '../services/flat_metadata_parser.dart';
import '../features/audio_assistant/tts_service.dart';
import '../models/claude_audio_response.dart';
import 'time_context_service.dart';

import 'integrated_mcp_processor.dart';
import 'activity_memory_service.dart';
import 'semantic_activity_detector.dart';
import 'shared_claude_rate_limiter.dart';
import 'activity_queue.dart' as ft154;
import '../utils/message_id_generator.dart';

import 'chat_storage_service.dart';

/// FT-151: Rate limiting now handled by SharedClaudeRateLimiter
/// Old _RateLimitTracker class removed to eliminate duplication

// Helper class for validation results
class ValidationResult {
  final bool isValid;
  final String reason;

  ValidationResult(this.isValid, this.reason);
}

/// Public interface for rate limit tracking (FT-119)
/// FT-151: Now delegates to SharedClaudeRateLimiter for consistency
class RateLimitTracker {
  /// Check if system recently encountered rate limiting
  static bool hasRecentRateLimit() {
    return SharedClaudeRateLimiter.hasRecentRateLimit();
  }

  /// Check if system is experiencing high API usage
  static bool hasHighApiUsage() {
    return SharedClaudeRateLimiter.hasHighApiUsage();
  }

  /// Get comprehensive status for monitoring
  static Map<String, dynamic> getStatus() {
    return SharedClaudeRateLimiter.getStatusStatic();
  }
}

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  late final String _apiKey;
  late final String _model;
  final List<Map<String, dynamic>> _conversationHistory = [];
  String? _systemPrompt;
  bool _isInitialized = false;
  final _logger = Logger();
  final http.Client _client;
  final SystemMCPService? _systemMCP;
  final ConfigLoader _configLoader;

  // Add these fields
  final AudioAssistantTTSService? _ttsService;
  final ChatStorageService? _storageService;
  bool _audioEnabled = true;

  // FT-153: Invisible rate limiting with auto-retry
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  // FT-154: Contextual user feedback tracking
  int _consecutiveFallbacks = 0;

  ClaudeService({
    http.Client? client,
    SystemMCPService? systemMCP,
    ConfigLoader? configLoader,
    AudioAssistantTTSService? ttsService,
    ChatStorageService? storageService,
    bool audioEnabled = true,
  })  : _client = client ?? http.Client(),
        _systemMCP = systemMCP ?? SystemMCPService.instance,
        _configLoader = configLoader ?? ConfigLoader(),
        _ttsService = ttsService,
        _storageService = storageService,
        _audioEnabled = audioEnabled {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    _model =
        (dotenv.env['ANTHROPIC_MODEL'] ?? 'claude-3-5-sonnet-latest').trim();

    // FT-195: Track SystemMCP singleton assignment
    print(
        '🔍 [FT-195] ClaudeService using SystemMCP instance: ${_systemMCP!.hashCode} (${systemMCP != null ? "injected" : "singleton"})');
  }

  // Add getter and setter for audioEnabled
  bool get audioEnabled => _audioEnabled;
  set audioEnabled(bool value) => _audioEnabled = value;

  // Method to enable or disable logging
  void setLogging(bool enable) {
    _logger.setLogging(enable);
    // Also set logging for MCP service if available
    _systemMCP?.setLogging(enable);
  }

  // FT-153: Invisible rate limiting helper methods
  // FT-155: Language-aware overload fallback response
  String _getOverloadFallbackResponse() {
    String detectedLanguage = 'pt_BR'; // Default fallback

    if (_ttsService != null) {
      try {
        detectedLanguage = _ttsService!.detectedLanguage;
      } catch (e) {
        _logger.debug('Language detection fallback: $e');
      }
    }

    switch (detectedLanguage) {
      case 'en_US':
        return "Got it! I'll process that as soon as possible. Keep telling me about your day! 😊";
      case 'pt_BR':
      default:
        return "Entendi! Vou processar isso assim que possível. Continue me contando! 😊";
    }
  }

  bool _isRateLimitError(dynamic error) {
    final errorStr = error.toString();
    return errorStr.contains('429') ||
        errorStr.contains('rate_limit_error') ||
        errorStr.contains('Rate limit exceeded');
  }

  String _getGracefulFallbackResponse() {
    _consecutiveFallbacks++;

    if (_consecutiveFallbacks == 1) {
      return "I'm processing a lot of requests right now. Let me get back to you with a thoughtful response in just a moment.";
    } else if (_consecutiveFallbacks <= 3) {
      return "I'm experiencing high demand right now. Your message is important to me - please give me a moment to respond thoughtfully.";
    } else {
      return "I'm working through a high volume of requests. I'll respond as soon as possible - thank you for your patience.";
    }
  }

  void _resetFallbackCounter() {
    _consecutiveFallbacks = 0;
  }

  Future<String> _retryWithBackoff(Future<String> Function() apiCall,
      {int attempt = 0}) async {
    try {
      return await apiCall();
    } catch (e) {
      if (_isRateLimitError(e) && attempt < _maxRetries) {
        // Calculate exponential backoff: 2s, 4s, 8s
        final delay =
            Duration(seconds: _baseRetryDelay.inSeconds * (1 << attempt));

        _logger.info(
            'FT-153: Rate limit hit, retrying in ${delay.inSeconds}s (attempt ${attempt + 1}/$_maxRetries)');

        await Future.delayed(delay);
        return await _retryWithBackoff(apiCall, attempt: attempt + 1);
      }

      // If max retries exceeded, return graceful fallback
      if (_isRateLimitError(e)) {
        _logger.warning(
            'FT-153: Max retries exceeded, returning graceful fallback');
        return _getGracefulFallbackResponse();
      }

      rethrow;
    }
  }

  /// FT-150-Simple: Load recent conversation history for cross-session memory
  /// FT-189: Enhanced with multi-persona awareness
  Future<void> _loadRecentHistory({int limit = 5}) async {
    _logger.debug(
        'FT-150-Simple: Starting to load conversation history (limit: $limit)');

    if (_storageService == null) {
      _logger.warning(
          'FT-150-Simple: StorageService is null, skipping history load');
      return;
    }

    try {
      _logger.debug('FT-150-Simple: Calling getMessages...');
      final recentMessages = await _storageService!.getMessages(limit: limit);
      _logger.debug(
          'FT-150-Simple: Retrieved ${recentMessages.length} messages from storage');

      // FT-189: Load multi-persona configuration
      final multiPersonaConfig = await _loadMultiPersonaConfig();
      final includePersonaInHistory =
          multiPersonaConfig['includePersonaInHistory'] ?? true;
      final personaPrefix =
          multiPersonaConfig['personaPrefix'] ?? '[Persona: {{displayName}}]';

      // Convert to conversation history format (newest first, so reverse)
      for (final message in recentMessages.reversed) {
        String content = message.text;

        // FT-189: Add persona context for assistant messages
        if (includePersonaInHistory &&
            !message.isUser &&
            message.personaDisplayName != null) {
          final prefix = personaPrefix.replaceAll(
              '{{displayName}}', message.personaDisplayName!);
          content = '$prefix\n${message.text}';
        }

        _conversationHistory.add({
          'role': message.isUser ? 'user' : 'assistant',
          'content': [
            {'type': 'text', 'text': content}
          ],
          // FT-157: Removed timestamp field - Claude API doesn't accept extra fields
        });
      }

      _logger.info(
          'FT-150-Simple: ✅ Loaded ${recentMessages.length} messages for cross-session memory');
      _logger.debug(
          'FT-150-Simple: Conversation history now has ${_conversationHistory.length} total messages');
    } catch (e) {
      _logger
          .warning('FT-150-Simple: ❌ Failed to load conversation history: $e');
      // Graceful degradation - continue without history
    }
  }

  /// FT-189: Load multi-persona configuration
  Future<Map<String, dynamic>> _loadMultiPersonaConfig() async {
    try {
      final configString = await rootBundle
          .loadString('assets/config/multi_persona_config.json');
      return json.decode(configString) as Map<String, dynamic>;
    } catch (e) {
      _logger
          .debug('FT-189: Multi-persona config not found, using defaults: $e');
      // Fallback to defaults
      return {
        'enabled': true,
        'includePersonaInHistory': true,
        'personaPrefix': '[Persona: {{displayName}}]'
      };
    }
  }

  /// FT-200: Check if conversation database queries are enabled
  Future<bool> _isConversationDatabaseEnabled() async {
    try {
      final configString = await rootBundle
          .loadString('assets/config/conversation_database_config.json');
      final config = json.decode(configString) as Map<String, dynamic>;
      final enabled = config['enabled'] == true;
      _logger.debug(
          'FT-200: Conversation database queries ${enabled ? 'enabled' : 'disabled'}');
      return enabled;
    } catch (e) {
      // Default to legacy behavior if config not found
      _logger
          .debug('FT-200: Config not found, defaulting to legacy behavior: $e');
      return false;
    }
  }

  /// FT-206: Load conversation database configuration
  Future<Map<String, dynamic>> _loadConversationDatabaseConfig() async {
    try {
      final configString = await rootBundle
          .loadString('assets/config/conversation_database_config.json');
      return json.decode(configString) as Map<String, dynamic>;
    } catch (e) {
      _logger.warning('FT-206: Failed to load conversation config: $e');
      return {}; // Return empty map as fallback
    }
  }

  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        _logger.debug('FT-150-Simple: Initializing ClaudeService...');
        _systemPrompt = await _configLoader.loadSystemPrompt();

        // FT-150-Enhanced: Load recent conversation history for context
        _logger.debug('FT-150-Enhanced: About to load recent history...');
        await _loadRecentHistory(
            limit: 25); // Enhanced: Handle complex conversations
        _logger.debug('FT-150-Enhanced: History loading completed');

        _isInitialized = true;
        _logger.debug('FT-150-Simple: ClaudeService initialization completed');
      } catch (e) {
        _logger.error('Error initializing Claude service: $e');
        return false;
      }
    }
    return _isInitialized;
  }

  // Helper method to extract user-friendly error messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    try {
      // Check if the error is a string that contains JSON
      if (error is String && error.contains('{') && error.contains('}')) {
        // Try to extract the error message from the JSON
        final errorJson = json.decode(
          error.substring(error.indexOf('{'), error.lastIndexOf('}') + 1),
        );

        // Handle specific error types
        if (errorJson['error'] != null && errorJson['error']['type'] != null) {
          final errorType = errorJson['error']['type'];

          switch (errorType) {
            case 'overloaded_error':
              return 'Claude is currently experiencing high demand. Please try again in a moment.';
            case 'rate_limit_error':
              SharedClaudeRateLimiter()
                  .recordRateLimit(); // FT-151: Track rate limit event
              // FT-153: Never show rate limit errors to users - this should not happen
              // as we now use retry logic, but keeping as fallback
              return _getGracefulFallbackResponse();
            case 'authentication_error':
              return 'Authentication failed. Please check your API key.';
            case 'invalid_request_error':
              return 'There was an issue with the request. Please try again with a different message.';
            default:
              // If we have a message in the error, use it
              if (errorJson['error']['message'] != null) {
                return 'Claude error: ${errorJson['error']['message']}';
              }
          }
        }
      }

      // If we couldn't parse the error or it's not a recognized type
      if (error.toString().contains('SocketException') ||
          error.toString().contains('Connection refused') ||
          error.toString().contains('Network is unreachable')) {
        return 'Unable to connect to Claude. Please check your internet connection.';
      }

      // Default error message
      return 'Unable to get a response from Claude. Please try again later.';
    } catch (e) {
      // If we fail to parse the error, return a generic message
      return 'An error occurred while communicating with Claude. Please try again.';
    }
  }

  // Note: MCP command processing now handled directly in sendMessage method

  // Note: Legacy LifePlan data fetching logic removed
  // System MCP functions are now called directly via JSON commands in user messages

  Future<String> sendMessage(String message) async {
    // FT-153: Wrap entire sendMessage with invisible retry logic
    return await _retryWithBackoff(() => _sendMessageInternal(message));
  }

  Future<String> _sendMessageInternal(String message) async {
    try {
      await initialize();

      // FT-156: Generate unique message ID for activity linking
      final messageId = MessageIdGenerator.generate();
      _logger.debug(
          'Generated message ID: $messageId for message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}');

      // Always reload system prompt to get current persona
      _systemPrompt = await _configLoader.loadSystemPrompt();

      // FT-206: Detect data query patterns and inject hints
      final queryHint = _detectDataQueryPattern(message);
      if (queryHint != null) {
        _logger.info('FT-206: Detected data query pattern, injecting hint');
        _systemPrompt = '$_systemPrompt$queryHint';
      }

      // Check if message contains a system MCP command
      if (_systemMCP != null && message.startsWith('{')) {
        try {
          final Map<String, dynamic> command = json.decode(message);
          final action = command['action'] as String?;

          if (action == null) {
            return 'Missing required parameter: action';
          }

          try {
            return await _systemMCP!.processCommand(message);
          } catch (e) {
            return 'Error processing system command: ${e.toString()}';
          }
        } catch (e) {
          return 'Invalid command format';
        }
      }

      // Add user message to history using content blocks format
      _conversationHistory.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': message},
        ],
      });

      // Note: Legacy MCP data fetching removed
      // System functions now called directly via JSON commands

      // Prepare messages array with history
      final messages = <Map<String, dynamic>>[];

      // FT-200: Feature toggle for conversation history database queries
      if (await _isConversationDatabaseEnabled()) {
        // FT-200: Use database queries (no history injection)
        _logger.info(
            'FT-200: Using conversation database queries - no history injection');
        // Only add current user message, no conversation history
        messages.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': message},
          ],
        });
      } else {
        // Legacy: Load conversation history into context
        messages.addAll(_conversationHistory);
        _logger.info(
            'Legacy: Using conversation history injection (${_conversationHistory.length} messages)');
      }

      // Generate enhanced time-aware context (FT-060)
      final lastMessageTime = await _getLastMessageTimestamp();
      await TimeContextService.generatePreciseTimeContext(lastMessageTime);

      // Debug logging for time context
      if (lastMessageTime != null) {
        final debugInfo = TimeContextService.getTimeGapDebugInfo(
          lastMessageTime,
        );
        _logger.debug('Time Context Debug: $debugInfo');
      } else {
        _logger.debug('Time Context: No previous message found');
      }

      // Activity context is now handled only when explicitly requested via MCP (FT-078)

      // Build enhanced system prompt with time context and FT-095 temporal intelligence
      final systemPrompt = await _buildSystemPrompt();

      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'messages': messages,
          'system': systemPrompt,
        }),
        encoding: utf8,
      );

      if (response.statusCode == 200) {
        // FT-154: Reset fallback counter and process queued activities on success
        _resetFallbackCounter();

        // Process any queued activities when system recovers
        if (!SharedClaudeRateLimiter.hasRecentRateLimit()) {
          ft154.ActivityQueue.processQueue();
        }

        final data = jsonDecode(utf8.decode(response.bodyBytes));
        var assistantMessage = data['content'][0]['text'];

        // Log the original AI response to see what we're working with
        _logger.debug('Original AI response: $assistantMessage');

        // FT-084: Check if Claude requested data using intelligent two-pass approach
        if (_containsMCPCommand(assistantMessage)) {
          _logger.info(
              '🧠 FT-084: Detected data request, switching to two-pass processing');
          // FT-156: Pass message context for activity linking
          final dataInformedResponse = await _processDataRequiredQuery(
              message, assistantMessage, messageId);

          // Background activity detection handled in _processDataRequiredQuery

          return dataInformedResponse;
        }

        // Regular conversation flow (no data required)
        _logger.debug('Regular conversation - no data required');

        // FT-104: Clean response to remove JSON commands before TTS
        final cleanedResponse = _cleanResponseForUser(assistantMessage);

        // FT-156: Process background activities with message context
        _processBackgroundActivitiesWithQualification(
            message, assistantMessage, messageId);

        // Add assistant response to history (user message already added at line 163)
        _conversationHistory.add({
          'role': 'assistant',
          'content': [
            {'type': 'text', 'text': cleanedResponse},
          ],
        });

        return _addActivityStatusNote(cleanedResponse);
      } else {
        // Handle different HTTP status codes
        switch (response.statusCode) {
          case 401:
            return 'Authentication failed. Please check your API key.';
          case 429:
            SharedClaudeRateLimiter()
                .recordRateLimit(); // FT-151: Track rate limit event
            // FT-153: Never show rate limit errors to users - this should not happen
            // as we now use retry logic, but keeping as fallback
            return _getGracefulFallbackResponse();
          case 529:
            // FT-155: Claude overload protection
            SharedClaudeRateLimiter.recordOverload();
            return _getOverloadFallbackResponse();
          case 500:
          case 502:
          case 503:
          case 504:
            return 'Claude service is temporarily unavailable. Please try again later.';
          default:
            // Try to parse the error response and log it for debugging
            try {
              final errorBody = utf8.decode(response.bodyBytes);
              _logger.error(
                'Claude API Error (${response.statusCode}): $errorBody',
              );

              final errorData = jsonDecode(errorBody);
              if (errorData['error'] != null &&
                  errorData['error']['type'] == 'overloaded_error') {
                // FT-155: Handle overloaded_error in response body (backup for 529)
                SharedClaudeRateLimiter.recordOverload();
                return _getOverloadFallbackResponse();
              }
              return _getUserFriendlyErrorMessage(errorBody);
            } catch (e) {
              _logger.error('Failed to parse error response: $e');
              return 'Error: Unable to get a response from Claude (Status ${response.statusCode})';
            }
        }
      }
    } catch (e) {
      return _getUserFriendlyErrorMessage(e.toString());
    }
  }

  // Note: Legacy LifePlan validation methods removed

  // Method to clear conversation history
  void clearConversation() {
    _conversationHistory.clear();
  }

  // Getter for conversation history
  List<Map<String, dynamic>> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Process MCP commands in the AI's response and replace them with results
  ///
  /// Looks for JSON commands like {"action": "get_current_time"} in the AI's response,
  /// executes them via SystemMCP, and replaces the commands with the results.
  /// Helper method to extract action from JSON command
  String _extractActionFromCommand(String command) {
    try {
      final data = jsonDecode(command);
      return data['action'] ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Check if response contains MCP commands that require data
  bool _containsMCPCommand(String response) {
    final mcpPattern = RegExp(r'\{"action":\s*"[^"]+"[^}]*\}');
    return mcpPattern.hasMatch(response);
  }

  /// Extract MCP commands from response
  List<String> _extractMCPCommands(String response) {
    final mcpPattern = RegExp(r'\{"action":\s*"[^"]+"[^}]*\}');
    return mcpPattern
        .allMatches(response)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// FT-098: Auto-correct common JSON malformation patterns
  String _correctMalformedJson(String jsonCommand) {
    String corrected = jsonCommand;

    // Fix: Extra quote after number values: "days": 2"} → "days": 2}
    corrected = corrected.replaceAllMapped(
        RegExp(r'(\d+)"\}'), (match) => '${match.group(1)!}}');

    // Log correction if changes were made
    if (corrected != jsonCommand) {
      _logger
          .debug('🔧 FT-098: JSON auto-corrected: $jsonCommand → $corrected');
    }

    return corrected;
  }

  /// Process data-required query using intelligent two-pass approach
  /// FT-156: Added message context for activity linking
  Future<String> _processDataRequiredQuery(
      String userMessage, String initialResponse, String messageId) async {
    try {
      _logger.info(
          '🧠 FT-084: Processing data-required query with two-pass approach');

      // Extract MCP commands from Claude's initial response
      _logger.info(
          '🔍 [FT-203] AI Initial Response: ${initialResponse.substring(0, initialResponse.length > 200 ? 200 : initialResponse.length)}...');
      final mcpCommands = _extractMCPCommands(initialResponse);
      _logger.info('🔍 [FT-203] Found MCP commands: $mcpCommands');

      // FT-203: Check if conversation commands are being used
      final hasConversationCommands = mcpCommands.any((cmd) =>
          cmd.toString().contains('get_recent_user_messages') ||
          cmd.toString().contains('get_current_persona_messages') ||
          cmd.toString().contains('search_conversation_context'));

      if (hasConversationCommands) {
        _logger.info('🔍 [FT-203] ✅ AI is using conversation MCP commands!');
      } else {
        _logger.warning(
            '🔍 [FT-203] ❌ AI NOT using conversation MCP commands - potential amnesia!');
      }

      // Execute all MCP commands and collect data
      String collectedData = '';
      for (final command in mcpCommands) {
        try {
          // FT-098: Auto-correct common JSON malformation before execution
          final correctedCommand = _correctMalformedJson(command);
          final result = await _systemMCP!.processCommand(correctedCommand);
          final data = jsonDecode(result);

          if (data['status'] == 'success') {
            collectedData += '\n${data['data']}';
          }
        } catch (e) {
          _logger.warning('MCP command failed: $command - $e');
        }
      }

      // Create enriched prompt for second pass with activity qualification
      final enrichedPrompt =
          _buildEnrichedPromptWithQualification(userMessage, collectedData);

      _logger.debug('Sending enriched prompt to Claude for final response');
      _logger.debug(
          '🔍 [DATA DEBUG] Raw collected data length: ${collectedData.length} chars');
      _logger.debug(
          '🔍 [DATA DEBUG] Collected data preview: ${collectedData.length > 500 ? "${collectedData.substring(0, 500)}..." : collectedData}');

      // FT-085: Smart delay to prevent API rate limiting bursts
      // 500ms delay is imperceptible to users but prevents 429 errors
      _logger.debug('🕐 FT-085: Applying 500ms delay to prevent rate limiting');
      await Future.delayed(const Duration(milliseconds: 500));
      _logger
          .debug('✅ FT-085: Delay completed, proceeding with second API call');

      // Second pass: Get data-informed response
      final rawResponse = await _callClaudeWithPrompt(enrichedPrompt);
      final dataInformedResponse = _cleanResponseForUser(rawResponse);

      // FT-210: Add assistant response to conversation history
      // NOTE: User message already added in _sendMessageInternal() at line 393-399
      // Only add assistant response here to avoid duplicates
      _conversationHistory.add({
        'role': 'assistant',
        'content': [
          {'type': 'text', 'text': dataInformedResponse}
        ],
      });

      _logger
          .info('✅ FT-084: Successfully completed two-pass data integration');

      // Process background activities with qualification using raw response
      // FT-156: Pass message context for activity linking
      await _processBackgroundActivitiesWithQualification(
          userMessage, rawResponse, messageId);

      return dataInformedResponse;
    } catch (e) {
      _logger.error('FT-084: Error in two-pass processing: $e');
      // Fallback to original response without data - properly remove MCP commands
      String cleanResponse = initialResponse;

      // Use the same extraction logic that successfully identifies commands
      final mcpCommands = _extractMCPCommands(initialResponse);
      for (final command in mcpCommands) {
        cleanResponse = cleanResponse.replaceAll(command, '');
      }

      // Clean up any extra whitespace or punctuation left behind
      cleanResponse =
          cleanResponse.replaceAll(RegExp(r'\s*\.\.\.\s*'), ' ').trim();

      _logger.warning(
          'FT-084: Returning cleaned fallback response after MCP command removal');
      return cleanResponse.isEmpty
          ? 'Desculpe, não consegui processar sua solicitação.'
          : cleanResponse;
    }
  }

  /// Build system prompt with time context and MCP documentation
  Future<String> _buildSystemPrompt() async {
    // Generate enhanced time-aware context (FT-060)
    final lastMessageTime = await _getLastMessageTimestamp();
    final timeContext = await TimeContextService.generatePreciseTimeContext(
      lastMessageTime,
    );

    // FT-157: Add recent conversation context for temporal awareness
    final conversationContext = await _buildRecentConversationContext();

    // Build enhanced system prompt with time context
    String systemPrompt = _systemPrompt ?? '';

    // FT-206: Check if Oracle is enabled for adaptive priority hierarchy
    final isOracleEnabled = _systemMCP?.isOracleEnabled ?? false;

    // FT-206: Add priority hierarchy header
    final priorityHeader = '''
## 🎯 INSTRUCTION PRIORITY HIERARCHY

**PRIORITY 1 (ABSOLUTE)**: Data Query Intelligence (MANDATORY)

When user asks about TIME PERIODS, QUANTITIES, or PROGRESS:
- Past periods: "week", "yesterday", "month", "last N days"
- Quantities: "how many", "how much", "total", "count"
- Progress: "summary", "progress", "how was", "compared to"
- Frequency: "how often", "usually", "typically"
- Intensity: "most", "least", "best", "worst"

MANDATORY ACTION:
1. Recognize query requires historical data
2. Generate MCP command: {"action": "get_activity_stats", "days": N}
3. Wait for data response
4. Provide data-informed answer

NEVER approximate historical data from conversation memory.
ALWAYS fetch fresh data via MCP for temporal/quantitative queries.

---

**PRIORITY 2 (ABSOLUTE)**: Time Awareness (MANDATORY)
- ALWAYS use current time from system context
- Never rely on memory for temporal information

**PRIORITY 3 (HIGHEST)**: Core Behavioral Rules & Persona Configuration
- Follow System Laws #1-#7 literally
- Maintain unique persona identity and symbols
- Adhere to persona-specific communication style

${isOracleEnabled ? '''**PRIORITY 4 (ORACLE FRAMEWORK)**: Oracle 4.2 Framework
- PRIMARY: Follow 8 dimensions (R, SF, TG, SM, E, TT, PR, F) and 265+ activities
- GUARDRAILS: Apply 9 theoretical foundations (Fogg, Hreha, Lembke, Lieberman, Seligman, Maslow, Huberman, Easter, Newberg)
- CRITICAL: Activity detection ONLY from current user message
- NEVER extract Oracle codes or metadata from conversation history

''' : ''}**PRIORITY ${isOracleEnabled ? '5' : '4'}**: Conversation Context (REFERENCE ONLY)
- Use for understanding conversation flow and topics
- Do NOT process activities from historical messages
- Do NOT extract metadata from conversation history
- Do NOT adopt other personas' communication styles

**PRIORITY ${isOracleEnabled ? '6' : '5'}**: User's Current Message (PRIMARY FOCUS)
- Activity detection: ONLY current user message
- Metadata extraction: ONLY current user message
- This is the ONLY message to process for data extraction

---

''';

    // Add conversation context first for immediate temporal awareness
    if (conversationContext.isNotEmpty) {
      systemPrompt = '$conversationContext\n\n$systemPrompt';
    }

    // Add time context after conversation context
    if (timeContext.isNotEmpty) {
      systemPrompt = '$timeContext\n\n$systemPrompt';
    }

    // Add priority header at the very beginning
    systemPrompt = '$priorityHeader$systemPrompt';

    // Add session-specific MCP context (FT-130: Simplified after config extraction)
    if (_systemMCP != null) {
      String sessionMcpContext = '\n\n## SESSION CONTEXT\n'
          '**Current Session**: Active MCP functions available\n'
          '**Data Source**: Real-time database queries\n'
          '**Temporal Context**: Use current time for accurate day calculations\n\n'
          '**Session Functions**:\n'
          '- get_current_time: Current temporal information\n'
          '- get_device_info: Device and system information\n'
          '- get_activity_stats: Activity tracking data\n'
          '- get_message_stats: Chat statistics\n\n'
          '**Session Rules**:\n'
          '- Always use fresh data from MCP commands\n'
          '- Never rely on conversation memory for activity data\n'
          '- Calculate precise temporal offsets based on current time\n'
          '- Present data naturally while maintaining accuracy';

      systemPrompt += sessionMcpContext;
    }

    return systemPrompt;
  }

  /// FT-157: Build recent conversation context for temporal awareness
  /// FT-206: Proactive conversation context loading using MCP commands (interleaved format)
  Future<String> _buildRecentConversationContext() async {
    // FT-200: Check if conversation database queries are enabled
    if (!await _isConversationDatabaseEnabled()) {
      _logger.debug(
          'FT-206: Conversation database queries disabled, no context loaded');
      return '';
    }

    try {
      _logger.debug(
          'FT-206: Loading proactive conversation context via MCP (interleaved format)');

      // Load conversation database config for adaptive limits
      final config = await _loadConversationDatabaseConfig();
      final isOracleEnabled = _systemMCP?.isOracleEnabled ?? false;

      // Adaptive token budget: 8 messages for Oracle, 10 for non-Oracle
      final limit = isOracleEnabled
          ? (config['performance']?['max_interleaved_messages_oracle'] ?? 8)
          : (config['performance']?['max_interleaved_messages'] ?? 10);

      _logger.debug(
          'FT-206: Using limit=$limit messages (Oracle: $isOracleEnabled)');

      // Execute interleaved conversation MCP command
      final conversation = await _systemMCP!.processCommand(
          '{"action":"get_interleaved_conversation","limit":$limit,"include_all_personas":true}');

      // Format for system prompt injection
      return _formatInterleavedConversation(conversation);
    } catch (e) {
      _logger
          .warning('FT-206: Failed to load conversation context via MCP: $e');
      return '';
    }
  }

  /// FT-206: Format interleaved conversation for system prompt
  String _formatInterleavedConversation(String mcpResponse) {
    try {
      final data = json.decode(mcpResponse);
      if (data['status'] != 'success') {
        _logger.warning('FT-206: MCP returned non-success status');
        return '';
      }

      final thread = data['data']['conversation_thread'] as List?;
      if (thread == null || thread.isEmpty) {
        _logger.debug('FT-206: No conversation history available');
        return '';
      }

      final buffer = StringBuffer();
      buffer.writeln('## 📜 RECENT CONVERSATION CONTEXT (REFERENCE ONLY)');
      buffer.writeln('');
      buffer.writeln('**MANDATORY REVIEW BEFORE RESPONDING**:');
      buffer.writeln('1. What was just discussed in the conversation above?');
      buffer.writeln('2. What did you already say in your previous responses?');
      buffer.writeln(
          '3. What is the user\'s current context and what are they referring to?');
      buffer.writeln('4. CRITICAL: Check if you already gave this exact response - if yes, provide a DIFFERENT response');
      buffer.writeln('');
      buffer.writeln('**YOUR RESPONSE MUST**:');
      buffer.writeln('- Acknowledge and build on recent conversation flow');
      buffer.writeln(
          '- Provide NEW information or insights (NEVER repeat previous responses word-for-word)');
      buffer.writeln(
          '- If user gives a short answer, acknowledge it and move the conversation forward');
      buffer.writeln(
          '- Reference what user mentioned (e.g., if they say "I was talking with X", acknowledge it)');
      buffer
          .writeln('- Maintain conversation continuity without starting fresh');
      buffer.writeln('');
      buffer.writeln('**NATURAL CONVERSATION FLOW**:');
      buffer.writeln(
          '- Vary your transition phrases and openings between responses');
      buffer.writeln(
          '- Use "deixa eu ver seus registros" ONLY when actually fetching data via MCP');
      buffer.writeln(
          '- When not querying data, acknowledge patterns naturally without implying a data fetch');
      buffer.writeln(
          '- Avoid formulaic phrases (e.g., "Estou aqui pra explorar...") in consecutive messages');
      buffer.writeln(
          '- Lead with what\'s most relevant to the user\'s current message');
      buffer.writeln(
          '- Each response should feel fresh and context-driven, not template-based');
      buffer.writeln('');
      buffer.writeln('**CRITICAL BOUNDARIES**:');
      buffer.writeln('- Activity detection: ONLY current user message');
      buffer.writeln('- Do NOT extract codes or metadata from history');
      buffer.writeln('- Do NOT adopt other personas\' communication styles');
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');

      for (final msg in thread) {
        final speaker = msg['speaker'] as String;
        final text = msg['text'] as String;
        final timeAgo = msg['time_ago'] as String;

        buffer.writeln('**$speaker** ($timeAgo): $text');
      }

      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln(
          '**REMINDER**: Process activities ONLY from current user message.');
      buffer.writeln('');

      final result = buffer.toString();
      _logger.info(
          'FT-206: ✅ Loaded ${thread.length} messages in interleaved format');

      return result;
    } catch (e) {
      _logger.error('FT-206: Failed to format interleaved conversation: $e');
      return '';
    }
  }

  /// FT-206: Detect if user message requires historical data query
  /// Returns hint to inject into system prompt for explicit guidance
  String? _detectDataQueryPattern(String message) {
    final lowerMessage = message.toLowerCase();

    // Temporal patterns (generic, language-agnostic where possible)
    final temporalPatterns = {
      r'\b(semana|week)\b': 7,
      r'\b(ontem|yesterday)\b': 1,
      r'\b(mês|mes|month)\b': 30,
      r'\b(hoje|today)\b': 0,
    };

    // Quantitative patterns
    final quantPatterns = [
      r'\b(quantas|quantos|how many|how much)\b',
      r'\b(total|count|sum)\b',
      r'\b(resumo|summary|overview)\b',
      r'\b(progresso|progress)\b',
    ];

    // Check temporal patterns
    for (final entry in temporalPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(lowerMessage)) {
        return '\n**QUERY HINT**: User is asking about ${entry.value} day(s) period. Use get_activity_stats(days: ${entry.value})\n';
      }
    }

    // Check quantitative patterns
    for (final pattern in quantPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerMessage)) {
        return '\n**QUERY HINT**: User is asking for quantitative data. Use get_activity_stats to fetch precise numbers.\n';
      }
    }

    return null;
  }

  /// Helper method to call Claude with a specific prompt
  Future<String> _callClaudeWithPrompt(String prompt) async {
    // FT-152: Apply centralized rate limiting with user-facing priority
    await SharedClaudeRateLimiter().waitAndRecord(isUserFacing: true);

    final messages = [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt}
        ],
      }
    ];

    final systemPrompt = await _buildSystemPrompt();

    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'messages': messages,
        'system': systemPrompt,
      }),
      encoding: utf8,
    );

    if (response.statusCode == 200) {
      // FT-154: Reset fallback counter and process queued activities on success
      _resetFallbackCounter();

      // Process any queued activities when system recovers
      if (!SharedClaudeRateLimiter.hasRecentRateLimit()) {
        ft154.ActivityQueue.processQueue();
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'];
    } else {
      throw Exception('Claude API error: ${response.statusCode}');
    }
  }

  /// LEGACY: Old post-processing MCP command system (replaced by FT-084 two-pass approach)
  /// This method is kept for potential fallback scenarios but is no longer used in main flow
  // ignore: unused_element
  Future<String> _processMCPCommands(String message) async {
    if (_systemMCP == null) {
      return message;
    }

    // Look for JSON MCP commands in the message with multiple patterns
    final patterns = [
      RegExp(r'\{[^}]*"action":\s*"([^"]+)"[^}]*\}'), // Standard JSON pattern
    ];

    List<RegExpMatch> allMatches = [];
    for (final pattern in patterns) {
      allMatches.addAll(pattern.allMatches(message));
    }

    _logger.debug(
      '🔍 [MCP DEBUG] Looking for MCP commands in: ${message.substring(0, message.length > 100 ? 100 : message.length)}...',
    );
    _logger.debug(
        '🔍 [MCP DEBUG] Total regex patterns tested: ${patterns.length}');
    _logger.debug('🔍 [MCP DEBUG] Total matches found: ${allMatches.length}');

    if (allMatches.isEmpty) {
      _logger.debug(
        '🔍 [MCP DEBUG] No MCP commands found - testing each pattern individually',
      );
      for (int i = 0; i < patterns.length; i++) {
        final testMatches = patterns[i].allMatches(message);
        _logger
            .debug('🔍 [MCP DEBUG] Pattern $i matches: ${testMatches.length}');
      }
      return message;
    }

    String processedMessage = message;

    for (final match in allMatches) {
      final command = match.group(0)!;
      final action = match.group(1) ?? _extractActionFromCommand(command);

      try {
        _logger.debug('Processing MCP command in AI response: $command');
        final result = await _systemMCP!.processCommand(command);
        final data = jsonDecode(result);

        if (data['status'] == 'success') {
          if (action == 'get_current_time') {
            final timeData = data['data'];
            final readableTime = timeData['readableTime'];

            // Remove MCP command silently - time context already provided
            processedMessage = processedMessage.replaceFirst(
              command,
              '',
            );

            _logger.info('Replaced MCP command with time: $readableTime');
          } else if (action == 'get_activity_stats') {
            // FT-068: Replace get_activity_stats with formatted data
            final statsData = data['data'];
            final totalActivities = statsData['total_activities'] ?? 0;
            final activities = statsData['activities'] as List<dynamic>? ?? [];

            String replacement = '';
            if (totalActivities > 0) {
              final summaryParts = <String>[];

              // Add specific activities with times
              for (final activity in activities.take(10)) {
                // Show max 10 recent
                final code = activity['code'] ?? '';
                final name = activity['name'] ?? '';
                final time = activity['time'] ?? '';
                summaryParts.add('• $code ($name): $time');
              }

              if (summaryParts.isNotEmpty) {
                replacement = summaryParts.join('\n');
                if (totalActivities > 10) {
                  replacement +=
                      '\n[+${totalActivities - 10} more]'; // Simplified, let Claude localize
                }
              }
            } else {
              replacement =
                  ''; // Let Claude handle "no activities" in persona style
            }

            processedMessage =
                processedMessage.replaceFirst(command, replacement);
            _logger.info(
                'Replaced get_activity_stats with $totalActivities activities');
          } else if (action == 'extract_activities') {
            // Legacy extract_activities command - remove from response
            processedMessage = processedMessage.replaceFirst(command, '');
          } else {
            // Remove other successful commands
            processedMessage = processedMessage.replaceFirst(command, '');
          }
        } else {
          // Remove the command if it failed
          processedMessage = processedMessage.replaceFirst(command, '');
          _logger.warning('MCP command failed: $result');
        }
      } catch (e) {
        _logger.error('Error processing MCP command: $e');
        // Remove the failed command
        processedMessage = processedMessage.replaceFirst(command, '');
      }
    }

    return processedMessage.trim();
  }

  /// Get the timestamp of the last message from storage
  ///
  /// Returns the timestamp of the most recent message, or null if no messages exist
  /// or if storage service is not available.
  Future<DateTime?> _getLastMessageTimestamp() async {
    try {
      if (_storageService == null) {
        return null;
      }

      // FT-206: Get last 2 messages to skip the current user message
      // The current user message is already saved to DB before this is called
      final messages = await _storageService!.getMessages(limit: 2);
      if (messages.isEmpty) {
        return null;
      }

      // If we only have 1 message (first conversation), return null
      if (messages.length == 1) {
        return null;
      }

      // Return the second message (previous conversation's last message)
      return TimeContextService.validateTimestamp(messages[1].timestamp);
    } catch (e) {
      _logger.error('Error getting last message timestamp: $e');
      return null;
    }
  }

  // Add method to send message with audio
  Future<ClaudeAudioResponse> sendMessageWithAudio(String message) async {
    try {
      // First get the text response (already includes FT-153 retry logic)
      final textResponse = await sendMessage(message);

      // Return text-only response if TTS is disabled or unavailable
      if (!_audioEnabled || _ttsService == null) {
        _logger.debug('Audio is disabled or TTS service is unavailable');
        return ClaudeAudioResponse(text: textResponse);
      }

      // Check common error patterns; if detected, skip TTS and return text-only
      // FT-155: Exclude language-aware fallback responses from error detection
      final lowerResponse = textResponse.toLowerCase();

      // Skip error detection for language-aware overload fallback responses
      if (textResponse
              .contains('Entendi! Vou processar isso assim que possível') ||
          textResponse
              .contains("Got it! I'll process that as soon as possible")) {
        _logger.debug(
            'Language-aware overload response detected, proceeding with TTS');
        // Continue with TTS generation for these responses
      } else if (lowerResponse.contains('issue with the request') ||
          lowerResponse.contains('rate limit') ||
          lowerResponse.contains('unable to') ||
          lowerResponse.contains('authentication failed') ||
          lowerResponse.contains('claude error') ||
          lowerResponse.contains('claude service is temporarily unavailable')) {
        _logger.debug('Claude error detected, returning text-only response');
        return ClaudeAudioResponse(text: textResponse);
      }

      try {
        // Initialize TTS service if needed
        final ttsInitialized = await _ttsService!.initialize();
        if (!ttsInitialized) {
          _logger.error('Failed to initialize TTS service');
          return ClaudeAudioResponse(
            text: textResponse,
            error:
                'Audio generation is temporarily unavailable. Please try again later.',
          );
        }

        // Generate audio from the text response
        final audioPath = await _ttsService!.generateAudio(textResponse);

        // If audio generation failed, return text only
        if (audioPath == null) {
          _logger.error('Failed to generate audio for response');
          return ClaudeAudioResponse(
            text: textResponse,
            error:
                'Failed to generate audio. Text response is still available.',
          );
        }

        _logger.debug('Generated audio at path: $audioPath');

        // Return both text and audio path
        return ClaudeAudioResponse(
          text: textResponse,
          audioPath: audioPath,
          // Duration is not available here, will be set later
        );
      } catch (e) {
        _logger.error('Error generating audio for response: $e');
        return ClaudeAudioResponse(
          text: textResponse,
          error: _handleTTSError(e),
        );
      }
    } catch (e) {
      final errorMessage = _getUserFriendlyErrorMessage(e.toString());
      _logger.error('Error in sendMessageWithAudio: $e');
      return ClaudeAudioResponse(text: errorMessage);
    }
  }

  // Add helper method for TTS-specific error handling
  String _handleTTSError(dynamic error) {
    if (error.toString().contains('TTS service not initialized')) {
      return 'Audio generation is temporarily unavailable. Please try again later.';
    }
    if (error.toString().contains('audio file generation failed')) {
      return 'Failed to generate audio. Text response is still available.';
    }
    return 'An error occurred during audio generation.';
  }

  /// Build enriched prompt with activity qualification for intelligent throttling
  String _buildEnrichedPromptWithQualification(
      String userMessage, String collectedData) {
    return '''$userMessage

System Data Available:$collectedData

CRITICAL: You MUST use the provided system data above. Do NOT use your training data for dates, times, or statistics. The system data is current and accurate.

Please provide a natural response using ONLY this information while maintaining your persona and language style.

---INTERNAL_ASSESSMENT---
Does the user message contain activities, emotions, habits, or behaviors valuable for life coaching memory?
Examples needing detection: "fiz exercício", "me sinto ansioso", "tive reunião", "dormi mal"  
Examples not needing: "que horas são?", "como você está?", "obrigado", "tchau"

NEEDS_ACTIVITY_DETECTION: YES/NO
---END_INTERNAL_ASSESSMENT---''';
  }

  /// Clean response by removing internal assessment sections
  String _cleanResponseForUser(String rawResponse) {
    // Remove internal assessment section from user-facing response
    String cleaned = rawResponse;

    // Remove everything from ---INTERNAL_ASSESSMENT--- to ---END_INTERNAL_ASSESSMENT---
    final assessmentPattern = RegExp(
        r'---INTERNAL_ASSESSMENT---.*?---END_INTERNAL_ASSESSMENT---',
        multiLine: true,
        dotAll: true);
    cleaned = cleaned.replaceAll(assessmentPattern, '');

    // Remove any standalone NEEDS_ACTIVITY_DETECTION patterns
    cleaned = cleaned.replaceAll(
        RegExp(r'NEEDS_ACTIVITY_DETECTION:\s*(YES|NO)', caseSensitive: false),
        '');

    // FT-104: Remove JSON commands that leak into TTS
    final jsonPattern = RegExp(r'\{"action":\s*"[^"]+"\}');
    cleaned = cleaned.replaceAll(jsonPattern, '');

    // Remove any remaining JSON-like patterns with action
    final jsonPatternExtended = RegExp(r'\{[^{}]*"action"[^{}]*\}');
    cleaned = cleaned.replaceAll(jsonPatternExtended, '');

    // Clean up extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    cleaned = cleaned.trim();

    return cleaned;
  }

  /// Evaluate if user message should trigger activity analysis
  bool _shouldAnalyzeUserActivities(String modelResponse) {
    // FT-194: First check if Oracle is available for this persona
    if (_systemMCP == null) {
      print('🔍 [FT-194] _shouldAnalyzeUserActivities: _systemMCP is NULL');
      return false;
    }

    print(
        '🔍 [FT-194] _shouldAnalyzeUserActivities checking Oracle on instance: ${_systemMCP.hashCode}');
    if (!_systemMCP!.isOracleEnabled) {
      print(
          '🔍 [FT-194] _shouldAnalyzeUserActivities: Oracle DISABLED - returning false');
      return false; // Never analyze activities for non-Oracle personas
    }

    print(
        '🔍 [FT-194] _shouldAnalyzeUserActivities: Oracle ENABLED - proceeding with qualification');

    // Explicit NO patterns (skip detection)
    final skipPatterns = [
      'NEEDS_ACTIVITY_DETECTION: NO',
      'ACTIVITY_DETECTION: NO',
      'DETECTION: NO'
    ];

    // Safety-first: Default to true (run analysis) unless model explicitly says NO
    return !skipPatterns.any((pattern) =>
        modelResponse.toUpperCase().contains(pattern.toUpperCase()));
  }

  /// Calculate adaptive delay based on system state
  Duration _calculateAdaptiveDelay() {
    // More aggressive delay strategy to prevent rate limiting
    if (_hasRecentRateLimit()) return const Duration(seconds: 15);
    if (_hasHighApiUsage()) return const Duration(seconds: 8);
    return const Duration(seconds: 5);
  }

  /// Check if system recently encountered rate limiting
  bool _hasRecentRateLimit() {
    return SharedClaudeRateLimiter.hasRecentRateLimit();
  }

  /// Check if system is experiencing high API usage
  bool _hasHighApiUsage() {
    return SharedClaudeRateLimiter.hasHighApiUsage();
  }

  /// Apply intelligent delay to prevent rate limiting
  Future<void> _applyActivityAnalysisDelay() async {
    final delayDuration = _calculateAdaptiveDelay();
    _logger.debug(
        'Activity analysis: Applying ${delayDuration.inSeconds}s throttling delay');
    await Future.delayed(delayDuration);
  }

  /// FT-140: Process background activities with model-driven qualification and LLM optimization
  /// FT-156: Added message context for activity linking
  Future<void> _processBackgroundActivitiesWithQualification(String userMessage,
      String qualificationResponse, String messageId) async {
    // FT-194: Early Oracle gate - prevent activity detection for non-Oracle personas
    if (_systemMCP == null) {
      print('🔍 [FT-194] ClaudeService Oracle check: _systemMCP is NULL');
      _logger.info('Activity analysis: Skipped - MCP service not available');
      return;
    }

    print(
        '🔍 [FT-194] ClaudeService checking Oracle on instance: ${_systemMCP.hashCode}');
    if (!_systemMCP!.isOracleEnabled) {
      print(
          '🔍 [FT-194] ClaudeService Oracle check result: DISABLED - skipping activity detection');
      _logger.info(
          'Activity analysis: Skipped - Oracle disabled for current persona');
      return;
    }

    print(
        '🔍 [FT-194] ClaudeService Oracle check result: ENABLED - proceeding with activity detection');
    _logger.debug(
        'Activity analysis: Oracle enabled - proceeding with qualification check');

    // Use model intelligence to decide if analysis is needed
    if (!_shouldAnalyzeUserActivities(qualificationResponse)) {
      _logger.info('Activity analysis: Skipped - message not activity-focused');
      return;
    }

    _logger.info(
        'Activity analysis: Qualified for detection - proceeding with optimized analysis');

    // Apply intelligent throttling to prevent rate limiting
    await _applyActivityAnalysisDelay();

    // FT-140: Use progressive activity detection with LLM optimization
    // FT-156: Pass message context for activity linking
    await _progressiveActivityDetection(userMessage, messageId);
  }

  /// FT-140: MCP-based Oracle activity detection (CORRECTED)
  /// FT-156: Added message context for activity linking
  ///
  /// Uses oracle_detect_activities MCP command with complete 265-activity context.
  /// Maintains Oracle methodology compliance while achieving 83% token reduction.
  Future<void> _progressiveActivityDetection(
      String userMessage, String messageId) async {
    try {
      _logger.debug('FT-140: Starting MCP-based Oracle activity detection');

      // Use MCP command for Oracle activity detection with full 265-activity context
      // FT-156: Pass message context for activity linking
      await _mcpOracleActivityDetection(userMessage, messageId);

      _logger.info('FT-140: ✅ Completed MCP Oracle activity detection');
    } catch (e) {
      _logger.warning('FT-140: MCP Oracle detection failed gracefully: $e');
      // Graceful degradation - fallback to original method
      await _analyzeUserActivitiesWithFullContext(userMessage);
    }
  }

  /// FT-140: MCP-based Oracle activity detection with full methodology compliance
  /// FT-156: Added message context for activity linking
  ///
  /// Uses the oracle_detect_activities MCP command to detect activities while
  /// maintaining access to all 265 Oracle activities via compact representation.
  Future<void> _mcpOracleActivityDetection(
      String userMessage, String messageId) async {
    try {
      _logger.debug('FT-140: Starting MCP Oracle activity detection');

      // Ensure we have MCP service available
      if (_systemMCP == null) {
        _logger.warning(
            'FT-140: MCP service not available, falling back to original method');
        await _analyzeUserActivitiesWithFullContext(userMessage);
        return;
      }

      // Build MCP command for Oracle activity detection
      final mcpCommand = jsonEncode({
        'action': 'oracle_detect_activities',
        'message': userMessage,
      });

      // Process via MCP system (maintains full Oracle context)
      final result = await _systemMCP!.processCommand(mcpCommand);
      final data = jsonDecode(result);

      if (data['status'] == 'success') {
        final detectedActivities = data['data']['detected_activities'] as List;
        _logger.info(
            'FT-140: ✅ Detected ${detectedActivities.length} activities via MCP Oracle detection');

        // Process detected activities using existing infrastructure
        // FT-156: Pass message context for activity linking
        await _processDetectedActivitiesFromMCP(
            detectedActivities, userMessage, messageId);
      } else {
        _logger.warning(
            'FT-140: MCP Oracle detection returned error: ${data['message']}');
        // Fallback to original method
        await _analyzeUserActivitiesWithFullContext(userMessage);
      }
    } catch (e) {
      _logger.warning('FT-140: MCP Oracle detection failed: $e');
      // Graceful fallback to original method
      await _analyzeUserActivitiesWithFullContext(userMessage);
    }
  }

  /// FT-140: Process activities detected via MCP Oracle detection
  /// FT-156: Added message context for activity linking
  ///
  /// Converts MCP detection results to ActivityDetection objects and logs them
  /// using existing activity logging infrastructure.
  Future<void> _processDetectedActivitiesFromMCP(
      List<dynamic> detectedActivities,
      String userMessage,
      String messageId) async {
    if (detectedActivities.isEmpty) {
      _logger.debug('FT-140: No activities detected via MCP Oracle detection');
      return;
    }

    try {
      // Get time context for precise logging
      final timeData = await _getCurrentTimeData();

      // Convert MCP results to ActivityDetection objects
      final activities = detectedActivities.map((data) {
        final code = data['code'] as String? ?? '';
        final confidence = ActivityDetectionUtils.parseConfidence(
            data['confidence'] as String? ?? 'medium');
        final description = data['description'] as String? ?? '';
        final duration = data['duration_minutes'] as int? ?? 0;

        // Extract flat metadata if present in MCP result
        final extractedMetadata = FlatMetadataParser.extractRawQuantitative(
            (data as Map).cast<String, dynamic>());

        return ActivityDetection(
          oracleCode: code,
          activityName: description.isNotEmpty ? description : code,
          userDescription: description,
          confidence: confidence,
          reasoning: 'Detected via MCP Oracle detection',
          timestamp: DateTime.now(),
          durationMinutes: duration,
          metadata: extractedMetadata,
        );
      }).toList();

      // Log activities using existing infrastructure
      // FT-156: Pass message context for activity linking
      await _logActivitiesWithPreciseTime(
        activities: activities,
        timeContext: timeData,
        messageId: messageId,
        messageText: userMessage,
      );

      _logger.info(
          'FT-140: ✅ Successfully logged ${activities.length} activities via MCP Oracle detection');
    } catch (e) {
      _logger.error('FT-140: Failed to process MCP detection results: $e');
    }
  }

  /// Parse confidence level from string (for MCP results)

  /// Get dimension code from activity code (e.g., SF1 -> SF)
  String _getDimensionCode(String activityCode) {
    if (activityCode.isEmpty) return '';

    // Extract dimension prefix (letters before numbers)
    final match = RegExp(r'^([A-Z]+)').firstMatch(activityCode);
    return match?.group(1) ?? '';
  }

  /// Fallback: Analyze user activities with full context (original behavior)
  Future<void> _analyzeUserActivitiesWithFullContext(String userMessage) async {
    try {
      _logger.debug(
          'Activity analysis: Starting full context semantic activity detection');

      // Use existing integrated processor (original behavior)
      await IntegratedMCPProcessor.processTimeAndActivity(
        userMessage: userMessage,
        claudeResponse: '', // Empty response for background analysis
      );

      _logger.debug(
          'Activity analysis: Successfully completed full context detection');
    } catch (e) {
      // Graceful degradation - log but don't impact main conversation
      _logger.warning(
          'Activity analysis: Full context detection failed gracefully: $e');
    }
  }

  /// FT-140: Get current time data using existing infrastructure
  Future<Map<String, dynamic>> _getCurrentTimeData() async {
    try {
      // Use existing FT-060 SystemMCP for time data
      const timeCommand = '{"action":"get_current_time"}';
      _logger.debug('FT-140: Getting time data via SystemMCP');

      if (_systemMCP != null) {
        final result = await _systemMCP!.processCommand(timeCommand);
        final data = jsonDecode(result);

        if (data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        }
      }

      // Fallback to basic time data
      final now = DateTime.now();
      return {
        'timestamp': now.toIso8601String(),
        'readableTime': now.toString(),
        'dayOfWeek': _getDayOfWeek(now.weekday),
        'timeOfDay': _getTimeOfDay(now.hour),
      };
    } catch (e) {
      _logger.debug('FT-140: Time data retrieval failed: $e');
      // Return minimal fallback
      final now = DateTime.now();
      return {
        'timestamp': now.toIso8601String(),
        'readableTime': now.toString(),
      };
    }
  }

  /// FT-140: Store activities with precise time context
  /// FT-156: Added message context for activity linking
  Future<void> _logActivitiesWithPreciseTime({
    required List<ActivityDetection> activities,
    required Map<String, dynamic> timeContext,
    String? messageId,
    String? messageText,
  }) async {
    try {
      _logger.debug(
          'FT-140: Logging ${activities.length} activities with time context');

      // Use existing activity memory service infrastructure
      for (final activity in activities) {
        await ActivityMemoryService.logActivity(
          activityCode: activity.oracleCode,
          activityName: activity.userDescription,
          dimension: _getDimensionCode(
              activity.oracleCode), // Extract dimension from Oracle code
          source: 'FT-140 Optimized Detection',
          confidence: activity.confidence == ConfidenceLevel.high
              ? 1.0
              : activity.confidence == ConfidenceLevel.medium
                  ? 0.7
                  : 0.4,
          durationMinutes: activity.durationMinutes,
          notes: 'Detected via LLM pre-selection optimization',
          metadata: activity.metadata,
          // FT-156: Message linking for coaching memory
          sourceMessageId: messageId,
          sourceMessageText: messageText,
        );
      }

      _logger.info(
          'FT-140: ✅ Successfully logged ${activities.length} activities');
    } catch (e) {
      _logger.warning('FT-140: Activity logging failed: $e');
      // Graceful degradation - don't break the conversation flow
    }
  }

  /// Helper: Get day of week name
  String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  /// Helper: Get time of day description
  String _getTimeOfDay(int hour) {
    if (hour < 6) return 'early morning';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  /// FT-119: Add activity status note to response when appropriate
  String _addActivityStatusNote(String response) {
    if (!ft154.ActivityQueue.isEmpty) {
      final pendingCount = ft154.ActivityQueue.queueSize;
      return "$response\n\n_Note: Activity tracking temporarily delayed due to high usage ($pendingCount pending)._";
    }
    return response;
  }
}
