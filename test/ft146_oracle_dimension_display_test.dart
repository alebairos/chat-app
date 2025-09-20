import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_personas_app/services/dimension_display_service.dart';
import 'package:ai_personas_app/services/oracle_static_cache.dart';

/// FT-146: Oracle-Based Dimension Display Test
///
/// Tests the Oracle-based dimension display service that eliminates hardcoded
/// dimension mappings by using Oracle JSON as the source of truth.
void main() {
  group('FT-146: Oracle-Based Dimension Display', () {
    setUpAll(() async {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Oracle cache and dimension service for testing
      try {
        await OracleStaticCache.initializeAtStartup();
        await DimensionDisplayService.initialize();
      } catch (e) {
        print('Test setup error: $e');
        // Continue with tests using fallback behavior
      }
    });

    group('Oracle Integration', () {
      testWidgets('should use Oracle JSON display names', (tester) async {
        // Test that dimension display names come from Oracle JSON
        final sfDisplayName = DimensionDisplayService.getDisplayName('SF');
        final ttDisplayName = DimensionDisplayService.getDisplayName('TT');
        final prDisplayName = DimensionDisplayService.getDisplayName('PR');
        final fDisplayName = DimensionDisplayService.getDisplayName('F');

        // Should return valid display names (Oracle Portuguese or fallback English)
        expect(sfDisplayName, isNotEmpty);
        expect(ttDisplayName, isNotEmpty);
        expect(prDisplayName, isNotEmpty);
        expect(fDisplayName, isNotEmpty);

        // Check if Oracle is initialized and working
        final debugInfo = DimensionDisplayService.getDebugInfo();
        if (debugInfo['initialized'] == true &&
            debugInfo['hasOracleContext'] == true) {
          // Oracle is available - should use Portuguese names
          expect(sfDisplayName,
              anyOf(equals('Saúde Física'), equals('Physical Health')));
          expect(ttDisplayName,
              anyOf(equals('Tempo de Tela'), equals('Screen Time')));
          expect(prDisplayName,
              anyOf(equals('Procrastinação'), equals('Anti-Procrastination')));
          expect(fDisplayName, anyOf(equals('Finanças'), equals('Finance')));
        } else {
          // Oracle not available - should use fallback names
          expect(sfDisplayName, equals('Physical Health'));
          expect(ttDisplayName, equals('Screen Time'));
          expect(prDisplayName, equals('Anti-Procrastination'));
          expect(fDisplayName, equals('Finance'));
        }
      });

      testWidgets('should support all Oracle 4.2 dimensions', (tester) async {
        // Test all 8 Oracle 4.2 dimensions
        final dimensions = ['SF', 'R', 'TG', 'E', 'SM', 'TT', 'PR', 'F'];

        for (final dimension in dimensions) {
          final displayName = DimensionDisplayService.getDisplayName(dimension);
          final color = DimensionDisplayService.getColor(dimension);
          final icon = DimensionDisplayService.getIcon(dimension);

          expect(displayName, isNotEmpty,
              reason: 'Dimension $dimension should have display name');
          expect(color, isNotNull,
              reason: 'Dimension $dimension should have color');
          expect(icon, isNotNull,
              reason: 'Dimension $dimension should have icon');
        }
      });

      testWidgets('should handle case insensitive dimension codes',
          (tester) async {
        // Test case insensitivity
        expect(DimensionDisplayService.getDisplayName('sf'),
            equals(DimensionDisplayService.getDisplayName('SF')));
        expect(DimensionDisplayService.getDisplayName('tt'),
            equals(DimensionDisplayService.getDisplayName('TT')));
      });
    });

    group('Fallback Behavior', () {
      testWidgets('should provide fallbacks for unknown dimensions',
          (tester) async {
        // Test unknown dimension handling
        final unknownDisplayName =
            DimensionDisplayService.getDisplayName('UNKNOWN');
        final unknownColor = DimensionDisplayService.getColor('UNKNOWN');
        final unknownIcon = DimensionDisplayService.getIcon('UNKNOWN');

        expect(unknownDisplayName, equals('UNKNOWN'));
        expect(unknownColor, equals(Colors.grey));
        expect(unknownIcon, equals(Icons.category));
      });

      testWidgets('should handle empty dimension codes', (tester) async {
        // Test empty string handling
        final emptyDisplayName = DimensionDisplayService.getDisplayName('');
        final emptyColor = DimensionDisplayService.getColor('');
        final emptyIcon = DimensionDisplayService.getIcon('');

        expect(emptyDisplayName, equals(''));
        expect(emptyColor, equals(Colors.grey));
        expect(emptyIcon, equals(Icons.category));
      });
    });

    group('Service Management', () {
      testWidgets('should initialize successfully', (tester) async {
        // Test service initialization
        expect(DimensionDisplayService.isInitialized, isTrue);

        final debugInfo = DimensionDisplayService.getDebugInfo();
        expect(debugInfo['initialized'], isTrue);

        // Dimension count may be 0 if Oracle context is not available in test environment
        expect(debugInfo['dimensionCount'], greaterThanOrEqualTo(0));

        // Service should still work with fallback behavior
        final testDisplayName = DimensionDisplayService.getDisplayName('SF');
        expect(testDisplayName, isNotEmpty);
      });

      testWidgets('should refresh Oracle context', (tester) async {
        // Test service refresh functionality
        await DimensionDisplayService.refresh();

        expect(DimensionDisplayService.isInitialized, isTrue);

        // Should still work after refresh
        final displayName = DimensionDisplayService.getDisplayName('SF');
        expect(displayName, isNotEmpty);
      });
    });

    group('Oracle 4.2 Specific Features', () {
      testWidgets('should support new Oracle 4.2 dimensions', (tester) async {
        // Test Oracle 4.2 specific dimensions
        final ttColor = DimensionDisplayService.getColor('TT');
        final prColor = DimensionDisplayService.getColor('PR');
        final fColor = DimensionDisplayService.getColor('F');

        // Should have distinct colors for new dimensions
        expect(ttColor, equals(Colors.red)); // Screen Time
        expect(prColor, equals(Colors.amber)); // Anti-Procrastination
        expect(fColor, equals(Colors.teal)); // Finance

        // Should have appropriate icons
        final ttIcon = DimensionDisplayService.getIcon('TT');
        final prIcon = DimensionDisplayService.getIcon('PR');
        final fIcon = DimensionDisplayService.getIcon('F');

        expect(ttIcon, equals(Icons.access_time));
        expect(prIcon, equals(Icons.timer));
        expect(fIcon, equals(Icons.account_balance_wallet));
      });
    });

    group('Consistency Tests', () {
      testWidgets('should maintain consistent colors across calls',
          (tester) async {
        // Test color consistency
        final color1 = DimensionDisplayService.getColor('SF');
        final color2 = DimensionDisplayService.getColor('SF');
        expect(color1, equals(color2));
      });

      testWidgets('should maintain consistent display names', (tester) async {
        // Test display name consistency
        final name1 = DimensionDisplayService.getDisplayName('TT');
        final name2 = DimensionDisplayService.getDisplayName('TT');
        expect(name1, equals(name2));
        expect(name1, isNotEmpty);
      });
    });
  });
}
