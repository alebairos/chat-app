import 'package:flutter/foundation.dart' show visibleForTesting;
import 'character_config_manager.dart';

class ConfigLoader {
  Future<String> Function() _loadSystemPromptImpl = _defaultLoadSystemPrompt;
  Future<Map<String, String>> Function() _loadExplorationPromptsImpl =
      _defaultLoadExplorationPrompts;

  final CharacterConfigManager _characterManager = CharacterConfigManager();

  Future<String> loadSystemPrompt() async {
    return _loadSystemPromptImpl();
  }

  Future<Map<String, String>> loadExplorationPrompts() async {
    return _loadExplorationPromptsImpl();
  }

  static Future<String> _defaultLoadSystemPrompt() async {
    try {
      final characterManager = CharacterConfigManager();
      return await characterManager.loadSystemPrompt();
    } catch (e) {
      print('Error loading system prompt: $e');
      throw Exception('Failed to load system prompt');
    }
  }

  static Future<Map<String, String>> _defaultLoadExplorationPrompts() async {
    try {
      final characterManager = CharacterConfigManager();
      return await characterManager.loadExplorationPrompts();
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

  /// Get the currently active character persona
  CharacterPersona get activePersona => _characterManager.activePersona;

  /// Set the active character persona
  void setActivePersona(CharacterPersona persona) {
    _characterManager.setActivePersona(persona);
  }

  /// Get the display name for the active persona
  String get activePersonaDisplayName => _characterManager.personaDisplayName;

  /// Get a list of all available personas
  Future<List<Map<String, dynamic>>> get availablePersonas =>
      _characterManager.availablePersonas;
}
