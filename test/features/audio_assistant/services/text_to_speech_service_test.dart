import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../../../../lib/features/audio_assistant/models/audio_file.dart';
import '../../../../lib/features/audio_assistant/services/text_to_speech_service.dart';

// Mock for FlutterTts
class MockFlutterTts extends Mock implements FlutterTts {
  @override
  Future<dynamic> setLanguage(String language) async => true;

  @override
  Future<dynamic> setSpeechRate(double rate) async => true;

  @override
  Future<dynamic> setVolume(double volume) async => true;

  @override
  Future<dynamic> setPitch(double pitch) async => true;

  @override
  Future<dynamic> synthesizeToFile(String text, String fileName,
      [bool? cache]) async {
    // Create an empty file to simulate the TTS output
    final file = File(fileName);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString('Mock TTS content');
    return true;
  }
}

// Mock for PathProvider
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  late TextToSpeechService ttsService;
  late MockFlutterTts mockFlutterTts;
  late Directory tempDir;

  setUp(() async {
    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Create a temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('audio_assistant_test');

    // Set up mock FlutterTts
    mockFlutterTts = MockFlutterTts();

    // Create the service with the mock
    ttsService = TextToSpeechService(mockFlutterTts);
  });

  tearDown(() async {
    // Clean up temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TextToSpeechService', () {
    test('should initialize successfully', () async {
      final result = await ttsService.initialize();

      expect(result, true);
      expect(ttsService.isInitialized, true);
    });

    test('should throw exception if generate is called before initialization',
        () async {
      expect(() => ttsService.generate('Hello world'), throwsException);
    });

    test('should generate audio file from text', () async {
      await ttsService.initialize();

      final audioFile = await ttsService.generate('Hello world');

      expect(audioFile, isNotNull);
      expect(audioFile.path, contains('.mp3'));
      expect(audioFile.duration, isNotNull);

      // Verify the file exists
      final file = File(audioFile.path);
      expect(await file.exists(), true);
    });

    test('should estimate duration based on word count', () async {
      await ttsService.initialize();

      // Test with different text lengths
      final shortText = 'Hello';
      final mediumText =
          'Hello world, this is a test of the text to speech service';
      final longText =
          'This is a much longer text that should result in a longer duration. '
          'It contains multiple sentences and should be estimated to take more time to speak. '
          'The duration should be proportional to the number of words in the text.';

      final shortAudio = await ttsService.generate(shortText);
      final mediumAudio = await ttsService.generate(mediumText);
      final longAudio = await ttsService.generate(longText);

      // Verify durations are proportional to text length
      expect(shortAudio.duration.inMilliseconds,
          lessThan(mediumAudio.duration.inMilliseconds));
      expect(mediumAudio.duration.inMilliseconds,
          lessThan(longAudio.duration.inMilliseconds));
    });

    test('should cleanup old files', () async {
      await ttsService.initialize();

      // Generate a file
      final audioFile = await ttsService.generate('Test cleanup');
      final file = File(audioFile.path);

      // Verify file exists
      expect(await file.exists(), true);

      // Modify the file time to make it appear older (25 hours ago)
      final oldTime = DateTime.now().subtract(const Duration(hours: 25));
      await file.setLastModified(oldTime);

      // Run cleanup
      await ttsService.cleanup();

      // Verify old file is deleted
      expect(await file.exists(), false);
    });
  });
}
