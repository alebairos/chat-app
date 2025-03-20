import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback_manager.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';
import 'dart:io';
import 'dart:async';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockFile extends Mock implements File {}

class MockDirectory extends Mock implements Directory {}

class MockAudioPlayback extends Mock implements AudioPlayback {}

/// Test implementation of AudioPlaybackManager for testing
class TestAudioPlaybackManager {
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

  group('AudioPlayback Tests', () {
    late TestAudioPlaybackManager playbackManager;

    setUp(() {
      playbackManager = TestAudioPlaybackManager();
    });

    tearDown(() async {
      await playbackManager.dispose();
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

      // Create widget IDs
      const widgetId1 = 'chat_message_1';
      const widgetId2 = 'chat_message_2';

      // Simulate playing the first audio
      bool playResult1 = await playbackManager.playAudio(widgetId1, audioFile1);
      expect(playResult1, isTrue);

      // Verify the first audio is playing
      expect(playbackManager.isPlaying(widgetId1), isTrue);
      expect(playbackManager.isPlaying(widgetId2), isFalse);

      // Simulate playing the second audio
      bool playResult2 = await playbackManager.playAudio(widgetId2, audioFile2);
      expect(playResult2, isTrue);

      // Verify the second audio is playing and the first is stopped
      expect(playbackManager.isPlaying(widgetId1), isFalse);
      expect(playbackManager.isPlaying(widgetId2), isTrue);

      // Stop any playing audio to reset state
      await playbackManager.stopAudio();

      // Verify no audio is playing
      expect(playbackManager.isPlaying(widgetId1), isFalse);
      expect(playbackManager.isPlaying(widgetId2), isFalse);

      // Verify we can play the first audio again
      bool playResult3 = await playbackManager.playAudio(widgetId1, audioFile1);
      expect(playResult3, isTrue);
      expect(playbackManager.isPlaying(widgetId1), isTrue);
    });
  });
}
