import 'dart:async';
import '../models/audio_file.dart';
import '../models/playback_state.dart';

/// Interface that defines the contract for audio playback functionality.
///
/// This abstraction allows for different implementations of audio playback,
/// making it easier to test and extend the audio functionality.
abstract class AudioPlayback {
  /// Stream of playback state changes
  Stream<PlaybackState> get onStateChanged;

  /// Stream of playback position updates in milliseconds
  Stream<int> get onPositionChanged;

  /// Current state of the audio playback
  PlaybackState get state;

  /// Current position of the audio playback in milliseconds
  Future<int> get position;

  /// Current duration of the loaded audio file in milliseconds
  Future<int> get duration;

  /// Initializes the audio playback system
  ///
  /// Returns true if initialization was successful, false otherwise
  Future<bool> initialize();

  /// Loads an audio file for playback
  ///
  /// [file] The audio file to load
  /// Returns true if the file was loaded successfully, false otherwise
  Future<bool> load(AudioFile file);

  /// Starts or resumes playback of the loaded audio file
  ///
  /// Returns true if playback started successfully, false otherwise
  Future<bool> play();

  /// Pauses playback of the loaded audio file
  ///
  /// Returns true if playback was paused successfully, false otherwise
  Future<bool> pause();

  /// Stops playback of the loaded audio file and resets the position to the beginning
  ///
  /// Returns true if playback was stopped successfully, false otherwise
  Future<bool> stop();

  /// Seeks to a specific position in the audio file
  ///
  /// [position] The position to seek to in milliseconds
  /// Returns true if seeking was successful, false otherwise
  Future<bool> seekTo(int position);

  /// Releases all resources used by the audio playback system
  ///
  /// This should be called when the audio playback is no longer needed
  /// to prevent memory leaks and resource usage.
  Future<void> dispose();
}
