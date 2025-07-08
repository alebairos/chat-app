import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/screens/character_selection_screen.dart';
import '../../lib/config/character_config_manager.dart';

void main() {
  group('CharacterSelectionScreen - Ari Life Coach Tests', () {
    late CharacterConfigManager manager;

    setUp(() {
      manager = CharacterConfigManager();
      // Reset to default (Ari) before each test
      manager.setActivePersona(CharacterPersona.ariLifeCoach);
    });

    testWidgets('Should display Ari as available persona',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSelectionScreen(
            onCharacterSelected: () {},
          ),
        ),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();

      // Check if Ari is displayed
      expect(find.text('Ari - Life Coach'), findsOneWidget);
    });

    testWidgets('Should show Ari with teal avatar color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSelectionScreen(
            onCharacterSelected: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the CircleAvatar for Ari
      final ariAvatarFinder = find.descendant(
        of: find.ancestor(
          of: find.text('Ari - Life Coach'),
          matching: find.byType(Card),
        ),
        matching: find.byType(CircleAvatar),
      );

      expect(ariAvatarFinder, findsOneWidget);

      final CircleAvatar avatar = tester.widget(ariAvatarFinder);
      expect(avatar.backgroundColor, Colors.teal);
    });

    testWidgets('Should show Ari as selected by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSelectionScreen(
            onCharacterSelected: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the radio button for Ari
      final ariRadioFinder = find.descendant(
        of: find.ancestor(
          of: find.text('Ari - Life Coach'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Radio<CharacterPersona>),
      );

      expect(ariRadioFinder, findsOneWidget);

      final Radio<CharacterPersona> radio = tester.widget(ariRadioFinder);
      expect(radio.value, CharacterPersona.ariLifeCoach);
      expect(radio.groupValue, CharacterPersona.ariLifeCoach);
    });

    testWidgets('Should display Ari description correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSelectionScreen(
            onCharacterSelected: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if Ari's description is displayed
      expect(
        find.text(
            'TARS-inspired life coach combining 9 expert frameworks with intelligent brevity and adaptive engagement for evidence-based personal transformation.'),
        findsOneWidget,
      );
    });

    testWidgets('Should allow switching from Ari to Sergeant Oracle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSelectionScreen(
            onCharacterSelected: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially Ari should be selected
      expect(manager.activePersona, CharacterPersona.ariLifeCoach);

      // Find and tap on Sergeant Oracle
      final sergeantCard = find.ancestor(
        of: find.text('Sergeant Oracle'),
        matching: find.byType(Card),
      );

      await tester.tap(sergeantCard);
      await tester.pumpAndSettle();

      // Find the radio button for Sergeant Oracle and verify it's selected
      final sergeantRadioFinder = find.descendant(
        of: find.ancestor(
          of: find.text('Sergeant Oracle'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Radio<CharacterPersona>),
      );

      final Radio<CharacterPersona> radio = tester.widget(sergeantRadioFinder);
      expect(radio.groupValue, CharacterPersona.sergeantOracle);
    });

    testWidgets('Should call onCharacterSelected when Continue is pressed',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSelectionScreen(
            onCharacterSelected: () {
              callbackCalled = true;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the Continue button
      final continueButton = find.text('Continue');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(callbackCalled, true);
    });

    testWidgets('Should update config manager when Continue is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSelectionScreen(
            onCharacterSelected: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Sergeant Oracle
      final sergeantCard = find.ancestor(
        of: find.text('Sergeant Oracle'),
        matching: find.byType(Card),
      );

      await tester.tap(sergeantCard);
      await tester.pumpAndSettle();

      // Press Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify the config manager was updated
      expect(manager.activePersona, CharacterPersona.sergeantOracle);
    });

    testWidgets('Should show card border for selected persona',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: Colors.blue),
          home: CharacterSelectionScreen(
            onCharacterSelected: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Ari's card (should be selected by default)
      final ariCard = find.ancestor(
        of: find.text('Ari - Life Coach'),
        matching: find.byType(Card),
      );

      expect(ariCard, findsOneWidget);

      final Card card = tester.widget(ariCard);
      final RoundedRectangleBorder shape = card.shape as RoundedRectangleBorder;
      expect(shape.side.color, Colors.blue); // Theme primary color
      expect(shape.side.width, 2);
    });

    testWidgets('Should display correct avatar initial for Ari',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSelectionScreen(
            onCharacterSelected: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Ari's avatar and check the initial
      final ariAvatarFinder = find.descendant(
        of: find.ancestor(
          of: find.text('Ari - Life Coach'),
          matching: find.byType(Card),
        ),
        matching: find.byType(CircleAvatar),
      );

      expect(ariAvatarFinder, findsOneWidget);

      // Check if the avatar contains the correct initial
      expect(
        find.descendant(
          of: ariAvatarFinder,
          matching: find.text('A'),
        ),
        findsOneWidget,
      );
    });
  });
}
