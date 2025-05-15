import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/widgets/chat_input.dart';

void main() {
  group('ChatInput Widget', () {
    late TextEditingController controller;
    late bool sendPressed;

    setUp(() {
      controller = TextEditingController();
      sendPressed = false;
    });

    tearDown(() {
      controller.dispose();
    });

    Future<void> pumpChatInput(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatInput(
            controller: controller,
            onSend: () {
              if (controller.text.trim().isNotEmpty) {
                sendPressed = true;
              }
            },
            onSendAudio: (path, duration) {
              // Audio callback required by the widget but not tested
            },
          ),
        ),
      ));
    }

    testWidgets('renders correctly', (tester) async {
      await pumpChatInput(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byType(IconButton),
          findsNWidgets(2)); // Send and audio record buttons
    });

    testWidgets('can enter text', (tester) async {
      await pumpChatInput(tester);

      await tester.enterText(find.byType(TextField), 'Test message');
      expect(controller.text, equals('Test message'));
    });

    testWidgets('triggers onSend when send button is pressed with text',
        (tester) async {
      await pumpChatInput(tester);

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();

      expect(sendPressed, isTrue);
    });

    testWidgets('clears text field after sending', (tester) async {
      await pumpChatInput(tester);

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();

      expect(controller.text, isEmpty);
    });

    testWidgets('handles empty text gracefully', (tester) async {
      await pumpChatInput(tester);

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();

      expect(sendPressed, isFalse);
    });

    testWidgets('handles whitespace-only text gracefully', (tester) async {
      await pumpChatInput(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();

      expect(sendPressed, isFalse);
    });

    testWidgets('maintains text field state between rebuilds', (tester) async {
      await pumpChatInput(tester);

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pump();

      // Rebuild widget
      await pumpChatInput(tester);

      expect(find.text('Test message'), findsOneWidget);
    });
  });
}
