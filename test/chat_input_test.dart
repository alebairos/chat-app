import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/chat_input.dart';

void main() {
  group('ChatInput Widget', () {
    late TextEditingController controller;
    late bool sendPressed;
    late String? audioPath;
    late Duration? audioDuration;

    setUp(() {
      controller = TextEditingController();
      sendPressed = false;
      audioPath = null;
      audioDuration = null;
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
              audioPath = path;
              audioDuration = duration;
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

    testWidgets('has correct keyboard configuration for special characters',
        (tester) async {
      await pumpChatInput(tester);

      final TextField textField =
          tester.widget<TextField>(find.byType(TextField));

      // Verify keyboard configuration
      expect(textField.keyboardType, equals(TextInputType.multiline));
      expect(
          textField.textCapitalization, equals(TextCapitalization.sentences));
      expect(textField.enableSuggestions, isTrue);
      expect(textField.enableIMEPersonalizedLearning, isTrue);
      expect(textField.textInputAction, equals(TextInputAction.newline));
      expect(textField.maxLines, isNull);
      expect(textField.style?.locale, equals(const Locale('pt', 'BR')));
      expect(textField.keyboardAppearance, equals(Brightness.light));
      expect(textField.autocorrect, isTrue);
      expect(textField.smartDashesType, equals(SmartDashesType.enabled));
      expect(textField.smartQuotesType, equals(SmartQuotesType.enabled));
      expect(textField.strutStyle?.height, equals(1.2));
      expect(textField.strutStyle?.leading, equals(0.5));
    });
  });
}
