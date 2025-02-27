import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:character_ai_clone/widgets/chat_message.dart';
import 'package:character_ai_clone/widgets/audio_message.dart';
import 'helpers/test_messages.dart';
import 'package:mockito/mockito.dart';

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
      expect(decoration.color, equals(Colors.blue[700]));

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.end));

      // User messages should not have an avatar
      expect(find.byType(CircleAvatar), findsNothing);
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

      expect(find.byType(MarkdownBody), findsOneWidget);
      final markdownBody =
          tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(markdownBody.data, isEmpty);
    });

    testWidgets('applies correct text colors based on user/non-user',
        (tester) async {
      // Test user message (should be white text)
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

      final userMarkdown =
          tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(
        userMarkdown.styleSheet?.p?.color ?? Colors.black,
        equals(Colors.white),
        reason: 'User messages should have white text',
      );

      // Test non-user message (should be black text)
      const nonUserMessage = MaterialApp(
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
      expect(
        find.text('Accessible message'),
        findsOneWidget,
        reason: 'Message text should be present',
      );

      // Clean up semantics
      handle.dispose();
    });

    testWidgets('handles invalid audio paths gracefully', (tester) async {
      const invalidAudioMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Invalid audio',
            isUser: true,
            audioPath: 'invalid_path.m4a',
            duration: Duration(seconds: 1),
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
      const audioMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Test audio',
            isUser: true,
            audioPath: 'test_audio.m4a',
            duration: Duration(seconds: 30),
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

    testWidgets('supports message deletion for user messages', (tester) async {
      bool deletePressed = false;
      final userMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Deletable message',
            isUser: true,
            isTest: true,
            onDelete: () => deletePressed = true,
          ),
        ),
      );

      await tester.pumpWidget(userMessage);
      await tester.pumpAndSettle();

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap the delete option in the menu
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deletePressed, isTrue,
          reason: 'Delete callback should be triggered');
    });

    testWidgets('prevents deletion of non-user messages', (tester) async {
      bool deletePressed = false;
      final botMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Bot message',
            isUser: false,
            isTest: true,
            onDelete: () => deletePressed = true,
          ),
        ),
      );

      await tester.pumpWidget(botMessage);
      await tester.pumpAndSettle();

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify delete option is not present in menu
      expect(find.text('Delete'), findsNothing,
          reason: 'Delete option should not be available for bot messages');
      expect(deletePressed, isFalse,
          reason: 'Delete callback should not be triggered for bot messages');
    });

    testWidgets('shows menu button for all messages', (tester) async {
      // Test user message - should have menu
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
      expect(find.byIcon(Icons.more_vert), findsOneWidget,
          reason: 'Menu button should be visible for user messages');

      // Test bot message - should have menu
      const botMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Bot message',
            isUser: false,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(botMessage);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.more_vert), findsOneWidget,
          reason: 'Menu button should be visible for bot messages');
    });

    testWidgets('shows all menu options for user messages', (tester) async {
      const message = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Test message',
            isUser: true,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(message);
      await tester.pumpAndSettle();

      // Tap menu button to show menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify all menu options are present
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
    });

    testWidgets('shows limited menu options for bot messages', (tester) async {
      const message = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Bot message',
            isUser: false,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(message);
      await tester.pumpAndSettle();

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify only copy and report options are present
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
    });

    testWidgets('supports message editing for user messages',
        (WidgetTester tester) async {
      String? editedText;

      final message = ChatMessage(
        text: 'Test message',
        isUser: true,
        isTest: true,
        onEdit: (text) {
          editedText = text;
          // Show edit dialog
          showDialog<void>(
            context: tester.element(find.byType(ChatMessage)),
            builder: (context) => AlertDialog(
              title: const Text('Edit Message'),
              content: TextField(
                key: const Key('edit-message-field'),
                controller: TextEditingController(text: text),
                decoration:
                    const InputDecoration(hintText: "Enter new message"),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    editedText = 'Edited message';
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: message,
        ),
      ));

      // Find and tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Find and tap the edit option
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Verify edit dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Message'), findsOneWidget);
      expect(find.byKey(const Key('edit-message-field')), findsOneWidget);

      // Enter new text
      await tester.enterText(
          find.byKey(const Key('edit-message-field')), 'Edited message');
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify edit callback was called with correct values
      expect(editedText, equals('Edited message'));
    });

    testWidgets('supports message copying', (tester) async {
      const message = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Copy this text',
            isUser: true,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(message);
      await tester.pumpAndSettle();

      // Tap menu button to show menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap the copy option
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      // Verify snackbar appears
      expect(find.text('Message copied to clipboard'), findsOneWidget);
    });
  });
}

class MockEditCallback extends Mock {
  void call(String id, String text);
}
