import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/screens/onboarding/name_setup_screen.dart';

/// FT-219: Tests for name validation UI glitch fix
///
/// These tests verify that the name setup screen doesn't show
/// error messages immediately and follows proper Flutter lifecycle.
void main() {
  group('FT-219: Name Validation UI Fix', () {
    testWidgets('should not show error message on initial load',
        (tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: NameSetupScreen(
            onContinue: () {},
          ),
        ),
      );

      // Verify no error message is shown initially
      expect(find.text('Name cannot be empty'), findsNothing);

      // Verify the text field exists and is empty
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Verify continue button exists but is disabled
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull); // Button should be disabled
    });

    testWidgets('should show error when user enters invalid input',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NameSetupScreen(
            onContinue: () {},
          ),
        ),
      );

      // Find the text field
      final textField = find.byType(TextField);

      // Enter empty spaces (invalid input)
      await tester.enterText(textField, '   ');
      await tester.pump();

      // Now error should appear
      expect(find.text('Name cannot be empty'), findsOneWidget);

      // Button should still be disabled
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('should enable button when valid name is entered',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NameSetupScreen(
            onContinue: () {},
          ),
        ),
      );

      final textField = find.byType(TextField);

      // Enter valid name
      await tester.enterText(textField, 'John Doe');
      await tester.pump();

      // No error should be shown
      expect(find.text('Name cannot be empty'), findsNothing);

      // Button should be enabled
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should show error for malicious input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NameSetupScreen(
            onContinue: () {},
          ),
        ),
      );

      final textField = find.byType(TextField);

      // Enter malicious input
      await tester.enterText(textField, '<script>alert("xss")</script>');
      await tester.pump();

      // Error should appear
      expect(find.text('Name contains invalid characters'), findsOneWidget);

      // Button should be disabled
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('should handle real-time validation correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NameSetupScreen(
            onContinue: () {},
          ),
        ),
      );

      final textField = find.byType(TextField);

      // Initially no error (empty field but no validation yet)
      expect(find.text('Name cannot be empty'), findsNothing);

      // Enter whitespace (triggers validation, should show error)
      await tester.enterText(textField, '   ');
      await tester.pump();
      expect(find.text('Name cannot be empty'), findsOneWidget);

      // Type valid input (error should disappear)
      await tester.enterText(textField, 'Alice');
      await tester.pump();
      expect(find.text('Name cannot be empty'), findsNothing);

      // Enter invalid characters (should show different error)
      await tester.enterText(textField, 'Alice<script>');
      await tester.pump();
      expect(find.text('Name contains invalid characters'), findsOneWidget);

      // Fix to valid input again
      await tester.enterText(textField, 'Bob Smith');
      await tester.pump();
      expect(find.text('Name contains invalid characters'), findsNothing);
      expect(find.text('Name cannot be empty'), findsNothing);
    });

    testWidgets('should handle button state transitions correctly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NameSetupScreen(
            onContinue: () {},
          ),
        ),
      );

      final textField = find.byType(TextField);
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');

      // Initially disabled
      var button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);

      // Enter valid name - should enable
      await tester.enterText(textField, 'Valid Name');
      await tester.pump();
      button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNotNull);

      // Clear field - should disable
      await tester.enterText(textField, '');
      await tester.pump();
      button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);

      // Enter invalid characters - should disable
      await tester.enterText(textField, 'Invalid<script>');
      await tester.pump();
      button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);

      // Fix to valid name - should enable
      await tester.enterText(textField, 'Valid Name Again');
      await tester.pump();
      button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should not call setState during initState', (tester) async {
      // This test verifies that no exceptions are thrown during widget initialization
      // which would happen if setState was called during initState

      await tester.pumpWidget(
        MaterialApp(
          home: NameSetupScreen(
            onContinue: () {},
          ),
        ),
      );

      // Verify widget is properly initialized without errors
      expect(find.byType(NameSetupScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
    });

    testWidgets('should preserve skip functionality', (tester) async {
      bool skipCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: NameSetupScreen(
            onContinue: () {
              skipCalled = true;
            },
          ),
        ),
      );

      // Find and tap skip button
      final skipButton = find.widgetWithText(TextButton, 'Skip for now');
      expect(skipButton, findsOneWidget);

      await tester.tap(skipButton);
      await tester.pump();

      // Verify skip callback was called
      expect(skipCalled, true);
    });
  });
}
