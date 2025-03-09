import 'dart:async';
import '../models/audio_file.dart';
import '../models/playback_state.dart';

/// Interface for services that handle audio playback.
///
/// This interface defines the contract for any service that plays audio files,
/// allowing for different implementations (e.g., native audio players,
/// web audio players, or mock implementations for testing).
abstract class AudioPlayback {
  /// Initializes the audio playback service.
  ///
  /// This method should be called before any other methods to ensure
  /// the service is properly set up. It returns a boolean indicating
  /// whether initialization was successful.
  Future<bool> initialize();

  /// Loads an audio file for playback.
  ///
  /// Takes an [AudioFile] object and prepares it for playback.
  /// Returns a boolean indicating whether the file was successfully loaded.
  Future<bool> load(AudioFile file);

  /// Starts or resumes playback of the currently loaded audio file.
  ///
  /// Returns a boolean indicating whether playback was successfully started.
  /// If no file is loaded or the service is not initialized, this method
  /// should return false.
  Future<bool> play();

  /// Pauses playback of the currently playing audio file.
  ///
  /// Returns a boolean indicating whether playback was successfully paused.
  /// If no file is playing or the service is not initialized, this method
  /// should return false.
  Future<bool> pause();

  /// Stops playback of the currently playing audio file and resets the playback position.
  ///
  /// Returns a boolean indicating whether playback was successfully stopped.
  /// If no file is playing or the service is not initialized, this method
  /// should return false.
  Future<bool> stop();

  /// Seeks to a specific position in the currently loaded audio file.
  ///
  /// Takes a [position] in milliseconds and seeks to that position in the audio file.
  /// Returns a boolean indicating whether seeking was successful.
  /// If no file is loaded or the service is not initialized, this method
  /// should return false.
  Future<bool> seekTo(int position);

  /// Gets the current playback position in milliseconds.
  ///
  /// Returns the current position in the audio file, or 0 if no file is loaded
  /// or the service is not initialized.
  Future<int> get position;

  /// Gets the duration of the currently loaded audio file in milliseconds.
  ///
  /// Returns the duration of the audio file, or 0 if no file is loaded
  /// or the service is not initialized.
  Future<int> get duration;

  /// Gets the current playback state.
  ///
  /// Returns the current state of the audio playback, which can be one of:
  /// - [PlaybackState.initial]: No file is loaded
  /// - [PlaybackState.loading]: A file is being loaded
  /// - [PlaybackState.playing]: Audio is currently playing
  /// - [PlaybackState.paused]: Audio is paused
  /// - [PlaybackState.stopped]: Audio is stopped
  PlaybackState get state;

  /// Stream of playback state changes.
  ///
  /// This stream emits a new value whenever the playback state changes,
  /// allowing UI components to react to changes in playback state.
  Stream<PlaybackState> get onStateChanged;

  /// Stream of playback position changes.
  ///
  /// This stream emits a new value periodically during playback,
  /// allowing UI components to update progress indicators.
  Stream<int> get onPositionChanged;

  /// Disposes of resources used by the audio playback service.
  ///
  /// This method should be called when the service is no longer needed
  /// to free up resources.
  Future<void> dispose();
}
