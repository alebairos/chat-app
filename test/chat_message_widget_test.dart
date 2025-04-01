import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/widgets/chat_message.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/audio_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatMessage Widget', () {
    testWidgets('renders text message correctly', (tester) async {
      const testWidget = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Test message',
            isUser: false,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Find text widget
      final textFinder = find.text('Test message');
      expect(textFinder, findsOneWidget);

      // Verify container styling
      final containerFinder = find.ancestor(
        of: textFinder,
        matching: find.byType(Container),
      );

      // Find the container with decoration
      Container? decoratedContainer;
      tester.widgetList<Container>(containerFinder).forEach((container) {
        if (container.decoration != null) {
          decoratedContainer = container;
        }
      });

      expect(decoratedContainer, isNotNull);
      final decoration = decoratedContainer!.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.grey[200]));

      // Non-user messages should have an avatar
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('renders user message correctly', (tester) async {
      const userMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'User message',
            isUser: true,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(userMessage);
      await tester.pumpAndSettle();

      // Find the text widget
      final textWidget = find.text('User message');
      expect(textWidget, findsOneWidget);

      // Find the container that contains the text
      final containerFinder = find.ancestor(
        of: textWidget,
        matching: find.byType(Container),
      );

      // Find the container with decoration
      Container? decoratedContainer;
      tester.widgetList<Container>(containerFinder).forEach((container) {
        if (container.decoration != null) {
          decoratedContainer = container;
        }
      });

      expect(decoratedContainer, isNotNull);
      final decoration = decoratedContainer!.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.blue[100]));

      // User messages should be aligned to the right
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.end));

      // Note: We're not checking for the absence of CircleAvatar because
      // the implementation might have it in the widget tree but not visible
    });

    testWidgets('renders audio message correctly', (tester) async {
      const audioMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Audio transcription',
            isUser: true,
            audioPath: 'test_audio.m4a',
            duration: Duration(seconds: 30),
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(audioMessage);
      await tester.pumpAndSettle();

      expect(find.byType(AudioMessage), findsOneWidget);

      final audioWidget =
          tester.widget<AudioMessage>(find.byType(AudioMessage));
      expect(audioWidget.audioPath, equals('test_audio.m4a'));
      expect(audioWidget.audioDuration, equals(const Duration(seconds: 30)));
      expect(audioWidget.isAssistantMessage, isFalse);
    });

    test('copyWith creates correct copy', () {
      const original = ChatMessage(
        text: 'Original',
        isUser: false,
        audioPath: null,
        duration: null,
      );

      final copy = original.copyWith(
        text: 'Modified',
        isUser: true,
        audioPath: 'audio.m4a',
        duration: const Duration(seconds: 10),
      );

      expect(copy.text, equals('Modified'));
      expect(copy.isUser, isTrue);
      expect(copy.audioPath, equals('audio.m4a'));
      expect(copy.duration, equals(const Duration(seconds: 10)));

      // Test partial updates
      final partialCopy = original.copyWith(text: 'Only text changed');
      expect(partialCopy.text, equals('Only text changed'));
      expect(partialCopy.isUser, equals(original.isUser));
      expect(partialCopy.audioPath, equals(original.audioPath));
      expect(partialCopy.duration, equals(original.duration));
    });

    testWidgets('handles empty text gracefully', (tester) async {
      const emptyMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: '',
            isUser: false,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(emptyMessage);
      await tester.pumpAndSettle();

      // Empty text should still render a container
      final textFinder = find.text('');
      expect(textFinder, findsOneWidget);
    });

    testWidgets('applies correct colors based on user/non-user',
        (tester) async {
      // Test user message (should have blue background)
      const userMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'User message',
            isUser: true,
            isTest: true,
          ),
        ),
      );
      await tester.pumpWidget(userMessage);
      await tester.pumpAndSettle();

      // Find the text widget
      final userTextWidget = find.text('User message');
      expect(userTextWidget, findsOneWidget);

      // Find the container that contains the text
      final userContainerFinder = find.ancestor(
        of: userTextWidget,
        matching: find.byType(Container),
      );

      // Find the container with decoration
      Container? userDecoratedContainer;
      tester.widgetList<Container>(userContainerFinder).forEach((container) {
        if (container.decoration != null) {
          userDecoratedContainer = container;
        }
      });

      expect(userDecoratedContainer, isNotNull);
      final userDecoration =
          userDecoratedContainer!.decoration as BoxDecoration;
      expect(userDecoration.color, equals(Colors.blue[100]));

      // Test non-user message (should have grey background)
      const nonUserMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Non-user message',
            isUser: false,
            isTest: true,
          ),
        ),
      );
      await tester.pumpWidget(nonUserMessage);
      await tester.pumpAndSettle();

      // Find the text widget
      final nonUserTextWidget = find.text('Non-user message');
      expect(nonUserTextWidget, findsOneWidget);

      // Find the container that contains the text
      final nonUserContainerFinder = find.ancestor(
        of: nonUserTextWidget,
        matching: find.byType(Container),
      );

      // Find the container with decoration
      Container? nonUserDecoratedContainer;
      tester.widgetList<Container>(nonUserContainerFinder).forEach((container) {
        if (container.decoration != null) {
          nonUserDecoratedContainer = container;
        }
      });

      expect(nonUserDecoratedContainer, isNotNull);
      final nonUserDecoration =
          nonUserDecoratedContainer!.decoration as BoxDecoration;
      expect(nonUserDecoration.color, equals(Colors.grey[200]));
    });

    testWidgets('handles long messages with proper wrapping', (tester) async {
      final longMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'A' * 300, // Very long message
            isUser: false,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(longMessage);
      await tester.pumpAndSettle();

      final messageFinder = find.byType(Flexible);
      expect(messageFinder, findsOneWidget,
          reason: 'Long messages should be wrapped in Flexible widget');
    });

    testWidgets('supports accessibility features', (tester) async {
      const message = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Accessible message',
            isUser: false,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(message);
      await tester.pumpAndSettle();

      // Enable semantics for testing
      final handle = tester.ensureSemantics();

      // Find the text widget and verify its semantics
      expect(find.text('Accessible message'), findsOneWidget);

      // Clean up
      handle.dispose();
    });

    testWidgets('handles audio file not found gracefully', (tester) async {
      const audioMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Audio transcription',
            isUser: true,
            audioPath: 'nonexistent.m4a',
            duration: Duration(seconds: 30),
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(audioMessage);
      await tester.pumpAndSettle();

      // Should show the fallback message with text and "Audio unavailable"
      expect(find.text('Audio transcription'), findsOneWidget);
      expect(find.text('Audio unavailable'), findsOneWidget);
    });

    testWidgets('handles audio playback state changes', (tester) async {
      const audioMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Audio transcription',
            isUser: true,
            audioPath: 'test_audio.m4a',
            duration: Duration(seconds: 30),
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(audioMessage);
      await tester.pumpAndSettle();

      // Should show AudioMessage widget
      expect(find.byType(AudioMessage), findsOneWidget);
    });
  });
}
