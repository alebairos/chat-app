import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_ai_clone/features/audio_assistant/tts_service.dart';

class MockAudioAssistantTTSService extends Mock
    implements AudioAssistantTTSService {
  bool _initialized = false;
  bool _shouldFailInitialize = false;
  bool _shouldFailGenerateAudio = false;
  String? lastGeneratedText;
  String? lastGeneratedFilePath;

  // Setup method to configure the mock
  @override
  void setup() {
    registerFallbackValue('');
  }

  @override
  Future<bool> initialize() async {
    if (_shouldFailInitialize) {
      return false;
    }
    _initialized = true;
    return true;
  }

  @override
  Future<String?> generateAudio(String text, {String? language}) async {
    if (!_initialized) {
      throw Exception('TTS service not initialized');
    }

    if (_shouldFailGenerateAudio) {
      return null;
    }

    lastGeneratedText = text;
    lastGeneratedFilePath =
        'audio_assistant/test_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
    return lastGeneratedFilePath;
  }

  void configureMock({
    bool shouldFailInitialize = false,
    bool shouldFailGenerateAudio = false,
  }) {
    _shouldFailInitialize = shouldFailInitialize;
    _shouldFailGenerateAudio = shouldFailGenerateAudio;
  }
}
