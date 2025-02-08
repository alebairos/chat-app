import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/chat_message.dart';
import 'helpers/test_messages.dart';

void main() {
  group('ChatMessage Widget', () {
    late Widget testWidget;

    setUp(() {
      testWidget = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: TestMessage.formattedMessage,
            isUser: false,
          ),
        ),
      );
    });

    testWidgets('renders formatted text correctly', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(); // Wait for all animations

      // Verify text content is present
      expect(find.textContaining(TestMessage.gesture), findsOneWidget);
      expect(find.textContaining(TestMessage.greeting), findsOneWidget);
      expect(find.textContaining(TestMessage.boldText), findsOneWidget);
      expect(find.textContaining(TestMessage.italicText), findsOneWidget);
      expect(find.textContaining(TestMessage.emoji), findsOneWidget);
    });

    testWidgets('applies correct text styling', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Debug: Print all text in the widget tree
      final texts = tester.widgetList<RichText>(find.byType(RichText));
      for (final text in texts) {
        print('Found RichText: ${text.text}');
      }

      // Find the specific RichText containing our bold text
      final richTextWithBold = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((widget) => (widget.text as TextSpan)
              .toPlainText()
              .contains(TestMessage.boldText));

      final textSpan = richTextWithBold.text as TextSpan;

      // Verify bold styling
      final hasBoldText = textSpan.visitChildren((span) {
        if (span is TextSpan &&
            span.text?.contains(TestMessage.boldText) == true &&
            span.style?.fontWeight == FontWeight.bold) {
          return false; // Stop visiting when found
        }
        return true; // Continue visiting
      });

      expect(hasBoldText, isFalse, reason: 'Should find bold text');

      // Verify italic styling
      final hasItalicText = textSpan.visitChildren((span) {
        if (span is TextSpan &&
            span.text?.contains(TestMessage.italicText) == true &&
            span.style?.fontStyle == FontStyle.italic) {
          return false; // Stop visiting when found
        }
        return true; // Continue visiting
      });

      expect(hasItalicText, isFalse, reason: 'Should find italic text');
    });
  });
}
