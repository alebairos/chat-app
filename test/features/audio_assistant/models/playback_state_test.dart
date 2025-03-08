import 'package:flutter_test/flutter_test.dart';
import '../../../../lib/features/audio_assistant/models/playback_state.dart';

void main() {
  group('PlaybackState', () {
    test('should have all required states', () {
      // Verify all expected states exist
      expect(PlaybackState.values.length, 5);
      expect(PlaybackState.values.contains(PlaybackState.initial), true);
      expect(PlaybackState.values.contains(PlaybackState.loading), true);
      expect(PlaybackState.values.contains(PlaybackState.playing), true);
      expect(PlaybackState.values.contains(PlaybackState.paused), true);
      expect(PlaybackState.values.contains(PlaybackState.stopped), true);
    });

    test('should convert to string correctly', () {
      // Verify string representation
      expect(PlaybackState.initial.toString(), contains('initial'));
      expect(PlaybackState.loading.toString(), contains('loading'));
      expect(PlaybackState.playing.toString(), contains('playing'));
      expect(PlaybackState.paused.toString(), contains('paused'));
      expect(PlaybackState.stopped.toString(), contains('stopped'));
    });

    test('should define valid state transitions', () {
      // Define a simple state machine to test valid transitions
      final validTransitions = {
        PlaybackState.initial: [PlaybackState.loading, PlaybackState.stopped],
        PlaybackState.loading: [PlaybackState.playing, PlaybackState.stopped],
        PlaybackState.playing: [PlaybackState.paused, PlaybackState.stopped],
        PlaybackState.paused: [PlaybackState.playing, PlaybackState.stopped],
        PlaybackState.stopped: [PlaybackState.loading],
      };

      // Verify each state has defined transitions
      for (final state in PlaybackState.values) {
        expect(validTransitions.containsKey(state), true,
            reason: 'State $state should have defined transitions');
        expect(validTransitions[state]!.isNotEmpty, true,
            reason: 'State $state should have at least one valid transition');
      }

      // Verify specific transitions
      expect(
          validTransitions[PlaybackState.initial]!
              .contains(PlaybackState.loading),
          true);
      expect(
          validTransitions[PlaybackState.loading]!
              .contains(PlaybackState.playing),
          true);
      expect(
          validTransitions[PlaybackState.playing]!
              .contains(PlaybackState.paused),
          true);
      expect(
          validTransitions[PlaybackState.paused]!
              .contains(PlaybackState.playing),
          true);
      expect(
          validTransitions[PlaybackState.stopped]!
              .contains(PlaybackState.loading),
          true);
    });
  });
}
