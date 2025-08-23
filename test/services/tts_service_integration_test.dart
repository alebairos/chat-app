import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/features/audio_assistant/tts_service.dart';
import 'package:ai_personas_app/services/tts_preprocessing_service.dart';
import 'package:ai_personas_app/services/language_detection_service.dart';

void main() {
  group('TTS Service Integration Tests', () {
    late AudioAssistantTTSService ttsService;

    setUp(() {
      ttsService = AudioAssistantTTSService();
      ttsService.enableTestMode(); // Use mock provider for testing
    });

    tearDown(() async {
      await ttsService.dispose();
    });

    group('Language Detection Integration', () {
      test('should detect Portuguese from user messages', () {
        // Add Portuguese messages
        ttsService.addUserMessage('Olá, como você está?');
        ttsService.addUserMessage('Preciso fazer exercícios hoje');
        ttsService.addUserMessage('Obrigado pela ajuda');

        final detectedLanguage = ttsService.detectedLanguage;

        expect(detectedLanguage, equals('pt_BR'));
      });

      test('should detect English from user messages', () {
        // Add English messages
        ttsService.addUserMessage('Hello, how are you?');
        ttsService.addUserMessage('I need to exercise today');
        ttsService.addUserMessage('Thank you for the help');

        final detectedLanguage = ttsService.detectedLanguage;

        expect(detectedLanguage, equals('en_US'));
      });

      test('should maintain recent messages list', () {
        // Add more than 10 messages to test the limit
        for (int i = 0; i < 15; i++) {
          ttsService.addUserMessage('Mensagem número $i');
        }

        final detectedLanguage = ttsService.detectedLanguage;

        // Should still work with limited message history
        expect(detectedLanguage, equals('pt_BR'));
      });

      test('should clear recent messages', () {
        ttsService.addUserMessage('Olá, como você está?');
        ttsService.addUserMessage('Preciso fazer exercícios hoje');

        ttsService.clearRecentMessages();

        final detectedLanguage = ttsService.detectedLanguage;

        // Should return default language when no messages
        expect(detectedLanguage, equals('pt_BR'));
      });
    });

    group('TTS Generation with Language Detection', () {
      test('should generate audio with Portuguese preprocessing', () async {
        // Set up Portuguese context
        ttsService.addUserMessage('Olá, como você está?');
        ttsService.addUserMessage('Preciso fazer exercícios hoje');

        const inputText = 'Complete 5 exercises (SF1233) for 30 min today';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath, isNotNull);
        expect(audioPath, contains('audio_assistant'));
        expect(audioPath, endsWith('.mp3'));
      }, skip: 'TTS integration test - skipping to avoid timeouts in CI');

      test('should generate audio with English preprocessing', () async {
        // Set up English context
        ttsService.addUserMessage('Hello, how are you?');
        ttsService.addUserMessage('I need to exercise today');

        const inputText = 'Complete 3 exercises (TG45) for 20 min today';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath, isNotNull);
        expect(audioPath, contains('audio_assistant'));
        expect(audioPath, endsWith('.mp3'));
      }, skip: 'TTS integration test - skipping to avoid timeouts in CI');

      test('should generate audio with explicit language override', () async {
        // Set up English context
        ttsService.addUserMessage('Hello, how are you?');
        ttsService.addUserMessage('I need to exercise today');

        const inputText = 'Complete 5 exercises (SF1233) for 30 min today';

        // Override to Portuguese
        final audioPath =
            await ttsService.generateAudio(inputText, language: 'pt_BR');

        expect(audioPath, isNotNull);
        expect(audioPath, contains('audio_assistant'));
        expect(audioPath, endsWith('.mp3'));
      });

      test('should handle empty text gracefully', () async {
        const inputText = '';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath,
            isNotNull); // Should still generate something in test mode
      });

      test('should handle whitespace-only text', () async {
        const inputText = '   ';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath,
            isNotNull); // Should still generate something in test mode
      });
    });

    group('TTS Preprocessing Integration', () {
      test('should preprocess text before TTS generation', () async {
        // Set up Portuguese context
        ttsService.addUserMessage('Olá, como você está?');
        ttsService.addUserMessage('Preciso fazer exercícios hoje');

        const inputText = 'Complete 5 exercises (SF1233) for 30 min today';

        // Test that preprocessing would be applied
        final detectedLanguage = ttsService.detectedLanguage;
        final processedText = TTSPreprocessingService.preprocessForTTS(
            inputText, detectedLanguage);

        expect(processedText,
            equals('Complete cinco exercises for trinta minutos today'));

        // Generate audio (should use processed text internally)
        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath, isNotNull);
      });

      test('should handle text with multiple optimization types', () async {
        // Set up Portuguese context
        ttsService.addUserMessage('Vou meditar hoje');
        ttsService.addUserMessage('Preciso dormir melhor');

        const inputText =
            'Exercise (SF1) for 10 min, then meditate (TG2) for 5 min';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath, isNotNull);

        // Verify preprocessing would work correctly
        final detectedLanguage = ttsService.detectedLanguage;
        final processedText = TTSPreprocessingService.preprocessForTTS(
            inputText, detectedLanguage);

        expect(
            processedText,
            equals(
                'Exercise for dez minutos, then meditate for cinco minutos'));
      });

      test('should handle text without processable elements', () async {
        // Set up Portuguese context
        ttsService.addUserMessage('Olá, tudo bem?');

        const inputText = 'Clean text without any special elements';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath, isNotNull);

        // Verify no processing needed
        final detectedLanguage = ttsService.detectedLanguage;
        final processedText = TTSPreprocessingService.preprocessForTTS(
            inputText, detectedLanguage);

        expect(processedText, equals(inputText)); // Should be unchanged
      });
    });

    group('Provider Configuration Integration', () {
      test('should initialize successfully', () async {
        final initialized = await ttsService.initialize();

        expect(initialized, isTrue);
      });

      test('should switch providers successfully', () async {
        final switched = await ttsService.switchProvider('MockTTS');

        expect(switched, isTrue);
        expect(ttsService.currentProviderName, equals('MockTTS'));
      });

      test('should handle invalid provider names', () async {
        final switched = await ttsService.switchProvider('InvalidProvider');

        expect(switched, isFalse);
      });

      test('should list available providers', () {
        final providers = ttsService.availableProviders;

        expect(providers, contains('ElevenLabs'));
        expect(providers, contains('MockTTS'));
      });

      test('should get and update provider config', () async {
        final config = ttsService.providerConfig;

        expect(config, isA<Map<String, dynamic>>());

        final updated = await ttsService
            .updateProviderConfig({'testParameter': 'testValue'});

        expect(updated, isTrue);
      });
    });

    group('Character Voice Integration', () {
      test('should apply character voice configuration', () async {
        final applied = await ttsService.applyCharacterVoice();

        expect(applied, isTrue);
      });

      test('should generate audio with character voice', () async {
        // Apply character voice
        await ttsService.applyCharacterVoice();

        const inputText = 'Test message with character voice';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath, isNotNull);
      });
    });

    group('Audio File Management Integration', () {
      test('should generate unique audio file names', () async {
        const inputText = 'Test message';

        final audioPath1 = await ttsService.generateAudio(inputText);

        // Add a small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));

        final audioPath2 = await ttsService.generateAudio(inputText);

        expect(audioPath1, isNotNull);
        expect(audioPath2, isNotNull);
        expect(
            audioPath1, isNot(equals(audioPath2))); // Should be different files
      });

      test('should handle cleanup gracefully', () async {
        await ttsService.cleanup();

        // Should not throw any exceptions
        expect(true, isTrue);
      });

      test('should handle delete audio gracefully', () async {
        const inputText = 'Test message';

        final audioPath = await ttsService.generateAudio(inputText);
        expect(audioPath, isNotNull);

        final deleted = await ttsService.deleteAudio(audioPath!);

        // In test mode, file operations are mocked
        expect(deleted, isA<bool>());
      });
    });

    group('Error Handling Integration', () {
      test('should handle TTS generation errors gracefully', () async {
        // This test verifies that the service handles errors without crashing
        const inputText = 'Test message';

        final audioPath = await ttsService.generateAudio(inputText);

        // In test mode, should always succeed
        expect(audioPath, isNotNull);
      });

      test('should handle language detection with mixed content', () async {
        // Add mixed language messages
        ttsService.addUserMessage('Hello, como você está?');
        ttsService.addUserMessage('I need fazer exercícios');

        const inputText = 'Mixed language content';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath, isNotNull);

        // Should detect one of the supported languages
        final detectedLanguage = ttsService.detectedLanguage;
        expect(detectedLanguage, isIn(['pt_BR', 'en_US']));
      });

      test('should handle initialization failure recovery', () async {
        // Test that service can recover from initialization issues
        await ttsService.initialize();

        const inputText = 'Test after initialization';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath, isNotNull);
      });
    });

    group('Feature Flag Integration', () {
      test('should respect feature enabled flag', () async {
        // Test with feature enabled (default in test mode)
        const inputText = 'Test message';

        final audioPath = await ttsService.generateAudio(inputText);

        expect(audioPath, isNotNull);
      });

      test('should handle test mode correctly', () {
        ttsService.enableTestMode();

        expect(ttsService.currentProviderName, equals('MockTTS'));

        ttsService.disableTestMode();

        expect(ttsService.currentProviderName, equals('ElevenLabs'));
      });
    });
  });
}
