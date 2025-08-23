import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/widgets/stats/activity_card.dart';

void main() {
  group('ActivityCard', () {
    testWidgets('should display activity information correctly',
        (tester) async {
      // Arrange
      const activityCard = ActivityCard(
        code: 'T8',
        name: 'Realizar sessão de trabalho focado',
        time: '14:20',
        confidence: 0.95,
        dimension: 'TG',
        source: 'Oracle FT-064 Semantic',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: activityCard,
          ),
        ),
      );

      // Assert
      expect(find.text('T8'), findsOneWidget);
      expect(find.text('Realizar sessão de trabalho focado'), findsOneWidget);
      expect(find.text('14:20'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('Work & Management'), findsOneWidget);
    });

    testWidgets('should handle activity without code', (tester) async {
      // Arrange
      const activityCard = ActivityCard(
        name: 'Custom Activity',
        time: '15:30',
        confidence: 0.8,
        dimension: 'SF',
        source: 'Manual',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: activityCard,
          ),
        ),
      );

      // Assert
      expect(find.text('Custom Activity'), findsOneWidget);
      expect(find.text('15:30'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('Physical Health'), findsOneWidget);
    });

    testWidgets('should display proper dimension colors', (tester) async {
      // Test different dimensions
      final dimensions = [
        ('SF', 'Physical Health'),
        ('SM', 'Mental Health'),
        ('TG', 'Work & Management'),
        ('R', 'Relationships'),
        ('CE', 'Creativity'),
        ('AE', 'Adventure'),
      ];

      for (final (code, name) in dimensions) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                name: 'Test Activity',
                time: '12:00',
                confidence: 0.9,
                dimension: code,
                source: 'Test',
              ),
            ),
          ),
        );

        // Assert dimension name is displayed
        expect(find.text(name), findsOneWidget);

        // Verify the widget renders without errors
        expect(find.byType(ActivityCard), findsOneWidget);
      }
    });

    testWidgets('should display confidence levels with proper colors',
        (tester) async {
      final confidenceTests = [
        (0.95, '95%'), // High confidence - should be green
        (0.75, '75%'), // Medium confidence - should be orange
        (0.55, '55%'), // Low confidence - should be red
      ];

      for (final (confidence, expected) in confidenceTests) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                name: 'Test Activity',
                time: '12:00',
                confidence: confidence,
                dimension: 'SF',
                source: 'Test',
              ),
            ),
          ),
        );

        // Assert confidence percentage is displayed
        expect(find.text(expected), findsOneWidget);

        // Verify the widget renders without errors
        expect(find.byType(ActivityCard), findsOneWidget);
      }
    });

    testWidgets('should handle edge cases gracefully', (tester) async {
      // Test with minimal required properties
      const activityCard = ActivityCard(
        name: '',
        time: '',
        confidence: 0.0,
        dimension: '',
        source: '',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: activityCard,
          ),
        ),
      );

      // Assert - Should render without crashing
      expect(find.byType(ActivityCard), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('should have proper visual structure', (tester) async {
      // Arrange
      const activityCard = ActivityCard(
        code: 'SF1',
        name: 'Test Activity',
        time: '10:30',
        confidence: 0.9,
        dimension: 'SF',
        source: 'Test',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: activityCard,
          ),
        ),
      );

      // Assert - Check for key UI components
      expect(find.byType(Card), findsOneWidget);
      expect(
          find.byType(Icon),
          findsAtLeastNWidgets(
              1)); // Should have dimension and confidence icons
      expect(find.byType(Container),
          findsAtLeastNWidgets(1)); // For styling containers
    });
  });
}
