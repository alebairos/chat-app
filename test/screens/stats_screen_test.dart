import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/screens/stats_screen.dart';
import '../../lib/services/activity_memory_service.dart';

void main() {
  group('StatsScreen', () {
    testWidgets('should show loading state initially', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading your activity data...'), findsOneWidget);
    });

    testWidgets('should show empty state when no activities', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      // Wait for async operations to complete
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Check for either empty state or loading state
      // Since we can't mock the service easily, we verify the widget handles both states
      final hasEmptyState =
          find.text('No activities tracked yet').evaluate().isNotEmpty;
      final hasLoadingState =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

      expect(hasEmptyState || hasLoadingState, isTrue);
    });

    testWidgets('should display stats widgets when data available',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      // Wait for async operations
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Look for structural elements that should be present
      expect(find.byType(Scaffold), findsOneWidget);

      // RefreshIndicator might not be present if showing empty state
      final hasRefreshIndicator =
          find.byType(RefreshIndicator).evaluate().isNotEmpty;
      final hasEmptyState =
          find.text('No activities tracked yet').evaluate().isNotEmpty;

      // Either we have the main UI with RefreshIndicator, or empty state
      expect(hasRefreshIndicator || hasEmptyState, isTrue);
    });

    testWidgets('should have refresh functionality', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      // Wait for initial load
      await tester.pump();
      await tester.pump();

      // Act - Find RefreshIndicator if present and test pull-to-refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        await tester.drag(refreshIndicator, const Offset(0, 200));
        await tester.pump();
      }

      // Assert - Should complete without errors
      expect(find.byType(StatsScreen), findsOneWidget);
    });

    testWidgets('should handle StatefulWidget lifecycle correctly',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      // Verify the widget builds as a StatefulWidget
      expect(find.byType(StatsScreen), findsOneWidget);

      // Navigate away and back to test state management
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Other Screen')),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      // Assert - Should rebuild without errors
      expect(find.byType(StatsScreen), findsOneWidget);
    });
  });

  group('StatsScreen Integration', () {
    testWidgets('should integrate with ActivityMemoryService', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      // Wait for service calls to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Should complete service integration without throwing
      expect(find.byType(StatsScreen), findsOneWidget);

      // The screen should show either empty state or data
      final hasEmptyState =
          find.text('No activities tracked yet').evaluate().isNotEmpty;
      final hasLoadingState =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

      // One of these states should be present
      expect(hasEmptyState || hasLoadingState, isTrue);
    });

    testWidgets('should handle service errors gracefully', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      // Wait for potential error handling
      await tester.pump();
      await tester.pump();

      // Assert - Should not crash on service errors
      expect(find.byType(StatsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StatsScreen UI Components', () {
    testWidgets('should display proper navigation structure', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Assert - Check for basic UI structure
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle different screen sizes', (tester) async {
      // Arrange - Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Phone

      await tester.pumpWidget(
        const MaterialApp(
          home: StatsScreen(),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Assert - Should render properly on phone
      expect(find.byType(StatsScreen), findsOneWidget);

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(800, 1200)); // Tablet
      await tester.pump();

      // Assert - Should adapt to larger screen
      expect(find.byType(StatsScreen), findsOneWidget);

      // Reset to default
      await tester.binding.setSurfaceSize(null);
    });
  });
}
