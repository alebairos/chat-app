import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/widgets/stats/activity_card.dart';
import 'package:ai_personas_app/services/dimension_display_service.dart';

void main() {
  group('ActivityCard', () {
    testWidgets('should display activity information correctly',
        (tester) async {
      // Arrange
      const activityCard = ActivityCard(
        code: 'T8',
        name: 'Realizar sessão de trabalho focado',
        time: '14:20',
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
      // FT-089: Confidence removed, now shows "Completed" indicator
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Work & Management'), findsOneWidget);
    });

    testWidgets('should handle activity without code', (tester) async {
      // Arrange
      const activityCard = ActivityCard(
        name: 'Custom Activity',
        time: '15:30',
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
      // FT-089: Confidence removed, now shows "Completed" indicator
      expect(find.text('Completed'), findsOneWidget);

      // FT-147: Test dimension display (Oracle or fallback)
      final hasPhysicalHealthText =
          find.textContaining('Physical Health').evaluate().isNotEmpty ||
              find.textContaining('Saúde Física').evaluate().isNotEmpty;
      expect(hasPhysicalHealthText, isTrue,
          reason:
              'Should display either Oracle "Saúde Física" or fallback "Physical Health"');
    });

    testWidgets('should display proper dimension colors', (tester) async {
      // FT-147: Test with Oracle version-agnostic approach
      // Test core dimensions that exist in all Oracle versions
      final coreDimensions = [
        ('SF', 'Physical Health', ['Saúde Física', 'Physical Health']),
        ('R', 'Relationships', ['Relacionamentos', 'Relationships']),
        ('SM', 'Mental Health', ['Saúde Mental', 'Mental Health']),
      ];

      for (final (code, _, _) in coreDimensions) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                name: 'Test Activity',
                time: '12:00',
                dimension: code,
                source: 'Test',
              ),
            ),
          ),
        );

        // FT-147: Test that dimension display works (Oracle or fallback)
        // Get the actual display name from the service
        final actualDisplayName = DimensionDisplayService.getDisplayName(code);

        // Verify the actual display name appears in the widget
        expect(find.text(actualDisplayName), findsOneWidget,
            reason:
                'Should display the dimension name returned by DimensionDisplayService: "$actualDisplayName"');

        // Verify the widget renders without errors
        expect(find.byType(ActivityCard), findsOneWidget);
      }
    });

    testWidgets('should handle Oracle 4.2 dimensions gracefully',
        (tester) async {
      // FT-147: Test Oracle 4.2 specific dimensions (TT, PR, F)
      // These may not exist in all Oracle versions, so test graceful handling
      final oracle42Dimensions = ['TT', 'PR', 'F'];

      for (final code in oracle42Dimensions) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                name: 'Test Activity',
                time: '12:00',
                dimension: code,
                source: 'Test',
              ),
            ),
          ),
        );

        // FT-147: Should display some dimension name (Oracle or fallback)
        final actualDisplayName = DimensionDisplayService.getDisplayName(code);

        // Verify the service returns a non-empty display name
        expect(actualDisplayName.isNotEmpty, isTrue,
            reason:
                'DimensionDisplayService should return a display name for $code');

        // Verify the display name appears in the widget
        expect(find.text(actualDisplayName), findsOneWidget,
            reason:
                'Should display dimension name for $code: "$actualDisplayName"');

        // Verify the widget renders without errors
        expect(find.byType(ActivityCard), findsOneWidget);
      }
    });

    testWidgets('should display completed indicator consistently',
        (tester) async {
      // FT-089: Test that all activities show "Completed" indicator
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              name: 'Test Activity',
              time: '12:00',
              dimension: 'SF',
              source: 'Test',
            ),
          ),
        ),
      );

      // Assert "Completed" indicator is displayed
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify the widget renders without errors
      expect(find.byType(ActivityCard), findsOneWidget);
    });

    testWidgets('should handle edge cases gracefully', (tester) async {
      // Test with minimal required properties
      const activityCard = ActivityCard(
        name: '',
        time: '',
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
      // FT-089: Always shows "Completed" instead of confidence percentage
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('should have proper visual structure', (tester) async {
      // Arrange
      const activityCard = ActivityCard(
        code: 'SF1',
        name: 'Test Activity',
        time: '10:30',
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
              1)); // Should have dimension and completion icons
      expect(find.byType(Container),
          findsAtLeastNWidgets(1)); // For styling containers
    });
  });
}
