import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:character_ai_clone/features/audio_assistant/services/eleven_labs_tts_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock HTTP client
class MockClient extends Mock implements http.Client {}

// Mock path provider
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock/path';
  }
}

void main() {
  late ElevenLabsTTSService ttsService;
  late MockClient mockClient;

  setUp(() async {
    // Set up mock environment
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock the path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Mock environment variables
    dotenv.testLoad(fileInput: '''
      ELEVEN_LABS_API_KEY=test_api_key
      ELEVEN_LABS_VOICE_ID=test_voice_id
    ''');

    // Create the service with test mode enabled
    mockClient = MockClient();
    ttsService = ElevenLabsTTSService();
    ttsService.enableTestMode();
  });

  group('ElevenLabsTTSService', () {
    test('initializes correctly in test mode', () async {
      // Act
      final result = await ttsService.initialize();

      // Assert
      expect(result, isTrue);
      expect(ttsService.isInitialized, isTrue);
    });

    test('generates audio using mock in test mode', () async {
      // Arrange
      await ttsService.initialize();

      // Act
      final audioFile = await ttsService.generate('Test text');

      // Assert
      expect(audioFile, isNotNull);
      expect(audioFile.path, contains('assets/audio'));
      expect(audioFile.duration, isNotNull);
    });

    test('uses different mock audio files based on text length', () async {
      // Arrange
      await ttsService.initialize();

      // Act - Short text
      final shortAudio = await ttsService.generate('Short text');

      // Act - Long text
      final longText =
          'This is a much longer text that should trigger the use of a different audio file. '
          'It needs to be over 100 characters long to ensure we get the longer audio sample. '
          'Adding more text to make sure we cross that threshold easily.';
      final longAudio = await ttsService.generate(longText);

      // Assert
      expect(shortAudio.path, contains('welcome_message'));
      expect(longAudio.path, contains('assistant_response'));
      expect(shortAudio.duration, const Duration(seconds: 3));
      expect(longAudio.duration, const Duration(seconds: 14));
    });

    test('cleanup does not throw in test mode', () async {
      // Arrange
      await ttsService.initialize();

      // Act & Assert
      expect(() => ttsService.cleanup(), returnsNormally);
    });
  });
}
