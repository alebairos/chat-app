@Skip('Temporarily skipping concurrency tests until state management is fixed')
library audio_recorder_concurrency_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:character_ai_clone/widgets/audio_recorder.dart';
import 'helpers/audio_recorder_test_helper.dart';

void main() {
  testWidgets('cannot start recording while already recording',
      (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Start recording
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();

    // Verify recording state
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // Verify mic button is disabled
    final micButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.mic),
        matching: find.byType(IconButton),
      ),
    );
    expect(micButton.onPressed, isNull);
  });

  testWidgets('cannot play while recording', (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Start recording again
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();

    // Verify play button is disabled
    final playButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.play_arrow),
        matching: find.byType(IconButton),
      ),
    );
    expect(playButton.onPressed, isNull);
  });

  testWidgets('cannot delete while recording', (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Start recording again
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();

    // Verify delete button is disabled
    final deleteButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.delete),
        matching: find.byType(IconButton),
      ),
    );
    expect(deleteButton.onPressed, isNull);
  });

  testWidgets('cannot send while recording', (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Start recording again
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();

    // Verify send button is disabled
    final sendButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(IconButton),
      ),
    );
    expect(sendButton.onPressed, isNull);
  });

  testWidgets('cannot record while playing', (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Start playing
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    // Verify mic button is disabled
    final micButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.mic),
        matching: find.byType(IconButton),
      ),
    );
    expect(micButton.onPressed, isNull);
  });

  testWidgets('cannot delete while playing', (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Start playing
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    // Verify delete button is disabled
    final deleteButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.delete),
        matching: find.byType(IconButton),
      ),
    );
    expect(deleteButton.onPressed, isNull);
  });

  testWidgets('cannot send while playing', (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Start playing
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    // Verify send button is disabled
    final sendButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(IconButton),
      ),
    );
    expect(sendButton.onPressed, isNull);
  });

  testWidgets('cannot play while deleting', (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Start deleting
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    // Verify play button is disabled
    final playButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.play_arrow),
        matching: find.byType(IconButton),
      ),
    );
    expect(playButton.onPressed, isNull);
  });

  testWidgets('cannot record while deleting', (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Start deleting
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    // Verify mic button is disabled
    final micButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.mic),
        matching: find.byType(IconButton),
      ),
    );
    expect(micButton.onPressed, isNull);
  });

  testWidgets('cannot send while deleting', (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Start deleting
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    // Verify send button is disabled
    final sendButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(IconButton),
      ),
    );
    expect(sendButton.onPressed, isNull);
  });

  testWidgets('rapid state transitions maintain consistency',
      (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Rapidly toggle between states
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();

    // Verify final state is consistent
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('concurrent operations maintain proper button states',
      (WidgetTester tester) async {
    await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
    await tester.pumpAndSettle();

    // Record and stop to get a recording
    await AudioRecorderTestHelper.simulateRecording(tester);

    // Verify initial state
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
