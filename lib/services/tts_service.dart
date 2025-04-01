import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// Service responsible for converting text to speech
class TTSService {
  final Logger _logger = Logger();
  bool isInitialized = false;

  /// Initialize the TTS service
  Future<bool> initialize() async {
    if (!isInitialized) {
      try {
        // For now, we'll just create a mock audio file
        final dir = await getApplicationDocumentsDirectory();
        final mockAudioPath = '${dir.path}/mock_audio.mp3';

        // Create an empty file for testing
        final file = File(mockAudioPath);
        if (!await file.exists()) {
          await file.create();
        }

        isInitialized = true;
        _logger.debug('TTS Service initialized successfully');
        return true;
      } catch (e) {
        _logger.error('Failed to initialize TTS Service: $e');
        return false;
      }
    }
    return true;
  }

  /// Map to store language code to voice ID mappings
  final Map<String, String> _languageToVoiceId = {
    'en': 'EXAVITQu4vr4xnSDxMaL', // English voice (Adam)
    'pt': 'IKne3meq5aSn9XLyUdCD', // Portuguese voice (Sergio)
    'pt-BR': 'IKne3meq5aSn9XLyUdCD', // Portuguese (Brazil) voice (Sergio)
    'es': 'ErXwobaYiN019PkySvjV', // Spanish voice (Antoni)
    // Add more languages as needed
  };

  /// Detect language of text (simplified version)
  String _detectLanguage(String text) {
    // This is a simplified approach - in production, use a proper language detection library
    // or rely on the language setting of the app

    // Check for common Portuguese words/patterns
    final portuguesePatterns = [
      'não',
      'sim',
      'obrigado',
      'como',
      'está',
      'bom dia',
      'boa tarde',
      'boa noite',
      'por favor',
      'muito',
      'bem',
      'que',
      'para',
      'com'
    ];

    final lowerText = text.toLowerCase();
    int portugueseMatches = 0;

    for (final pattern in portuguesePatterns) {
      if (lowerText.contains(pattern)) {
        portugueseMatches++;
      }
    }

    // If multiple Portuguese patterns are found, assume Portuguese
    if (portugueseMatches >= 2) {
      return 'pt-BR';
    }

    // Default to English if no clear language is detected
    return 'en';
  }

  /// Convert text to speech and return the path to the audio file
  Future<String> generateAudio(String text) async {
    if (!isInitialized) {
      throw Exception('TTS Service not initialized');
    }

    // Detect language and get appropriate voice ID
    final language = _detectLanguage(text);
    final voiceId = _languageToVoiceId[language] ?? _languageToVoiceId['en']!;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final voicePrefix = language == 'pt-BR' ? 'pt_voice' : 'en_voice';
      final audioPath = '${dir.path}/tts_${voicePrefix}_$timestamp.mp3';

      // For now, we'll just create an empty file
      final file = File(audioPath);
      await file.create();

      _logger.debug('Generated audio file at: $audioPath');
      return audioPath;
    } catch (e) {
      _logger.error('Failed to generate audio: $e');
      throw Exception('Failed to generate audio: $e');
    }
  }

  /// Clean up any temporary audio files
  Future<void> cleanup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync().where(
          (file) => file.path.endsWith('.mp3') && file.path.contains('tts_'));

      for (final file in files) {
        await file.delete();
      }

      _logger.debug('Cleaned up temporary audio files');
    } catch (e) {
      _logger.error('Failed to cleanup audio files: $e');
    }
  }
}
