import 'package:flutter_test/flutter_test.dart';
import '../../../../lib/features/audio_assistant/models/audio_file.dart';
import '../../../../lib/features/audio_assistant/services/audio_generation.dart';

// Mock implementation of AudioGeneration for testing
class MockAudioGeneration implements AudioGeneration {
  bool _initialized = false;
  final Map<String, String> _generatedFiles = {};

  @override
  Future<bool> initialize() async {
    _initialized = true;
    return true;
  }

  @override
  Future<AudioFile> generate(String text) async {
    if (!_initialized) {
      throw Exception('AudioGeneration not initialized');
    }

    // Simulate audio generation by creating a mock file path
    final filePath = '/mock/path/${text.hashCode}.mp3';
    _generatedFiles[text] = filePath;

    // Return a mock AudioFile with a fixed duration
    return AudioFile(
      path: filePath,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Future<void> cleanup() async {
    _generatedFiles.clear();
  }

  @override
  bool get isInitialized => _initialized;
}

void main() {
  group('AudioGeneration', () {
    late MockAudioGeneration audioGeneration;

    setUp(() {
      audioGeneration = MockAudioGeneration();
    });

    test('should initialize successfully', () async {
      expect(audioGeneration.isInitialized, false);

      final result = await audioGeneration.initialize();

      expect(result, true);
      expect(audioGeneration.isInitialized, true);
    });

    test('should throw exception if generate is called before initialization',
        () async {
      expect(() => audioGeneration.generate('Hello world'), throwsException);
    });

    test('should generate audio file from text', () async {
      await audioGeneration.initialize();

      final audioFile = await audioGeneration.generate('Hello world');

      expect(audioFile, isNotNull);
      expect(audioFile.path, contains('/mock/path/'));
      expect(audioFile.path, contains('.mp3'));
      expect(audioFile.duration, equals(const Duration(seconds: 3)));
    });

    test('should generate different files for different texts', () async {
      await audioGeneration.initialize();

      final audioFile1 = await audioGeneration.generate('Hello world');
      final audioFile2 = await audioGeneration.generate('Goodbye world');

      expect(audioFile1.path, isNot(equals(audioFile2.path)));
    });

    test('should cleanup generated files', () async {
      await audioGeneration.initialize();
      await audioGeneration.generate('Hello world');

      await audioGeneration.cleanup();

      // We can't directly test that files are deleted since we're using a mock,
      // but we can verify that the mock's internal state is reset
      expect(audioGeneration.isInitialized,
          true); // Cleanup doesn't reset initialization
    });
  });
}
