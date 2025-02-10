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

    when(mockRecord.hasPermission()).thenAnswer((_) async => true);
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
}
