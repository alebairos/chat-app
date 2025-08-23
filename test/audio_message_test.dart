import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_personas_app/widgets/audio_message.dart';

void main() {
  testWidgets('AudioMessage displays correct duration format',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioMessage(
            audioPath: 'test_path.m4a',
            isUser: true,
            transcription: 'Test transcription',
            duration: Duration(minutes: 1, seconds: 30),
          ),
        ),
      ),
    );

    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('AudioMessage displays transcription text',
      (WidgetTester tester) async {
    const testTranscription = 'This is a test transcription';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioMessage(
            audioPath: 'test_path.m4a',
            isUser: true,
            transcription: testTranscription,
            duration: Duration(seconds: 30),
          ),
        ),
      ),
    );

    expect(find.text(testTranscription), findsOneWidget);
  });

  testWidgets('AudioMessage shows play button initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioMessage(
            audioPath: 'test_path.m4a',
            isUser: true,
            transcription: 'Test transcription',
            duration: Duration(seconds: 30),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });
}
