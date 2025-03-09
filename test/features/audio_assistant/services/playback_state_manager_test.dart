import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../../../../lib/features/audio_assistant/models/playback_state.dart';
import '../../../../lib/features/audio_assistant/services/playback_state_manager.dart';

// Mock implementation of PlaybackStateManager for testing
class MockPlaybackStateManager implements PlaybackStateManager {
  PlaybackState _state = PlaybackState.initial;
  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();

  // Define valid state transitions
  final Map<PlaybackState, List<PlaybackState>> _validTransitions = {
    PlaybackState.initial: [PlaybackState.loading, PlaybackState.stopped],
    PlaybackState.loading: [PlaybackState.playing, PlaybackState.stopped],
    PlaybackState.playing: [PlaybackState.paused, PlaybackState.stopped],
    PlaybackState.paused: [PlaybackState.playing, PlaybackState.stopped],
    PlaybackState.stopped: [PlaybackState.loading],
  };

  @override
  PlaybackState get state => _state;

  @override
  void updateState(PlaybackState newState) {
    if (canTransitionTo(newState) || newState == _state) {
      _state = newState;
      _stateController.add(newState);
    } else {
      throw StateError('Invalid state transition from $_state to $newState');
    }
  }

  @override
  Stream<PlaybackState> get onStateChanged => _stateController.stream;

  @override
  bool canTransitionTo(PlaybackState targetState) {
    return _validTransitions[_state]?.contains(targetState) ?? false;
  }

  @override
  void reset() {
    _state = PlaybackState.initial;
    _stateController.add(_state);
  }

  @override
  void dispose() {
    _stateController.close();
  }
}

void main() {
  group('PlaybackStateManager', () {
    late MockPlaybackStateManager stateManager;

    setUp(() {
      stateManager = MockPlaybackStateManager();
    });

    tearDown(() {
      stateManager.dispose();
    });

    test('should have initial state', () {
      expect(stateManager.state, PlaybackState.initial);
    });

    test('should update state for valid transitions', () {
      // Initial -> Loading
      stateManager.updateState(PlaybackState.loading);
      expect(stateManager.state, PlaybackState.loading);

      // Loading -> Playing
      stateManager.updateState(PlaybackState.playing);
      expect(stateManager.state, PlaybackState.playing);

      // Playing -> Paused
      stateManager.updateState(PlaybackState.paused);
      expect(stateManager.state, PlaybackState.paused);

      // Paused -> Playing
      stateManager.updateState(PlaybackState.playing);
      expect(stateManager.state, PlaybackState.playing);

      // Playing -> Stopped
      stateManager.updateState(PlaybackState.stopped);
      expect(stateManager.state, PlaybackState.stopped);
    });

    test('should throw error for invalid transitions', () {
      // Initial -> Playing (invalid)
      expect(() => stateManager.updateState(PlaybackState.playing),
          throwsStateError);

      // Initial -> Paused (invalid)
      expect(() => stateManager.updateState(PlaybackState.paused),
          throwsStateError);

      // Set to Loading
      stateManager.updateState(PlaybackState.loading);

      // Loading -> Paused (invalid)
      expect(() => stateManager.updateState(PlaybackState.paused),
          throwsStateError);
    });

    test('should allow updating to the same state', () {
      stateManager.updateState(PlaybackState.initial);
      expect(stateManager.state, PlaybackState.initial);

      stateManager.updateState(PlaybackState.loading);
      stateManager.updateState(PlaybackState.loading);
      expect(stateManager.state, PlaybackState.loading);
    });

    test('should check if transition is valid', () {
      // From initial state
      expect(stateManager.canTransitionTo(PlaybackState.loading), true);
      expect(stateManager.canTransitionTo(PlaybackState.stopped), true);
      expect(stateManager.canTransitionTo(PlaybackState.playing), false);
      expect(stateManager.canTransitionTo(PlaybackState.paused), false);

      // Update to loading
      stateManager.updateState(PlaybackState.loading);

      // From loading state
      expect(stateManager.canTransitionTo(PlaybackState.playing), true);
      expect(stateManager.canTransitionTo(PlaybackState.stopped), true);
      expect(stateManager.canTransitionTo(PlaybackState.initial), false);
      expect(stateManager.canTransitionTo(PlaybackState.paused), false);
    });

    test('should reset state to initial', () {
      // Set to a non-initial state
      stateManager.updateState(PlaybackState.loading);
      stateManager.updateState(PlaybackState.playing);
      expect(stateManager.state, PlaybackState.playing);

      // Reset
      stateManager.reset();
      expect(stateManager.state, PlaybackState.initial);
    });

    test('should emit state changes', () async {
      final states = <PlaybackState>[];
      final subscription = stateManager.onStateChanged.listen(states.add);

      stateManager.updateState(PlaybackState.loading);
      stateManager.updateState(PlaybackState.playing);
      stateManager.updateState(PlaybackState.paused);
      stateManager.reset();

      // Wait for all events to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      expect(states, [
        PlaybackState.loading,
        PlaybackState.playing,
        PlaybackState.paused,
        PlaybackState.initial,
      ]);

      await subscription.cancel();
    });
  });
}
