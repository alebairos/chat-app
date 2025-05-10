import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';
import '../../utils/path_utils.dart';

/// Service responsible for converting text to speech.
///
/// This class provides text-to-speech functionality for the assistant,
/// allowing it to generate audio responses that can be played back to the user.
class AudioAssistantTTSService {
  final Logger _logger = Logger();
  bool _isInitialized = false;
  bool _isTestMode = false;
  static const String _audioDir = 'audio_assistant';

  /// Flag to enable/disable the audio assistant feature
  static bool featureEnabled = true;

  /// Initialize the TTS service
  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        if (!_isTestMode && featureEnabled) {
          // Create the audio directory if it doesn't exist
          final dir = await getApplicationDocumentsDirectory();
          final audioDir = Directory('${dir.path}/$_audioDir');
          if (!await audioDir.exists()) {
            await audioDir.create(recursive: true);
          }

          // For now, we'll create a placeholder file
          // In a real implementation, we would initialize the TTS engine here
          final mockAudioPath = '${audioDir.path}/mock_audio.mp3';
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
  ///
  /// [text] The text to convert to speech
  /// Returns a relative path to the generated audio file
  Future<String?> generateAudio(String text) async {
    // Return null if feature is disabled (but allow in test mode)
    if (!featureEnabled && !_isTestMode) {
      _logger.debug('Audio Assistant feature is disabled');
      return null;
    }

    if (!_isInitialized) {
      if (_isTestMode) {
        throw Exception('Audio Assistant TTS Service not initialized');
      }
      final initialized = await initialize();
      if (!initialized) {
        _logger
            .error('Failed to initialize TTS service before generating audio');
        return null;
      }
    }

    try {
      if (_isTestMode) {
        return '$_audioDir/test_audio_assistant_${DateTime.now().millisecondsSinceEpoch}.mp3';
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_assistant_$timestamp.mp3';
      final relativePath = '$_audioDir/$fileName';
      final absolutePath = '${dir.path}/$relativePath';

      // In a real implementation, we would:
      // 1. Convert the text to speech using a TTS engine
      // 2. Save the audio to the file at absolutePath
      // 3. Return the relative path for storage

      // For now, we'll just create an empty file as a placeholder
      final file = File(absolutePath);
      await file.create();

      _logger.debug('Generated audio assistant audio file at: $absolutePath');
      // Return the relative path for storage
      return relativePath;
    } catch (e) {
      _logger.error('Failed to generate audio assistant audio: $e');
      return null;
    }
  }

  /// Clean up any temporary audio files
  Future<void> cleanup() async {
    if (!featureEnabled && !_isTestMode) {
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/$_audioDir');
      if (await audioDir.exists()) {
        final files = audioDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.mp3'));

        for (final file in files) {
          await file.delete();
        }
      }

      _logger.debug('Cleaned up audio assistant temporary audio files');
    } catch (e) {
      _logger.error('Failed to cleanup audio assistant audio files: $e');
    }
  }

  /// Delete a specific audio file
  ///
  /// [relativePath] The relative path to the audio file to delete
  Future<bool> deleteAudio(String relativePath) async {
    if (!featureEnabled && !_isTestMode) {
      return false;
    }

    try {
      final absolutePath = await PathUtils.relativeToAbsolute(relativePath);
      if (absolutePath == null) {
        _logger.error(
            'Failed to convert relative path to absolute path: $relativePath');
        return false;
      }

      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
        _logger.debug('Deleted audio file at: $absolutePath');
        return true;
      } else {
        _logger.debug('Audio file not found at: $absolutePath');
        return false;
      }
    } catch (e) {
      _logger.error('Failed to delete audio file: $e');
      return false;
    }
  }

  /// Enable test mode for testing
  void enableTestMode() {
    _isTestMode = true;
  }

  /// Disable test mode
  void disableTestMode() {
    _isTestMode = false;
  }
}
