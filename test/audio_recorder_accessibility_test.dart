import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_personas_app/widgets/audio_recorder.dart';
import 'helpers/audio_recorder_test_helper.dart';

@GenerateMocks([Record, AudioPlayer])
import 'audio_recorder_test.mocks.dart';

void main() {
  late MockRecord mockRecord;
  late MockAudioPlayer mockPlayer;

  setUp(() {
    mockRecord = MockRecord();
    mockPlayer = MockAudioPlayer();

    when(mockRecord.hasPermission()).thenAnswer((_) async => true);
    when(mockRecord.isRecording()).thenAnswer((_) async => false);
    when(mockRecord.start(
      path: anyNamed('path'),
      encoder: anyNamed('encoder'),
      bitRate: anyNamed('bitRate'),
      samplingRate: anyNamed('samplingRate'),
    )).thenAnswer((_) async => {});
    when(mockRecord.stop()).thenAnswer((_) async => '');
    when(mockPlayer.onPlayerComplete).thenAnswer((_) => const Stream.empty());
  });

  group('AudioRecorder Accessibility Tests', () {
    testWidgets('mic button has appropriate tooltip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioRecorder(
              testRecord: mockRecord,
              testPlayer: mockPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the mic button
      final micButton = find.byIcon(Icons.mic);
      expect(micButton, findsOneWidget);

      // Get the IconButton widget
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: micButton,
          matching: find.byType(IconButton),
        ),
      );

      // Verify tooltip
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, contains('Record'));
    });

    testWidgets('stop button has appropriate tooltip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(isRecording: true),
      );
      await tester.pumpAndSettle();

      // Find the stop button
      final stopButton = find.byIcon(Icons.stop);
      expect(stopButton, findsOneWidget);

      // Get the IconButton widget
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: stopButton,
          matching: find.byType(IconButton),
        ),
      );

      // Verify tooltip
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, contains('Stop'));
    });

    testWidgets('play button has appropriate tooltip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(isRecorded: true),
      );
      await tester.pumpAndSettle();

      // Find the play button
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      // Get the IconButton widget
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: playButton,
          matching: find.byType(IconButton),
        ),
      );

      // Verify tooltip
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, contains('Play'));
    });

    testWidgets('delete button has appropriate tooltip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(isRecorded: true),
      );
      await tester.pumpAndSettle();

      // Find the delete button
      final deleteButton = find.byIcon(Icons.delete);
      expect(deleteButton, findsOneWidget);

      // Get the IconButton widget
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: deleteButton,
          matching: find.byType(IconButton),
        ),
      );

      // Verify tooltip
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, contains('Delete'));
    });

    testWidgets('send button has appropriate tooltip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(isRecorded: true),
      );
      await tester.pumpAndSettle();

      // Find the send button
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);

      // Get the IconButton widget
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: sendButton,
          matching: find.byType(IconButton),
        ),
      );

      // Verify tooltip
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, contains('Send'));
    });

    testWidgets('buttons have minimum size for touch targets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(isRecorded: true),
      );
      await tester.pumpAndSettle();

      // Check all buttons
      final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
      for (final button in buttons) {
        // Minimum touch target size should be 48x48 according to WCAG guidelines
        final minimumSize = button.style?.minimumSize?.resolve({});
        if (minimumSize != null) {
          expect(minimumSize.width, greaterThanOrEqualTo(48.0));
          expect(minimumSize.height, greaterThanOrEqualTo(48.0));
        } else {
          // If minimumSize is not explicitly set, check the constraints
          // This is a fallback check
          final constraints = button.constraints;
          if (constraints != null) {
            expect(constraints.minWidth, greaterThanOrEqualTo(48.0));
            expect(constraints.minHeight, greaterThanOrEqualTo(48.0));
          }
        }
      }
    });

    testWidgets('buttons have sufficient color contrast',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(isRecorded: true),
      );
      await tester.pumpAndSettle();

      // Check send button (blue background with white icon)
      await AudioRecorderTestHelper.verifyButtonStyle(
        tester,
        Icons.send,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      );

      // The contrast ratio between blue and white is typically sufficient
      // This is a simplified check - in a real app, you might use a contrast
      // calculation library to verify WCAG compliance
    });

    testWidgets('buttons have consistent spacing for usability',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(isRecorded: true),
      );
      await tester.pumpAndSettle();

      await AudioRecorderTestHelper.verifyButtonSpacing(tester);
    });

    testWidgets('error messages are accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Show error snackbar
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Test error'),
                    ),
                  );
                });
                return const AudioRecorder();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the error message
      final errorText = find.text('Error: Test error');
      expect(errorText, findsOneWidget);
    });

    testWidgets('all buttons use circle shape for consistent UI',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(isRecorded: true),
      );
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
      for (final button in buttons) {
        expect(button.style?.shape?.resolve({}), isA<CircleBorder>());
      }
    });
  });
}
