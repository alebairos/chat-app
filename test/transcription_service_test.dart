import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/transcription_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late OpenAITranscriptionService transcriptionService;

  setUp(() async {
    await dotenv.load(fileName: '.env');
    transcriptionService = OpenAITranscriptionService();
  });

  test('OpenAI service initializes with API key', () {
    expect(transcriptionService._apiKey.isNotEmpty, true,
        reason: 'OpenAI API key should be loaded from .env');
  });

  test('Transcription handles errors gracefully', () async {
    final result =
        await transcriptionService.transcribeAudio('invalid_path.m4a');
    expect(result, 'Transcription unavailable');
  });

  // Optional: Test with real audio file
  /*
  test('Transcribes audio file successfully', () async {
    const testPath = 'test/assets/test_audio.m4a';
    final result = await transcriptionService.transcribeAudio(testPath);
    expect(result, isNot('Transcription unavailable'));
    expect(result, isNot(startsWith('Transcription failed')));
  });
  */
}
