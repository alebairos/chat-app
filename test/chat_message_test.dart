import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../lib/widgets/chat_message.dart';
import '../lib/widgets/audio_message.dart';
import 'helpers/test_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatMessage Widget', () {
    late Widget testWidget;

    setUp(() {
      testWidget = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: TestMessage.formattedMessage,
            isUser: false,
            isTest: true, // Use test mode to avoid loading network images
          ),
        ),
      );
    });

    testWidgets('renders formatted text correctly', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Find markdown text
      final markdownFinder = find.byType(MarkdownBody);
      expect(markdownFinder, findsOneWidget);

      // Verify text content through markdown
      final markdownBody = tester.widget<MarkdownBody>(markdownFinder);
      expect(markdownBody.data, contains(TestMessage.gesture));
      expect(markdownBody.data, contains(TestMessage.greeting));
      expect(markdownBody.data, contains(TestMessage.boldText));
      expect(markdownBody.data, contains(TestMessage.italicText));
      expect(markdownBody.data, contains(TestMessage.emoji));
    });

    testWidgets('applies correct text styling', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Find markdown text
      final markdownFinder = find.byType(MarkdownBody);
      expect(markdownFinder, findsOneWidget);

      // Verify markdown formatting
      final markdownBody = tester.widget<MarkdownBody>(markdownFinder);
      expect(markdownBody.data, contains('**${TestMessage.boldText}**'),
          reason: 'Text should contain bold markdown syntax');
      expect(markdownBody.data, contains('_${TestMessage.italicText}_'),
          reason: 'Text should contain italic markdown syntax');
    });

    testWidgets('renders user message correctly', (tester) async {
      final userMessage = MaterialApp(
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

      // User messages should be blue and aligned to the right
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Container),
              matching: find.byWidgetPredicate(
                (widget) => widget is Container && widget.decoration != null,
              ),
            )
            .last,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.blue));

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.end));

      // User messages should not have an avatar
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('renders audio message correctly', (tester) async {
      final audioMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Audio transcription',
            isUser: true,
            audioPath: 'test_audio.m4a',
            duration: const Duration(seconds: 30),
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
      expect(audioWidget.duration, equals(const Duration(seconds: 30)));
      expect(audioWidget.transcription, equals('Audio transcription'));
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
      final emptyMessage = MaterialApp(
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

      expect(find.byType(MarkdownBody), findsOneWidget);
      final markdownBody =
          tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(markdownBody.data, isEmpty);
    });

    testWidgets('applies correct text colors based on user/non-user',
        (tester) async {
      // Test user message (should be white text)
      final userMessage = MaterialApp(
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

      final userMarkdown =
          tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(
        userMarkdown.styleSheet?.p?.color ?? Colors.black,
        equals(Colors.white),
        reason: 'User messages should have white text',
      );

      // Test non-user message (should be black text)
      final nonUserMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Bot message',
            isUser: false,
            isTest: true,
          ),
        ),
      );
      await tester.pumpWidget(nonUserMessage);
      await tester.pumpAndSettle();

      final nonUserMarkdown =
          tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(
        nonUserMarkdown.styleSheet?.p?.color ?? Colors.white,
        equals(Colors.black),
        reason: 'Non-user messages should have black text',
      );
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
      final message = MaterialApp(
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

      final semantics = tester.getSemantics(find.byType(MarkdownBody));
      expect(
        semantics.label,
        contains('Accessible message'),
        reason: 'Message should be accessible to screen readers',
      );
    });

    testWidgets('handles invalid audio paths gracefully', (tester) async {
      final invalidAudioMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Invalid audio',
            isUser: true,
            audioPath: 'invalid_path.m4a',
            duration: const Duration(seconds: 1),
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(invalidAudioMessage);
      await tester.pumpAndSettle();

      // Should still render without crashing
      expect(find.byType(AudioMessage), findsOneWidget);
      expect(find.text('Invalid audio'), findsOneWidget);
    });

    testWidgets('audio player controls are responsive', (tester) async {
      final audioMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Test audio',
            isUser: true,
            audioPath: 'test_audio.m4a',
            duration: const Duration(seconds: 30),
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(audioMessage);
      await tester.pumpAndSettle();

      // Verify play button is present and tappable
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      // Verify duration is displayed correctly
      expect(find.text('0:30'), findsOneWidget);
    });
  });
}
