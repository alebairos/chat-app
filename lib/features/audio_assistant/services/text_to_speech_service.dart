import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/audio_file.dart';
import 'audio_generation.dart';

/// A service that converts text to speech using the device's TTS capabilities.
///
/// This service implements the [AudioGeneration] interface and uses the
/// Flutter TTS package to generate audio files from text.
class TextToSpeechService implements AudioGeneration {
  /// The Flutter TTS instance used for text-to-speech conversion.
  final FlutterTts _flutterTts;

  /// Flag indicating whether the service has been initialized.
  bool _initialized = false;

  /// Directory where generated audio files are stored.
  late final Directory _audioDirectory;

  /// Creates a new [TextToSpeechService] instance.
  ///
  /// Optionally, a custom [FlutterTts] instance can be provided for testing.
  TextToSpeechService([FlutterTts? flutterTts])
      : _flutterTts = flutterTts ?? FlutterTts();

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> initialize() async {
    try {
      // Initialize the TTS engine
      await _flutterTts.setLanguage('en-US');
      await _flutterTts
          .setSpeechRate(0.5); // Slightly slower for better clarity
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Create directory for storing audio files
      final appDir = await getApplicationDocumentsDirectory();
      _audioDirectory = Directory(path.join(appDir.path, 'audio_assistant'));

      if (!await _audioDirectory.exists()) {
        await _audioDirectory.create(recursive: true);
      }

      _initialized = true;
      return true;
    } catch (e) {
      print('Failed to initialize TextToSpeechService: $e');
      return false;
    }
  }

  @override
  Future<AudioFile> generate(String text) async {
    if (!_initialized) {
      throw Exception('TextToSpeechService not initialized');
    }

    try {
      // Generate a unique filename based on text content and timestamp
      final filename = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final filePath = path.join(_audioDirectory.path, filename);

      // Save the speech to a file
      await _flutterTts.synthesizeToFile(text, filePath);

      // Get the duration of the generated audio
      // Since Flutter TTS doesn't provide duration, we estimate it based on word count
      // Average speaking rate is about 150 words per minute
      final wordCount = text.split(' ').length;
      final estimatedDurationMs = (wordCount / 150 * 60 * 1000).round();

      return AudioFile(
        path: filePath,
        duration: Duration(milliseconds: estimatedDurationMs),
      );
    } catch (e) {
      throw Exception('Failed to generate audio: $e');
    }
  }

  @override
  Future<void> cleanup() async {
    if (!_initialized) return;

    try {
      // Delete files older than 24 hours
      final now = DateTime.now();
      final files = await _audioDirectory.list().toList();

      for (var entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final fileAge = now.difference(stat.modified);

          if (fileAge.inHours > 24) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}
