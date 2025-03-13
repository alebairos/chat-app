import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/audio_file.dart';
import 'audio_generation.dart';
import 'audio_playback.dart';
import 'tts_service_factory.dart';

/// A provider that manages audio messages for the assistant.
///
/// This class coordinates between the text-to-speech service and audio playback,
/// handling the conversion of text responses to audio and managing the audio files.
class AudioMessageProvider {
  /// The service used to generate audio from text.
  final AudioGeneration _audioGeneration;

  /// The service used to play audio files.
  final AudioPlayback _audioPlayback;

  /// Whether the provider has been initialized.
  bool _initialized = false;

  /// A map of message IDs to their corresponding audio files.
  final Map<String, AudioFile> _audioFiles = {};

  /// Creates a new [AudioMessageProvider] instance.
  ///
  /// [audioGeneration] is the service used to generate audio from text.
  /// If not provided, it will be created using the TTSServiceFactory.
  /// [audioPlayback] is the service used to play audio files.
  AudioMessageProvider({
    AudioGeneration? audioGeneration,
    required AudioPlayback audioPlayback,
  })  : _audioGeneration =
            audioGeneration ?? TTSServiceFactory.createTTSService(),
        _audioPlayback = audioPlayback;

  /// Whether the provider has been initialized.
  bool get isInitialized => _initialized;

  /// Get the current TTS service type
  TTSServiceType get ttsServiceType => TTSServiceFactory.activeServiceType;

  /// Get the current audio generation service
  AudioGeneration getAudioGenerationService() {
    return _audioGeneration;
  }

  /// Change the TTS service type
  ///
  /// This will reinitialize the provider with the new service type.
  /// Returns true if the change was successful, false otherwise.
  Future<bool> changeTTSServiceType(TTSServiceType serviceType) async {
    if (serviceType == TTSServiceFactory.activeServiceType) {
      return true; // Already using this service type
    }

    // Set the new service type
    TTSServiceFactory.setActiveServiceType(serviceType);

    // Reset initialization flag
    _initialized = false;

    // Reinitialize with the new service
    return initialize();
  }

  /// Initializes the provider.
  ///
  /// This method initializes the audio generation and playback services.
  /// Returns true if initialization was successful, false otherwise.
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      final generationInitialized = await _audioGeneration.initialize();
      final playbackInitialized = await _audioPlayback.initialize();

      _initialized = generationInitialized && playbackInitialized;
      return _initialized;
    } catch (e) {
      debugPrint('Failed to initialize AudioMessageProvider: $e');
      return false;
    }
  }

  /// Generates an audio file for the given text and associates it with the message ID.
  ///
  /// [messageId] is a unique identifier for the message.
  /// [text] is the text to convert to audio.
  /// Returns the generated audio file, or null if generation failed.
  Future<AudioFile?> generateAudioForMessage(
      String messageId, String text) async {
    if (!_initialized) {
      debugPrint('AudioMessageProvider not initialized');
      throw Exception('AudioMessageProvider not initialized');
    }

    // Generate a unique ID for this request to track it through logs
    final requestId =
        DateTime.now().millisecondsSinceEpoch.toString().substring(6);

    debugPrint(
        '[$requestId] Generating audio for message $messageId with text: "${text.substring(0, min(50, text.length))}..."');

    try {
      final audioFile = await _audioGeneration.generate(text);
      debugPrint(
          '[$requestId] Audio generation successful for message $messageId: ${audioFile.path}, duration: ${audioFile.duration}');

      // Store the audio file with the message ID
      _audioFiles[messageId] = audioFile;

      // Log the current state of the audio files map
      debugPrint(
          '[$requestId] Current audio files map: ${_audioFiles.keys.join(', ')}');

      return audioFile;
    } catch (e) {
      debugPrint(
          '[$requestId] Failed to generate audio for message $messageId: $e');
      return null;
    }
  }

  /// Gets the audio file associated with the given message ID.
  ///
  /// [messageId] is the unique identifier for the message.
  /// Returns the audio file, or null if no audio file is associated with the message ID.
  AudioFile? getAudioForMessage(String messageId) {
    final audioFile = _audioFiles[messageId];
    debugPrint(
        'Getting audio for message $messageId: ${audioFile != null ? "Found - ${audioFile.path}" : "Not found"}');
    return audioFile;
  }

  /// Plays the audio file associated with the given message ID.
  ///
  /// [messageId] is the unique identifier for the message.
  /// Returns true if playback started successfully, false otherwise.
  Future<bool> playAudioForMessage(String messageId) async {
    if (!_initialized) {
      debugPrint('AudioMessageProvider not initialized');
      throw Exception('AudioMessageProvider not initialized');
    }

    final audioFile = _audioFiles[messageId];
    if (audioFile == null) {
      debugPrint('No audio file found for message $messageId');
      return false;
    }

    // Verify file exists
    final file = File(audioFile.path);
    final exists = await file.exists();
    debugPrint(
        'File exists check for playback: $exists for path: ${audioFile.path}');

    if (!exists) {
      debugPrint('Audio file does not exist for playback: ${audioFile.path}');
      return false;
    }

    try {
      debugPrint('Playing audio for message $messageId: ${audioFile.path}');
      await _audioPlayback.load(audioFile);
      await _audioPlayback.play();
      return true;
    } catch (e) {
      debugPrint('Failed to play audio for message $messageId: $e');
      return false;
    }
  }

  /// Pauses the currently playing audio.
  ///
  /// Returns true if the audio was paused successfully, false otherwise.
  Future<bool> pauseAudio() async {
    if (!_initialized) {
      throw Exception('AudioMessageProvider not initialized');
    }

    try {
      await _audioPlayback.pause();
      return true;
    } catch (e) {
      debugPrint('Failed to pause audio: $e');
      return false;
    }
  }

  /// Stops the currently playing audio.
  ///
  /// Returns true if the audio was stopped successfully, false otherwise.
  Future<bool> stopAudio() async {
    if (!_initialized) {
      throw Exception('AudioMessageProvider not initialized');
    }

    try {
      await _audioPlayback.stop();
      return true;
    } catch (e) {
      debugPrint('Failed to stop audio: $e');
      return false;
    }
  }

  /// Loads an audio file from the assets directory.
  ///
  /// [messageId] is the unique identifier for the message.
  /// [assetPath] is the path to the audio file in the assets directory.
  /// [duration] is the duration of the audio file.
  /// Returns the loaded audio file, or null if loading failed.
  Future<AudioFile?> loadAudioFromAsset(
    String messageId,
    String assetPath,
    Duration duration,
  ) async {
    if (!_initialized) {
      throw Exception('AudioMessageProvider not initialized');
    }

    try {
      final audioFile = AudioFile(
        path: assetPath,
        duration: duration,
      );
      _audioFiles[messageId] = audioFile;
      return audioFile;
    } catch (e) {
      debugPrint('Failed to load audio from asset for message $messageId: $e');
      return null;
    }
  }

  /// Cleans up resources used by the provider.
  ///
  /// This method should be called when the provider is no longer needed.
  Future<void> dispose() async {
    if (_initialized) {
      await _audioGeneration.cleanup();
      await _audioPlayback.dispose();
      _audioFiles.clear();
      _initialized = false;
    }
  }

  /// Clears the audio cache.
  ///
  /// This method can be called to force reloading of audio files.
  void clearAudioCache() {
    debugPrint(
        'Clearing audio cache. Current cache size: ${_audioFiles.length}');
    _audioFiles.clear();
    debugPrint('Audio cache cleared');
  }
}
