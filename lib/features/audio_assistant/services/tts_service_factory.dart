import 'package:flutter/foundation.dart';
import 'audio_generation.dart';
import 'text_to_speech_service.dart';
import 'eleven_labs_tts_service.dart';

/// Enum representing the available TTS service types
enum TTSServiceType {
  /// Local TTS using Flutter TTS
  flutterTTS,

  /// Cloud-based TTS using ElevenLabs
  elevenLabs,
}

/// Factory class for creating TTS service instances
class TTSServiceFactory {
  /// The currently active TTS service type
  static TTSServiceType _activeServiceType = TTSServiceType.flutterTTS;

  /// Get the currently active TTS service type
  static TTSServiceType get activeServiceType => _activeServiceType;

  /// Set the active TTS service type
  static void setActiveServiceType(TTSServiceType serviceType) {
    _activeServiceType = serviceType;
    debugPrint('TTS Service type set to: $_activeServiceType');
  }

  /// Create and return an instance of the currently active TTS service
  static AudioGeneration createTTSService() {
    switch (_activeServiceType) {
      case TTSServiceType.flutterTTS:
        debugPrint('Creating Flutter TTS service');
        return TextToSpeechService();
      case TTSServiceType.elevenLabs:
        debugPrint('Creating ElevenLabs TTS service');
        return ElevenLabsTTSService();
    }
  }
}
