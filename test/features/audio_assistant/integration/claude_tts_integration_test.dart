import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../lib/services/claude_service.dart';
import '../../../../lib/features/audio_assistant/tts_service.dart';
import '../../../../lib/config/config_loader.dart';
import '../../../../lib/models/claude_audio_response.dart';

// This is an integration test that tests ClaudeService with a real TTS service
void main() {
  late ClaudeService claudeService;
  late AudioAssistantTTSService ttsService;
  late ConfigLoader configLoader;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Load environment variables - use .env file instead of .env.test
    await dotenv.load(fileName: '.env');

    // Create real services
    ttsService = AudioAssistantTTSService();
    ttsService.enableTestMode(); // Use mock TTS provider for tests

    configLoader = ConfigLoader();

    // Create ClaudeService with real TTS service
    claudeService = ClaudeService(
      configLoader: configLoader,
      ttsService: ttsService,
      audioEnabled: true,
    );

    // Initialize the services
    await claudeService.initialize();
  });

  group('ClaudeService TTS Integration', () {
    test('sendMessageWithAudio returns valid ClaudeAudioResponse', () async {
      // Skip this test if API key is not set
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        markTestSkipped('Skipping test because ANTHROPIC_API_KEY is not set.');
        return;
      }

      // Send a message that requires audio
      final response = await claudeService
          .sendMessageWithAudio('Hello, can you tell me a short joke?');

      // Verify response format
      expect(response, isA<ClaudeAudioResponse>());
      expect(response.text, isNotEmpty);

      // Since we're in test mode, audio should be generated
      expect(response.audioPath, isNotEmpty);
      expect(response.audioPath, contains('audio_assistant/'));

      // No error should be present
      expect(response.error, isNull);
    });

    test('sendMessageWithAudio falls back to text-only when audio is disabled',
        () async {
      // Skip this test if API key is not set
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        markTestSkipped('Skipping test because ANTHROPIC_API_KEY is not set.');
        return;
      }

      // Disable audio
      claudeService.audioEnabled = false;

      // Send a message
      final response = await claudeService
          .sendMessageWithAudio('Hello, can you tell me another joke?');

      // Verify response has text but no audio
      expect(response.text, isNotEmpty);
      expect(response.audioPath, isNull);
    });
  });
}
