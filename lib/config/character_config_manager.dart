import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Class to manage character configurations and allow switching between personas
class CharacterConfigManager {
  static final CharacterConfigManager _instance =
      CharacterConfigManager._internal();
  factory CharacterConfigManager() => _instance;
  CharacterConfigManager._internal();

  /// The currently active character persona key
  String _activePersonaKey = 'ariLifeCoach';

  /// Get the currently active character persona key
  String get activePersonaKey => _activePersonaKey;

  /// Set the active character persona by key
  void setActivePersona(String personaKey) {
    _activePersonaKey = personaKey;
  }

  /// Get the configuration file path for the active persona
  Future<String> get configFilePath async {
    try {
      // Get configPath from personas_config.json
      final String jsonString =
          await rootBundle.loadString('assets/config/personas_config.json');
      final Map<String, dynamic> config = json.decode(jsonString);
      final Map<String, dynamic> personas = config['personas'] ?? {};

      if (personas.containsKey(_activePersonaKey)) {
        final persona = personas[_activePersonaKey] as Map<String, dynamic>?;
        if (persona != null && persona['configPath'] != null) {
          return persona['configPath'] as String;
        }
      }
    } catch (e) {
      print('Error loading persona config path: $e');
    }

    // Default fallback
    return 'assets/config/ari_life_coach_config_2.0.json';
  }

  /// Get the display name for the active persona
  Future<String> get personaDisplayName async {
    try {
      // Get displayName from personas_config.json
      final String jsonString =
          await rootBundle.loadString('assets/config/personas_config.json');
      final Map<String, dynamic> config = json.decode(jsonString);
      final Map<String, dynamic> personas = config['personas'] ?? {};

      if (personas.containsKey(_activePersonaKey)) {
        final persona = personas[_activePersonaKey] as Map<String, dynamic>?;
        if (persona != null && persona['displayName'] != null) {
          return persona['displayName'] as String;
        }
      }
    } catch (e) {
      print('Error loading persona display name: $e');
    }

    // Default fallback
    return 'Unknown Persona';
  }

  /// Load the system prompt for the active persona
  Future<String> loadSystemPrompt() async {
    try {
      // 1) Always try to load Oracle prompt first
      final String defaultOraclePath =
          'assets/config/oracle/oracle_prompt_1.0.md';
      final String oraclePathEnv =
          (dotenv.env['ORACLE_PROMPT_PATH'] ?? '').trim();
      final String oraclePath =
          oraclePathEnv.isNotEmpty ? oraclePathEnv : defaultOraclePath;

      String? oraclePrompt;
      try {
        oraclePrompt = await rootBundle.loadString(oraclePath);
      } catch (oracleError) {
        print('Oracle prompt not found or failed to load: $oracleError');
      }

      // 2) Load persona prompt from dynamic config path
      String personaPrompt;
      final String personaConfigPath = await configFilePath;

      try {
        final String jsonString =
            await rootBundle.loadString(personaConfigPath);
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        personaPrompt = jsonMap['system_prompt']['content'] as String;
      } catch (jsonLoadError) {
        // Legacy fallback only for Ari
        if (_activePersonaKey == 'ariLifeCoach') {
          try {
            final String jsonString = await rootBundle
                .loadString('assets/config/ari_life_coach_config_1.0.json');
            final Map<String, dynamic> jsonMap = json.decode(jsonString);
            personaPrompt = jsonMap['system_prompt']['content'] as String;
          } catch (_) {
            final String jsonString = await rootBundle
                .loadString('assets/config/ari_life_coach_config.json');
            final Map<String, dynamic> jsonMap = json.decode(jsonString);
            personaPrompt = jsonMap['system_prompt']['content'] as String;
          }
        } else {
          rethrow;
        }
      }

      // 3) Compose: Oracle (if loaded) + Persona prompt
      if (oraclePrompt != null && oraclePrompt.trim().isNotEmpty) {
        return oraclePrompt.trim() + '\n\n' + personaPrompt.trim();
      }

      // 4) Fallback: return persona prompt only
      return personaPrompt;
    } catch (e) {
      print('Error loading system prompt: $e');
      final displayName = await personaDisplayName;
      throw Exception('Failed to load system prompt for $displayName');
    }
  }

  /// Load the exploration prompts for the active persona
  Future<Map<String, String>> loadExplorationPrompts() async {
    try {
      final String personaConfigPath = await configFilePath;
      String jsonString;

      try {
        jsonString = await rootBundle.loadString(personaConfigPath);
      } catch (jsonLoadError) {
        // Legacy fallback only for Ari
        if (_activePersonaKey == 'ariLifeCoach') {
          try {
            jsonString = await rootBundle
                .loadString('assets/config/ari_life_coach_config_1.0.json');
          } catch (_) {
            jsonString = await rootBundle
                .loadString('assets/config/ari_life_coach_config.json');
          }
        } else {
          rethrow;
        }
      }

      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      if (jsonMap['exploration_prompts'] == null) {
        throw Exception('Exploration prompts not found in config');
      }

      final Map<String, dynamic> promptsMap =
          jsonMap['exploration_prompts'] as Map<String, dynamic>;
      return promptsMap.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      print('Error loading exploration prompts: $e');
      final displayName = await personaDisplayName;
      throw Exception('Failed to load exploration prompts for $displayName');
    }
  }

  /// Get a list of all available personas with their display names and descriptions
  Future<List<Map<String, dynamic>>> get availablePersonas async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/config/personas_config.json');
      final Map<String, dynamic> config = json.decode(jsonString);
      final Map<String, dynamic> personas = config['personas'] ?? {};

      return personas.entries.where((entry) {
        final persona = entry.value as Map<String, dynamic>?;
        return persona != null && persona['enabled'] == true;
      }).map((entry) {
        final personaKey = entry.key;
        final persona = entry.value as Map<String, dynamic>;
        return {
          'key': personaKey,
          'displayName': persona['displayName'],
          'description': persona['description']
        };
      }).toList();
    } catch (e) {
      print('Error loading personas config: $e');
      // Minimal fallback
      return [
        {
          'key': 'ariLifeCoach',
          'displayName': 'Ari - Life Coach',
          'description': 'Default persona'
        }
      ];
    }
  }
}
