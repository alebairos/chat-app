import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/features/audio_assistant/tts_service.dart';

void main() {
  late AudioAssistantTTSService ttsService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ttsService = AudioAssistantTTSService();
    ttsService.enableTestMode(); // Use mock provider for tests
  });

  group('TTS Service with Providers', () {
    test('should initialize with mock provider in test mode', () async {
      // Act
      final result = await ttsService.initialize();

      // Assert
      expect(result, true);
      expect(ttsService.currentProviderName, 'MockTTS');
    });

    test('should list available providers', () {
      // Act
      final providers = ttsService.availableProviders;

      // Assert
      expect(providers, contains('MockTTS'));
      expect(providers, contains('ElevenLabs'));
    });

    test('should successfully switch between providers', () async {
      // Arrange
      expect(ttsService.currentProviderName, 'MockTTS');

      // Act
      final result = await ttsService.switchProvider('ElevenLabs');

      // Assert
      expect(result, true);
      expect(ttsService.currentProviderName, 'ElevenLabs');

      // Switch back to MockTTS for the rest of the tests
      await ttsService.switchProvider('MockTTS');
    });

    test('should return false when switching to non-existent provider',
        () async {
      // Act
      final result = await ttsService.switchProvider('NonExistentProvider');

      // Assert
      expect(result, false);
      expect(
          ttsService.currentProviderName, 'MockTTS'); // Should remain the same
    });

    test('should get and update provider configuration', () async {
      // Arrange
      final initialConfig = ttsService.providerConfig;

      // Act - update configuration
      final updateResult = await ttsService.updateProviderConfig(
          {'simulateDelay': false, 'customSetting': 'test value'});

      // Assert
      expect(updateResult, true);

      // Get updated config
      final updatedConfig = ttsService.providerConfig;
      expect(updatedConfig['simulateDelay'], false);
      expect(updatedConfig['customSetting'], 'test value');

      // Restore original settings
      await ttsService.updateProviderConfig({
        'simulateDelay': initialConfig['simulateDelay'],
      });
    });

    test('should generate audio with current provider', () async {
      // Arrange
      await ttsService.initialize();

      // Act
      final audioPath =
          await ttsService.generateAudio('Test text for speech generation');

      // Assert
      expect(audioPath, isNotNull);
      expect(audioPath, contains('audio_assistant'));
      expect(audioPath, endsWith('.mp3'));
    });

    test('should handle provider switching during operation', () async {
      // Arrange
      await ttsService.initialize();
      await ttsService.generateAudio('Initial text');

      // Act - switch provider
      await ttsService.switchProvider('ElevenLabs');

      // The provider would attempt to initialize when generating audio
      // But since we're in test mode and don't have actual API keys,
      // we'll switch back to MockTTS before testing generation
      await ttsService.switchProvider('MockTTS');

      // Try to generate audio after switching
      final audioPath =
          await ttsService.generateAudio('Text after switching providers');

      // Assert
      expect(audioPath, isNotNull);
    });
  });
}
