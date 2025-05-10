import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/models/playback_state.dart';

void main() {
  group('AudioFile Model', () {
    test('should create AudioFile with required parameters', () {
      final audioFile = AudioFile(
        path: 'audio/test.mp3',
        duration: const Duration(seconds: 30),
      );

      expect(audioFile.path, 'audio/test.mp3');
      expect(audioFile.duration.inSeconds, 30);
      expect(audioFile.waveformData, null);
      expect(audioFile.transcription, null);
    });

    test('should create AudioFile with all parameters', () {
      final waveformData = [0.1, 0.5, 0.3, 0.8, 0.4];
      final audioFile = AudioFile(
        path: 'audio/test.mp3',
        duration: const Duration(seconds: 30),
        waveformData: waveformData,
        transcription: 'Test transcription',
      );

      expect(audioFile.path, 'audio/test.mp3');
      expect(audioFile.duration.inSeconds, 30);
      expect(audioFile.waveformData, waveformData);
      expect(audioFile.transcription, 'Test transcription');
    });

    test('should create a copy with updated values', () {
      final audioFile = AudioFile(
        path: 'audio/test.mp3',
        duration: const Duration(seconds: 30),
      );

      final updatedFile = audioFile.copyWith(
        path: 'audio/updated.mp3',
        duration: const Duration(seconds: 45),
        waveformData: [0.1, 0.5, 0.3],
        transcription: 'New transcription',
      );

      expect(updatedFile.path, 'audio/updated.mp3');
      expect(updatedFile.duration.inSeconds, 45);
      expect(updatedFile.waveformData, [0.1, 0.5, 0.3]);
      expect(updatedFile.transcription, 'New transcription');
    });

    test('should correctly convert to and from JSON', () {
      final waveformData = [0.1, 0.5, 0.3, 0.8, 0.4];
      final original = AudioFile(
        path: 'audio/test.mp3',
        duration: const Duration(seconds: 30),
        waveformData: waveformData,
        transcription: 'Test transcription',
      );

      final json = original.toJson();
      final fromJson = AudioFile.fromJson(json);

      expect(fromJson.path, original.path);
      expect(fromJson.duration.inSeconds, original.duration.inSeconds);
      expect(fromJson.waveformData, original.waveformData);
      expect(fromJson.transcription, original.transcription);
    });

    test('should correctly encode and decode', () {
      final original = AudioFile(
        path: 'audio/test.mp3',
        duration: const Duration(seconds: 30),
        transcription: 'Test transcription',
      );

      final encoded = original.encode();
      final decoded = AudioFile.decode(encoded);

      expect(decoded.path, original.path);
      expect(decoded.duration.inSeconds, original.duration.inSeconds);
      expect(decoded.transcription, original.transcription);
    });

    test('equality should work correctly', () {
      final file1 = AudioFile(
        path: 'audio/test.mp3',
        duration: const Duration(seconds: 30),
        waveformData: [0.1, 0.5, 0.3],
        transcription: 'Test',
      );

      final file2 = AudioFile(
        path: 'audio/test.mp3',
        duration: const Duration(seconds: 30),
        waveformData: [0.1, 0.5, 0.3],
        transcription: 'Test',
      );

      final file3 = AudioFile(
        path: 'audio/different.mp3',
        duration: const Duration(seconds: 30),
        waveformData: [0.1, 0.5, 0.3],
        transcription: 'Test',
      );

      expect(file1 == file2, true);
      expect(file1 == file3, false);
    });

    test('toString should include path, duration and data length', () {
      final file = AudioFile(
        path: 'audio/test.mp3',
        duration: const Duration(seconds: 30),
        waveformData: [0.1, 0.5, 0.3],
        transcription: 'This is a long transcription that should be truncated',
      );

      final string = file.toString();
      expect(string, contains('audio/test.mp3'));
      expect(string, contains('0:00:30.000000'));
      expect(string, contains('3 points'));
      expect(string, contains('This is a long trans'));
    });
  });

  group('PlaybackState Enum', () {
    test('should have the correct values', () {
      expect(PlaybackState.values.length, 5);
      expect(PlaybackState.values, contains(PlaybackState.initial));
      expect(PlaybackState.values, contains(PlaybackState.loading));
      expect(PlaybackState.values, contains(PlaybackState.playing));
      expect(PlaybackState.values, contains(PlaybackState.paused));
      expect(PlaybackState.values, contains(PlaybackState.stopped));
    });
  });
}
