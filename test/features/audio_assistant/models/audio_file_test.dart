import 'package:flutter_test/flutter_test.dart';
import '../../../../lib/features/audio_assistant/models/audio_file.dart';

void main() {
  group('AudioFile', () {
    test('should create instance with required parameters', () {
      final audioFile = AudioFile(
        path: '/path/to/audio.mp3',
        duration: const Duration(seconds: 30),
      );

      expect(audioFile, isNotNull);
      expect(audioFile.path, '/path/to/audio.mp3');
      expect(audioFile.duration, const Duration(seconds: 30));
    });

    test('should create instance with optional parameters', () {
      final audioFile = AudioFile(
        path: '/path/to/audio.mp3',
        duration: const Duration(seconds: 30),
        waveformData: [0.1, 0.2, 0.3, 0.4, 0.5],
        transcription: 'This is a test audio file',
      );

      expect(audioFile, isNotNull);
      expect(audioFile.path, '/path/to/audio.mp3');
      expect(audioFile.duration, const Duration(seconds: 30));
      expect(audioFile.waveformData, [0.1, 0.2, 0.3, 0.4, 0.5]);
      expect(audioFile.transcription, 'This is a test audio file');
    });

    test('should implement equality correctly', () {
      final audioFile1 = AudioFile(
        path: '/path/to/audio.mp3',
        duration: const Duration(seconds: 30),
      );

      final audioFile2 = AudioFile(
        path: '/path/to/audio.mp3',
        duration: const Duration(seconds: 30),
      );

      final audioFile3 = AudioFile(
        path: '/path/to/different.mp3',
        duration: const Duration(seconds: 30),
      );

      expect(audioFile1 == audioFile2, true);
      expect(audioFile1 == audioFile3, false);
      expect(audioFile1.hashCode == audioFile2.hashCode, true);
      expect(audioFile1.hashCode == audioFile3.hashCode, false);
    });

    test('should convert to and from JSON correctly', () {
      final audioFile = AudioFile(
        path: '/path/to/audio.mp3',
        duration: const Duration(seconds: 30),
        waveformData: [0.1, 0.2, 0.3, 0.4, 0.5],
        transcription: 'This is a test audio file',
      );

      final json = audioFile.toJson();
      final fromJson = AudioFile.fromJson(json);

      expect(fromJson.path, audioFile.path);
      expect(fromJson.duration, audioFile.duration);
      expect(fromJson.waveformData, audioFile.waveformData);
      expect(fromJson.transcription, audioFile.transcription);
    });

    test('should handle null optional parameters', () {
      final audioFile = AudioFile(
        path: '/path/to/audio.mp3',
        duration: const Duration(seconds: 30),
      );

      expect(audioFile.waveformData, isNull);
      expect(audioFile.transcription, isNull);

      final json = audioFile.toJson();
      final fromJson = AudioFile.fromJson(json);

      expect(fromJson.waveformData, isNull);
      expect(fromJson.transcription, isNull);
    });
  });
}
