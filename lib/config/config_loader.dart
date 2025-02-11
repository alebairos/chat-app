import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show visibleForTesting;

class ConfigLoader {
  static Future<String> Function() _loadSystemPromptImpl =
      _defaultLoadSystemPrompt;

  static Future<String> loadSystemPrompt() async {
    return _loadSystemPromptImpl();
  }

  static Future<String> _defaultLoadSystemPrompt() async {
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

  @visibleForTesting
  static set loadSystemPromptImpl(Future<String> Function() impl) {
    _loadSystemPromptImpl = impl;
  }
}
