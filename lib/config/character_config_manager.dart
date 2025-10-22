import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/system_mcp_service.dart';

/// Class to manage character configurations and allow switching between personas
class CharacterConfigManager {
  static final CharacterConfigManager _instance =
      CharacterConfigManager._internal();
  factory CharacterConfigManager() => _instance;
  CharacterConfigManager._internal();

  /// The currently active character persona key
  String _activePersonaKey = 'ariLifeCoach';

  /// Flag to track if the manager has been initialized
  bool _isInitialized = false;

  /// Get the currently active character persona key
  String get activePersonaKey => _activePersonaKey;

  /// Set the active character persona by key
  Future<void> setActivePersona(String personaKey) async {
    _activePersonaKey = personaKey;

    // FT-192: Configure Oracle availability for the new persona
    await _configureOracleForPersona(personaKey);
  }

  /// FT-192: Configure Oracle availability based on persona configuration
  Future<void> _configureOracleForPersona(String personaKey) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/config/personas_config.json',
      );
      final Map<String, dynamic> config = json.decode(jsonString);
      final Map<String, dynamic> personas = config['personas'] ?? {};

      if (personas.containsKey(personaKey)) {
        final persona = personas[personaKey] as Map<String, dynamic>?;

        // FT-198: Proper Oracle detection logic
        bool oracleEnabled;

        if (persona?['oracleEnabled'] != null) {
          // Use explicit flag if present
          oracleEnabled = persona!['oracleEnabled'] as bool;
        } else {
          // Check for Oracle configuration presence
          final hasOracleConfig = persona?['oracleConfigPath'] != null;
          final hasMcpExtensions = persona?['mcpExtensions'] != null;
          oracleEnabled = hasOracleConfig || hasMcpExtensions;
        }

        // FT-195: Configure SystemMCPService Oracle availability using singleton
        final mcpService = SystemMCPService.instance;
        mcpService.setOracleEnabled(oracleEnabled);

        print(
            '✅ Oracle ${oracleEnabled ? 'enabled' : 'disabled'} for persona: $personaKey (${persona?['oracleEnabled'] != null ? 'explicit' : 'inferred'})');
      }
    } catch (e) {
      print('⚠️ Error configuring Oracle for persona $personaKey: $e');
      // FT-198: Default to disabled on error for safety
      final mcpService = SystemMCPService.instance;
      mcpService.setOracleEnabled(false);
    }
  }

  /// Initialize the manager by reading the default persona from config
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load personas config to get defaultPersona
      final String jsonString = await rootBundle.loadString(
        'assets/config/personas_config.json',
      );
      final Map<String, dynamic> config = json.decode(jsonString);

      // Check for defaultPersona in config
      final String? defaultPersona = config['defaultPersona'] as String?;
      if (defaultPersona != null && defaultPersona.isNotEmpty) {
        // Verify the default persona exists in the personas list
        final Map<String, dynamic> personas = config['personas'] ?? {};
        if (personas.containsKey(defaultPersona)) {
          _activePersonaKey = defaultPersona;
          print(
            '✅ CharacterConfigManager initialized with default persona: $defaultPersona',
          );
        } else {
          print(
            '⚠️ Default persona "$defaultPersona" not found in personas list, keeping current: $_activePersonaKey',
          );
        }
      } else {
        print(
          '⚠️ No defaultPersona specified in config, keeping current: $_activePersonaKey',
        );
      }

      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing CharacterConfigManager: $e');
      print('⚠️ Keeping current persona: $_activePersonaKey');
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  /// Check if the manager has been initialized
  bool get isInitialized => _isInitialized;

  /// Get the configuration file path for the active persona
  Future<String> get configFilePath async {
    try {
      // Get configPath from personas_config.json
      final String jsonString = await rootBundle.loadString(
        'assets/config/personas_config.json',
      );
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
      final String jsonString = await rootBundle.loadString(
        'assets/config/personas_config.json',
      );
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

  /// Get the Oracle configuration path for the active persona
  Future<String?> getOracleConfigPath() async {
    try {
      // Get oracleConfigPath from personas_config.json
      final String jsonString = await rootBundle.loadString(
        'assets/config/personas_config.json',
      );
      final Map<String, dynamic> config = json.decode(jsonString);
      final Map<String, dynamic> personas = config['personas'] ?? {};

      if (personas.containsKey(_activePersonaKey)) {
        final persona = personas[_activePersonaKey] as Map<String, dynamic>?;
        if (persona != null && persona['oracleConfigPath'] != null) {
          return persona['oracleConfigPath'] as String;
        }
      }
    } catch (e) {
      print('Error loading Oracle config path: $e');
    }

    return null; // No Oracle config specified
  }

  /// Check if the active persona is Oracle-enabled (FT-130)
  Future<bool> isOracleEnabled() async {
    final oracleConfigPath = await getOracleConfigPath();
    return oracleConfigPath != null;
  }

  /// Get MCP config paths for current persona (FT-143 Base + Extensions)
  Future<Map<String, dynamic>> getMcpConfigPaths() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/config/personas_config.json',
      );
      final Map<String, dynamic> config = json.decode(jsonString);
      final Map<String, dynamic> personas = config['personas'] ?? {};

      if (personas.containsKey(_activePersonaKey)) {
        final persona = personas[_activePersonaKey] as Map<String, dynamic>?;

        return {
          'baseConfig': persona?['mcpBaseConfig'] as String?,
          'extensions': persona?['mcpExtensions'] as List<dynamic>? ?? [],
          'legacyConfig': persona?['mcpInstructionsConfig']
              as String?, // Backward compatibility
        };
      }
    } catch (e) {
      print('Error loading MCP config paths: $e');
    }
    return {'baseConfig': null, 'extensions': <String>[], 'legacyConfig': null};
  }

  /// Load persona-specific MCP instructions configuration (FT-143)
  Future<Map<String, dynamic>?> loadMcpInstructions() async {
    try {
      // Get persona-specific MCP config paths
      final configPaths = await getMcpConfigPaths();

      // Check for legacy config first (backward compatibility)
      if (configPaths['legacyConfig'] != null) {
        print('🔄 Loading legacy MCP config for persona: $_activePersonaKey');
        return await _loadLegacyMcpConfig(
          configPaths['legacyConfig'] as String,
        );
      }

      // Load Base + Extensions architecture
      final baseConfigPath = configPaths['baseConfig'] as String?;
      final extensions = configPaths['extensions'] as List<dynamic>;

      if (baseConfigPath == null) {
        print('No base MCP config for persona: $_activePersonaKey');
        return null;
      }

      // Load base configuration
      print('📄 Loading base MCP config: $baseConfigPath');
      final String baseJsonString = await rootBundle.loadString(baseConfigPath);
      final Map<String, dynamic> baseMcpConfig = json.decode(baseJsonString);

      // Check if base MCP is enabled
      if (baseMcpConfig['enabled'] != true) {
        print('Base MCP disabled in config: $baseConfigPath');
        return null;
      }

      // Merge extensions if any
      if (extensions.isNotEmpty) {
        print('🔧 Loading ${extensions.length} MCP extensions...');
        for (final extensionPath in extensions) {
          await _mergeExtension(baseMcpConfig, extensionPath as String);
        }
      }

      // Validate Oracle version compatibility if applicable
      await _validateMergedOracleCompatibility(baseMcpConfig);

      print('✅ Loaded Base + Extensions MCP config for: $_activePersonaKey');
      return baseMcpConfig;
    } catch (e) {
      print('Error loading Base + Extensions MCP instructions: $e');
      return null;
    }
  }

  /// Validate Oracle version compatibility between MCP config and Oracle data (FT-143)
  Future<void> _validateOracleVersionCompatibility(
    Map<String, dynamic> mcpConfig,
  ) async {
    final mcpOracleVersion = mcpConfig['oracle_version'] as String?;

    if (mcpOracleVersion != null) {
      final oracleConfigPath = await getOracleConfigPath();
      if (oracleConfigPath != null) {
        // Extract Oracle version from path (e.g., "oracle_prompt_4.2.md" → "4.2")
        final oracleVersionMatch = RegExp(
          r'oracle_prompt_(\d+\.\d+)',
        ).firstMatch(oracleConfigPath);
        final actualOracleVersion = oracleVersionMatch?.group(1);

        if (actualOracleVersion != mcpOracleVersion) {
          throw Exception(
            'Oracle version mismatch: MCP config expects $mcpOracleVersion, but Oracle data is $actualOracleVersion',
          );
        }

        print('✅ Oracle version compatibility validated: $actualOracleVersion');
      }
    }
  }

  /// Get Oracle version for current persona (FT-143)
  Future<String?> getOracleVersion() async {
    final oracleConfigPath = await getOracleConfigPath();
    if (oracleConfigPath != null) {
      final versionMatch = RegExp(
        r'oracle_prompt_(\d+\.\d+)',
      ).firstMatch(oracleConfigPath);
      return versionMatch?.group(1);
    }
    return null;
  }

  /// Load legacy MCP config (backward compatibility)
  Future<Map<String, dynamic>?> _loadLegacyMcpConfig(String configPath) async {
    try {
      final String jsonString = await rootBundle.loadString(configPath);
      final Map<String, dynamic> mcpConfig = json.decode(jsonString);

      if (mcpConfig['enabled'] != true) {
        print('Legacy MCP disabled in config: $configPath');
        return null;
      }

      await _validateOracleVersionCompatibility(mcpConfig);
      print('✅ Loaded legacy MCP config: $configPath');
      return mcpConfig;
    } catch (e) {
      print('Error loading legacy MCP config: $e');
      return null;
    }
  }

  /// Merge extension into base MCP config
  Future<void> _mergeExtension(
    Map<String, dynamic> baseConfig,
    String extensionPath,
  ) async {
    try {
      print('   🔧 Merging extension: $extensionPath');

      final String extensionJsonString = await rootBundle.loadString(
        extensionPath,
      );
      final Map<String, dynamic> extension = json.decode(extensionJsonString);

      // Validate extension format
      if (extension['extends'] != 'mcp_base_config.json') {
        throw Exception(
          'Extension $extensionPath does not extend mcp_base_config.json',
        );
      }

      // Merge Oracle capabilities
      if (extension.containsKey('oracle_capabilities')) {
        baseConfig['oracle_capabilities'] = extension['oracle_capabilities'];
      }

      // Merge additional instructions
      if (extension.containsKey('additional_instructions')) {
        final additionalInstructions =
            extension['additional_instructions'] as Map<String, dynamic>;
        final baseInstructions =
            baseConfig['instructions'] as Map<String, dynamic>;

        for (final entry in additionalInstructions.entries) {
          baseInstructions[entry.key] = entry.value;
        }
      }

      // Merge additional functions
      if (extension.containsKey('additional_functions')) {
        final additionalFunctions =
            extension['additional_functions'] as List<dynamic>;
        final systemFunctions = baseConfig['instructions']['system_functions']
            as Map<String, dynamic>;
        final availableFunctions =
            systemFunctions['available_functions'] as List<dynamic>;

        availableFunctions.addAll(additionalFunctions);
      }

      // Add extension metadata
      baseConfig['loaded_extensions'] =
          (baseConfig['loaded_extensions'] as List<dynamic>? ?? [])
            ..add({
              'path': extensionPath,
              'version': extension['version'],
              'type': extension['type'],
            });

      print('   ✅ Extension merged successfully');
    } catch (e) {
      print('   ❌ Failed to merge extension $extensionPath: $e');
      rethrow;
    }
  }

  /// Validate Oracle compatibility for merged config
  Future<void> _validateMergedOracleCompatibility(
    Map<String, dynamic> mergedConfig,
  ) async {
    final oracleCapabilities =
        mergedConfig['oracle_capabilities'] as Map<String, dynamic>?;

    if (oracleCapabilities != null) {
      final oracleConfigPath = await getOracleConfigPath();
      if (oracleConfigPath != null) {
        // Extract Oracle version from extension metadata
        final loadedExtensions =
            mergedConfig['loaded_extensions'] as List<dynamic>? ?? [];
        if (loadedExtensions.isNotEmpty) {
          final extensionVersion = loadedExtensions.first['version'] as String?;

          // Extract Oracle version from path
          final oracleVersionMatch = RegExp(
            r'oracle_prompt_(\d+\.\d+)',
          ).firstMatch(oracleConfigPath);
          final actualOracleVersion = oracleVersionMatch?.group(1);

          if (extensionVersion != null &&
              actualOracleVersion != extensionVersion) {
            throw Exception(
              'Oracle version mismatch: Extension expects $extensionVersion, but Oracle data is $actualOracleVersion',
            );
          }

          print(
            '✅ Oracle version compatibility validated: $actualOracleVersion',
          );
        }
      }
    }
  }

  /// Build MCP instructions text from configuration (FT-130)
  Future<String> buildMcpInstructionsText() async {
    final mcpConfig = await loadMcpInstructions();
    if (mcpConfig == null) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();
    final Map<String, dynamic> instructions = mcpConfig['instructions'] ?? {};

    // FT-203: Log if conversation continuity instructions are present
    final hasConversationContinuity =
        instructions.containsKey('conversation_continuity');
    print(
        '🔍 [FT-203] MCP Config has conversation_continuity: $hasConversationContinuity');
    if (hasConversationContinuity) {
      print(
          '🔍 [FT-203] ✅ Conversation continuity instructions found in MCP config');
    } else {
      print(
          '🔍 [FT-203] ❌ Conversation continuity instructions MISSING from MCP config');
    }

    // System header
    final systemHeader = instructions['system_header'] ?? {};
    if (systemHeader['title'] != null) {
      buffer.writeln(systemHeader['title']);
      buffer.writeln();
    }
    if (systemHeader['description'] != null) {
      buffer.writeln(systemHeader['description']);
      buffer.writeln();
    }

    // Mandatory commands
    final mandatoryCommands = instructions['mandatory_commands'] ?? {};
    if (mandatoryCommands['title'] != null) {
      buffer.writeln(mandatoryCommands['title']);
      buffer.writeln();
    }

    // get_activity_stats command
    final getActivityStats = mandatoryCommands['get_activity_stats'] ?? {};
    if (getActivityStats['title'] != null) {
      buffer.writeln(getActivityStats['title']);
      buffer.writeln();
    }
    if (getActivityStats['critical_instruction'] != null) {
      buffer.writeln(getActivityStats['critical_instruction']);
    }
    if (getActivityStats['command_format'] != null) {
      buffer.writeln('```');
      buffer.writeln(getActivityStats['command_format']);
      buffer.writeln('```');
      buffer.writeln();
    }

    // Mandatory examples
    if (getActivityStats['mandatory_examples'] != null) {
      buffer.writeln('**EXEMPLOS OBRIGATÓRIOS**:');
      final List<dynamic> examples = getActivityStats['mandatory_examples'];
      for (final example in examples) {
        buffer.writeln('- $example');
      }
      buffer.writeln();
    }

    if (getActivityStats['never_approximate'] != null) {
      buffer.writeln(getActivityStats['never_approximate']);
      buffer.writeln();
    }

    // Response format
    final responseFormat = instructions['response_format'] ?? {};
    if (responseFormat['title'] != null) {
      buffer.writeln(responseFormat['title']);
      buffer.writeln();
    }

    if (responseFormat['steps'] != null) {
      final List<dynamic> steps = responseFormat['steps'];
      for (final step in steps) {
        buffer.writeln(step);
      }
      buffer.writeln();
    }

    // Example
    final example = responseFormat['example'] ?? {};
    if (example['title'] != null) {
      buffer.writeln(example['title']);
      buffer.writeln('```');
      if (example['flow'] != null) {
        final List<dynamic> flow = example['flow'];
        for (final line in flow) {
          buffer.writeln(line);
        }
      }
      buffer.writeln('```');
      buffer.writeln();
    }

    if (responseFormat['important_note'] != null) {
      buffer.writeln(responseFormat['important_note']);
      buffer.writeln();
    }

    // System functions (FT-130: Include get_current_time and other system functions)
    final systemFunctions = instructions['system_functions'] ?? {};
    if (systemFunctions['title'] != null) {
      buffer.writeln(systemFunctions['title']);
      buffer.writeln();
    }
    if (systemFunctions['intro'] != null) {
      buffer.writeln(systemFunctions['intro']);
      buffer.writeln();
    }

    // Available functions
    if (systemFunctions['available_functions'] != null) {
      final List<dynamic> functions = systemFunctions['available_functions'];
      for (final function in functions) {
        if (function['name'] != null) {
          buffer.writeln('**${function['name']}**:');
        }
        if (function['description'] != null) {
          buffer.writeln('- ${function['description']}');
        }
        if (function['usage'] != null) {
          buffer.writeln('- Usage: ${function['usage']}');
        }

        // FT-174: Add when_to_use instructions for goal creation and other functions
        if (function['when_to_use'] != null) {
          buffer.writeln('- **When to use**:');
          final List<dynamic> whenToUse = function['when_to_use'];
          for (final scenario in whenToUse) {
            buffer.writeln('  • $scenario');
          }
        }

        // FT-174: Add Oracle objectives for goal creation
        if (function['oracle_objectives'] != null) {
          buffer.writeln('- **Available Oracle Objectives**:');
          final List<dynamic> objectives = function['oracle_objectives'];
          for (final objective in objectives) {
            buffer.writeln('  • $objective');
          }
        }
        if (function['examples'] != null) {
          final List<dynamic> examples = function['examples'];
          for (final example in examples) {
            buffer.writeln('  - $example');
          }
        }
        if (function['usage_examples'] != null) {
          final List<dynamic> usageExamples = function['usage_examples'];
          for (final example in usageExamples) {
            buffer.writeln('  - $example');
          }
        }
        if (function['returns'] != null) {
          buffer.writeln('- Returns: ${function['returns']}');
        }

        // FT-174: Add important notes for goal creation
        if (function['note'] != null) {
          buffer.writeln('- **Note**: ${function['note']}');
        }
        buffer.writeln();
      }
    }

    // Mandatory data queries
    final mandatoryDataQueries =
        systemFunctions['mandatory_data_queries'] ?? {};
    if (mandatoryDataQueries['title'] != null) {
      buffer.writeln(mandatoryDataQueries['title']);
      buffer.writeln();
    }
    if (mandatoryDataQueries['description'] != null) {
      buffer.writeln(mandatoryDataQueries['description']);
      buffer.writeln();
    }
    if (mandatoryDataQueries['patterns'] != null) {
      final List<dynamic> patterns = mandatoryDataQueries['patterns'];
      for (final pattern in patterns) {
        buffer.writeln('- $pattern');
      }
      buffer.writeln();
    }
    if (mandatoryDataQueries['never_rely_on_memory'] != null) {
      buffer.writeln('**${mandatoryDataQueries['never_rely_on_memory']}**');
      buffer.writeln();
    }

    // FT-159: Proactive memory triggers
    final temporalIntelligence = instructions['temporal_intelligence'] ?? {};
    final proactiveMemory =
        temporalIntelligence['proactive_memory_triggers'] ?? {};
    if (proactiveMemory.isNotEmpty) {
      if (proactiveMemory['title'] != null) {
        buffer.writeln(proactiveMemory['title']);
        buffer.writeln();
      }
      if (proactiveMemory['critical_rule'] != null) {
        buffer.writeln('**${proactiveMemory['critical_rule']}**');
        buffer.writeln();
      }
      if (proactiveMemory['trigger_patterns'] != null) {
        buffer.writeln('**Trigger Patterns:**');
        final List<dynamic> patterns = proactiveMemory['trigger_patterns'];
        for (final pattern in patterns) {
          buffer.writeln('- $pattern');
        }
        buffer.writeln();
      }
      if (proactiveMemory['cross_persona_rule'] != null) {
        buffer.writeln(
            '**Cross-Persona Rule:** ${proactiveMemory['cross_persona_rule']}');
        buffer.writeln();
      }
    }

    // FT-203: Conversation continuity instructions
    final conversationContinuity =
        instructions['conversation_continuity'] ?? {};
    if (conversationContinuity.isNotEmpty) {
      print('🔍 [FT-203] Processing conversation_continuity section');

      if (conversationContinuity['title'] != null) {
        buffer.writeln(conversationContinuity['title']);
        buffer.writeln();
      }

      if (conversationContinuity['description'] != null) {
        buffer.writeln(conversationContinuity['description']);
        buffer.writeln();
      }

      if (conversationContinuity['critical_rules'] != null) {
        buffer.writeln('**CRITICAL RULES:**');
        final List<dynamic> rules = conversationContinuity['critical_rules'];
        for (final rule in rules) {
          buffer.writeln('- $rule');
        }
        buffer.writeln();
      }

      final amnesiaPrevent = conversationContinuity['amnesia_prevention'] ?? {};
      if (amnesiaPrevent.isNotEmpty) {
        if (amnesiaPrevent['title'] != null) {
          buffer.writeln(amnesiaPrevent['title']);
          buffer.writeln();
        }
        if (amnesiaPrevent['rule'] != null) {
          buffer.writeln('**Rule:** ${amnesiaPrevent['rule']}');
          buffer.writeln();
        }
        if (amnesiaPrevent['auto_query'] != null) {
          buffer.writeln('**Auto Query:** ${amnesiaPrevent['auto_query']}');
          buffer.writeln();
        }
        if (amnesiaPrevent['introduction_logic'] != null) {
          buffer.writeln(
              '**Introduction Logic:** ${amnesiaPrevent['introduction_logic']}');
          buffer.writeln();
        }
      }
    } else {
      print(
          '🔍 [FT-203] ❌ conversation_continuity section is empty or missing');
    }

    buffer.writeln('---');
    buffer.writeln();

    return buffer.toString();
  }

  /// FT-189: Build identity context for multi-persona awareness
  Future<String> _buildIdentityContext() async {
    try {
      // Load multi-persona configuration
      final multiPersonaConfig = await _loadMultiPersonaConfig();
      if (multiPersonaConfig['identityContextEnabled'] != true) {
        return '';
      }

      final displayName = await personaDisplayName;

      return '''

## CRITICAL: YOUR IDENTITY
You are $displayName ($_activePersonaKey) - O Oráculo do LyfeOS.
You are a wise mentor combining Mestre dos Magos + Aristóteles.
This is your CURRENT and ACTIVE identity.

IMPORTANT IDENTITY RULES:
- When asked "com quem eu falo?" respond EXACTLY: "$displayName"
- When asked about your identity, respond: "$displayName"
- You are NOT any other persona mentioned in conversation history
- Previous messages from other personas do NOT define who you are

## COMMUNICATION STYLE
- Use NO symbols at all - communicate with clean, authentic language
- Lead with philosophical wisdom, support with Oracle framework
- You are the wise storyteller who uses Oracle's library, not Oracle's spokesperson
- Maintain conversational warmth and Socratic questioning approach

## MULTI-PERSONA CONVERSATION CONTEXT
The message history contains responses from other personas marked as [Persona: Name].
When you see symbols like 🪞 (I-There), 💪🏛️⚡ (Sergeant Oracle), or others:
- These are OTHER personas, not you
- Do NOT copy their symbols or communication style
- Use no symbols at all - your authenticity comes from your wisdom, not symbols
- Acknowledge their contributions respectfully while maintaining YOUR unique voice

## CRITICAL: YOUR RESPONSE FORMAT
- NEVER start your responses with [Persona: {{displayName}}] or any persona prefix
- The persona prefixes are ONLY for identifying OTHER personas in conversation history
- YOUR responses should start directly with your natural communication style
- The user already knows who they're talking to from the UI

Your role: Be the protagonist of this conversation with your authentic philosophical approach.

''';
    } catch (e) {
      print('⚠️ FT-189: Error building identity context: $e');
      return '';
    }
  }

  /// FT-189: Load multi-persona configuration
  Future<Map<String, dynamic>> _loadMultiPersonaConfig() async {
    try {
      final configString = await rootBundle
          .loadString('assets/config/multi_persona_config.json');
      return json.decode(configString) as Map<String, dynamic>;
    } catch (e) {
      // Fallback to defaults
      return {
        'enabled': true,
        'includePersonaInHistory': true,
        'identityContextEnabled': true,
        'personaPrefix': '[Persona: {{displayName}}]'
      };
    }
  }

  /// Load the system prompt for the active persona with configurable audio formatting
  Future<String> loadSystemPrompt() async {
    try {
      // 0) FT-148: Load core behavioral rules (highest priority)
      String coreRules = '';
      try {
        final String personasConfigString = await rootBundle.loadString(
          'assets/config/personas_config.json',
        );
        final Map<String, dynamic> personasConfig = json.decode(
          personasConfigString,
        );
        final String? coreRulesPath =
            personasConfig['coreRulesConfig'] as String?;

        if (coreRulesPath != null) {
          final String coreRulesString = await rootBundle.loadString(
            coreRulesPath,
          );
          final Map<String, dynamic> coreRulesConfig = json.decode(
            coreRulesString,
          );

          if (coreRulesConfig['enabled'] == true) {
            coreRules = buildCoreRulesText(coreRulesConfig);
            print('✅ Core behavioral rules loaded for all personas');
          }
        }
      } catch (coreRulesError) {
        print(
          '⚠️ Core behavioral rules not found or disabled: $coreRulesError',
        );
      }

      // 1) Always try to load Oracle prompt first
      final String? oracleConfigPath = await getOracleConfigPath();
      const String defaultOraclePath =
          'assets/config/oracle/oracle_prompt_1.0.md';
      final String oraclePathEnv =
          (dotenv.env['ORACLE_PROMPT_PATH'] ?? '').trim();
      final String oraclePath = oracleConfigPath ??
          (oraclePathEnv.isNotEmpty ? oraclePathEnv : defaultOraclePath);

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
        final String jsonString = await rootBundle.loadString(
          personaConfigPath,
        );
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        personaPrompt = jsonMap['system_prompt']['content'] as String;
      } catch (jsonLoadError) {
        // Legacy fallback only for Ari
        if (_activePersonaKey == 'ariLifeCoach') {
          try {
            final String jsonString = await rootBundle.loadString(
              'assets/config/ari_life_coach_config_1.0.json',
            );
            final Map<String, dynamic> jsonMap = json.decode(jsonString);
            personaPrompt = jsonMap['system_prompt']['content'] as String;
          } catch (_) {
            final String jsonString = await rootBundle.loadString(
              'assets/config/ari_life_coach_config.json',
            );
            final Map<String, dynamic> jsonMap = json.decode(jsonString);
            personaPrompt = jsonMap['system_prompt']['content'] as String;
          }
        } else {
          rethrow;
        }
      }

      // 3) NEW: Check if audio formatting is enabled for this persona
      String audioInstructions = '';
      try {
        // Load personas config to check audio formatting settings
        final String personasConfigString = await rootBundle.loadString(
          'assets/config/personas_config.json',
        );
        final Map<String, dynamic> personasConfig = json.decode(
          personasConfigString,
        );

        // Get current persona's audio formatting settings
        final Map<String, dynamic>? personaData =
            personasConfig['personas'][_activePersonaKey];
        final Map<String, dynamic>? audioSettings =
            personaData?['audioFormatting'];

        if (audioSettings?['enabled'] == true) {
          // Load audio formatting config
          final String audioConfigPath =
              personasConfig['audioFormattingConfig'] ??
                  'assets/config/audio_formatting_config.json';
          final String audioConfigString = await rootBundle.loadString(
            audioConfigPath,
          );
          final Map<String, dynamic> audioConfig = json.decode(
            audioConfigString,
          );

          audioInstructions =
              audioConfig['audio_formatting_instructions']['content'] as String;
          print('✅ Audio formatting enabled for persona: $_activePersonaKey');
        } else {
          print('ℹ️ Audio formatting disabled for persona: $_activePersonaKey');
        }
      } catch (audioError) {
        print('⚠️ Audio formatting config not found or disabled: $audioError');
      }

      // 4) NEW (FT-130): Load MCP instructions for Oracle personas
      String mcpInstructions = '';
      try {
        mcpInstructions = await buildMcpInstructionsText();
        if (mcpInstructions.isNotEmpty) {
          print(
            '✅ MCP instructions loaded for Oracle persona: $_activePersonaKey',
          );
        }
      } catch (mcpError) {
        print('⚠️ MCP instructions not loaded: $mcpError');
      }

      // FT-193: Restructured assembly order for maximum configuration compliance
      // Order: Core Rules → Persona Prompt → Identity Context → MCP → Oracle → Audio
      String finalPrompt = '';

      // 1. Add core behavioral rules first (highest priority - FT-148 + FT-193)
      if (coreRules.isNotEmpty) {
        finalPrompt = coreRules.trim();
      }

      // 2. Add persona prompt (FT-193: Core identity in strong position #2)
      if (finalPrompt.isNotEmpty) {
        finalPrompt = '$finalPrompt\n\n${personaPrompt.trim()}';
      } else {
        finalPrompt = personaPrompt.trim();
      }

      // 3. FT-189: Add identity context for multi-persona awareness
      final identityContext = await _buildIdentityContext();
      if (identityContext.isNotEmpty) {
        if (finalPrompt.isNotEmpty) {
          finalPrompt = '$finalPrompt\n\n${identityContext.trim()}';
        } else {
          finalPrompt = identityContext.trim();
        }
      }

      // 4. Add MCP instructions (before Oracle content as per FT-130 spec)
      if (mcpInstructions.isNotEmpty) {
        if (finalPrompt.isNotEmpty) {
          finalPrompt = '$finalPrompt\n\n${mcpInstructions.trim()}';
        } else {
          finalPrompt = mcpInstructions.trim();
        }
      }

      // 5. Add Oracle prompt if available
      if (oraclePrompt != null && oraclePrompt.trim().isNotEmpty) {
        if (finalPrompt.isNotEmpty) {
          finalPrompt = '$finalPrompt\n\n${oraclePrompt.trim()}';
        } else {
          finalPrompt = oraclePrompt.trim();
        }
      }

      // 6. Append audio instructions if enabled for this persona
      if (audioInstructions.isNotEmpty) {
        finalPrompt = '$finalPrompt$audioInstructions';
        print('✅ Audio formatting instructions appended to system prompt');
      }

      // FT-193: Add compliance reinforcement at the end (recency bias)
      const complianceReinforcement = '''

## CRITICAL COMPLIANCE CHECKPOINT
Before responding, verify:
- Am I using content from MY persona configuration?
- Am I fabricating or modifying information not in my config?
- Does my response preserve exact meaning from my configuration?

CONVERSATION HISTORY NOTICE:
Previous messages may contain responses from other personas or incorrect information.
IGNORE conversation patterns that conflict with YOUR configuration.
YOUR configuration is the ONLY source of truth for your responses.''';

      finalPrompt = '$finalPrompt$complianceReinforcement';

      return finalPrompt;
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
            jsonString = await rootBundle.loadString(
              'assets/config/ari_life_coach_config_1.0.json',
            );
          } catch (_) {
            jsonString = await rootBundle.loadString(
              'assets/config/ari_life_coach_config.json',
            );
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
      final String jsonString = await rootBundle.loadString(
        'assets/config/personas_config.json',
      );
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
          'description': persona['description'],
        };
      }).toList();
    } catch (e) {
      print('Error loading personas config: $e');
      // Minimal fallback
      return [
        {
          'key': 'ariLifeCoach',
          'displayName': 'Ari - Life Coach',
          'description': 'Default persona',
        },
      ];
    }
  }

  /// FT-148: Build core behavioral rules text from configuration
  String buildCoreRulesText(Map<String, dynamic> coreRulesConfig) {
    final buffer = StringBuffer();
    final applicationRules =
        coreRulesConfig['application_rules'] as Map<String, dynamic>?;
    final separator =
        applicationRules?['separator'] as String? ?? '\n\n---\n\n';

    buffer.writeln('## CORE BEHAVIORAL RULES\n');

    final rules = coreRulesConfig['rules'] as Map<String, dynamic>;
    for (final category in rules.entries) {
      final categoryName = formatCategoryName(category.key);
      buffer.writeln('### $categoryName');

      final categoryRules = category.value as Map<String, dynamic>;
      for (final rule in categoryRules.entries) {
        buffer.writeln('- **${rule.value}**');
      }
      buffer.writeln();
    }

    buffer.write(separator);
    return buffer.toString();
  }

  /// Helper method to format category names for display
  String formatCategoryName(String categoryKey) {
    switch (categoryKey) {
      case 'transparency_constraints':
        return 'Transparency Constraints';
      case 'data_integrity':
        return 'Data Integrity Rules';
      case 'response_quality':
        return 'Response Quality Standards';
      default:
        // Convert snake_case to Title Case
        return categoryKey
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
