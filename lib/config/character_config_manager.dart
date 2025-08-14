import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Enum representing the available character personas
enum CharacterPersona {
  personalDevelopmentAssistant,
  sergeantOracle,
  zenGuide,
  ariLifeCoach
}

/// Class to manage character configurations and allow switching between personas
class CharacterConfigManager {
  static final CharacterConfigManager _instance =
      CharacterConfigManager._internal();
  factory CharacterConfigManager() => _instance;
  CharacterConfigManager._internal();

  /// The currently active character persona
  CharacterPersona _activePersona = CharacterPersona.ariLifeCoach;

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
        // Deprecated persona → route to Sergeant Oracle config to avoid referencing removed files
        return 'assets/config/sergeant_oracle_config.json';
      case CharacterPersona.sergeantOracle:
        return 'assets/config/sergeant_oracle_config.json';
      case CharacterPersona.zenGuide:
        // Deprecated persona → route to Ari config to avoid referencing removed files
        return 'assets/config/ari_life_coach_config_2.0.json';
      case CharacterPersona.ariLifeCoach:
        // Use Ari 2.0 persona overlay with Oracle composition per FT-021
        return 'assets/config/ari_life_coach_config_2.0.json';
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
      case CharacterPersona.ariLifeCoach:
        return 'Ari - Life Coach';
    }
  }

  /// Load the system prompt for the active persona
  Future<String> loadSystemPrompt() async {
    try {
      // 1) Resolve Oracle prompt (ALWAYS try) using env path or default
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

      // 2) Load persona layer from JSON config only
      String personaPrompt;

      // 2a) Try dynamic configPath from personas_config.json (FT-022 compatible)
      String? dynamicConfigPath;
      try {
        dynamicConfigPath = await _resolvePersonaConfigPathFromConfig();
      } catch (e) {
        // Ignore and continue to hardcoded fallback
      }

      final String effectiveConfigPath =
          (dynamicConfigPath != null && dynamicConfigPath.isNotEmpty)
              ? dynamicConfigPath
              : configFilePath;

      // 2b) Load from effective config path (with Ari legacy fallback if needed)
      try {
        final String jsonString =
            await rootBundle.loadString(effectiveConfigPath);
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        personaPrompt = jsonMap['system_prompt']['content'] as String;
      } catch (jsonLoadError) {
        // Ari-specific legacy fallback chain
        if (_activePersona == CharacterPersona.ariLifeCoach) {
          // Prefer Ari 1.0 (full) to preserve semantics when overlay missing
          try {
            final String jsonString = await rootBundle
                .loadString('assets/config/ari_life_coach_config_1.0.json');
            final Map<String, dynamic> jsonMap = json.decode(jsonString);
            personaPrompt = jsonMap['system_prompt']['content'] as String;
          } catch (_) {
            final String legacyPath =
                'assets/config/ari_life_coach_config.json';
            final String jsonString = await rootBundle.loadString(legacyPath);
            final Map<String, dynamic> jsonMap = json.decode(jsonString);
            personaPrompt = jsonMap['system_prompt']['content'] as String;
          }
        } else {
          rethrow;
        }
      }

      // 3) Compose: Oracle (if loaded) + Persona overlay/content
      if (oraclePrompt != null && oraclePrompt.trim().isNotEmpty) {
        return oraclePrompt.trim() + '\n\n' + personaPrompt.trim();
      }

      // 4) Oracle missing → preserve semantics for Ari by returning full Ari 1.0
      if (_activePersona == CharacterPersona.ariLifeCoach) {
        try {
          final String jsonString = await rootBundle
              .loadString('assets/config/ari_life_coach_config_1.0.json');
          final Map<String, dynamic> jsonMap = json.decode(jsonString);
          return jsonMap['system_prompt']['content'] as String;
        } catch (_) {
          // Final legacy fallback
          final String jsonString = await rootBundle
              .loadString('assets/config/ari_life_coach_config.json');
          final Map<String, dynamic> jsonMap = json.decode(jsonString);
          return jsonMap['system_prompt']['content'] as String;
        }
      }

      // 5) Other personas: return persona prompt only
      return personaPrompt;
    } catch (e) {
      print('Error loading system prompt: $e');
      throw Exception('Failed to load system prompt for $personaDisplayName');
    }
  }

  /// Load the exploration prompts for the active persona
  Future<Map<String, String>> loadExplorationPrompts() async {
    try {
      // Load from JSON config using dynamic configPath when available
      Map<String, dynamic> jsonMap;
      try {
        String? dynamicConfigPath = await _resolvePersonaConfigPathFromConfig();
        final String effectiveConfigPath =
            (dynamicConfigPath != null && dynamicConfigPath.isNotEmpty)
                ? dynamicConfigPath
                : configFilePath;
        final String jsonString =
            await rootBundle.loadString(effectiveConfigPath);
        jsonMap = json.decode(jsonString);
      } catch (jsonLoadError) {
        if (_activePersona == CharacterPersona.ariLifeCoach) {
          // Prefer Ari 1.0 if overlay missing
          try {
            final String jsonString = await rootBundle
                .loadString('assets/config/ari_life_coach_config_1.0.json');
            jsonMap = json.decode(jsonString);
          } catch (_) {
            final String legacyPath =
                'assets/config/ari_life_coach_config.json';
            final String jsonString = await rootBundle.loadString(legacyPath);
            jsonMap = json.decode(jsonString);
          }
        } else {
          rethrow;
        }
      }

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

  /// Resolve configPath from personas_config.json for the active persona (FT-022 compatible)
  Future<String?> _resolvePersonaConfigPathFromConfig() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/config/personas_config.json');
      final Map<String, dynamic> config = json.decode(jsonString);
      final Map<String, dynamic> personas =
          (config['personas'] as Map<String, dynamic>?) ?? {};
      final String key = _activePersonaKey;
      final Map<String, dynamic>? persona =
          personas[key] as Map<String, dynamic>?;
      if (persona == null) return null;
      final String? path = persona['configPath'] as String?;
      return path;
    } catch (e) {
      return null;
    }
  }

  String get _activePersonaKey {
    switch (_activePersona) {
      case CharacterPersona.personalDevelopmentAssistant:
        return 'personalDevelopmentAssistant';
      case CharacterPersona.sergeantOracle:
        return 'sergeantOracle';
      case CharacterPersona.zenGuide:
        return 'zenGuide';
      case CharacterPersona.ariLifeCoach:
        return 'ariLifeCoach';
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
