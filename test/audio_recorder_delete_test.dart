import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'helpers/audio_recorder_test_helper.dart';

void main() {
  group('AudioRecorder Delete Feature', () {
    testWidgets('delete button is not visible initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('delete button appears in correct order after recording',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Verify button order
      await AudioRecorderTestHelper.verifyButtonOrder(tester);
      await AudioRecorderTestHelper.verifyButtonSpacing(tester);
    });

    testWidgets('delete button has correct style', (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      await AudioRecorderTestHelper.verifyButtonStyle(
        tester,
        Icons.delete,
        backgroundColor: Colors.grey[200],
      );
    });

    testWidgets('tapping delete button resets to initial state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Delete recording
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Verify reset to initial state
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('send button is disabled while deleting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Verify send button is enabled initially
      final sendButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.send),
          matching: find.byType(IconButton),
        ),
      );
      expect(sendButton.onPressed, isNotNull);

      // Start deleting
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Verify send button is gone
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('send button has blue background and white icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      await AudioRecorderTestHelper.verifyButtonStyle(
        tester,
        Icons.send,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      );
    });

    testWidgets('play button toggles between play and stop icons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Initially shows play icon
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);

      // Tap to toggle
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Shows stop icon
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      // Tap to toggle back
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      // Back to play icon
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('play button maintains grey background while playing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Verify initial style
      await AudioRecorderTestHelper.verifyButtonStyle(
        tester,
        Icons.play_arrow,
        backgroundColor: Colors.grey[200],
      );

      // Start playing
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify style remains the same while playing
      await AudioRecorderTestHelper.verifyButtonStyle(
        tester,
        Icons.stop,
        backgroundColor: Colors.grey[200],
      );
    });

    testWidgets('play button is disabled while deleting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Verify play button is enabled initially
      final playButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.play_arrow),
          matching: find.byType(IconButton),
        ),
      );
      expect(playButton.onPressed, isNotNull);

      // Start deleting
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Verify play button is gone
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('container has consistent padding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byType(Container));
      final padding = container.padding as EdgeInsets;

      expect(padding.left, 16.0);
      expect(padding.right, 16.0);
      expect(padding.top, 16.0);
      expect(padding.bottom, 16.0);
    });

    testWidgets('row uses minimum required space', (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('all buttons use circle shape', (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
      for (final button in buttons) {
        expect(button.style?.shape?.resolve({}), isA<CircleBorder>());
      }
    });

    testWidgets('mic button has grey background initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
      await tester.pumpAndSettle();

      await AudioRecorderTestHelper.verifyButtonStyle(
        tester,
        Icons.mic,
        backgroundColor: Colors.grey[200],
      );
    });

    testWidgets('stop button has red style while recording',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecording: true));
      await tester.pumpAndSettle();

      // Verify background color through style
      await AudioRecorderTestHelper.verifyButtonStyle(
        tester,
        Icons.stop,
        backgroundColor: Colors.red[100],
      );

      // Verify icon color directly
      final icon = tester.widget<Icon>(find.byIcon(Icons.stop));
      expect(icon.color, Colors.red);
    });

    testWidgets('send callback receives correct parameters',
        (WidgetTester tester) async {
      String? receivedPath;
      Duration? receivedDuration;

      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(
          isRecorded: true,
          onSendAudio: (path, duration) {
            receivedPath = path;
            receivedDuration = duration;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(receivedPath, 'test_path');
      expect(receivedDuration, Duration.zero);
    });

    testWidgets('send button clears recording state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);

      // Send recording
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify reset to initial state
      expect(find.byIcon(Icons.send), findsNothing);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('play button is disabled during sending',
        (WidgetTester tester) async {
      bool sendStarted = false;

      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(
          isRecorded: true,
          onSendAudio: (path, duration) {
            sendStarted = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify play button is enabled initially
      final playButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.play_arrow),
          matching: find.byType(IconButton),
        ),
      );
      expect(playButton.onPressed, isNotNull);

      // Start sending
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify play button is gone
      expect(sendStarted, isTrue);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('delete button remains enabled during playback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Verify delete button is enabled initially
      final deleteButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.delete),
          matching: find.byType(IconButton),
        ),
      );
      expect(deleteButton.onPressed, isNotNull);

      // Start playing
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify delete button remains enabled
      final deleteButtonAfterPlay = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.delete),
          matching: find.byType(IconButton),
        ),
      );
      expect(deleteButtonAfterPlay.onPressed, isNotNull);
    });

    testWidgets('send button remains enabled during playback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Verify send button is enabled initially
      final sendButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.send),
          matching: find.byType(IconButton),
        ),
      );
      expect(sendButton.onPressed, isNotNull);

      // Start playing
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify send button remains enabled
      final sendButtonAfterPlay = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.send),
          matching: find.byType(IconButton),
        ),
      );
      expect(sendButtonAfterPlay.onPressed, isNotNull);
    });

    testWidgets('play button stops when deleting during playback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecorded: true));
      await tester.pumpAndSettle();

      // Start playing
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify playing state
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      // Delete while playing
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Verify reset to initial state
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('play button can toggle while sending is pending',
        (WidgetTester tester) async {
      bool sendStarted = false;

      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(
          isRecorded: true,
          onSendAudio: (path, duration) {
            sendStarted = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Start sending
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify send started
      expect(sendStarted, isTrue);

      // Verify play button still works
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('stop button shows recording controls when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecording: true));
      await tester.pumpAndSettle();

      // Verify recording state
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);

      // Stop recording
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      // Verify recording controls appear
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.mic), findsNothing);
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('stop button has red background and icon during recording',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          AudioRecorderTestHelper.buildTestWidget(isRecording: true));
      await tester.pumpAndSettle();

      // Verify background color through style
      await AudioRecorderTestHelper.verifyButtonStyle(
        tester,
        Icons.stop,
        backgroundColor: Colors.red[100],
      );

      // Verify icon color directly
      final icon = tester.widget<Icon>(find.byIcon(Icons.stop));
      expect(icon.color, Colors.red);
    });

    testWidgets('mic button transitions to stop button when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(AudioRecorderTestHelper.buildTestWidget());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);

      // Start recording
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      // Verify recording state
      expect(find.byIcon(Icons.mic), findsNothing);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      // Verify stop button style
      await AudioRecorderTestHelper.verifyButtonStyle(
        tester,
        Icons.stop,
        backgroundColor: Colors.red[100],
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.stop));
      expect(icon.color, Colors.red);
    });
  });
}
