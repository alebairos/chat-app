import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';

/// Service responsible for converting text to speech
class AudioAssistantTTSService {
  final Logger _logger = Logger();
  bool _isInitialized = false;
  bool _isTestMode = false;

  /// Initialize the TTS service
  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        if (!_isTestMode) {
          // For now, we'll just create a mock audio file
          final dir = await getApplicationDocumentsDirectory();
          final mockAudioPath = '${dir.path}/mock_audio.mp3';

          // Create an empty file for testing
          final file = File(mockAudioPath);
          if (!await file.exists()) {
            await file.create();
          }
        }

        _isInitialized = true;
        _logger.debug('Audio Assistant TTS Service initialized successfully');
        return true;
      } catch (e) {
        _logger.error('Failed to initialize Audio Assistant TTS Service: $e');
        return false;
      }
    }
    return true;
  }

  /// Convert text to speech and return the path to the audio file
  Future<String> generateAudio(String text) async {
    if (!_isInitialized) {
      if (_isTestMode) {
        throw Exception('Audio Assistant TTS Service not initialized');
      }
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Audio Assistant TTS Service not initialized');
      }
    }

    try {
      if (_isTestMode) {
        return 'test_audio_assistant_${DateTime.now().millisecondsSinceEpoch}.mp3';
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioPath = '${dir.path}/audio_assistant_$timestamp.mp3';

      // For now, we'll just create an empty file
      final file = File(audioPath);
      await file.create();

      _logger.debug('Generated audio assistant audio file at: $audioPath');
      return audioPath;
    } catch (e) {
      _logger.error('Failed to generate audio assistant audio: $e');
      throw Exception('Failed to generate audio assistant audio: $e');
    }
  }

  /// Clean up any temporary audio files
  Future<void> cleanup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync().where((file) =>
          file.path.endsWith('.mp3') && file.path.contains('audio_assistant_'));

      for (final file in files) {
        await file.delete();
      }

      _logger.debug('Cleaned up audio assistant temporary audio files');
    } catch (e) {
      _logger.error('Failed to cleanup audio assistant audio files: $e');
    }
  }

  /// Enable test mode for testing
  void enableTestMode() {
    _isTestMode = true;
  }
}
