import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/config_loader.dart';

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  late final String _apiKey;
  final List<Map<String, String>> _conversationHistory = [];
  String? _systemPrompt;
  bool _isInitialized = false;
  final http.Client _client;

  ClaudeService({http.Client? client}) : _client = client ?? http.Client() {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  }

  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        _systemPrompt = await ConfigLoader.loadSystemPrompt();
        _isInitialized = true;
      } catch (e) {
        print('Error initializing Claude service: $e');
        return false;
      }
    }
    return _isInitialized;
  }

  Future<String> sendMessage(String message) async {
    try {
      await initialize();

      // Add user message to history
      _conversationHistory.add({
        'role': 'user',
        'content': message,
      });

      // Prepare messages array with system prompt and history
      final messages = <Map<String, String>>[];

      // Add system prompt if available
      if (_systemPrompt != null) {
        messages.add({
          'role': 'system',
          'content': _systemPrompt!,
        });
      }

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
      }

      throw Exception('Failed to get response from Claude: ${response.body}');
    } catch (e) {
      return 'Error: Unable to connect to Claude: $e';
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
