import 'package:flutter_test/flutter_test.dart';
import '../../../lib/features/audio_assistant/services/character_voice_config.dart';

void main() {
  group('CharacterVoiceConfig Tests', () {
    test('should return correct voice config for Guide Sergeant Oracle', () {
      // Act
      final config =
          CharacterVoiceConfig.getVoiceConfig('Guide Sergeant Oracle');

      // Assert - Military voice characteristics
      expect(config['stability'], 0.75); // Higher for authority
      expect(config['similarityBoost'], 0.85); // Strong character presence
      expect(config['style'], 0.3); // Assertive character
      expect(config['speakerBoost'], true);
      expect(config['modelId'], 'eleven_multilingual_v1');
      expect(config['description'], contains('military sergeant'));
      expect(config['description'], contains('Authoritative'));
      expect(config['description'], contains('commanding'));
    });

    test('should return default config for unknown character', () {
      // Act
      final config = CharacterVoiceConfig.getVoiceConfig('Unknown Character');

      // Assert - Default voice characteristics
      expect(config['stability'], 0.6);
      expect(config['similarityBoost'], 0.8);
      expect(config['style'], 0.0);
      expect(config['description'], contains('Standard assistant'));
    });

    test('should list available characters', () {
      // Act
      final characters = CharacterVoiceConfig.getAvailableCharacters();

      // Assert
      expect(characters, contains('Guide Sergeant Oracle'));
      expect(
          characters, isNot(contains('default'))); // Should not include default
    });

    test('should provide military voice optimization settings', () {
      // Act
      final militaryConfig =
          CharacterVoiceConfig.getMilitaryVoiceOptimization();

      // Assert - Military-specific optimizations
      expect(militaryConfig['stability'], 0.8); // Very stable for authority
      expect(militaryConfig['similarityBoost'], 0.9); // Strong presence
      expect(militaryConfig['style'], 0.4); // More assertive
      expect(militaryConfig['additionalInstructions']['tone'],
          contains('authoritative'));
      expect(militaryConfig['additionalInstructions']['character'],
          contains('drill sergeant'));
    });

    test('should create independent config copies', () {
      // Act
      final config1 =
          CharacterVoiceConfig.getVoiceConfig('Guide Sergeant Oracle');
      final config2 =
          CharacterVoiceConfig.getVoiceConfig('Guide Sergeant Oracle');

      // Modify one config
      config1['stability'] = 999.0;

      // Assert - Configs should be independent
      expect(config1['stability'], 999.0);
      expect(config2['stability'], 0.75); // Should remain unchanged
    });
  });
}
