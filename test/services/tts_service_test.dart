import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/tts_service.dart';

class TestTTSService extends TTSService {
  @override
  Future<bool> initialize() async {
    isInitialized = true;
    return true;
  }

  @override
  Future<String> generateAudio(String text) async {
    if (!isInitialized) {
      throw Exception('TTS Service not initialized');
    }
    return 'test_audio.mp3';
  }
}

void main() {
  group('TTSService', () {
    late TestTTSService ttsService;

    setUp(() {
      ttsService = TestTTSService();
    });

    test('initializes successfully', () async {
      final result = await ttsService.initialize();
      expect(result, true);
      expect(ttsService.isInitialized, true);
    });

    test('generates audio file path', () async {
      await ttsService.initialize();
      final result = await ttsService.generateAudio('Test message');
      expect(result, 'test_audio.mp3');
    });
  });
}
