import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/widgets/stats/stats_summary.dart';

void main() {
  group('StatsSummary', () {
    testWidgets('should display summary information correctly', (tester) async {
      // Arrange
      const summary = StatsSummary(
        totalActivities: 5,
        lastActivityTime: '2 hours ago',
        activeDimensions: ['Physical Health', 'Work & Management'],
        period: 'today',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: summary,
          ),
        ),
      );

      // Assert
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('5 activities detected'), findsOneWidget);
      expect(find.text('Last activity: 2 hours ago'), findsOneWidget);
      expect(find.text('Dimensions: Physical Health, Work & Management'),
          findsOneWidget);
    });

    testWidgets('should handle different periods correctly', (tester) async {
      final periods = [
        ('today', 'Today'),
        ('this_week', 'This Week'),
        ('this_month', 'This Month'),
        ('custom', 'Activity Summary'),
      ];

      for (final (period, expected) in periods) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatsSummary(
                totalActivities: 3,
                lastActivityTime: '1 hour ago',
                activeDimensions: const ['Test'],
                period: period,
              ),
            ),
          ),
        );

        // Assert period title is displayed correctly
        expect(find.text(expected), findsOneWidget);
      }
    });

    testWidgets('should handle empty last activity time', (tester) async {
      // Arrange
      const summary = StatsSummary(
        totalActivities: 2,
        lastActivityTime: '',
        activeDimensions: ['Physical Health'],
        period: 'today',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: summary,
          ),
        ),
      );

      // Assert - Should not show last activity time when empty
      expect(find.text('2 activities detected'), findsOneWidget);
      expect(find.textContaining('Last activity:'), findsNothing);
    });

    testWidgets('should handle empty dimensions list', (tester) async {
      // Arrange
      const summary = StatsSummary(
        totalActivities: 1,
        lastActivityTime: '30 minutes ago',
        activeDimensions: [],
        period: 'today',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: summary,
          ),
        ),
      );

      // Assert - Should not show dimensions when empty
      expect(find.text('1 activities detected'), findsOneWidget);
      expect(find.textContaining('Dimensions:'), findsNothing);
    });

    testWidgets('should display proper visual structure', (tester) async {
      // Arrange
      const summary = StatsSummary(
        totalActivities: 3,
        lastActivityTime: '1 hour ago',
        activeDimensions: ['Test Dimension'],
        period: 'today',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: summary,
          ),
        ),
      );

      // Assert - Check for key UI components
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Icon),
          findsAtLeastNWidgets(2)); // Title icon + activity icons
      expect(find.byType(Row), findsAtLeastNWidgets(1)); // For layout rows
    });

    testWidgets('should handle zero activities', (tester) async {
      // Arrange
      const summary = StatsSummary(
        totalActivities: 0,
        lastActivityTime: '',
        activeDimensions: [],
        period: 'today',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: summary,
          ),
        ),
      );

      // Assert
      expect(find.text('0 activities detected'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('should display multiple dimensions correctly', (tester) async {
      // Arrange
      const summary = StatsSummary(
        totalActivities: 8,
        lastActivityTime: '15 minutes ago',
        activeDimensions: [
          'Physical Health',
          'Mental Health',
          'Work & Management',
          'Relationships'
        ],
        period: 'this_week',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: summary,
          ),
        ),
      );

      // Assert
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('8 activities detected'), findsOneWidget);
      expect(
        find.text(
            'Dimensions: Physical Health, Mental Health, Work & Management, Relationships'),
        findsOneWidget,
      );
    });
  });
}
