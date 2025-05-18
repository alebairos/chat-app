import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../lib/services/claude_service.dart';
import '../../lib/models/claude_audio_response.dart';
import '../mocks/mock_audio_assistant_tts_service.dart';
import '../mocks/mock_client.dart';
import '../mocks/mock_config_loader.dart';

void main() {
  late ClaudeService claudeService;
  late MockAudioAssistantTTSService mockTTSService;
  late MockClient mockClient;
  late MockConfigLoader mockConfigLoader;

  setUp(() async {
    // Load dotenv file for testing
    await dotenv.load(fileName: '.env');

    mockClient = MockClient();
    mockTTSService = MockAudioAssistantTTSService();
    mockConfigLoader = MockConfigLoader();

    claudeService = ClaudeService(
      client: mockClient,
      configLoader: mockConfigLoader,
      ttsService: mockTTSService,
      audioEnabled: true,
    );
  });

  group('ClaudeService with TTS', () {
    test('constructor correctly sets audioEnabled', () {
      expect(claudeService.audioEnabled, true);

      final disabledService = ClaudeService(
        client: mockClient,
        configLoader: mockConfigLoader,
        ttsService: mockTTSService,
        audioEnabled: false,
      );
      expect(disabledService.audioEnabled, false);
    });

    test('audioEnabled setter works correctly', () {
      expect(claudeService.audioEnabled, true);

      claudeService.audioEnabled = false;
      expect(claudeService.audioEnabled, false);

      claudeService.audioEnabled = true;
      expect(claudeService.audioEnabled, true);
    });

    test('sendMessageWithAudio returns text response when TTS is disabled',
        () async {
      // Setup mock client to return a valid response
      mockClient.addResponse(
        'user query',
        'Claude response',
        statusCode: 200,
      );

      // Disable audio
      claudeService.audioEnabled = false;

      // Send message
      final response = await claudeService.sendMessageWithAudio('user query');

      // Verify response contains only text
      expect(response.text, 'Claude response');
      expect(response.audioPath, isNull);
      expect(response.audioDuration, isNull);
      expect(response.error, isNull);
    });

    test('sendMessageWithAudio returns audioPath when successful', () async {
      // Setup mock client to return a valid response
      mockClient.addResponse(
        'user query',
        'Claude response',
        statusCode: 200,
      );

      // Send message
      final response = await claudeService.sendMessageWithAudio('user query');

      // Verify response contains text and audio path
      expect(response.text, 'Claude response');
      expect(response.audioPath, isNotNull);
      expect(response.audioPath, contains('audio_assistant/test_audio_'));
      expect(response.audioDuration, isNull);
      expect(response.error, isNull);

      // Verify TTS service received the text
      expect(mockTTSService.lastGeneratedText, 'Claude response');
    });

    test('sendMessageWithAudio returns error when TTS initialization fails',
        () async {
      // Configure mock to fail initialization
      mockTTSService.configureMock(shouldFailInitialize: true);

      // Setup mock client to return a valid response
      mockClient.addResponse(
        'user query',
        'Claude response',
        statusCode: 200,
      );

      // Send message
      final response = await claudeService.sendMessageWithAudio('user query');

      // Verify response contains text but no audio
      expect(response.text, 'Claude response');
      expect(response.audioPath, isNull);
      expect(response.audioDuration, isNull);
      expect(response.error, isNull);
    });

    test('sendMessageWithAudio returns error when audio generation fails',
        () async {
      // Configure mock to fail audio generation
      mockTTSService.configureMock(shouldFailGenerateAudio: true);

      // Setup mock client to return a valid response
      mockClient.addResponse(
        'user query',
        'Claude response',
        statusCode: 200,
      );

      // Send message
      final response = await claudeService.sendMessageWithAudio('user query');

      // Verify response contains text but no audio
      expect(response.text, 'Claude response');
      expect(response.audioPath, isNull);
      expect(response.audioDuration, isNull);
      expect(response.error, isNull);
    });

    test('sendMessageWithAudio handles Claude API errors gracefully', () async {
      // Configure mock to fail audio generation for this test
      mockTTSService.configureMock(shouldFailGenerateAudio: true);

      // Setup mock client to return an error
      mockClient.addResponse(
        'user query',
        '{"error":{"type":"overloaded_error","message":"Claude is busy"}}',
        statusCode: 429,
      );

      // Send message
      final response = await claudeService.sendMessageWithAudio('user query');

      // Verify error response
      expect(response.text, 'Rate limit exceeded. Please try again later.');
      expect(response.audioPath, isNull);
      expect(response.audioDuration, isNull);
      expect(response.error, isNull);
    });
  });
}
