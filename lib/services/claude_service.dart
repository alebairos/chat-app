import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ai_personas_app/config/config_loader.dart';

import 'system_mcp_service.dart';
import '../utils/logger.dart';
import '../features/audio_assistant/tts_service.dart';
import '../models/claude_audio_response.dart';
import 'time_context_service.dart';

import 'integrated_mcp_processor.dart';
import 'activity_memory_service.dart';

import 'chat_storage_service.dart';

/// FT-119: Rate limit state tracking for graceful degradation
class _RateLimitTracker {
  static DateTime? _lastRateLimit;
  static final List<DateTime> _apiCallHistory = [];
  static const int _maxCallsPerMinute = 8;
  static const Duration _rateLimitMemory = Duration(minutes: 2);

  /// Check if system recently encountered rate limiting
  static bool hasRecentRateLimit() {
    if (_lastRateLimit == null) return false;
    return DateTime.now().difference(_lastRateLimit!) < _rateLimitMemory;
  }

  /// Record a rate limit event
  static void recordRateLimit() {
    _lastRateLimit = DateTime.now();
  }

  /// Check if system is experiencing high API usage
  static bool hasHighApiUsage() {
    _cleanOldCalls();
    return _apiCallHistory.length > _maxCallsPerMinute;
  }

  /// Record an API call for usage tracking
  static void recordApiCall() {
    _apiCallHistory.add(DateTime.now());
    _cleanOldCalls();
  }

  /// Clean old API calls from tracking (older than 1 minute)
  static void _cleanOldCalls() {
    final cutoff = DateTime.now().subtract(Duration(minutes: 1));
    _apiCallHistory.removeWhere((call) => call.isBefore(cutoff));
  }

  /// Get current rate limit status for debugging
  static Map<String, dynamic> getStatus() {
    _cleanOldCalls();
    return {
      'hasRecentRateLimit': hasRecentRateLimit(),
      'hasHighApiUsage': hasHighApiUsage(),
      'lastRateLimit': _lastRateLimit?.toIso8601String(),
      'apiCallsLastMinute': _apiCallHistory.length,
      'maxCallsPerMinute': _maxCallsPerMinute,
    };
  }
}

// Helper class for validation results
class ValidationResult {
  final bool isValid;
  final String reason;

  ValidationResult(this.isValid, this.reason);
}

/// Public interface for rate limit tracking (FT-119)
class RateLimitTracker {
  /// Check if system recently encountered rate limiting
  static bool hasRecentRateLimit() {
    return _RateLimitTracker.hasRecentRateLimit();
  }

  /// Check if system is experiencing high API usage
  static bool hasHighApiUsage() {
    return _RateLimitTracker.hasHighApiUsage();
  }

  /// Get comprehensive status for monitoring
  static Map<String, dynamic> getStatus() {
    return _RateLimitTracker.getStatus();
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
              _RateLimitTracker
                  .recordRateLimit(); // FT-119: Track rate limit event
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
            _RateLimitTracker
                .recordRateLimit(); // FT-119: Track rate limit event
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

    // Add system MCP function documentation with enhanced temporal intelligence (FT-095)
    if (_systemMCP != null) {
      String mcpFunctions = '\n\nSystem Functions Available:\n'
          'You can call system functions by using JSON format: {"action": "function_name"}\n\n'
          '🎯 MANDATORY DATA QUERIES:\n'
          'For ANY activity-related questions, you MUST generate fresh MCP commands:\n'
          '- "o que eu fiz [tempo]" → {"action": "get_activity_stats"} REQUIRED\n'
          '- "quantas/quanto [atividade]" → {"action": "get_activity_stats"} REQUIRED\n'
          '- "como foi [dia/período]" → {"action": "get_activity_stats"} REQUIRED\n'
          '- Activity comparisons → {"action": "get_activity_stats"} REQUIRED\n'
          '- "quais atividades" → {"action": "get_activity_stats"} REQUIRED\n'
          '- "meu desempenho" → {"action": "get_activity_stats"} REQUIRED\n'
          '- Questions about specific days, counts, or activity summaries → ALWAYS query\n'
          'NEVER rely on conversation memory for activity data - ALWAYS query fresh data.\n'
          'Like a coach checking their notes: conversation memory may be imprecise, fresh data ensures accurate guidance.\n\n'
          'Available functions:\n'
          '- get_current_time: Returns ALL temporal information (date, day, time, day of week)\n'
          '  ALWAYS use for temporal queries:\n'
          '  • "que horas são?" / "what time?" → get_current_time\n'
          '  • "que dia é hoje?" / "what day?" → get_current_time\n'
          '  • "que data é hoje?" / "what date?" → get_current_time\n'
          '  • "que dia da semana?" / "day of week?" → get_current_time\n'
          '  Returns: timestamp, hour, minute, dayOfWeek, readableTime (PT-BR formatted)\n'
          '- get_device_info: Returns device platform, OS version, locale, and system info\n'
          '- get_activity_stats: Get precise activity tracking data from database\n'
          '  Usage: {"action": "get_activity_stats", "days": 0} for today\'s activities\n'
          '  Usage: {"action": "get_activity_stats", "days": 1} for yesterday\'s activities\n'
          '  Usage: {"action": "get_activity_stats", "days": 7} for last 7 days (optional days parameter)\n'
          '- get_message_stats: Get chat message statistics from database\n'
          '  Usage: {"action": "get_message_stats", "limit": 10} (optional limit parameter, defaults to 10)\n\n'
          '## TEMPORAL INTELLIGENCE GUIDELINES (FT-095)\n\n'
          '### Temporal Expression Mapping\n'
          'When users ask about activities with time references, automatically map to appropriate MCP commands:\n\n'
          '**Temporal Intelligence Guidelines:**\n'
          'Use your natural understanding of temporal expressions to generate appropriate MCP commands.\n\n'
          '**Command Structure**: {"action": "get_activity_stats", "days": N}\n'
          '- days: 0 = today (current day activities)\n'
          '- days: 1 = yesterday (previous day activities)\n'
          '- days: 7 = last week (7 days of data)\n'
          '- days: 14 = last 2 weeks (14 days of data)\n'
          '- days: 30 = last month (30 days of data)\n\n'
          '**Context-Aware Temporal Mapping**:\n'
          'Consider TODAY\'S context when interpreting temporal references:\n'
          '- Today is: [check current day from time context]\n'
          '- "hoje" (today) → days: 0\n'
          '- "ontem" (yesterday) → days: 1\n'
          '- Specific day names: Calculate days back from today\n'
          '- "sábado", "segunda", etc. → Count days from current day\n'
          '- Period references: "semana", "mês" → Use range parameters\n\n'
          '**🎯 PRECISE DAY CALCULATION (FT-099):**\n'
          'For SPECIFIC DAY queries, calculate exact days parameter:\n'
          '- Monday asking about "sábado" (Saturday) → days: 3 (gets Saturday only)\n'
          '- Tuesday asking about "domingo" (Sunday) → days: 2 (gets Sunday only)\n'
          '- Wednesday asking about "segunda" (Monday) → days: 2 (gets Monday only)\n'
          '- CRITICAL: Use days parameter that reaches the specific day, not ranges\n'
          '- Single day name = single day data, not multi-day periods\n\n'
          '**Query Specificity Intelligence**:\n'
          '⚠️ CRITICAL: Distinguish between SPECIFIC DAYS vs PERIODS:\n'
          '- Single day name ("sábado") → Calculate precise days to get ONLY that day\n'
          '- Period reference ("esta semana") → Query the entire period range\n'
          '- When user asks about a specific day, avoid multi-day ranges\n'
          '- Use temporal context to calculate precise day offsets\n'
          '- Example: Monday + "sábado" = days: 3 (not days: 2 which gives 2 days)\n\n'
          'Trust your understanding of calendar relationships and user intent. '
          'Map temporal expressions to ensure queries capture the exact timeframe requested.\n\n'
          '### Complex Query Processing\n'
          'For multi-part temporal queries, use structured approach:\n\n'
          '**Exclusion Queries ("além de X", "other than X"):**\n'
          '1. Execute appropriate temporal query: {"action": "get_activity_stats", "days": N}\n'
          '2. Filter returned data to exclude mentioned activities (e.g., SF1 for water)\n'
          '3. Present filtered results with context\n\n'
          '**Comparison Queries ("comparado com", "vs", "compared to"):**\n'
          '1. Execute current period query\n'
          '2. Execute previous period query (typically double the days for comparison)\n'
          '3. Calculate differences and identify trends\n'
          '4. Present comparative analysis\n\n'
          '**Time-of-Day Filtering ("manhã", "tarde", "morning", "afternoon"):**\n'
          '1. Execute temporal query for appropriate day(s)\n'
          '2. Filter results using "timeOfDay" field from activity data\n'
          '3. Present time-specific activities\n\n'
          '### Data Utilization Rules\n'
          '- ALWAYS use real data from MCP commands, never approximate\n'
          '- Use EXACT counts from "total_activities" and "by_activity" fields\n'
          '- Reference specific times and counts from returned data\n'
          '- Use exact activity codes (SF1, T8, etc.) from results\n'
          '- Count activities from the activities array for precision\n'
          '- Never inflate or summarize numbers - report actual database counts\n'
          '- Include confidence scores and timestamps when relevant\n'
          '- Present data in natural, conversational language while being accurate\n\n'
          '**Smart Data Filtering for Specific Day Queries**:\n'
          'When user asks about a SPECIFIC DAY (e.g., "sábado", "terça-feira"):\n'
          '- Check the "period" field to understand data scope (e.g., "last_2_days")\n'
          '- If period covers multiple days but user wants one specific day:\n'
          '  * Filter activities array by examining timestamps/dates\n'
          '  * Only count activities that occurred on the requested day\n'
          '  * Recalculate totals based on filtered activities\n'
          '- Use "full_timestamp" field to determine which specific day each activity occurred\n'
          '- Report only activities from the day actually requested by user\n'
          'Example: User asks "sábado" but data covers "last_2_days" (Sat+Sun)\n'
          '→ Filter timestamps for Saturday only and count those activities\n\n'
          '### Contextual Response Enhancement\n'
          'Adapt response tone and language based on temporal context:\n\n'
          '**Time-of-Day Awareness:**\n'
          '- Morning queries (6-12h): "Esta manhã você já...", "Bom ritmo para começar o dia!"\n'
          '- Afternoon queries (12-18h): "Hoje pela manhã você fez... E à tarde?", "Como vai o restante do dia?"\n'
          '- Evening queries (18-22h): "Hoje você completou...", "Como foi o dia?"\n'
          '- Night queries (22-6h): "Reflexão do dia...", "Hora de descansar?"\n\n'
          '**Data-Driven Insights:**\n'
          '- Identify patterns: "água manteve consistência (5x)", "pomodoros diminuíram de 3x para 1x"\n'
          '- Suggest improvements: "Quer aumentar o foco à tarde?", "Que tal mais água pela manhã?"\n'
          '- Celebrate achievements: "Excelente consistência!", "Superou a meta da semana!"\n'
          '- Reference specific times: "às 10:58", "entre 11:23 e 11:24"\n\n'
          '**Natural Query Flow:**\n'
          '- Use MCP data to generate relevant follow-up questions\n'
          '- Connect current data to previous patterns when available\n'
          '- Maintain conversational persona while being data-accurate\n'
          '- Provide actionable insights based on real activity trends';

      systemPrompt += mcpFunctions;
    }

    return systemPrompt;
  }

  /// Helper method to call Claude with a specific prompt
  Future<String> _callClaudeWithPrompt(String prompt) async {
    // FT-119: Track API call for rate limiting
    _RateLimitTracker.recordApiCall();

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
    return _RateLimitTracker.hasRecentRateLimit();
  }

  /// Check if system is experiencing high API usage
  bool _hasHighApiUsage() {
    return _RateLimitTracker.hasHighApiUsage();
  }

  /// Apply intelligent delay to prevent rate limiting
  Future<void> _applyActivityAnalysisDelay() async {
    final delayDuration = _calculateAdaptiveDelay();
    _logger.debug(
        'Activity analysis: Applying ${delayDuration.inSeconds}s throttling delay');
    await Future.delayed(delayDuration);
  }

  /// Process background activities with model-driven qualification
  Future<void> _processBackgroundActivitiesWithQualification(
      String userMessage, String qualificationResponse) async {
    // Use model intelligence to decide if analysis is needed
    if (!_shouldAnalyzeUserActivities(qualificationResponse)) {
      _logger.info('Activity analysis: Skipped - message not activity-focused');
      return;
    }

    _logger.info(
        'Activity analysis: Qualified for detection - proceeding with throttled analysis');

    // Apply intelligent throttling to prevent rate limiting
    await _applyActivityAnalysisDelay();

    // Run existing activity detection with throttling protection
    await _analyzeUserActivitiesWithContext(userMessage);
  }

  /// Analyze user activities with context (throttled version of background detection)
  Future<void> _analyzeUserActivitiesWithContext(String userMessage) async {
    try {
      _logger.debug('Activity analysis: Starting semantic activity detection');

      // Use existing integrated processor but with throttling
      await IntegratedMCPProcessor.processTimeAndActivity(
        userMessage: userMessage,
        claudeResponse: '', // Empty response for background analysis
      );

      _logger.debug('Activity analysis: Successfully completed detection');
    } catch (e) {
      // Graceful degradation - log but don't impact main conversation
      _logger.warning('Activity analysis: Detection failed gracefully: $e');
    }
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
