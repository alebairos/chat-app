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
  CharacterPersona _activePersona =
      CharacterPersona.personalDevelopmentAssistant;

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
        return 'The Zen Guide';
    }
  }

  /// Load the system prompt for the active persona
  Future<String> loadSystemPrompt() async {
    try {
      final String jsonString = await rootBundle.loadString(configFilePath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return jsonMap['system_prompt']['content'] as String;
    } catch (e) {
      print('Error loading system prompt: $e');
      throw Exception('Failed to load system prompt for $personaDisplayName');
    }
  }

  /// Load the exploration prompts for the active persona
  Future<Map<String, String>> loadExplorationPrompts() async {
    try {
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

  /// Get a list of all available personas with their display names and descriptions
  List<Map<String, dynamic>> get availablePersonas {
    return [
      {
        'displayName': 'Personal Development Assistant',
        'description':
            'Empathetic and encouraging guide focused on practical solutions for achieving goals through positive habits.'
      },
      {
        'displayName': 'Sergeant Oracle',
        'description':
            'Roman time-traveler with military precision and ancient wisdom, combining historical insights with futuristic perspective.'
      },
      {
        'displayName': 'The Zen Guide',
        'description':
            'Calm and mindful mentor with Eastern wisdom traditions, focusing on balance, mindfulness, and inner peace.'
      }
    ];
  }
}
