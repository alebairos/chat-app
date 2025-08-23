import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_personas_app/widgets/chat_message.dart';

void main() {
  group('ChatMessage Persona Icons', () {
    testWidgets('displays correct icon for Ari Life Coach',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: 'Test message from Ari',
              isUser: false,
              personaKey: 'ariLifeCoach',
              personaDisplayName: 'Ari Life Coach',
            ),
          ),
        ),
      );

      // Verify psychology icon is displayed
      expect(find.byIcon(Icons.psychology), findsOneWidget);

      // Verify teal color is used
      final CircleAvatar avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatar.backgroundColor, Colors.teal);
    });

    testWidgets('displays correct icon for Sergeant Oracle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: 'Test message from Sergeant',
              isUser: false,
              personaKey: 'sergeantOracle',
              personaDisplayName: 'Sergeant Oracle',
            ),
          ),
        ),
      );

      // Verify military_tech icon is displayed
      expect(find.byIcon(Icons.military_tech), findsOneWidget);

      // Verify deep purple color is used
      final CircleAvatar avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatar.backgroundColor, Colors.deepPurple);
    });

    testWidgets('displays correct icon for I-There Clone',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: 'Test message from I-There',
              isUser: false,
              personaKey: 'iThereClone',
              personaDisplayName: 'I-There',
            ),
          ),
        ),
      );

      // Verify face icon is displayed
      expect(find.byIcon(Icons.face), findsOneWidget);

      // Verify blue color is used
      final CircleAvatar avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatar.backgroundColor, Colors.blue);
    });

    testWidgets('displays default Sergeant icon when persona is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: 'Test message without persona',
              isUser: false,
            ),
          ),
        ),
      );

      // Verify military_tech icon is displayed (default)
      expect(find.byIcon(Icons.military_tech), findsOneWidget);

      // Verify deep purple color is used (default)
      final CircleAvatar avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatar.backgroundColor, Colors.deepPurple);
    });

    testWidgets('does not display avatar for user messages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: 'Test user message',
              isUser: true,
              personaKey: 'ariLifeCoach',
            ),
          ),
        ),
      );

      // Verify no avatar is displayed for user messages
      expect(find.byType(CircleAvatar), findsNothing);
    });
  });
}
