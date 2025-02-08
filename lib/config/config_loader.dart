import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ConfigLoader {
  static Future<String> loadSystemPrompt() async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/config/claude_config.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return jsonMap['system_prompt']['content'] as String;
    } catch (e) {
      print('Error loading system prompt: $e');
      throw Exception('Failed to load system prompt');
    }
  }
}
