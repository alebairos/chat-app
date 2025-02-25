import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/config_loader.dart';
import 'life_plan_mcp_service.dart';

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  late final String _apiKey;
  final List<Map<String, String>> _conversationHistory = [];
  String? _systemPrompt;
  bool _isInitialized = false;
  final http.Client _client;
  final LifePlanMCPService? _lifePlanMCP;
  final ConfigLoader _configLoader;

  ClaudeService({
    http.Client? client,
    LifePlanMCPService? lifePlanMCP,
    ConfigLoader? configLoader,
  })  : _client = client ?? http.Client(),
        _lifePlanMCP = lifePlanMCP,
        _configLoader = configLoader ?? ConfigLoader() {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  }

  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        _systemPrompt = await _configLoader.loadSystemPrompt();
        _isInitialized = true;
      } catch (e) {
        print('Error initializing Claude service: $e');
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
            return await _lifePlanMCP!.processCommand(message);
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

      // Prepare messages array with history
      final messages = <Map<String, String>>[];

      // Add conversation history
      messages.addAll(_conversationHistory);

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
          'system': _systemPrompt,
        }),
        encoding: utf8,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final assistantMessage = data['content'][0]['text'];

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

  // Method to clear conversation history
  void clearConversation() {
    _conversationHistory.clear();
  }

  // Getter for conversation history
  List<Map<String, String>> get conversationHistory =>
      List.unmodifiable(_conversationHistory);
}
