import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:character_ai_clone/widgets/audio_recorder.dart';
import 'dart:async';
import 'helpers/audio_recorder_test_helper.dart';

@GenerateMocks([Record, AudioPlayer])
import 'audio_recorder_test.mocks.dart';

void main() {
  late MockRecord mockRecord;
  late MockAudioPlayer mockPlayer;
  late StreamController<Duration> durationStreamController;

  setUp(() {
    mockRecord = MockRecord();
    mockPlayer = MockAudioPlayer();
    durationStreamController = StreamController<Duration>.broadcast();

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

  tearDown(() {
    durationStreamController.close();
  });

  testWidgets('duration starts at zero', (WidgetTester tester) async {
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

    // Verify no duration text is visible initially
    expect(find.text('0:00'), findsNothing);
  });

  testWidgets('duration increases during recording',
      (WidgetTester tester) async {
    // Use the test helper to create a widget with recording state
    await tester.pumpWidget(
      AudioRecorderTestHelper.buildTestWidget(isRecording: true),
    );
    await tester.pumpAndSettle();

    // Verify recording has started
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // Stop recording
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();

    // Verify recording has stopped and we have buttons for a recorded audio
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('duration is passed to onSendAudio callback',
      (WidgetTester tester) async {
    String? receivedPath;
    Duration? receivedDuration;

    // Use the test helper to create a widget with recorded state
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

    // Verify we have a recording
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);

    // Send the audio
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify the callback received a path and duration
    expect(receivedPath, isNotNull);
    expect(receivedPath, equals('test_path'));
    expect(receivedDuration, isNotNull);
  });

  testWidgets('duration resets after sending audio',
      (WidgetTester tester) async {
    // Use the test helper to create a widget with recorded state
    await tester.pumpWidget(
      AudioRecorderTestHelper.buildTestWidget(isRecorded: true),
    );
    await tester.pumpAndSettle();

    // Verify we have a recording
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);

    // Send the audio
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify we're back to initial state
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.send), findsNothing);
  });

  testWidgets('duration resets after deleting recording',
      (WidgetTester tester) async {
    // Use the test helper to create a widget with recorded state
    await tester.pumpWidget(
      AudioRecorderTestHelper.buildTestWidget(isRecorded: true),
    );
    await tester.pumpAndSettle();

    // Verify we have a recording
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);

    // Delete the recording
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    // Verify we're back to initial state
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.send), findsNothing);
  });
}
