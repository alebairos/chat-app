import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/audio_file.dart';
import 'audio_generation.dart';
import 'audio_playback.dart';

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
  /// [audioPlayback] is the service used to play audio files.
  AudioMessageProvider({
    required AudioGeneration audioGeneration,
    required AudioPlayback audioPlayback,
  })  : _audioGeneration = audioGeneration,
        _audioPlayback = audioPlayback;

  /// Whether the provider has been initialized.
  bool get isInitialized => _initialized;

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

    debugPrint(
        'Generating audio for message $messageId with text: ${text.substring(0, min(50, text.length))}...');

    try {
      final audioFile = await _audioGeneration.generate(text);
      debugPrint(
          'Audio generation successful: ${audioFile.path}, duration: ${audioFile.duration}');
      _audioFiles[messageId] = audioFile;
      return audioFile;
    } catch (e) {
      debugPrint('Failed to generate audio for message $messageId: $e');
      return null;
    }
  }

  /// Gets the audio file associated with the given message ID.
  ///
  /// [messageId] is the unique identifier for the message.
  /// Returns the audio file, or null if no audio file is associated with the message ID.
  AudioFile? getAudioForMessage(String messageId) {
    return _audioFiles[messageId];
  }

  /// Plays the audio file associated with the given message ID.
  ///
  /// [messageId] is the unique identifier for the message.
  /// Returns true if playback started successfully, false otherwise.
  Future<bool> playAudioForMessage(String messageId) async {
    if (!_initialized) {
      throw Exception('AudioMessageProvider not initialized');
    }

    final audioFile = _audioFiles[messageId];
    if (audioFile == null) {
      debugPrint('No audio file found for message $messageId');
      return false;
    }

    try {
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
}
