# FT-137: Consolidated Persona Voice Configuration System

**Feature ID:** FT-137  
**Priority:** High  
**Category:** Architecture Refactoring  
**Effort:** 2 days  

## OVERVIEW

Consolidate all voice configuration into the `audioFormatting` section of `personas_config.json`, creating a unified, maintainable system that eliminates scattered voice settings and enables persona-specific voice customization with language optimization.

## PROBLEM STATEMENT

The current voice configuration system has multiple issues:

1. **Fragmented Configuration Sources:**
   - Hardcoded voice settings in `CharacterVoiceConfig.dart`
   - `.env` file voice ID only affects "Ari - Life Coach"
   - Individual persona configs sometimes contain voice settings
   - No centralized voice management system

2. **Limited Scalability:**
   - Adding new personas requires code changes in multiple files
   - No easy way to customize voice parameters per persona
   - Language optimizations are hardcoded and not persona-specific
   - Difficult to implement A/B testing for voice configurations

3. **Maintenance Complexity:**
   - Voice configurations scattered across codebase
   - Character name string matching between different systems
   - No clear ownership of voice configuration data
   - Difficult to debug voice-related issues

## SOLUTION

Create a unified voice configuration system where all voice settings are defined in the `audioFormatting` section of `personas_config.json`, with a new service layer to manage voice configuration loading and application.

## FUNCTIONAL REQUIREMENTS

### FR-137.1: Unified Configuration Schema
- All voice configurations stored in `personas_config.json`
- Each persona's `audioFormatting` section contains complete voice configuration
- Support for language-specific parameter optimizations
- Fallback voice ID support for premium voices

### FR-137.2: Voice Configuration Structure
```json
{
  "audioFormatting": {
    "enabled": true,
    "voice": {
      "voiceId": "string",
      "modelId": "string", 
      "stability": 0.0-1.0,
      "similarityBoost": 0.0-1.0,
      "style": 0.0-1.0,
      "speakerBoost": boolean,
      "apply_text_normalization": "auto|on|off",
      "description": "string",
      "fallbackVoiceId": "string|null",
      "languageOptimizations": {
        "pt_BR": { /* parameter overrides */ },
        "en_US": { /* parameter overrides */ }
      }
    }
  }
}
```

### FR-137.3: Dynamic Voice Loading
- Load voice configuration at runtime from personas config
- Support for language-specific parameter optimization
- Graceful fallback to default configuration if persona config missing
- Backward compatibility with existing .env voice ID (deprecated)

### FR-137.4: Configuration Validation
- Validate voice configuration schema on load
- Verify required parameters are present
- Provide meaningful error messages for invalid configurations
- Support for configuration hot-reloading during development

## TECHNICAL REQUIREMENTS

### TR-137.1: Configuration Schema

**Complete Persona Configuration Example:**
```json
{
  "defaultPersona": "iThereWithOracle42",
  "audioFormattingConfig": "assets/config/audio_formatting_config.json",
  "mcpInstructionsConfig": "assets/config/mcp_instructions_config.json",
  "personas": {
    "ariWithOracle42": {
      "enabled": true,
      "displayName": "Aristios 4.2",
      "description": "Advanced Life Management Coach with comprehensive behavioral change framework integrating 9 scientific methodologies, structured onboarding, and complete habit catalog system - latest version with enhanced features.",
      "configPath": "assets/config/ari_life_coach_config_2.0.json",
      "oracleConfigPath": "assets/config/oracle/oracle_prompt_4.2_optimized.md",
      "audioFormatting": {
        "enabled": true,
        "voice": {
          "voiceId": "pNInz6obpgDQGcFmaJgB",
          "modelId": "eleven_multilingual_v2",
          "stability": 0.75,
          "similarityBoost": 0.80,
          "style": 0.15,
          "speakerBoost": true,
          "apply_text_normalization": "auto",
          "description": "Professional masculine coach voice - authoritative, warm, methodical",
          "fallbackVoiceId": null,
          "languageOptimizations": {
            "pt_BR": {
              "stability": 0.68,
              "style": 0.08,
              "speaking_rate": 0.95
            },
            "en_US": {
              "stability": 0.65,
              "style": 0.05,
              "speaking_rate": 0.95
            }
          }
        }
      }
    },
    "iThereWithOracle42": {
      "enabled": true,
      "displayName": "I-There 4.2",
      "description": "AI reflection enhanced with Aristos 4.2 Life Management framework - your mirror realm guide with the most advanced behavioral science, real-time habit monitoring, and intelligent data insights.",
      "configPath": "assets/config/i_there_config.json",
      "oracleConfigPath": "assets/config/oracle/oracle_prompt_4.2_optimized.md",
      "audioFormatting": {
        "enabled": true,
        "voice": {
          "voiceId": "pNInz6obpgDQGcFmaJgB",
          "modelId": "eleven_multilingual_v2",
          "stability": 0.60,
          "similarityBoost": 0.85,
          "style": 0.35,
          "speakerBoost": true,
          "apply_text_normalization": "auto",
          "description": "Curious, conversational reflection voice - engaging, friendly, authentic",
          "fallbackVoiceId": null,
          "languageOptimizations": {
            "pt_BR": {
              "stability": 0.55,
              "style": 0.40,
              "speaking_rate": 1.05
            },
            "en_US": {
              "stability": 0.60,
              "style": 0.35,
              "speaking_rate": 1.05
            }
          }
        }
      }
    },
    "sergeantOracleWithOracle42": {
      "enabled": true,
      "displayName": "Sergeant Oracle 4.2",
      "description": "Time-traveling Roman gladiator coach powered by Aristos 4.2 framework! Ancient warrior wisdom meets the most cutting-edge behavioral science and real-time habit monitoring for epic life transformation! 💪🏛️⚡📊✨",
      "configPath": "assets/config/sergeant_oracle_config.json",
      "oracleConfigPath": "assets/config/oracle/oracle_prompt_4.2_optimized.md",
      "audioFormatting": {
        "enabled": true,
        "voice": {
          "voiceId": "pNInz6obpgDQGcFmaJgB",
          "modelId": "eleven_multilingual_v2",
          "stability": 0.45,
          "similarityBoost": 0.90,
          "style": 0.55,
          "speakerBoost": true,
          "apply_text_normalization": "auto",
          "description": "High-energy motivational coach voice - dynamic, enthusiastic, commanding",
          "fallbackVoiceId": null,
          "languageOptimizations": {
            "pt_BR": {
              "stability": 0.40,
              "style": 0.60,
              "speaking_rate": 1.15
            },
            "en_US": {
              "stability": 0.45,
              "style": 0.55,
              "speaking_rate": 1.15
            }
          }
        }
      }
    },
    "aryaWithOracle42": {
      "enabled": true,
      "displayName": "Arya 4.2",
      "description": "Empowering female Life Management Coach combining Oracle 4.2 framework with feminine wisdom, emotional intelligence, and holistic approach to behavioral change and personal transformation.",
      "configPath": "assets/config/arya_life_coach_config.json",
      "oracleConfigPath": "assets/config/oracle/oracle_prompt_4.2_optimized.md",
      "audioFormatting": {
        "enabled": true,
        "voice": {
          "voiceId": "aMSt68OGf4xUZAnLpTU8",
          "modelId": "eleven_multilingual_v2",
          "stability": 0.70,
          "similarityBoost": 0.85,
          "style": 0.25,
          "speakerBoost": true,
          "apply_text_normalization": "auto",
          "description": "Sophisticated female empowering voice (Juniper) - warm, confident, emotionally intelligent",
          "fallbackVoiceId": "pNInz6obpgDQGcFmaJgB",
          "languageOptimizations": {
            "pt_BR": {
              "stability": 0.65,
              "style": 0.30,
              "speaking_rate": 1.0
            },
            "en_US": {
              "stability": 0.70,
              "style": 0.25,
              "speaking_rate": 1.0
            }
          }
        }
      }
    }
  }
}
```

### TR-137.2: Voice Configuration Service

**File:** `lib/services/persona_voice_config_service.dart`

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Service for loading and managing persona voice configurations
class PersonaVoiceConfigService {
  static final Logger _logger = Logger();
  static Map<String, dynamic>? _personasConfig;
  static bool _isInitialized = false;

  /// Initialize the service by loading personas configuration
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final configString = await rootBundle.loadString('assets/config/personas_config.json');
      _personasConfig = json.decode(configString);
      _isInitialized = true;
      _logger.debug('PersonaVoiceConfigService initialized successfully');
      return true;
    } catch (e) {
      _logger.error('Failed to initialize PersonaVoiceConfigService: $e');
      return false;
    }
  }

  /// Get voice configuration for a specific persona
  static Map<String, dynamic>? getVoiceConfig(String personaKey) {
    if (!_isInitialized || _personasConfig == null) {
      _logger.error('PersonaVoiceConfigService not initialized');
      return null;
    }

    final personas = _personasConfig!['personas'] as Map<String, dynamic>?;
    if (personas == null) return null;

    final persona = personas[personaKey] as Map<String, dynamic>?;
    if (persona == null) return null;

    final audioFormatting = persona['audioFormatting'] as Map<String, dynamic>?;
    if (audioFormatting == null || audioFormatting['enabled'] != true) {
      return null;
    }

    return audioFormatting['voice'] as Map<String, dynamic>?;
  }

  /// Get voice configuration with fallback to default
  static Map<String, dynamic> getVoiceConfigWithFallback(String personaKey) {
    final voiceConfig = getVoiceConfig(personaKey);
    if (voiceConfig != null) {
      return Map<String, dynamic>.from(voiceConfig);
    }

    // Return default configuration
    return _getDefaultVoiceConfig();
  }

  /// Get language-optimized voice configuration
  static Map<String, dynamic> getLanguageOptimizedConfig(
    String personaKey, 
    String language
  ) {
    final baseConfig = getVoiceConfigWithFallback(personaKey);
    final voiceConfig = getVoiceConfig(personaKey);

    if (voiceConfig != null) {
      final languageOpts = voiceConfig['languageOptimizations'] as Map<String, dynamic>?;
      if (languageOpts != null && languageOpts.containsKey(language)) {
        final langConfig = languageOpts[language] as Map<String, dynamic>;
        // Merge language-specific overrides
        final optimizedConfig = Map<String, dynamic>.from(baseConfig);
        langConfig.forEach((key, value) {
          optimizedConfig[key] = value;
        });
        return optimizedConfig;
      }
    }

    return baseConfig;
  }

  /// Get all available persona keys
  static List<String> getAvailablePersonaKeys() {
    if (!_isInitialized || _personasConfig == null) return [];

    final personas = _personasConfig!['personas'] as Map<String, dynamic>?;
    if (personas == null) return [];

    return personas.keys.toList();
  }

  /// Get persona key from display name
  static String? getPersonaKeyFromDisplayName(String displayName) {
    if (!_isInitialized || _personasConfig == null) return null;

    final personas = _personasConfig!['personas'] as Map<String, dynamic>?;
    if (personas == null) return null;

    for (final entry in personas.entries) {
      final persona = entry.value as Map<String, dynamic>;
      if (persona['displayName'] == displayName) {
        return entry.key;
      }
    }

    return null;
  }

  /// Validate voice configuration
  static bool validateVoiceConfig(Map<String, dynamic> config) {
    final requiredFields = ['voiceId', 'modelId', 'stability', 'similarityBoost', 'style'];
    
    for (final field in requiredFields) {
      if (!config.containsKey(field)) {
        _logger.error('Voice configuration missing required field: $field');
        return false;
      }
    }

    // Validate parameter ranges
    final stability = config['stability'] as num?;
    if (stability == null || stability < 0 || stability > 1) {
      _logger.error('Invalid stability value: $stability (must be 0.0-1.0)');
      return false;
    }

    final similarityBoost = config['similarityBoost'] as num?;
    if (similarityBoost == null || similarityBoost < 0 || similarityBoost > 1) {
      _logger.error('Invalid similarityBoost value: $similarityBoost (must be 0.0-1.0)');
      return false;
    }

    final style = config['style'] as num?;
    if (style == null || style < 0 || style > 1) {
      _logger.error('Invalid style value: $style (must be 0.0-1.0)');
      return false;
    }

    return true;
  }

  /// Get default voice configuration
  static Map<String, dynamic> _getDefaultVoiceConfig() {
    return {
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.6,
      'similarityBoost': 0.8,
      'style': 0.0,
      'speakerBoost': true,
      'apply_text_normalization': 'auto',
      'description': 'Default voice configuration',
      'fallbackVoiceId': null,
    };
  }

  /// Reload configuration (for development/testing)
  static Future<bool> reload() async {
    _isInitialized = false;
    _personasConfig = null;
    return await initialize();
  }
}
```

### TR-137.3: Updated Character Voice Config

**File:** `lib/features/audio_assistant/services/character_voice_config.dart`

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../services/persona_voice_config_service.dart';
import '../../../utils/logger.dart';

/// Service for managing character-specific voice configurations
/// Now delegates to PersonaVoiceConfigService for centralized configuration
class CharacterVoiceConfig {
  static final Logger _logger = Logger();

  /// Get voice configuration for a specific character
  static Map<String, dynamic> getVoiceConfig(String characterName) {
    // Map display name to persona key
    final personaKey = PersonaVoiceConfigService.getPersonaKeyFromDisplayName(characterName);
    if (personaKey == null) {
      _logger.warning('No persona key found for character: $characterName');
      return _getDefaultConfig();
    }

    final config = PersonaVoiceConfigService.getVoiceConfigWithFallback(personaKey);
    
    // Apply backward compatibility for .env voice ID (deprecated)
    return _applyEnvCompatibility(config, characterName);
  }

  /// Get language-optimized voice configuration
  static Map<String, dynamic> getLanguageOptimizedConfig(
    String characterName, 
    String language
  ) {
    final personaKey = PersonaVoiceConfigService.getPersonaKeyFromDisplayName(characterName);
    if (personaKey == null) {
      _logger.warning('No persona key found for character: $characterName');
      return _getDefaultConfig();
    }

    final config = PersonaVoiceConfigService.getLanguageOptimizedConfig(personaKey, language);
    
    // Apply backward compatibility for .env voice ID (deprecated)
    return _applyEnvCompatibility(config, characterName);
  }

  /// Get all available character voices
  static List<String> getAvailableCharacters() {
    final personaKeys = PersonaVoiceConfigService.getAvailablePersonaKeys();
    final characterNames = <String>[];

    for (final personaKey in personaKeys) {
      final config = PersonaVoiceConfigService.getVoiceConfig(personaKey);
      if (config != null) {
        // Get display name from persona config
        // This would require additional method in PersonaVoiceConfigService
        characterNames.add(personaKey); // Simplified for now
      }
    }

    return characterNames;
  }

  /// Apply backward compatibility for .env voice ID (deprecated)
  static Map<String, dynamic> _applyEnvCompatibility(
    Map<String, dynamic> config, 
    String characterName
  ) {
    // Only apply .env override for specific characters (backward compatibility)
    if (characterName == 'Aristios 4.2' || characterName == 'Ari - Life Coach') {
      final envVoiceId = dotenv.env['ELEVEN_LABS_VOICE_ID'] ??
          dotenv.env['ELEVENLABS_VOICE_ID'];
      
      if (envVoiceId != null && envVoiceId.isNotEmpty) {
        final modifiedConfig = Map<String, dynamic>.from(config);
        modifiedConfig['voiceId'] = envVoiceId;
        
        // Ensure multilingual model for cross-language support
        final modelId = modifiedConfig['modelId'] as String? ?? '';
        if (!modelId.startsWith('eleven_multilingual_')) {
          modifiedConfig['modelId'] = 'eleven_multilingual_v1';
        }
        
        _logger.debug('Applied .env voice ID override for $characterName: $envVoiceId');
        return modifiedConfig;
      }
    }

    return config;
  }

  /// Get default voice configuration
  static Map<String, dynamic> _getDefaultConfig() {
    return {
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.6,
      'similarityBoost': 0.8,
      'style': 0.0,
      'speakerBoost': true,
      'apply_text_normalization': 'auto',
      'description': 'Default voice configuration',
    };
  }

  /// Update voice configuration for a character (deprecated)
  @deprecated
  static void updateCharacterVoice(
      String characterName, Map<String, dynamic> newConfig) {
    _logger.warning(
        'updateCharacterVoice is deprecated. Update personas_config.json instead.');
  }
}
```

### TR-137.4: Enhanced TTS Service Integration

**Updates to:** `lib/features/audio_assistant/tts_service.dart`

```dart
/// Apply persona-specific voice configuration with language optimization
Future<bool> applyPersonaVoice(String personaKey, String language) async {
  try {
    if (_isTestMode) return true;

    // Initialize voice config service if needed
    await PersonaVoiceConfigService.initialize();

    // Get language-optimized voice configuration
    final voiceConfig = PersonaVoiceConfigService.getLanguageOptimizedConfig(
      personaKey, 
      language
    );

    // Validate configuration
    if (!PersonaVoiceConfigService.validateVoiceConfig(voiceConfig)) {
      _logger.error('Invalid voice configuration for persona: $personaKey');
      return false;
    }

    _logger.debug('Applying persona voice for: $personaKey (language: $language)');
    _logger.debug('Voice config: $voiceConfig');

    // Apply configuration to current provider
    final success = await updateProviderConfig(voiceConfig);

    if (success) {
      _logger.debug('Successfully applied persona voice configuration');
    } else {
      _logger.error('Failed to apply persona voice configuration');
    }

    return success;
  } catch (e) {
    _logger.error('Error applying persona voice configuration: $e');
    return false;
  }
}

/// Apply character-specific voice configuration (updated method)
Future<bool> applyCharacterVoice() async {
  try {
    if (_isTestMode) return true;

    final characterName = await _configLoader.activePersonaDisplayName;
    final personaKey = PersonaVoiceConfigService.getPersonaKeyFromDisplayName(characterName);
    
    if (personaKey == null) {
      _logger.error('No persona key found for character: $characterName');
      return false;
    }

    // Get current language (implement language detection logic)
    final language = await _getCurrentLanguage(); // This method needs to be implemented

    return await applyPersonaVoice(personaKey, language);
  } catch (e) {
    _logger.error('Error applying character voice configuration: $e');
    return false;
  }
}
```

## IMPLEMENTATION PHASES

### **Phase 1: Configuration Migration (Day 1)**

**Tasks:**
1. **Update personas_config.json**
   - Add voice configuration to each persona's audioFormatting section
   - Include language optimizations for pt_BR and en_US
   - Set appropriate fallback voice IDs

2. **Create PersonaVoiceConfigService**
   - Implement configuration loading and validation
   - Add language optimization support
   - Include error handling and logging

3. **Update existing personas**
   - Aristios 4.2: Professional masculine voice
   - I-There 4.2: Curious conversational voice
   - Sergeant Oracle 4.2: High-energy motivational voice
   - Arya 4.2: Sophisticated female voice (Juniper)

### **Phase 2: Code Integration (Day 2)**

**Tasks:**
1. **Refactor CharacterVoiceConfig**
   - Update to delegate to PersonaVoiceConfigService
   - Maintain backward compatibility with .env
   - Add deprecation warnings for old methods

2. **Enhance TTS Service**
   - Add persona-based voice configuration methods
   - Implement language-aware voice optimization
   - Update initialization flow

3. **Testing and Validation**
   - Unit tests for PersonaVoiceConfigService
   - Integration tests for voice configuration loading
   - Validation of all persona voice configurations

## ACCEPTANCE CRITERIA

### AC-137.1: Configuration Consolidation
- [ ] All voice configurations moved to personas_config.json
- [ ] Each persona has complete voice configuration in audioFormatting section
- [ ] Language-specific optimizations defined for pt_BR and en_US
- [ ] Fallback voice IDs configured where appropriate

### AC-137.2: Service Implementation
- [ ] PersonaVoiceConfigService successfully loads configurations
- [ ] Voice configuration validation works correctly
- [ ] Language optimization applies appropriate parameter overrides
- [ ] Error handling provides meaningful messages

### AC-137.3: Integration
- [ ] CharacterVoiceConfig delegates to new service
- [ ] TTS Service uses persona-based voice configuration
- [ ] Backward compatibility maintained with .env voice ID
- [ ] All existing personas work with new system

### AC-137.4: Quality Assurance
- [ ] All voice configurations validated on load
- [ ] Unit tests cover all service methods
- [ ] Integration tests verify end-to-end functionality
- [ ] Performance impact is minimal

## TESTING STRATEGY

### **Unit Tests**
```dart
// Test PersonaVoiceConfigService
test('should load voice configuration for valid persona', () {
  final config = PersonaVoiceConfigService.getVoiceConfig('aryaWithOracle42');
  expect(config, isNotNull);
  expect(config!['voiceId'], equals('aMSt68OGf4xUZAnLpTU8'));
});

test('should apply language optimizations', () {
  final config = PersonaVoiceConfigService.getLanguageOptimizedConfig(
    'aryaWithOracle42', 
    'pt_BR'
  );
  expect(config['stability'], equals(0.65)); // pt_BR optimization
});

test('should validate voice configuration', () {
  final validConfig = {
    'voiceId': 'test',
    'modelId': 'eleven_multilingual_v1',
    'stability': 0.7,
    'similarityBoost': 0.8,
    'style': 0.2,
  };
  expect(PersonaVoiceConfigService.validateVoiceConfig(validConfig), isTrue);
});
```

### **Integration Tests**
```dart
testWidgets('should apply persona voice configuration', (tester) async {
  final ttsService = TTSService();
  await ttsService.initialize();
  
  final success = await ttsService.applyPersonaVoice('aryaWithOracle42', 'en_US');
  expect(success, isTrue);
  
  final config = ttsService.providerConfig;
  expect(config['voiceId'], equals('aMSt68OGf4xUZAnLpTU8'));
});
```

## MIGRATION GUIDE

### **For Developers**

**Before (Old System):**
```dart
// Voice configuration scattered in multiple files
final config = CharacterVoiceConfig.getVoiceConfig('Arya 4.2');
```

**After (New System):**
```dart
// Centralized configuration with language optimization
final config = PersonaVoiceConfigService.getLanguageOptimizedConfig(
  'aryaWithOracle42', 
  'pt_BR'
);
```

### **Configuration Migration**

**Old:** Hardcoded in `CharacterVoiceConfig.dart`
```dart
'Arya - Empowering Life Strategist': {
  'voiceId': 'aMSt68OGf4xUZAnLpTU8',
  'stability': 0.70,
  // ...
}
```

**New:** In `personas_config.json`
```json
"audioFormatting": {
  "enabled": true,
  "voice": {
    "voiceId": "aMSt68OGf4xUZAnLpTU8",
    "stability": 0.70,
    "languageOptimizations": {
      "pt_BR": {"stability": 0.65}
    }
  }
}
```

## BENEFITS

### **Immediate Benefits**
- **Single Source of Truth**: All voice configurations in one place
- **Persona-Specific Voices**: Each persona can have unique voice parameters
- **Language Optimization**: Different voice settings per language per persona
- **Easy Maintenance**: Add new personas without code changes

### **Long-term Benefits**
- **Scalability**: Easy to add new personas with custom voices
- **Flexibility**: Support for A/B testing and user preferences
- **Maintainability**: Clear configuration ownership and structure
- **Debugging**: Centralized configuration makes issues easier to trace

### **User Experience**
- **Consistent Quality**: Optimized voice parameters per persona
- **Language Adaptation**: Better pronunciation and delivery per language
- **Distinct Personalities**: Each persona sounds unique and authentic
- **Reliability**: Fallback mechanisms ensure voice always works

This consolidated voice configuration system will create a much more maintainable, scalable, and user-friendly voice experience across all personas! 🎙️✨
