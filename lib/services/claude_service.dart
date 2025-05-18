import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/config_loader.dart';
import 'life_plan_mcp_service.dart';
import '../models/life_plan/dimensions.dart';
import '../utils/logger.dart';
import '../features/audio_assistant/tts_service.dart';
import '../models/claude_audio_response.dart';

// Helper class for validation results
class ValidationResult {
  final bool isValid;
  final String reason;

  ValidationResult(this.isValid, this.reason);
}

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  late final String _apiKey;
  final List<Map<String, String>> _conversationHistory = [];
  String? _systemPrompt;
  bool _isInitialized = false;
  final _logger = Logger();
  final http.Client _client;
  final LifePlanMCPService? _lifePlanMCP;
  final ConfigLoader _configLoader;

  // Add these fields
  final AudioAssistantTTSService? _ttsService;
  bool _audioEnabled = true;

  ClaudeService({
    http.Client? client,
    LifePlanMCPService? lifePlanMCP,
    ConfigLoader? configLoader,
    AudioAssistantTTSService? ttsService,
    bool audioEnabled = true,
  })  : _client = client ?? http.Client(),
        _lifePlanMCP = lifePlanMCP,
        _configLoader = configLoader ?? ConfigLoader(),
        _ttsService = ttsService,
        _audioEnabled = audioEnabled {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  }

  // Add getter and setter for audioEnabled
  bool get audioEnabled => _audioEnabled;
  set audioEnabled(bool value) => _audioEnabled = value;

  // Method to enable or disable logging
  void setLogging(bool enable) {
    _logger.setLogging(enable);
    // Also set logging for MCP service if available
    _lifePlanMCP?.setLogging(enable);
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
            error.substring(error.indexOf('{'), error.lastIndexOf('}') + 1));

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

  // Helper method to process MCP commands and get data
  Future<Map<String, dynamic>> _processMCPCommand(String command) async {
    if (_lifePlanMCP == null) {
      return {'error': 'MCP service not available'};
    }

    try {
      final response = _lifePlanMCP!.processCommand(command);
      final decoded = json.decode(response);
      return decoded;
    } catch (e) {
      _logger.error('Error processing MCP command: $e');
      return {'error': e.toString()};
    }
  }

  // Helper method to detect dimensions in user message
  List<String> _detectDimensions(String message) {
    // Instead of hard-coded keyword matching, we'll fetch all dimensions
    // and let Claude's system prompt handle the detection
    return Dimensions.codes; // Return all dimension codes
  }

  // Helper method to fetch relevant MCP data based on user message
  Future<String> _fetchRelevantMCPData(String message) async {
    if (_lifePlanMCP == null) {
      return '';
    }

    final dimensions = _detectDimensions(message);
    final buffer = StringBuffer();

    // If no dimensions detected, fetch data for all dimensions
    if (dimensions.isEmpty) {
      dimensions.addAll(['SF', 'SM', 'R']);
    }

    // Fetch goals for each detected dimension
    for (final dimension in dimensions) {
      final command = json
          .encode({'action': 'get_goals_by_dimension', 'dimension': dimension});

      final result = await _processMCPCommand(command);
      if (result['status'] == 'success' && result['data'] != null) {
        buffer.writeln('\nMCP DATA - Goals for dimension $dimension:');
        buffer.writeln(json.encode(result['data']));

        // For each goal, try to fetch the associated track
        for (final goal in result['data']) {
          if (goal['trackId'] != null) {
            final trackCommand = json.encode(
                {'action': 'get_track_by_id', 'trackId': goal['trackId']});

            final trackResult = await _processMCPCommand(trackCommand);
            if (trackResult['status'] == 'success' &&
                trackResult['data'] != null) {
              buffer.writeln('\nMCP DATA - Track for goal ${goal['id']}:');
              buffer.writeln(json.encode(trackResult['data']));

              // For each challenge in the track, fetch habits
              if (trackResult['data']['challenges'] != null) {
                for (final challenge in trackResult['data']['challenges']) {
                  final habitsCommand = json.encode({
                    'action': 'get_habits_for_challenge',
                    'trackId': goal['trackId'],
                    'challengeCode': challenge['code']
                  });

                  final habitsResult = await _processMCPCommand(habitsCommand);
                  if (habitsResult['status'] == 'success' &&
                      habitsResult['data'] != null) {
                    buffer.writeln(
                        '\nMCP DATA - Habits for challenge ${challenge['code']}:');
                    buffer.writeln(json.encode(habitsResult['data']));
                  }
                }
              }
            }
          }
        }
      }
    }

    // Fetch recommended habits for each dimension
    for (final dimension in dimensions) {
      final command = json.encode({
        'action': 'get_recommended_habits',
        'dimension': dimension,
        'minImpact': 3
      });

      final result = await _processMCPCommand(command);
      if (result['status'] == 'success' && result['data'] != null) {
        buffer.writeln(
            '\nMCP DATA - Recommended habits for dimension $dimension:');
        buffer.writeln(json.encode(result['data']));
      }
    }

    return buffer.toString();
  }

  Future<String> sendMessage(String message) async {
    try {
      await initialize();

      // Check if message contains a life plan command
      if (_lifePlanMCP != null && message.startsWith('{')) {
        try {
          final Map<String, dynamic> command = json.decode(message);
          final action = command['action'] as String?;

          if (action == null) {
            return 'Missing required parameter: action';
          }

          try {
            return _lifePlanMCP!.processCommand(message);
          } catch (e) {
            return 'Missing required parameter: ${e.toString()}';
          }
        } catch (e) {
          return 'Invalid command format';
        }
      }

      // Add user message to history
      _conversationHistory.add({
        'role': 'user',
        'content': message,
      });

      // Fetch relevant MCP data based on user message
      final mcpData = await _fetchRelevantMCPData(message);
      Map<String, dynamic>? mcpDataMap;

      // Parse MCP data for validation
      if (mcpData.isNotEmpty) {
        mcpDataMap = _parseMCPDataForValidation(mcpData);
      }

      // Prepare messages array with history
      final messages = <Map<String, String>>[];

      // Add conversation history
      messages.addAll(_conversationHistory);

      // If we have MCP data, add it as a system message before sending to Claude
      String systemPrompt = _systemPrompt ?? '';
      if (mcpData.isNotEmpty) {
        systemPrompt +=
            '\n\nHere is the relevant data from the MCP database that you MUST use to answer the user\'s query. DO NOT make up any information not contained in this data:\n$mcpData';
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
          'model': 'claude-3-opus-20240229',
          'max_tokens': 1024,
          'messages': messages,
          'system': systemPrompt,
        }),
        encoding: utf8,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        var assistantMessage = data['content'][0]['text'];

        // Validate response against MCP data if available
        if (mcpDataMap != null && mcpDataMap.isNotEmpty) {
          final validationResult =
              _validateResponseAgainstMCPData(assistantMessage, mcpDataMap);
          if (!validationResult.isValid) {
            // Add a warning to the response
            assistantMessage = _addValidationWarning(
                assistantMessage, validationResult.reason);
          }
        }

        // Add assistant's response to history
        _conversationHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
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
            // Try to parse the error response
            try {
              final errorData = jsonDecode(utf8.decode(response.bodyBytes));
              if (errorData['error'] != null &&
                  errorData['error']['type'] == 'overloaded_error') {
                return 'Claude is currently experiencing high demand. Please try again in a moment.';
              }
              return _getUserFriendlyErrorMessage(response.body);
            } catch (e) {
              return 'Error: Unable to get a response from Claude (Status ${response.statusCode})';
            }
        }
      }
    } catch (e) {
      return _getUserFriendlyErrorMessage(e.toString());
    }
  }

  // Helper method to parse MCP data for validation
  Map<String, dynamic> _parseMCPDataForValidation(String mcpData) {
    final result = <String, dynamic>{};
    final lines = mcpData.split('\n');
    String currentSection = '';
    StringBuffer currentData = StringBuffer();

    for (final line in lines) {
      if (line.startsWith('MCP DATA - ')) {
        // If we were processing a section, save it
        if (currentSection.isNotEmpty && currentData.isNotEmpty) {
          try {
            result[currentSection] = json.decode(currentData.toString());
          } catch (e) {
            _logger.error(
                'Error parsing MCP data for section $currentSection: $e');
          }
        }

        // Start a new section
        currentSection = line.substring('MCP DATA - '.length);
        currentData = StringBuffer();
      } else if (currentSection.isNotEmpty && line.trim().isNotEmpty) {
        currentData.writeln(line);
      }
    }

    // Save the last section
    if (currentSection.isNotEmpty && currentData.isNotEmpty) {
      try {
        result[currentSection] = json.decode(currentData.toString());
      } catch (e) {
        _logger.error('Error parsing MCP data for section $currentSection: $e');
      }
    }

    return result;
  }

  // Helper method to validate Claude's response against MCP data
  ValidationResult _validateResponseAgainstMCPData(
      String response, Map<String, dynamic> mcpData) {
    // This is a simplified validation that checks if the response mentions key terms from the MCP data
    // A more sophisticated validation would parse the response and check for specific facts

    final lowerResponse = response.toLowerCase();
    final mentionedTerms = <String>[];
    final missingTerms = <String>[];

    // Extract key terms from MCP data
    final keyTerms = _extractKeyTermsFromMCPData(mcpData);

    // Check if response mentions key terms
    for (final term in keyTerms) {
      if (lowerResponse.contains(term.toLowerCase())) {
        mentionedTerms.add(term);
      } else {
        missingTerms.add(term);
      }
    }

    // If no key terms are mentioned, the response might not be based on MCP data
    if (mentionedTerms.isEmpty && keyTerms.isNotEmpty) {
      return ValidationResult(
          false, 'Response does not mention any key terms from MCP data');
    }

    // If less than 30% of key terms are mentioned, the response might not be based on MCP data
    if (keyTerms.isNotEmpty && mentionedTerms.length / keyTerms.length < 0.3) {
      return ValidationResult(false,
          'Response mentions only ${mentionedTerms.length} out of ${keyTerms.length} key terms from MCP data');
    }

    return ValidationResult(true, '');
  }

  // Helper method to extract key terms from MCP data
  List<String> _extractKeyTermsFromMCPData(Map<String, dynamic> mcpData) {
    final keyTerms = <String>{};

    // Extract terms from goals
    for (final entry in mcpData.entries) {
      if (entry.key.contains('Goals for dimension')) {
        final goals = entry.value as List<dynamic>;
        for (final goal in goals) {
          if (goal['description'] != null) {
            final description = goal['description'] as String;
            // Extract significant words (longer than 4 characters)
            final words = description
                .split(' ')
                .where((word) => word.length > 4)
                .map((word) => word.replaceAll(RegExp(r'[^\w\s]'), ''))
                .toList();
            keyTerms.addAll(words);
          }
        }
      }
    }

    // Extract terms from tracks
    for (final entry in mcpData.entries) {
      if (entry.key.contains('Track for goal')) {
        final track = entry.value as Map<String, dynamic>;
        if (track['name'] != null) {
          keyTerms.add(track['name'] as String);
        }

        if (track['challenges'] != null) {
          final challenges = track['challenges'] as List<dynamic>;
          for (final challenge in challenges) {
            if (challenge['name'] != null) {
              keyTerms.add(challenge['name'] as String);
            }
          }
        }
      }
    }

    // Extract terms from habits
    for (final entry in mcpData.entries) {
      if (entry.key.contains('Habits for challenge') ||
          entry.key.contains('Recommended habits')) {
        final habits = entry.value as List<dynamic>;
        for (final habit in habits) {
          if (habit['description'] != null) {
            final description = habit['description'] as String;
            // Extract significant words (longer than 4 characters)
            final words = description
                .split(' ')
                .where((word) => word.length > 4)
                .map((word) => word.replaceAll(RegExp(r'[^\w\s]'), ''))
                .toList();
            keyTerms.addAll(words);
          }
        }
      }
    }

    return keyTerms.toList();
  }

  // Helper method to add a validation warning to the response
  String _addValidationWarning(String response, String reason) {
    // Add a warning at the end of the response
    return '$response\n\n[SYSTEM WARNING: This response may not be based on specialist-created content. $reason]';
  }

  // Method to clear conversation history
  void clearConversation() {
    _conversationHistory.clear();
  }

  // Getter for conversation history
  List<Map<String, String>> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

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

      try {
        // Initialize TTS service if needed
        final ttsInitialized = await _ttsService!.initialize();
        if (!ttsInitialized) {
          _logger.error('Failed to initialize TTS service');
          return ClaudeAudioResponse(text: textResponse);
        }

        // Generate audio from the text response
        final audioPath = await _ttsService!.generateAudio(textResponse);

        // If audio generation failed, return text only
        if (audioPath == null) {
          _logger.error('Failed to generate audio for response');
          return ClaudeAudioResponse(text: textResponse);
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
            text: textResponse, error: _handleTTSError(e));
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
}
