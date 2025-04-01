import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/audio_message.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:mockito/mockito.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioMessage', () {
    testWidgets('should render with correct initial state',
        (WidgetTester tester) async {
      // Build an audio message
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioMessage(
              messageId: 'test_message',
              audioPath: 'test_path.mp3',
              audioDuration: Duration(seconds: 5),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.text('00:05'), findsOneWidget);
    });

    testWidgets('should show correct duration text',
        (WidgetTester tester) async {
      // Build an audio message with a specific duration
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioMessage(
              messageId: 'test_message',
              audioPath: 'test_path.mp3',
              audioDuration: Duration(minutes: 1, seconds: 30),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify duration text
      expect(find.text('01:30'), findsOneWidget);
    });

    testWidgets('should render differently for assistant vs user messages',
        (WidgetTester tester) async {
      // Build an assistant audio message
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioMessage(
              messageId: 'assistant_message',
              audioPath: 'test_path.mp3',
              audioDuration: Duration(seconds: 5),
              isAssistantMessage: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the container color for assistant message
      final assistantContainer = find.byType(Container).first;
      final assistantColor = (tester.widget(assistantContainer) as Container)
          .decoration as BoxDecoration;

      // Build a user audio message
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioMessage(
              messageId: 'user_message',
              audioPath: 'test_path.mp3',
              audioDuration: Duration(seconds: 5),
              isAssistantMessage: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the container color for user message
      final userContainer = find.byType(Container).first;
      final userColor = (tester.widget(userContainer) as Container).decoration
          as BoxDecoration;

      // Verify they have different colors
      expect(assistantColor.color, isNot(equals(userColor.color)));
    });
  });
}
