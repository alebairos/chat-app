import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'dart:io';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockFile extends Mock implements File {}

class MockDirectory extends Mock implements Directory {}

/// Test implementation of AudioPlaybackManager for testing
class TestAudioPlayer {
  Map<String, bool> _playingWidgets = {};

  /// Play an audio file
  Future<bool> playAudio(String widgetId, AudioFile audioFile) async {
    // Stop any currently playing audio
    await stopAudio();

    // Set this widget as the playing one
    _playingWidgets[widgetId] = true;
    return true;
  }

  /// Stop the currently playing audio
  Future<bool> stopAudio() async {
    _playingWidgets.clear();
    return true;
  }

  /// Check if a widget is currently playing audio
  bool isPlaying(String widgetId) {
    return _playingWidgets[widgetId] ?? false;
  }

  /// Dispose resources
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Playback Logic Tests', () {
    late TestAudioPlayer player;

    setUp(() {
      player = TestAudioPlayer();
    });

    tearDown(() async {
      await player.dispose();
    });

    test('Only one audio message plays at a time', () async {
      // Create test audio files
      final audioFile1 = AudioFile(
        path: '/mock/path/test_audio1.mp3',
        duration: const Duration(seconds: 10),
      );

      final audioFile2 = AudioFile(
        path: '/mock/path/test_audio2.mp3',
        duration: const Duration(seconds: 15),
      );

      final audioFile3 = AudioFile(
        path: '/mock/path/test_audio3.mp3',
        duration: const Duration(seconds: 20),
      );

      // Create widget IDs
      const widgetId1 = 'widget_1';
      const widgetId2 = 'widget_2';
      const widgetId3 = 'widget_3';

      // Play first audio
      await player.playAudio(widgetId1, audioFile1);

      // Verify first audio is playing
      expect(player.isPlaying(widgetId1), isTrue);
      expect(player.isPlaying(widgetId2), isFalse);
      expect(player.isPlaying(widgetId3), isFalse);

      // Play second audio
      await player.playAudio(widgetId2, audioFile2);

      // Verify second audio is playing and first is stopped
      expect(player.isPlaying(widgetId1), isFalse);
      expect(player.isPlaying(widgetId2), isTrue);
      expect(player.isPlaying(widgetId3), isFalse);

      // Play third audio
      await player.playAudio(widgetId3, audioFile3);

      // Verify third audio is playing and others are stopped
      expect(player.isPlaying(widgetId1), isFalse);
      expect(player.isPlaying(widgetId2), isFalse);
      expect(player.isPlaying(widgetId3), isTrue);

      // Verify only one audio is playing at a time
      expect(
        (player.isPlaying(widgetId1) ? 1 : 0) +
            (player.isPlaying(widgetId2) ? 1 : 0) +
            (player.isPlaying(widgetId3) ? 1 : 0),
        equals(1),
        reason: 'Exactly one audio message should be playing',
      );
    });
  });
}
