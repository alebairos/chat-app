import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show visibleForTesting;

class ConfigLoader {
  Future<String> Function() _loadSystemPromptImpl = _defaultLoadSystemPrompt;
  Future<Map<String, String>> Function() _loadExplorationPromptsImpl =
      _defaultLoadExplorationPrompts;

  Future<String> loadSystemPrompt() async {
    return _loadSystemPromptImpl();
  }

  Future<Map<String, String>> loadExplorationPrompts() async {
    return _loadExplorationPromptsImpl();
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

  static Future<Map<String, String>> _defaultLoadExplorationPrompts() async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/config/claude_config.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      if (jsonMap['exploration_prompts'] == null) {
        throw Exception('Exploration prompts not found in config');
      }

      final Map<String, dynamic> promptsMap =
          jsonMap['exploration_prompts'] as Map<String, dynamic>;
      return promptsMap.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      print('Error loading exploration prompts: $e');
      throw Exception('Failed to load exploration prompts');
    }
  }

  @visibleForTesting
  void setLoadSystemPromptImpl(Future<String> Function() impl) {
    _loadSystemPromptImpl = impl;
  }

  @visibleForTesting
  void setLoadExplorationPromptsImpl(
      Future<Map<String, String>> Function() impl) {
    _loadExplorationPromptsImpl = impl;
  }
}
