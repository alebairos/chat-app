import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/audio_waveform.dart';

void main() {
  group('AudioWaveform', () {
    testWidgets('should render with correct size for short audio',
        (WidgetTester tester) async {
      // Build a short audio waveform (2 seconds)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioWaveform(
              audioPath: 'test_path.mp3',
              audioDuration: Duration(seconds: 2),
              currentPosition: Duration.zero,
            ),
          ),
        ),
      );

      // Find the waveform container
      final container = find.byType(Container).first;

      // Verify the size is appropriate for a short audio
      expect(tester.getSize(container).width, lessThan(300.0));
      expect(tester.getSize(container).height, equals(40.0));
    });

    testWidgets('should render with maximum size for long audio',
        (WidgetTester tester) async {
      // Build a long audio waveform (30 seconds)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioWaveform(
              audioPath: 'test_path.mp3',
              audioDuration: Duration(seconds: 30),
              currentPosition: Duration.zero,
            ),
          ),
        ),
      );

      // Find the waveform container
      final container = find.byType(Container).first;

      // Verify the size is capped for a long audio
      expect(tester.getSize(container).width, equals(300.0));
      expect(tester.getSize(container).height, equals(40.0));
    });

    testWidgets('should render progress indicator at correct position',
        (WidgetTester tester) async {
      // Define total duration and target position
      const totalDuration = Duration(seconds: 10);
      const targetPosition = Duration(seconds: 5); // 50%

      // Build audio waveform passing the target position
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioWaveform(
              audioPath: 'test_path.mp3',
              audioDuration: totalDuration,
              currentPosition: targetPosition,
            ),
          ),
        ),
      );

      // Find the progress indicator (the Positioned widget)
      // Assuming the indicator is the last Positioned widget in the stack
      final progressIndicatorFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Positioned &&
              widget.child is Container &&
              (widget.child as Container).color ==
                  Theme.of(tester.element(find.byType(AudioWaveform)))
                      .colorScheme
                      .primary,
          description: 'progress indicator Positioned widget');

      expect(progressIndicatorFinder, findsOneWidget);
      final Positioned progressIndicator =
          tester.widget(progressIndicatorFinder);

      // Verify its 'left' property is roughly in the middle
      final containerWidthFinder = find.byWidgetPredicate((widget) =>
          widget is Container && widget.decoration is BoxDecoration);
      expect(containerWidthFinder, findsOneWidget);
      final containerWidth = tester.getSize(containerWidthFinder).width;

      // Calculate expected position (50% of width)
      final expectedPosition = containerWidth *
          (targetPosition.inMilliseconds / totalDuration.inMilliseconds);

      // Check if the 'left' value of the Positioned widget matches
      expect(progressIndicator.left,
          closeTo(expectedPosition, 1.0)); // Use closeTo for double comparison
    });
  });
}
