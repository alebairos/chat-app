import 'dart:async';
import '../models/playback_state.dart';

/// Interface for managing audio playback state.
///
/// This interface defines the contract for any service that manages
/// the state of audio playback, allowing for centralized state management
/// and coordination between different components of the audio system.
abstract class PlaybackStateManager {
  /// Gets the current playback state.
  ///
  /// Returns the current state of audio playback.
  PlaybackState get state;

  /// Updates the current playback state.
  ///
  /// Takes a new [PlaybackState] and updates the current state.
  /// This method should emit the new state to all listeners.
  void updateState(PlaybackState newState);

  /// Stream of playback state changes.
  ///
  /// This stream emits a new value whenever the playback state changes,
  /// allowing UI components and other services to react to changes in playback state.
  Stream<PlaybackState> get onStateChanged;

  /// Checks if a transition from the current state to the given state is valid.
  ///
  /// Takes a target [PlaybackState] and returns a boolean indicating
  /// whether the transition from the current state to the target state is valid.
  /// This method can be used to enforce state transition rules.
  bool canTransitionTo(PlaybackState targetState);

  /// Resets the playback state to the initial state.
  ///
  /// This method should be called when playback is stopped or when
  /// a new audio file is loaded.
  void reset();

  /// Disposes of resources used by the playback state manager.
  ///
  /// This method should be called when the manager is no longer needed
  /// to free up resources.
  void dispose();
}
