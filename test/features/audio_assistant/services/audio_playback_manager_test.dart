import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback_manager.dart';

void main() {
  group('AudioPlaybackManager', () {
    late AudioPlaybackManager manager;

    setUp(() {
      manager = AudioPlaybackManager();
    });

    test('should only allow one audio to play at a time', () {
      // Setup
      bool audio1Stopped = false;
      bool audio2Stopped = false;

      // Register two audio players
      manager.registerAudioPlayer('audio1', () {
        audio1Stopped = true;
      });

      manager.registerAudioPlayer('audio2', () {
        audio2Stopped = true;
      });

      // Start playing audio1
      manager.startPlayback('audio1');

      // Verify audio1 is playing
      expect(manager.isPlaying('audio1'), true);
      expect(audio1Stopped, false);

      // Start playing audio2
      manager.startPlayback('audio2');

      // Verify audio1 was stopped and audio2 is now playing
      expect(audio1Stopped, true);
      expect(manager.isPlaying('audio1'), false);
      expect(manager.isPlaying('audio2'), true);
    });

    test('should unregister audio players correctly', () {
      // Setup
      bool audioCalled = false;

      // Register an audio player
      manager.registerAudioPlayer('audio', () {
        audioCalled = true;
      });

      // Unregister the audio player
      manager.unregisterAudioPlayer('audio');

      // Start playing another audio
      manager.startPlayback('another_audio');

      // Verify the callback wasn't called
      expect(audioCalled, false);
    });
  });
}
