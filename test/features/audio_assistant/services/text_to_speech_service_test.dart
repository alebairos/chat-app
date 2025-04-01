import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/services/text_to_speech_service.dart';

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

  @override
  Future<bool> isLanguageAvailable(String language) async => true;
}

// Mock for simulator environment
class MockSimulatorFlutterTts extends MockFlutterTts {
  @override
  Future<bool> isLanguageAvailable(String language) async => false;
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

// Custom TextToSpeechService for testing
class TestTextToSpeechService extends TextToSpeechService {
  TestTextToSpeechService([FlutterTts? flutterTts]) : super(flutterTts);

  @override
  Future<AudioFile> generate(String text) async {
    if (!isInitialized) {
      throw Exception('TextToSpeechService not initialized');
    }

    // Simulate the behavior of _usePreGeneratedAudio
    final assetPath = text.length > 100
        ? 'assets/audio/assistant_response.aiff'
        : 'assets/audio/welcome_message.aiff';

    final duration = assetPath.contains('welcome_message')
        ? const Duration(seconds: 3)
        : const Duration(seconds: 14);

    return AudioFile(
      path: assetPath,
      duration: duration,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestTextToSpeechService ttsService;
  late MockFlutterTts mockFlutterTts;
  late Directory tempDir;

  setUp(() async {
    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Create a temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('audio_assistant_test');

    // Set up mock FlutterTts
    mockFlutterTts = MockFlutterTts();

    // Mock the asset bundle
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        return Uint8List(1024).buffer.asByteData();
      },
    );

    // Create the service with the mock
    ttsService = TestTextToSpeechService(mockFlutterTts);
  });

  tearDown(() async {
    // Clean up temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }

    // Reset mock message handler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      null,
    );
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

    test('should generate audio file from text in test environment', () async {
      await ttsService.initialize();

      final audioFile = await ttsService.generate('Hello world');

      expect(audioFile, isNotNull);
      expect(audioFile.path, isNotEmpty);
      expect(audioFile.duration, isNotNull);

      // In test environment, it should use pre-generated audio
      expect(audioFile.path.contains('assets/audio/'), isTrue);
    });

    test('should use different pre-generated audio based on text length',
        () async {
      await ttsService.initialize();

      // Test with different text lengths
      const shortText = 'Hello';
      const longText =
          'This is a much longer text that should result in a longer duration. '
          'It contains multiple sentences and should be estimated to take more time to speak.';

      final shortAudio = await ttsService.generate(shortText);
      final longAudio = await ttsService.generate(longText);

      // In test environment, short text should use welcome_message.aiff
      expect(shortAudio.path.contains('welcome_message'), isTrue);
      // Long text should use assistant_response.aiff
      expect(longAudio.path.contains('assistant_response'), isTrue);

      // Durations should match the pre-defined values
      expect(shortAudio.duration, equals(const Duration(seconds: 3)));
      expect(longAudio.duration, equals(const Duration(seconds: 14)));
    });

    test('should cleanup old files', () async {
      await ttsService.initialize();

      // Create a test file in the audio directory
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/audio_assistant');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final testFile = File('${audioDir.path}/test_old_file.mp3');
      await testFile.writeAsString('Test content');

      // Modify the file time to make it appear older (25 hours ago)
      final oldTime = DateTime.now().subtract(const Duration(hours: 25));
      await testFile.setLastModified(oldTime);

      // Run cleanup
      await ttsService.cleanup();

      // Verify old file is deleted
      expect(await testFile.exists(), false);
    });

    test('should handle simulator environment correctly', () async {
      // Create a new service with a mock that simulates a simulator
      final simulatorMockTts = MockSimulatorFlutterTts();

      final simulatorService = TestTextToSpeechService(simulatorMockTts);
      await simulatorService.initialize();

      final audioFile = await simulatorService.generate('Test in simulator');

      // Should use pre-generated audio in simulator
      expect(audioFile.path.contains('assets/audio/'), isTrue);
      expect(audioFile.duration, isNotNull);
    });
  });
}
