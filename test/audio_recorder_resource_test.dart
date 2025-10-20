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
    when(mockPlayer.stop()).thenAnswer((_) async => {});
    when(mockPlayer.dispose()).thenAnswer((_) async => {});
  });

  group('AudioRecorder Resource Management Tests', () {
    testWidgets('disposes player when widget is removed',
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

      // Remove the widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      // Verify resources are disposed
      verify(mockPlayer.dispose()).called(1);
    });

    testWidgets('uses appropriate audio encoding settings',
        (WidgetTester tester) async {
      // Reset mock to ensure clean verification
      reset(mockRecord);

      // Setup mock responses
      when(mockRecord.hasPermission()).thenAnswer((_) async => true);
      when(mockRecord.isRecording()).thenAnswer((_) async => false);
      when(mockRecord.start(
        path: anyNamed('path'),
        encoder: anyNamed('encoder'),
        bitRate: anyNamed('bitRate'),
        samplingRate: anyNamed('samplingRate'),
      )).thenAnswer((_) async => {});

      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(isRecording: true),
      );
      await tester.pumpAndSettle();

      // Verify recording has started by checking for the stop button
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('cleans up state when deleting recording',
        (WidgetTester tester) async {
      // Start with a recorded state
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(
          isRecorded: true,
        ),
      );
      await tester.pumpAndSettle();

      // Verify we have a recording
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Delete recording
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Verify we're back to initial state
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('stops playback when starting a new recording',
        (WidgetTester tester) async {
      // Setup a test widget with recorded state
      await tester.pumpWidget(
        AudioRecorderTestHelper.buildTestWidget(
          isRecorded: true,
        ),
      );
      await tester.pumpAndSettle();

      // Verify we have a recording
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Start playing
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify playing has started (stop button is shown)
      expect(find.byIcon(Icons.stop), findsOneWidget);

      // Delete recording to get back to initial state
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Start a new recording
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      // Verify recording has started
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });
  });
}
