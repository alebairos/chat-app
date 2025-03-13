import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/services/tts_service_factory.dart';
import 'package:character_ai_clone/features/audio_assistant/services/text_to_speech_service.dart';
import 'package:character_ai_clone/features/audio_assistant/services/eleven_labs_tts_service.dart';

void main() {
  group('TTSServiceFactory', () {
    test('default service type is Flutter TTS', () {
      // Assert
      expect(TTSServiceFactory.activeServiceType,
          equals(TTSServiceType.flutterTTS));
    });

    test('setActiveServiceType changes the active service type', () {
      // Arrange
      TTSServiceFactory.setActiveServiceType(TTSServiceType.flutterTTS);

      // Act
      TTSServiceFactory.setActiveServiceType(TTSServiceType.elevenLabs);

      // Assert
      expect(TTSServiceFactory.activeServiceType,
          equals(TTSServiceType.elevenLabs));

      // Reset for other tests
      TTSServiceFactory.setActiveServiceType(TTSServiceType.flutterTTS);
    });

    test('createTTSService returns TextToSpeechService for flutterTTS type',
        () {
      // Arrange
      TTSServiceFactory.setActiveServiceType(TTSServiceType.flutterTTS);

      // Act
      final service = TTSServiceFactory.createTTSService();

      // Assert
      expect(service, isA<TextToSpeechService>());
    });

    test('createTTSService returns ElevenLabsTTSService for elevenLabs type',
        () {
      // Arrange
      TTSServiceFactory.setActiveServiceType(TTSServiceType.elevenLabs);

      // Act
      final service = TTSServiceFactory.createTTSService();

      // Assert
      expect(service, isA<ElevenLabsTTSService>());

      // Reset for other tests
      TTSServiceFactory.setActiveServiceType(TTSServiceType.flutterTTS);
    });
  });
}
