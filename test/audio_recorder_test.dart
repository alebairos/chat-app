import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/widgets/audio_recorder.dart';

@GenerateMocks([Record, AudioPlayer])
import 'audio_recorder_test.mocks.dart';

void main() {
  late MockRecord mockRecord;
  late MockAudioPlayer mockPlayer;

  setUp(() {
    mockRecord = MockRecord();
    mockPlayer = MockAudioPlayer();

    // Only mock what we can reliably control
    when(mockRecord.hasPermission()).thenAnswer((_) async => true);
    when(mockRecord.isRecording()).thenAnswer((_) async => false);
    when(mockRecord.start(
      path: anyNamed('path'),
      encoder: anyNamed('encoder'),
      bitRate: anyNamed('bitRate'),
      samplingRate: anyNamed('samplingRate'),
    )).thenAnswer((_) async => {});
    when(mockPlayer.onPlayerComplete).thenAnswer((_) => Stream.empty());
  });

  testWidgets('AudioRecorder shows mic button initially',
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

    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('verifies recording permission before starting',
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

    // Start recording
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    // Verify permission was checked
    verify(mockRecord.hasPermission()).called(1);
  });
}
