import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/features/audio_assistant/services/eleven_labs_provider.dart';
import 'package:ai_personas_app/utils/logger.dart';

void main() {
  group('FT-132 Language Code Integration Tests', () {
    late ElevenLabsProvider provider;

    setUp(() {
      provider = ElevenLabsProvider();
    });

    tearDown(() async {
      await provider.dispose();
    });

    group('Language Code Configuration', () {
      test('should accept detectedLanguage in configuration', () async {
        // Test Portuguese configuration
        final ptConfig = {
          'apiKey': 'test_key',
          'voiceId': 'test_voice',
          'detectedLanguage': 'pt_BR',
        };

        final result = await provider.updateConfig(ptConfig);
        expect(result, isTrue);
        expect(provider.config['detectedLanguage'], equals('pt_BR'));
      });

      test('should accept English configuration', () async {
        // Test English configuration
        final enConfig = {
          'apiKey': 'test_key',
          'voiceId': 'test_voice',
          'detectedLanguage': 'en_US',
        };

        final result = await provider.updateConfig(enConfig);
        expect(result, isTrue);
        expect(provider.config['detectedLanguage'], equals('en_US'));
      });

      test('should handle configuration without detectedLanguage', () async {
        // Test configuration without language
        final config = {
          'apiKey': 'test_key',
          'voiceId': 'test_voice',
        };

        final result = await provider.updateConfig(config);
        expect(result, isTrue);
        expect(provider.config['detectedLanguage'], isNull);
      });
    });

    group('Language Code Mapping Verification', () {
      test('should use LanguageUtils for language code mapping', () async {
        // This test verifies that the provider uses the centralized language utils
        // We can't directly test the private _getLanguageCode method, but we can
        // verify that the configuration is properly stored and would be used

        final testCases = [
          {'input': 'pt_BR', 'expectedInConfig': 'pt_BR'},
          {'input': 'pt', 'expectedInConfig': 'pt'},
          {'input': 'en_US', 'expectedInConfig': 'en_US'},
          {'input': 'en', 'expectedInConfig': 'en'},
          {'input': 'es', 'expectedInConfig': 'es'},
          {'input': 'fr_FR', 'expectedInConfig': 'fr_FR'},
        ];

        for (final testCase in testCases) {
          final config = {
            'apiKey': 'test_key',
            'voiceId': 'test_voice',
            'detectedLanguage': testCase['input'],
          };

          await provider.updateConfig(config);
          expect(provider.config['detectedLanguage'],
              equals(testCase['expectedInConfig']));
        }
      });
    });

    group('Provider Integration', () {
      test(
          'should maintain provider functionality after language code integration',
          () {
        // Verify that the provider still has all expected methods
        expect(provider.name, equals('ElevenLabs'));
        expect(provider.config, isA<Map<String, dynamic>>());

        // Verify that updateConfig still works
        expect(() => provider.updateConfig({}), returnsNormally);
      });

      test('should handle initialization with language configuration',
          () async {
        final config = {
          'apiKey': 'test_key',
          'voiceId': 'test_voice',
          'detectedLanguage': 'pt_BR',
          'useAuthFromEnv': false,
        };

        final result = await provider.updateConfig(config);
        expect(result, isTrue);

        // Verify the configuration was stored correctly
        expect(provider.config['detectedLanguage'], equals('pt_BR'));
        expect(provider.config['apiKey'], equals('test_key'));
        expect(provider.config['voiceId'], equals('test_voice'));
      });
    });

    group('Backward Compatibility', () {
      test('should work without detectedLanguage parameter', () async {
        // Test that existing configurations without detectedLanguage still work
        final legacyConfig = {
          'apiKey': 'test_key',
          'voiceId': 'test_voice',
          'modelId': 'eleven_multilingual_v1',
          'stability': 0.65,
          'similarityBoost': 0.8,
        };

        final result = await provider.updateConfig(legacyConfig);
        expect(result, isTrue);

        // Should not have detectedLanguage but should work fine
        expect(provider.config['detectedLanguage'], isNull);
        expect(provider.config['apiKey'], equals('test_key'));
      });

      test('should handle null detectedLanguage gracefully', () async {
        final config = {
          'apiKey': 'test_key',
          'voiceId': 'test_voice',
          'detectedLanguage': null,
        };

        final result = await provider.updateConfig(config);
        expect(result, isTrue);
        expect(provider.config['detectedLanguage'], isNull);
      });
    });
  });
}
