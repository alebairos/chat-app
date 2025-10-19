/// FT-207: Persona Mention Autocomplete
/// Service for loading and filtering persona options
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/persona_option.dart';

class PersonaAutocompleteService {
  static const int _maxSuggestions =
      10; // FT-208: Increased from 5 to show more personas
  static const String _configPath = 'assets/config/persona_mention_config.json';
  static const String _personasConfigPath =
      'assets/config/personas_config.json';

  List<PersonaOption>? _cachedPersonas;
  bool? _cachedFeatureEnabled;

  /// Check if the mention feature is enabled via configuration
  Future<bool> isFeatureEnabled() async {
    // Return cached result if available
    if (_cachedFeatureEnabled != null) {
      return _cachedFeatureEnabled!;
    }

    try {
      final configString = await rootBundle.loadString(_configPath);
      final config = json.decode(configString) as Map<String, dynamic>;
      _cachedFeatureEnabled = config['enabled'] == true;
      return _cachedFeatureEnabled!;
    } catch (e) {
      // Default to disabled if config not found or invalid
      _cachedFeatureEnabled = false;
      return false;
    }
  }

  /// Load available personas from configuration
  Future<List<PersonaOption>> getAvailablePersonas() async {
    // Return cached result if available
    if (_cachedPersonas != null) {
      return _cachedPersonas!;
    }

    try {
      // Load personas configuration
      final configString = await rootBundle.loadString(_personasConfigPath);
      final config = json.decode(configString) as Map<String, dynamic>;

      final personas = <PersonaOption>[];

      // Get the personas object from the config
      final personasConfig = config['personas'] as Map<String, dynamic>?;
      if (personasConfig == null) {
        print('FT-207: No personas found in config');
        return [];
      }

      print('FT-207: Found ${personasConfig.length} personas in config');

      for (final entry in personasConfig.entries) {
        final personaKey = entry.key;
        final personaData = entry.value as Map<String, dynamic>;

        // Skip disabled personas
        if (personaData['enabled'] != true) {
          print('FT-208: Skipping disabled persona: $personaKey');
          continue;
        }

        print(
            'FT-208: Adding enabled persona: $personaKey (${personaData['displayName']})');
        personas.add(PersonaOption(
          key: personaKey,
          displayName: personaData['displayName'] ?? personaKey,
          shortName: _extractShortName(personaKey),
          description: personaData['description'] ?? '',
          icon: _getPersonaIcon(personaKey),
          isEnabled: true,
        ));
      }

      // Sort personas alphabetically by display name
      personas.sort((a, b) => a.displayName.compareTo(b.displayName));

      print('FT-208: Successfully loaded ${personas.length} enabled personas');
      print(
          'FT-208: Enabled personas: ${personas.map((p) => '${p.displayName} (@${p.shortName})').join(', ')}');
      _cachedPersonas = personas;
      return personas;
    } catch (e) {
      print('Error loading personas for autocomplete: $e');
      return [];
    }
  }

  /// Filter personas by search query with relevance sorting
  List<PersonaOption> filterPersonas(
      List<PersonaOption> personas, String query) {
    print('FT-208: Filtering ${personas.length} personas with query: "$query"');

    if (query.isEmpty) {
      // Return all personas, limited by max suggestions
      final result = personas.take(_maxSuggestions).toList();
      print(
          'FT-208: Empty query, returning first ${result.length} personas alphabetically');
      for (int i = 0; i < result.length; i++) {
        print(
            'FT-208: [$i] ${result[i].displayName} (@${result[i].shortName})');
      }
      return result;
    }

    // Filter personas that match the query
    final matchingPersonas = <PersonaOption>[];
    for (final persona in personas) {
      final matches = persona.matches(query);
      print(
          'FT-208: ${persona.displayName} (@${persona.shortName}) matches "$query": $matches');
      if (matches) {
        matchingPersonas.add(persona);
      }
    }

    print(
        'FT-208: Found ${matchingPersonas.length} matching personas before sorting');

    // Sort by relevance (lower score = more relevant)
    matchingPersonas.sort((a, b) {
      final scoreA = a.getRelevanceScore(query);
      final scoreB = b.getRelevanceScore(query);

      if (scoreA != scoreB) {
        return scoreA.compareTo(scoreB);
      }

      // If same relevance, sort alphabetically
      return a.displayName.compareTo(b.displayName);
    });

    // Apply max suggestions limit
    final result = matchingPersonas.take(_maxSuggestions).toList();
    print('FT-208: Final result: ${result.length} personas');
    for (int i = 0; i < result.length; i++) {
      print(
          'FT-208: [$i] ${result[i].displayName} (@${result[i].shortName}) - relevance: ${result[i].getRelevanceScore(query)}');
    }

    return result;
  }

  /// Extract short name for easier typing from persona key
  String _extractShortName(String personaKey) {
    // Handle known persona patterns
    if (personaKey.startsWith('aristios')) {
      return 'aristios';
    }
    if (personaKey.startsWith('ari')) {
      return 'ari';
    }
    if (personaKey.startsWith('iThere')) {
      return 'ithere';
    }
    if (personaKey.startsWith('tony')) {
      return 'tony';
    }
    if (personaKey.startsWith('ryo')) {
      return 'ryo';
    }
    if (personaKey.startsWith('sergeant')) {
      return 'sergeant';
    }

    // Fallback: extract first lowercase part before capital letter or number
    final match = RegExp(r'^([a-z]+)').firstMatch(personaKey.toLowerCase());
    if (match != null) {
      return match.group(1)!;
    }

    // Ultimate fallback: use full key in lowercase
    return personaKey.toLowerCase();
  }

  /// Get appropriate icon for persona based on key patterns
  String _getPersonaIcon(String personaKey) {
    final lowerKey = personaKey.toLowerCase();

    if (lowerKey.contains('aristios') || lowerKey.contains('ari')) {
      return '🧠'; // Brain for Aristios/Ari
    }
    if (lowerKey.contains('ithere')) {
      return '🪞'; // Mirror for I-There
    }
    if (lowerKey.contains('tony')) {
      return '🎯'; // Target for Tony
    }
    if (lowerKey.contains('ryo')) {
      return '🎨'; // Art for Ryo
    }
    if (lowerKey.contains('sergeant')) {
      return '⚔️'; // Sword for Sergeant
    }
    if (lowerKey.contains('oracle')) {
      return '🔮'; // Crystal ball for Oracle variants
    }

    // Default icon
    return '🤖';
  }

  /// Clear cached data (useful for testing or config changes)
  void clearCache() {
    _cachedPersonas = null;
    _cachedFeatureEnabled = null;
  }

  /// Get persona by key (for validation)
  Future<PersonaOption?> getPersonaByKey(String key) async {
    final personas = await getAvailablePersonas();
    try {
      return personas.firstWhere((persona) => persona.key == key);
    } catch (e) {
      return null;
    }
  }

  /// Check if a persona key is valid and enabled
  Future<bool> isValidPersonaKey(String key) async {
    final persona = await getPersonaByKey(key);
    return persona != null && persona.isEnabled;
  }
}
