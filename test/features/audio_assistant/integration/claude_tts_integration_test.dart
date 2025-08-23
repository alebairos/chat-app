import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ai_personas_app/services/claude_service.dart';
import 'package:ai_personas_app/features/audio_assistant/tts_service.dart';
import 'package:ai_personas_app/config/config_loader.dart';
import 'package:ai_personas_app/models/claude_audio_response.dart';
import '../../../mocks/mock_client.dart';
import '../../../mocks/mock_config_loader.dart';

// This is an integration test that tests ClaudeService with a real TTS service
// but mocked HTTP responses
void main() {
  late ClaudeService claudeService;
  late AudioAssistantTTSService ttsService;
  late MockClient mockClient;
  late MockConfigLoader mockConfigLoader;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Load environment variables - use .env file instead of .env.test
    await dotenv.load(fileName: '.env');

    // Create mocks and real services
    mockClient = MockClient();
    ttsService = AudioAssistantTTSService();
    ttsService.enableTestMode(); // Use mock TTS provider for tests
    mockConfigLoader = MockConfigLoader();

    // Create Claude service with mocked HTTP client but real TTS service
    claudeService = ClaudeService(
      client: mockClient,
      configLoader: mockConfigLoader,
      ttsService: ttsService,
      audioEnabled: true,
    );

    // Setup mock response
    mockClient.addResponse(
      'Hello, can you tell me a short joke?',
      '{"content":[{"text":"Why don\'t scientists trust atoms? Because they make up everything!"}]}',
      statusCode: 200,
    );

    mockClient.addResponse(
      'Hello, can you tell me another joke?',
      '{"content":[{"text":"Did you hear about the mathematician who\'s afraid of negative numbers? He\'ll stop at nothing to avoid them!"}]}',
      statusCode: 200,
    );

    // Initialize the services
    await claudeService.initialize();
  });

  group('ClaudeService TTS Integration', () {
    test('sendMessageWithAudio returns valid ClaudeAudioResponse', () async {
      // Send a message that requires audio
      final response = await claudeService
          .sendMessageWithAudio('Hello, can you tell me a short joke?');

      // Verify response format
      expect(response, isA<ClaudeAudioResponse>());
      expect(response.text, isNotEmpty);
      expect(response.text, contains("Why don't scientists trust atoms"));

      // In test mode, audio might be generated but we only check it's not null
      // since we can't guarantee the file will always be created in test environment
      expect(response.audioPath, isNotNull);

      // No error should be present
      expect(response.error, isNull);
    });

    test('sendMessageWithAudio falls back to text-only when audio is disabled',
        () async {
      // Disable audio
      claudeService.audioEnabled = false;

      // Send a message
      final response = await claudeService
          .sendMessageWithAudio('Hello, can you tell me another joke?');

      // Verify response has text but no audio
      expect(response.text, isNotEmpty);
      expect(response.text,
          contains("mathematician who's afraid of negative numbers"));
      expect(response.audioPath, isNull);
    });
  });
}
