import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  late final String _apiKey;

  ClaudeService() {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-sonnet-20240229',
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': message,
            }
          ],
        }),
        encoding: utf8,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['content'][0]['text'];
      } else {
        throw Exception('Failed to get response from Claude: ${response.body}');
      }
    } catch (e) {
      return 'Error: Unable to connect to Claude: $e';
    }
  }
}
