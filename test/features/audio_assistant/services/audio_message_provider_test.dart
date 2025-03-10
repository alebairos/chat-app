import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_generation.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_message_provider.dart';

class MockAudioGeneration extends Mock implements AudioGeneration {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> initialize() async {
    _initialized = true;
    return true;
  }

  @override
  Future<AudioFile> generate(String text) async {
    return AudioFile(
      path: 'test_path.mp3',
      duration: const Duration(seconds: 10),
    );
  }

  @override
  Future<void> cleanup() async {
    _initialized = false;
  }
}

class MockAudioPlayback extends Mock implements AudioPlayback {
  bool _initialized = false;
  AudioFile? _loadedFile;

  @override
  Future<bool> initialize() async {
    _initialized = true;
    return true;
  }

  @override
  Future<bool> load(AudioFile file) async {
    _loadedFile = file;
    return true;
  }

  @override
  Future<bool> play() async {
    return true;
  }

  @override
  Future<bool> pause() async {
    return true;
  }

  @override
  Future<bool> stop() async {
    return true;
  }

  @override
  Future<void> dispose() async {
    // Clean up resources
  }
}

void main() {
  group('AudioMessageProvider', () {
    late MockAudioGeneration mockAudioGeneration;
    late MockAudioPlayback mockAudioPlayback;
    late AudioMessageProvider provider;

    setUp(() {
      mockAudioGeneration = MockAudioGeneration();
      mockAudioPlayback = MockAudioPlayback();
      provider = AudioMessageProvider(
        audioGeneration: mockAudioGeneration,
        audioPlayback: mockAudioPlayback,
      );
    });

    test('initializes audio generation and playback services', () async {
      final result = await provider.initialize();

      expect(result, isTrue);
      expect(mockAudioGeneration.isInitialized, isTrue);
    });

    test('generates audio for message', () async {
      await provider.initialize();

      final messageId = 'test_message_id';
      final text = 'Test message';

      final audioFile = await provider.generateAudioForMessage(messageId, text);

      expect(audioFile, isNotNull);
      expect(audioFile!.path, equals('test_path.mp3'));
      expect(audioFile.duration, equals(const Duration(seconds: 10)));
    });

    test('gets audio for message', () async {
      await provider.initialize();

      final messageId = 'test_message_id';
      final text = 'Test message';

      await provider.generateAudioForMessage(messageId, text);
      final audioFile = provider.getAudioForMessage(messageId);

      expect(audioFile, isNotNull);
      expect(audioFile!.path, equals('test_path.mp3'));
    });

    test('plays audio for message', () async {
      await provider.initialize();

      final messageId = 'test_message_id';
      final text = 'Test message';

      await provider.generateAudioForMessage(messageId, text);
      final result = await provider.playAudioForMessage(messageId);

      expect(result, isTrue);
    });

    test('returns false when playing non-existent message', () async {
      await provider.initialize();

      final result = await provider.playAudioForMessage('non_existent_id');

      expect(result, isFalse);
    });

    test('loads audio from asset', () async {
      await provider.initialize();

      final messageId = 'test_message_id';
      final assetPath = 'assets/audio/test.mp3';
      final duration = const Duration(seconds: 30);

      final audioFile = await provider.loadAudioFromAsset(
        messageId,
        assetPath,
        duration,
      );

      expect(audioFile, isNotNull);
      expect(audioFile!.path, equals(assetPath));
      expect(audioFile.duration, equals(duration));

      // Verify it's stored in the provider
      final storedFile = provider.getAudioForMessage(messageId);
      expect(storedFile, isNotNull);
      expect(storedFile!.path, equals(assetPath));
    });

    test('disposes resources', () async {
      await provider.initialize();
      await provider.dispose();

      // Verify audio generation is cleaned up
      expect(mockAudioGeneration.isInitialized, isFalse);
    });
  });
}
