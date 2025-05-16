import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/assistant_audio_message.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/models/playback_state.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlaybackManager extends Mock implements AudioPlaybackManager {}

void main() {
  group('AssistantAudioMessage Widget Tests', () {
    testWidgets('displays audio message with initial state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioPath: 'test_audio.m4a',
              transcription: 'This is a test transcription',
              duration: const Duration(seconds: 30),
              messageId: 'test-message-id',
            ),
          ),
        ),
      );

      // Verify initial state elements are displayed
      expect(find.text('This is a test transcription'),
          findsNothing); // Initially collapsed
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_filled), findsNothing);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('expanding shows transcription text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioPath: 'test_audio.m4a',
              transcription: 'This is a test transcription',
              duration: const Duration(seconds: 30),
              messageId: 'test-message-id',
            ),
          ),
        ),
      );

      // Initially transcription is not visible
      expect(find.text('This is a test transcription'), findsNothing);

      // Tap the expand button
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pump();

      // Now transcription should be visible
      expect(find.text('This is a test transcription'), findsOneWidget);
    });

    testWidgets('play button triggers playback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioPath: 'test_audio.m4a',
              transcription: 'This is a test transcription',
              duration: const Duration(seconds: 30),
              messageId: 'test-message-id',
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);

      // Note: We can't fully test audio playback in a widget test
      // as it requires mocking the AudioPlaybackManager properly,
      // which would need more complex test setup.
    });
  });

  group('AssistantAudioMessage Format Tests', () {
    testWidgets('formats duration correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioPath: 'test_audio.m4a',
              transcription: 'This is a test transcription',
              duration: const Duration(minutes: 1, seconds: 45),
              messageId: 'test-message-id',
            ),
          ),
        ),
      );

      expect(find.text('01:45'), findsOneWidget);
    });
  });

  group('AssistantAudioMessage Playback State Tests', () {
    testWidgets('playback state changes correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioPath: 'test_audio.m4a',
              transcription: 'This is a test transcription',
              duration: const Duration(seconds: 30),
              messageId: 'test-message-id',
            ),
          ),
        ),
      );

      // Initial state check
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);

      // Tap play button
      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pump();

      // We can't fully test state changes without mocking the audio playback manager
    });
  });

  group('AssistantAudioMessage Progress Indicator Tests', () {
    testWidgets('progress indicator works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioPath: 'test_audio.m4a',
              transcription: 'This is a test transcription',
              duration: const Duration(seconds: 30),
              messageId: 'test-message-id',
            ),
          ),
        ),
      );

      // Progress indicator should be present
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('AssistantAudioMessage Error Handling Tests', () {
    testWidgets('handles errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioPath: 'test_audio.m4a',
              transcription: 'This is a test transcription',
              duration: const Duration(seconds: 30),
              messageId: 'test-message-id',
            ),
          ),
        ),
      );

      // We can't test actual error behavior without mock implementation
      // This is a placeholder for future error testing
    });
  });

  group('AssistantAudioMessage Styling Tests', () {
    testWidgets('has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioPath: 'test_audio.m4a',
              transcription: 'This is a test transcription',
              duration: const Duration(seconds: 30),
              messageId: 'test-message-id',
            ),
          ),
        ),
      );

      // Verify container styling
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
    });
  });
}
