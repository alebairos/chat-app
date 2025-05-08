library audio_recorder_concurrency_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'helpers/audio_recorder_test_helper.dart';

void main() {
  group('Audio Recorder Concurrency Tests', () {
    testWidgets('cannot start recording while already recording',
        (WidgetTester tester) async {
      // Build the widget in recording state
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecording: true));
      await tester.pumpAndSettle();

      // Verify recording state shows stop button and no mic button
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('cannot play while recording', (WidgetTester tester) async {
      // Build the widget in recording state with a previous recording
      await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget(
        isRecording: true,
        isRecorded: true,
      ));
      await tester.pumpAndSettle();

      // Verify recording state shows stop button and no playback controls
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('cannot record while playing', (WidgetTester tester) async {
      // Start with a recorded message
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Start playback
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify mic button is not visible during playback
      expect(find.byIcon(Icons.mic), findsNothing);
      expect(find.byIcon(Icons.stop), findsOneWidget); // playback stop button
    });

    testWidgets('cannot send while playing', (WidgetTester tester) async {
      // Start with a recorded message
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Start playback
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify send button is disabled during playback
      final sendButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.send),
          matching: find.byType(IconButton),
        ),
      );
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('buttons are disabled during deletion',
        (WidgetTester tester) async {
      // Start with a recorded message
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Start deletion
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Verify all operation buttons are not visible during deletion
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);
      expect(find.byIcon(Icons.mic),
          findsOneWidget); // Should show mic for new recording
    });

    testWidgets('state transitions maintain consistency',
        (WidgetTester tester) async {
      // Start with a recorded message
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Initial state should show all controls
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Start playback
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // During playback, send should be disabled
      final sendButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.send),
          matching: find.byType(IconButton),
        ),
      );
      expect(sendButton.onPressed, isNull);

      // Stop playback
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      // After playback, all controls should be enabled again
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
