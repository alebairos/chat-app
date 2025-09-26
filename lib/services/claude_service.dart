import 'dart:convert';
import 'package:http/http.dart' as http;
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

  ClaudeService({
    http.Client? client,
    SystemMCPService? systemMCP,
    ConfigLoader? configLoader,
    AudioAssistantTTSService? ttsService,
    ChatStorageService? storageService,
    bool audioEnabled = true,
  })  : _client = client ?? http.Client(),
        _systemMCP = systemMCP,
        _configLoader = configLoader ?? ConfigLoader(),
        _ttsService = ttsService,
        _storageService = storageService,
        _audioEnabled = audioEnabled {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    _model =
        (dotenv.env['ANTHROPIC_MODEL'] ?? 'claude-3-5-sonnet-latest').trim();
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

  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        _systemPrompt = await _configLoader.loadSystemPrompt();
        _isInitialized = true;
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
              return 'You\'ve reached the rate limit. Please wait a moment before sending more messages.';
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
    try {
      await initialize();

      // Always reload system prompt to get current persona
      _systemPrompt = await _configLoader.loadSystemPrompt();

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

      // Add conversation history
      messages.addAll(_conversationHistory);

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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        var assistantMessage = data['content'][0]['text'];

        // Log the original AI response to see what we're working with
        _logger.debug('Original AI response: $assistantMessage');

        // FT-084: Check if Claude requested data using intelligent two-pass approach
        if (_containsMCPCommand(assistantMessage)) {
          _logger.info(
              '🧠 FT-084: Detected data request, switching to two-pass processing');
          final dataInformedResponse =
              await _processDataRequiredQuery(message, assistantMessage);

          // Background activity detection handled in _processDataRequiredQuery

          return dataInformedResponse;
        }

        // Regular conversation flow (no data required)
        _logger.debug('Regular conversation - no data required');

        // FT-104: Clean response to remove JSON commands before TTS
        final cleanedResponse = _cleanResponseForUser(assistantMessage);

        // Process background activities with qualification for regular flow
        _processBackgroundActivitiesWithQualification(
            message, assistantMessage);

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
            return 'Rate limit exceeded. Please try again later.';
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
                return 'Claude is currently experiencing high demand. Please try again in a moment.';
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
  Future<String> _processDataRequiredQuery(
      String userMessage, String initialResponse) async {
    try {
      _logger.info(
          '🧠 FT-084: Processing data-required query with two-pass approach');

      // Extract MCP commands from Claude's initial response
      final mcpCommands = _extractMCPCommands(initialResponse);
      _logger.debug('Found MCP commands: $mcpCommands');

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
          '🔍 [DATA DEBUG] Collected data preview: ${collectedData.length > 500 ? collectedData.substring(0, 500) + "..." : collectedData}');

      // FT-085: Smart delay to prevent API rate limiting bursts
      // 500ms delay is imperceptible to users but prevents 429 errors
      _logger.debug('🕐 FT-085: Applying 500ms delay to prevent rate limiting');
      await Future.delayed(Duration(milliseconds: 500));
      _logger
          .debug('✅ FT-085: Delay completed, proceeding with second API call');

      // Second pass: Get data-informed response
      final rawResponse = await _callClaudeWithPrompt(enrichedPrompt);
      final dataInformedResponse = _cleanResponseForUser(rawResponse);

      // Add to conversation history
      _conversationHistory.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': userMessage}
        ],
      });

      _conversationHistory.add({
        'role': 'assistant',
        'content': [
          {'type': 'text', 'text': dataInformedResponse}
        ],
      });

      _logger
          .info('✅ FT-084: Successfully completed two-pass data integration');

      // Process background activities with qualification using raw response
      await _processBackgroundActivitiesWithQualification(
          userMessage, rawResponse);

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

    // Build enhanced system prompt with time context
    String systemPrompt = _systemPrompt ?? '';

    // Add time context at the beginning if available
    if (timeContext.isNotEmpty) {
      systemPrompt = '$timeContext\n\n$systemPrompt';
    }

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

      final messages = await _storageService!.getMessages(limit: 1);
      if (messages.isEmpty) {
        return null;
      }

      return TimeContextService.validateTimestamp(messages.first.timestamp);
    } catch (e) {
      _logger.error('Error getting last message timestamp: $e');
      return null;
    }
  }

  // Add method to send message with audio
  Future<ClaudeAudioResponse> sendMessageWithAudio(String message) async {
    try {
      // First get the text response
      final textResponse = await sendMessage(message);

      // Return text-only response if TTS is disabled or unavailable
      if (!_audioEnabled || _ttsService == null) {
        _logger.debug('Audio is disabled or TTS service is unavailable');
        return ClaudeAudioResponse(text: textResponse);
      }

      // Check common error patterns; if detected, skip TTS and return text-only
      final lowerResponse = textResponse.toLowerCase();
      if (lowerResponse.contains('issue with the request') ||
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
    if (_hasRecentRateLimit()) return Duration(seconds: 15);
    if (_hasHighApiUsage()) return Duration(seconds: 8);
    return Duration(seconds: 5);
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
  Future<void> _processBackgroundActivitiesWithQualification(
      String userMessage, String qualificationResponse) async {
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
    await _progressiveActivityDetection(userMessage);
  }

  /// FT-140: MCP-based Oracle activity detection (CORRECTED)
  ///
  /// Uses oracle_detect_activities MCP command with complete 265-activity context.
  /// Maintains Oracle methodology compliance while achieving 83% token reduction.
  Future<void> _progressiveActivityDetection(String userMessage) async {
    try {
      _logger.debug('FT-140: Starting MCP-based Oracle activity detection');

      // Use MCP command for Oracle activity detection with full 265-activity context
      await _mcpOracleActivityDetection(userMessage);

      _logger.info('FT-140: ✅ Completed MCP Oracle activity detection');
    } catch (e) {
      _logger.warning('FT-140: MCP Oracle detection failed gracefully: $e');
      // Graceful degradation - fallback to original method
      await _analyzeUserActivitiesWithFullContext(userMessage);
    }
  }

  /// FT-140: MCP-based Oracle activity detection with full methodology compliance
  ///
  /// Uses the oracle_detect_activities MCP command to detect activities while
  /// maintaining access to all 265 Oracle activities via compact representation.
  Future<void> _mcpOracleActivityDetection(String userMessage) async {
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
        await _processDetectedActivitiesFromMCP(
            detectedActivities, userMessage);
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
  ///
  /// Converts MCP detection results to ActivityDetection objects and logs them
  /// using existing activity logging infrastructure.
  Future<void> _processDetectedActivitiesFromMCP(
      List<dynamic> detectedActivities, String userMessage) async {
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
      await _logActivitiesWithPreciseTime(
        activities: activities,
        timeContext: timeData,
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
  Future<void> _logActivitiesWithPreciseTime({
    required List<ActivityDetection> activities,
    required Map<String, dynamic> timeContext,
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
    if (ActivityQueue.hasPendingActivities()) {
      final pendingCount = ActivityQueue.getPendingCount();
      return "$response\n\n_Note: Activity tracking temporarily delayed due to high usage ($pendingCount pending)._";
    }
    return response;
  }
}
