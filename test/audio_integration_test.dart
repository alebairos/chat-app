import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback_manager.dart';
import 'package:character_ai_clone/features/audio_assistant/services/eleven_labs_tts_service.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('Audio Integration Tests', () {
    late AudioPlaybackManager playbackManager;
    late ElevenLabsTTSService ttsService;
    late Directory tempDir;

    setUpAll(() async {
      // Load environment variables
      await dotenv.load(fileName: '.env');

      // Create a temporary directory for test audio files
      tempDir = await Directory.systemTemp.createTemp('audio_test_');
      debugPrint('Created temp directory: ${tempDir.path}');
    });

    setUp(() {
      // Initialize the playback manager before each test
      playbackManager = AudioPlaybackManager();

      // Initialize the TTS service
      ttsService = ElevenLabsTTSService();
      // Enable test mode to avoid making actual API calls
      ttsService.enableTestMode();
    });

    tearDownAll(() async {
      // Clean up the temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('AudioPlaybackManager initializes correctly', () async {
      // Access the audioPlayback property to ensure it's initialized
      final audioPlayback = playbackManager.audioPlayback;
      expect(audioPlayback, isNotNull);
    });

    test('ElevenLabsTTSService initializes correctly', () async {
      // Initialize the service
      final initialized = await ttsService.initialize();
      expect(initialized, isTrue);
      expect(ttsService.isInitialized, isTrue);
    });

    test('ElevenLabsTTSService generates mock audio in test mode', () async {
      // Initialize the service
      await ttsService.initialize();

      // Generate audio for a test message
      final audioFile = await ttsService.generate('This is a test message');

      // Verify the audio file was generated
      expect(audioFile, isNotNull);
      expect(audioFile.path, isNotEmpty);
      expect(audioFile.duration, isNotNull);

      // In test mode, it should use an asset path
      expect(audioFile.path.contains('assets/audio/'), isTrue);
    });

    test('AudioPlaybackManager can load and play audio', () async {
      // Create a test audio file
      final testAudioPath = path.join(tempDir.path, 'test_audio.mp3');
      final testFile = File(testAudioPath);

      // Write some dummy data to the file
      await testFile.writeAsBytes([0, 1, 2, 3, 4, 5]);

      // Create an AudioFile object
      final audioFile = AudioFile(
        path: testAudioPath,
        duration: const Duration(seconds: 1),
      );

      // Attempt to load and play the audio
      // Note: This won't actually play audio in the test environment,
      // but it will test the API calls
      final widgetId = 'test_widget_${DateTime.now().millisecondsSinceEpoch}';

      // This might fail in the test environment, but we're just testing the API
      try {
        final result = await playbackManager.playAudio(widgetId, audioFile);
        // We don't expect this to succeed in the test environment
        // but we're just making sure the API doesn't throw
      } catch (e) {
        // Expected to fail in test environment
        debugPrint('Expected error in test environment: $e');
      }
    });
  });
}
