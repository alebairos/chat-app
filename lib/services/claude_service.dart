import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:character_ai_clone/config/config_loader.dart';

import 'system_mcp_service.dart';
import '../utils/logger.dart';
import '../features/audio_assistant/tts_service.dart';
import '../models/claude_audio_response.dart';
import 'time_context_service.dart';

import 'integrated_mcp_processor.dart';

import 'chat_storage_service.dart';

// Helper class for validation results
class ValidationResult {
  final bool isValid;
  final String reason;

  ValidationResult(this.isValid, this.reason);
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
      final timeContext = await TimeContextService.generatePreciseTimeContext(
        lastMessageTime,
      );

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

      // Build enhanced system prompt with time and activity context
      String systemPrompt = _systemPrompt ?? '';

      // Add time context at the beginning if available
      if (timeContext.isNotEmpty) {
        systemPrompt = '$timeContext\n\n$systemPrompt';
      }

      // REMOVED: Activity context injection - now only available via MCP when explicitly requested
      // if (activityContext.isNotEmpty) {
      //   systemPrompt = '$systemPrompt\n\n$activityContext';
      // }

      // Add system MCP function documentation
      if (_systemMCP != null) {
        String mcpFunctions = '\n\nSystem Functions Available:\n'
            'You can call system functions by using JSON format: {"action": "function_name"}\n'
            'Available functions:\n'
            '- get_current_time: Returns current date, time, and temporal information\n'
            '- get_device_info: Returns device platform, OS version, locale, and system info\n'
            '- get_activity_stats: Get precise activity tracking data from database\n'
            '  Usage: {"action": "get_activity_stats", "days": 1} (optional days parameter, defaults to today)\n'
            '- get_message_stats: Get chat message statistics from database\n'
            '  Usage: {"action": "get_message_stats", "limit": 10} (optional limit parameter, defaults to 10)';

        systemPrompt += mcpFunctions;
      }

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

        // Process MCP commands in the AI's response
        // Process any MCP commands in the assistant's response
        _logger.debug(
            '🔍 [MCP DEBUG] Before processing: ${assistantMessage.length} chars');
        _logger.debug(
            '🔍 [MCP DEBUG] Response preview: ${assistantMessage.substring(0, assistantMessage.length > 200 ? 200 : assistantMessage.length)}');
        assistantMessage = await _processMCPCommands(assistantMessage);
        _logger.debug(
            '🔍 [MCP DEBUG] After processing: ${assistantMessage.length} chars');

        // FT-064: Two-pass semantic activity detection (background processing)
        // Pass 1: Return immediate conversation response (no latency impact)
        // Pass 2: Background semantic analysis for activity detection
        _performBackgroundActivityDetection(message, assistantMessage);

        // Add assistant's response to history using content blocks format
        _conversationHistory.add({
          'role': 'assistant',
          'content': [
            {'type': 'text', 'text': assistantMessage},
          ],
        });

        return assistantMessage;
      } else {
        // Handle different HTTP status codes
        switch (response.statusCode) {
          case 401:
            return 'Authentication failed. Please check your API key.';
          case 429:
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
            final timeOfDay = timeData['timeOfDay'];

            // Replace the JSON command with a natural time response
            processedMessage = processedMessage.replaceFirst(
              command,
              'It is currently $readableTime ($timeOfDay).',
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
                      '\n[... and ${totalActivities - 10} more activities]';
                }
              }
            } else {
              replacement = 'No activities found for the requested period.';
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

  /// FT-064: Background semantic activity detection (Pass 2)
  ///
  /// Performs semantic activity detection without blocking conversation flow.
  /// Uses IntegratedMCPProcessor to coordinate time + activity detection.
  void _performBackgroundActivityDetection(
      String userMessage, String assistantMessage) {
    // Use unawaited to ensure background processing doesn't block response
    () async {
      try {
        _logger.debug('FT-064: Starting background activity detection');

        // Coordinate time + activity detection via IntegratedMCPProcessor
        await IntegratedMCPProcessor.processTimeAndActivity(
          userMessage: userMessage,
          claudeResponse: assistantMessage,
        );

        _logger.debug('FT-064: Background activity detection completed');
      } catch (e) {
        // Silent failure - never interrupt conversation flow
        _logger
            .debug('FT-064: Background activity detection failed silently: $e');
      }
    }();
  }
}
