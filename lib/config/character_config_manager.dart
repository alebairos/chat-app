import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Enum representing the available character personas
enum CharacterPersona { personalDevelopmentAssistant, sergeantOracle, zenGuide }

/// Class to manage character configurations and allow switching between personas
class CharacterConfigManager {
  static final CharacterConfigManager _instance =
      CharacterConfigManager._internal();
  factory CharacterConfigManager() => _instance;
  CharacterConfigManager._internal();

  /// The currently active character persona
  CharacterPersona _activePersona = CharacterPersona.sergeantOracle;

  /// Get the currently active character persona
  CharacterPersona get activePersona => _activePersona;

  /// Set the active character persona
  void setActivePersona(CharacterPersona persona) {
    _activePersona = persona;
  }

  /// Get the configuration file path for the active persona
  String get configFilePath {
    switch (_activePersona) {
      case CharacterPersona.personalDevelopmentAssistant:
        return 'lib/config/claude_config.json';
      case CharacterPersona.sergeantOracle:
        return 'lib/config/sergeant_oracle_config.json';
      case CharacterPersona.zenGuide:
        return 'lib/config/zen_guide_config.json';
    }
  }

  /// Get the display name for the active persona
  String get personaDisplayName {
    switch (_activePersona) {
      case CharacterPersona.personalDevelopmentAssistant:
        return 'Personal Development Assistant';
      case CharacterPersona.sergeantOracle:
        return 'Sergeant Oracle';
      case CharacterPersona.zenGuide:
        return 'The Zen Master';
    }
  }

  /// Load the system prompt for the active persona
  Future<String> loadSystemPrompt() async {
    try {
      // Try to load from external prompt file first
      final String promptPath = _getSystemPromptPath();
      try {
        return await rootBundle.loadString(promptPath);
      } catch (promptError) {
        print(
            'External prompt not found, falling back to config: $promptError');
        // Fallback to original JSON config
        final String jsonString = await rootBundle.loadString(configFilePath);
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        return jsonMap['system_prompt']['content'] as String;
      }
    } catch (e) {
      print('Error loading system prompt: $e');
      throw Exception('Failed to load system prompt for $personaDisplayName');
    }
  }

  /// Get the system prompt file path for the active persona
  String _getSystemPromptPath() {
    switch (_activePersona) {
      case CharacterPersona.personalDevelopmentAssistant:
        return 'assets/prompts/personal_development_system.txt';
      case CharacterPersona.sergeantOracle:
        return 'assets/prompts/sergeant_oracle_system.txt';
      case CharacterPersona.zenGuide:
        return 'assets/prompts/zen_guide_system.txt';
    }
  }

  /// Load the exploration prompts for the active persona
  Future<Map<String, String>> loadExplorationPrompts() async {
    try {
      // Try to load from external prompt files first
      final Map<String, String> prompts = {};
      final List<String> dimensions = [
        'physical',
        'mental',
        'relationships',
        'spirituality',
        'work'
      ];

      bool hasExternalPrompts = false;
      for (final dimension in dimensions) {
        try {
          final String promptPath = _getExplorationPromptPath(dimension);
          final String content = await rootBundle.loadString(promptPath);
          prompts[dimension] = content;
          hasExternalPrompts = true;
        } catch (promptError) {
          print('External prompt not found for $dimension: $promptError');
        }
      }

      if (hasExternalPrompts && prompts.isNotEmpty) {
        return prompts;
      }

      // Fallback to original JSON config
      final String jsonString = await rootBundle.loadString(configFilePath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      if (jsonMap['exploration_prompts'] == null) {
        throw Exception('Exploration prompts not found in config');
      }

      final Map<String, dynamic> promptsMap =
          jsonMap['exploration_prompts'] as Map<String, dynamic>;
      return promptsMap.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      print('Error loading exploration prompts: $e');
      throw Exception(
          'Failed to load exploration prompts for $personaDisplayName');
    }
  }

  /// Get the exploration prompt file path for the active persona and dimension
  String _getExplorationPromptPath(String dimension) {
    switch (_activePersona) {
      case CharacterPersona.personalDevelopmentAssistant:
        return 'assets/prompts/personal_development_$dimension.txt';
      case CharacterPersona.sergeantOracle:
        return 'assets/prompts/sergeant_oracle_$dimension.txt';
      case CharacterPersona.zenGuide:
        return 'assets/prompts/zen_guide_$dimension.txt';
    }
  }

  /// Get a list of all available personas with their display names and descriptions
  Future<List<Map<String, dynamic>>> get availablePersonas async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/config/personas_config.json');
      final Map<String, dynamic> config = json.decode(jsonString);

      final List<String> enabledPersonas =
          List<String>.from(config['enabledPersonas'] ?? []);
      final Map<String, dynamic> personas = config['personas'] ?? {};

      return enabledPersonas
          .map((personaKey) {
            final persona = personas[personaKey];
            if (persona != null && persona['enabled'] == true) {
              return {
                'key': personaKey,
                'displayName': persona['displayName'],
                'description': persona['description']
              };
            }
            return null;
          })
          .where((persona) => persona != null)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('Error loading personas config: $e');
      // Fallback to Sergeant Oracle only
      return [
        {
          'key': 'sergeantOracle',
          'displayName': 'Sergeant Oracle',
          'description':
              'Roman time-traveler with military precision and ancient wisdom, combining historical insights with futuristic perspective.'
        }
      ];
    }
  }
}
