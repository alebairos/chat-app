import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/config/character_config_manager.dart';
import 'package:character_ai_clone/config/config_loader.dart';
import 'package:character_ai_clone/widgets/chat_app_bar.dart';

void main() {
  group('Persona UI Tests', () {
    testWidgets('CustomChatAppBar shows correct persona',
        (WidgetTester tester) async {
      // Set Ari as active persona
      final configLoader = ConfigLoader();
      configLoader.setActivePersona('ariLifeCoach');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const CustomChatAppBar(),
          ),
        ),
      );

      // Verify that Ari is displayed
      expect(find.text('Ari - Life Coach'), findsOneWidget);

      // Verify that Sergeant Oracle is NOT displayed
      expect(find.text('Sergeant Oracle'), findsNothing);
    });

    testWidgets('CustomChatAppBar shows correct persona for Sergeant Oracle',
        (WidgetTester tester) async {
      // Set Sergeant Oracle as active persona
      final configLoader = ConfigLoader();
      configLoader.setActivePersona('sergeantOracle');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const CustomChatAppBar(),
          ),
        ),
      );

      // Verify that Sergeant Oracle is displayed
      expect(find.text('Sergeant Oracle'), findsOneWidget);

      // Verify that Ari is NOT displayed
      expect(find.text('Ari - Life Coach'), findsNothing);
    });
  });
}
