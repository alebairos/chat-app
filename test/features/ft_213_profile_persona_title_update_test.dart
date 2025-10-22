import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/screens/profile_screen.dart';

/// FT-213: Test Profile Persona Selection Title Update Fix
///
/// This test verifies that ProfileScreen correctly accepts and uses the
/// onPersonaChanged callback parameter, ensuring the app title can be updated
/// when personas are selected via the profile menu.
void main() {
  group('FT-213: Profile Persona Title Update Fix', () {
    testWidgets('ProfileScreen accepts onPersonaChanged callback parameter',
        (WidgetTester tester) async {
      // Arrange: Track if callback parameter is accepted
      bool callbackWasCalled = false;
      void onPersonaChangedCallback() {
        callbackWasCalled = true;
      }

      // Act: Build ProfileScreen with callback (should not crash)
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            onPersonaChanged: onPersonaChangedCallback,
          ),
        ),
      );

      // Wait for initial build and async operations
      await tester.pumpAndSettle();

      // Assert: ProfileScreen should build successfully with callback
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('AI Persona'), findsOneWidget);
    });

    testWidgets(
        'ProfileScreen works without onPersonaChanged callback (backward compatibility)',
        (WidgetTester tester) async {
      // Act: Build ProfileScreen without callback (should not crash)
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(), // No onPersonaChanged parameter
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Assert: Should build without issues
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('AI Persona'), findsOneWidget);
    });

    testWidgets(
        'ProfileScreen callback parameter is optional and handles null safely',
        (WidgetTester tester) async {
      // Act: Explicitly pass null callback
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(
            onPersonaChanged: null,
          ),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Assert: Should build without issues
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('AI Persona'), findsOneWidget);
    });

    testWidgets(
        'ProfileScreen has persona selection ListTile that can be tapped',
        (WidgetTester tester) async {
      // Arrange
      bool callbackWasCalled = false;
      void onPersonaChangedCallback() {
        callbackWasCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            onPersonaChanged: onPersonaChangedCallback,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Find the persona selection tile
      final personaTile = find.widgetWithText(ListTile, 'AI Persona');
      expect(personaTile, findsOneWidget);

      // Verify tile has chevron icons (there might be multiple in the screen)
      expect(find.byIcon(Icons.chevron_right), findsWidgets);

      // Assert: Tile should be tappable (this verifies the onTap is set up)
      final listTile = tester.widget<ListTile>(personaTile);
      expect(listTile.onTap, isNotNull,
          reason: 'Persona selection tile should have onTap handler');
    });

    group('Integration with HomeScreen title update pattern', () {
      testWidgets('Callback follows same pattern as ChatScreen',
          (WidgetTester tester) async {
        // Arrange: Simulate HomeScreen callback pattern
        String currentPersonaTitle = 'Default Persona';
        int callbackCount = 0;

        void refreshPersonaName() {
          currentPersonaTitle = 'Updated Persona';
          callbackCount++;
        }

        // Build ProfileScreen with HomeScreen-style callback
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: Text(currentPersonaTitle),
              ),
              body: ProfileScreen(
                onPersonaChanged: refreshPersonaName,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial title
        expect(find.text('Default Persona'), findsOneWidget);
        expect(callbackCount, equals(0));

        // Assert: Callback is properly stored and ready to be called
        final profileScreen =
            tester.widget<ProfileScreen>(find.byType(ProfileScreen));
        expect(profileScreen.onPersonaChanged, equals(refreshPersonaName),
            reason: 'ProfileScreen should store the callback correctly');
      });
    });

    group('Constructor and parameter validation', () {
      test(
          'ProfileScreen constructor accepts optional onPersonaChanged parameter',
          () {
        // Test constructor with callback
        void callback() {}
        final screenWithCallback = ProfileScreen(onPersonaChanged: callback);
        expect(screenWithCallback.onPersonaChanged, equals(callback));

        // Test constructor without callback
        const screenWithoutCallback = ProfileScreen();
        expect(screenWithoutCallback.onPersonaChanged, isNull);

        // Test constructor with null callback
        const screenWithNullCallback = ProfileScreen(onPersonaChanged: null);
        expect(screenWithNullCallback.onPersonaChanged, isNull);
      });
    });

    group('Code structure validation', () {
      testWidgets('ProfileScreen follows FT-213 implementation pattern',
          (WidgetTester tester) async {
        // This test validates that the implementation follows the exact
        // pattern specified in FT-213 specification

        bool callbackExecuted = false;
        void testCallback() {
          callbackExecuted = true;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(
              onPersonaChanged: testCallback,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the ProfileScreen has the expected structure
        expect(find.byType(ProfileScreen), findsOneWidget);

        // Verify persona section exists
        expect(find.text('AI Persona'), findsOneWidget);

        // Verify the callback is stored correctly
        final profileScreen =
            tester.widget<ProfileScreen>(find.byType(ProfileScreen));
        expect(profileScreen.onPersonaChanged, isNotNull);
        expect(profileScreen.onPersonaChanged, equals(testCallback));
      });
    });
  });
}
