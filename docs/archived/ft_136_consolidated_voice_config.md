# FT-136: Consolidated Persona Voice Configuration

**Feature ID:** FT-136  
**Priority:** High  
**Category:** Architecture Improvement  
**Effort:** 1 day  

## OVERVIEW

Consolidate voice configuration into the personas config `audioFormatting` section, eliminating the need for separate voice configuration files and .env voice ID dependencies, creating a cleaner, more maintainable system.

## CURRENT ARCHITECTURE ANALYSIS

### **Current Problems**

1. **Multiple Configuration Sources:**
   - `CharacterVoiceConfig.dart` - Hardcoded voice configurations
   - `.env` file - Single voice ID for all personas (ELEVEN_LABS_VOICE_ID)
   - Individual persona config files - Some contain voice settings
   - Personas config - Only has basic `audioFormatting.enabled`

2. **Inconsistent Voice ID Management:**
   - .env voice ID overrides hardcoded values only for "Ari - Life Coach"
   - Other personas stuck with hardcoded voice IDs
   - No easy way to change voice IDs per persona

3. **Maintenance Issues:**
   - Voice configurations scattered across multiple files
   - Hardcoded character name matching between systems
   - Difficult to add new personas with custom voices
   - .env approach doesn't scale to multiple personas

4. **Limited Flexibility:**
   - Can't easily A/B test different voices per persona
   - No runtime voice switching capabilities
   - Difficult to implement user voice preferences per persona

## PROPOSED SOLUTION

### **Consolidated Configuration Architecture**

Move all voice configuration into the `audioFormatting` section of `personas_config.json`, making it the single source of truth for persona voice settings.

### **Enhanced Personas Config Structure**

```json
{
  "defaultPersona": "iThereWithOracle42",
  "audioFormattingConfig": "assets/config/audio_formatting_config.json",
  "mcpInstructionsConfig": "assets/config/mcp_instructions_config.json",
  "personas": {
    "ariWithOracle42": {
      "enabled": true,
      "displayName": "Aristios 4.2",
      "description": "Advanced Life Management Coach...",
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
          "description": "Professional masculine coach voice",
          "fallbackVoiceId": null,
          "languageOptimizations": {
            "pt_BR": {
              "stability": 0.68,
              "style": 0.08
            },
            "en_US": {
              "stability": 0.65,
              "style": 0.05
            }
          }
        }
      }
    },
    "iThereWithOracle42": {
      "enabled": true,
      "displayName": "I-There 4.2",
      "description": "AI reflection enhanced...",
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
          "description": "Curious, conversational reflection voice",
          "fallbackVoiceId": null,
          "languageOptimizations": {
            "pt_BR": {
              "stability": 0.55,
              "style": 0.40
            },
            "en_US": {
              "stability": 0.60,
              "style": 0.35
            }
          }
        }
      }
    },
    "sergeantOracleWithOracle42": {
      "enabled": true,
      "displayName": "Sergeant Oracle 4.2",
      "description": "Time-traveling Roman gladiator coach...",
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
          "description": "High-energy motivational coach voice",
          "fallbackVoiceId": null,
          "languageOptimizations": {
            "pt_BR": {
              "stability": 0.40,
              "style": 0.60
            },
            "en_US": {
              "stability": 0.45,
              "style": 0.55
            }
          }
        }
      }
    },
    "aryaWithOracle42": {
      "enabled": true,
      "displayName": "Arya 4.2",
      "description": "Empowering female Life Management Coach...",
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
          "description": "Sophisticated female empowering voice (Juniper)",
          "fallbackVoiceId": "pNInz6obpgDQGcFmaJgB",
          "languageOptimizations": {
            "pt_BR": {
              "stability": 0.65,
              "style": 0.30
            },
            "en_US": {
              "stability": 0.70,
              "style": 0.25
            }
          }
        }
      }
    }
  }
}
```

## TECHNICAL IMPLEMENTATION

### **1. Enhanced Configuration Loader**

```dart
class PersonaVoiceConfigLoader {
  static Map<String, dynamic>? getVoiceConfig(String personaKey) {
    // Load from personas_config.json
    final personaConfig = PersonasConfig.getPersona(personaKey);
    if (personaConfig == null) return null;
    
    final audioFormatting = personaConfig['audioFormatting'] as Map<String, dynamic>?;
    if (audioFormatting == null || audioFormatting['enabled'] != true) {
      return null;
    }
    
    return audioFormatting['voice'] as Map<String, dynamic>?;
  }
  
  static Map<String, dynamic> getVoiceConfigWithFallback(String personaKey) {
    final voiceConfig = getVoiceConfig(personaKey);
    if (voiceConfig != null) return voiceConfig;
    
    // Fallback to default voice configuration
    return {
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.6,
      'similarityBoost': 0.8,
      'style': 0.0,
      'speakerBoost': true,
      'apply_text_normalization': 'auto',
      'description': 'Default voice',
    };
  }
  
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
        return {...baseConfig, ...langConfig};
      }
    }
    
    return baseConfig;
  }
}
```

### **2. Simplified Character Voice Config**

```dart
/// Simplified service that delegates to PersonaVoiceConfigLoader
class CharacterVoiceConfig {
  /// Get voice configuration for a specific character
  static Map<String, dynamic> getVoiceConfig(String characterName) {
    // Map display name to persona key
    final personaKey = _mapDisplayNameToPersonaKey(characterName);
    if (personaKey == null) {
      return _getDefaultConfig();
    }
    
    return PersonaVoiceConfigLoader.getVoiceConfigWithFallback(personaKey);
  }
  
  /// Get language-optimized voice configuration
  static Map<String, dynamic> getLanguageOptimizedConfig(
    String characterName, 
    String language
  ) {
    final personaKey = _mapDisplayNameToPersonaKey(characterName);
    if (personaKey == null) {
      return _getDefaultConfig();
    }
    
    return PersonaVoiceConfigLoader.getLanguageOptimizedConfig(personaKey, language);
  }
  
  static String? _mapDisplayNameToPersonaKey(String displayName) {
    // Map display names to persona keys
    const displayNameToKey = {
      'Aristios 4.2': 'ariWithOracle42',
      'I-There 4.2': 'iThereWithOracle42',
      'Sergeant Oracle 4.2': 'sergeantOracleWithOracle42',
      'Arya 4.2': 'aryaWithOracle42',
      // Add other mappings...
    };
    
    return displayNameToKey[displayName];
  }
  
  static Map<String, dynamic> _getDefaultConfig() {
    return {
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.6,
      'similarityBoost': 0.8,
      'style': 0.0,
      'speakerBoost': true,
      'apply_text_normalization': 'auto',
      'description': 'Default voice',
    };
  }
}
```

### **3. Enhanced TTS Service Integration**

```dart
/// Enhanced TTS service with consolidated voice configuration
class TTSService {
  // ... existing code ...
  
  /// Apply persona-specific voice configuration with language optimization
  Future<bool> applyPersonaVoice(String personaKey, String language) async {
    try {
      if (_isTestMode) return true;
      
      // Get language-optimized voice configuration
      final voiceConfig = PersonaVoiceConfigLoader.getLanguageOptimizedConfig(
        personaKey, 
        language
      );
      
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
}
```

## MIGRATION STRATEGY

### **Phase 1: Configuration Migration**
1. Update `personas_config.json` with voice configurations
2. Create `PersonaVoiceConfigLoader` class
3. Update existing personas with voice settings

### **Phase 2: Code Refactoring**
1. Modify `CharacterVoiceConfig` to use new loader
2. Update `TTSService` to use persona keys instead of display names
3. Remove .env voice ID dependency

### **Phase 3: Cleanup**
1. Remove hardcoded voice configurations from `CharacterVoiceConfig`
2. Update documentation
3. Add migration tests

## BENEFITS

### **1. Centralized Management**
- Single source of truth for all voice configurations
- Easy to add new personas with custom voices
- Clear relationship between persona and voice settings

### **2. Enhanced Flexibility**
- Per-persona voice ID configuration
- Language-specific optimizations per persona
- Fallback voice ID support for premium voices
- Runtime voice switching capabilities

### **3. Better Maintainability**
- No more hardcoded character name matching
- Easier to add new personas
- Clear configuration structure
- Version control friendly

### **4. Improved User Experience**
- Consistent voice quality per persona
- Language-optimized voice parameters
- Better error handling with fallbacks
- Future support for user voice preferences

### **5. Developer Experience**
- Clear configuration schema
- Easy to understand voice settings
- Better debugging with centralized config
- Simplified testing with mock configurations

## BACKWARD COMPATIBILITY

### **Environment Variable Support**
```dart
static Map<String, dynamic> getVoiceConfigWithEnvFallback(String personaKey) {
  final config = getVoiceConfigWithFallback(personaKey);
  
  // Check for environment variable override (backward compatibility)
  final envVoiceId = dotenv.env['ELEVEN_LABS_VOICE_ID'] ?? 
                     dotenv.env['ELEVENLABS_VOICE_ID'];
  
  if (envVoiceId != null && envVoiceId.isNotEmpty) {
    // Only override if this is a "default" voice ID
    if (config['voiceId'] == 'pNInz6obpgDQGcFmaJgB') {
      config['voiceId'] = envVoiceId;
    }
  }
  
  return config;
}
```

### **Gradual Migration**
- Keep existing `CharacterVoiceConfig` as wrapper during transition
- Support both old and new configuration methods
- Deprecate old methods with clear migration path

## FUTURE ENHANCEMENTS

### **1. User Preferences**
```json
"audioFormatting": {
  "enabled": true,
  "voice": { /* default config */ },
  "userPreferences": {
    "allowVoiceCustomization": true,
    "preferredVoiceId": null,
    "customParameters": {}
  }
}
```

### **2. A/B Testing Support**
```json
"voice": {
  "variants": {
    "default": { /* config A */ },
    "alternative": { /* config B */ }
  },
  "activeVariant": "default"
}
```

### **3. Dynamic Voice Loading**
```json
"voice": {
  "voiceId": "aMSt68OGf4xUZAnLpTU8",
  "voiceSource": "elevenlabs",
  "customVoiceUrl": null,
  "voiceCloneId": null
}
```

## IMPLEMENTATION CHECKLIST

- [ ] Design new personas config schema
- [ ] Create `PersonaVoiceConfigLoader` class
- [ ] Update `personas_config.json` with voice configurations
- [ ] Modify `CharacterVoiceConfig` to use new system
- [ ] Update `TTSService` for persona key usage
- [ ] Add language optimization support
- [ ] Implement fallback mechanisms
- [ ] Create migration tests
- [ ] Update documentation
- [ ] Remove deprecated code

This consolidation will create a much cleaner, more maintainable voice configuration system that scales beautifully with new personas and provides excellent flexibility for future enhancements! 🎙️✨
