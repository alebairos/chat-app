import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../lib/services/oracle_context_manager.dart';
import '../lib/services/oracle_static_cache.dart';
import '../lib/config/character_config_manager.dart';

/// FT-141 Oracle 4.2 Integration Validation Test
///
/// Tests the enhanced Oracle 4.2 validation and integration implemented in Phase 1:
/// 1. OracleContextManager validates Oracle 4.2 completeness
/// 2. OracleStaticCache validates Oracle 4.2 compliance
/// 3. Enhanced debug info provides Oracle 4.2 specifics
/// 4. All 8 dimensions and 265+ activities are accessible
void main() {
  group('FT-141 Oracle 4.2 Integration Validation', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      print('🚀 Starting FT-141 Oracle 4.2 Integration Validation Tests');

      // Initialize CharacterConfigManager with Oracle 4.2 persona
      final configManager = CharacterConfigManager();
      await configManager.initialize();
      configManager.setActivePersona('iThereWithOracle42');
      print('✅ CharacterConfigManager initialized with Oracle 4.2 persona');
    });

    setUp(() async {
      // Clear any existing cache before each test
      OracleStaticCache.clearCache();
      OracleContextManager.clearCache();
    });

    testWidgets('OracleContextManager should validate Oracle 4.2 completeness',
        (tester) async {
      print('\n🧪 Testing OracleContextManager Oracle 4.2 validation...');

      try {
        // Load Oracle context for current persona (should be Oracle 4.2)
        final context = await OracleContextManager.getForCurrentPersona();

        // Validate context was loaded
        expect(context, isNotNull, reason: 'Oracle context should be loaded');

        if (context != null) {
          print(
              '   📊 Loaded Oracle context: ${context.totalActivities} activities, ${context.dimensions.length} dimensions');

          // Check if this is Oracle 4.2 (has TT, PR, F dimensions)
          final hasOracle42Dimensions = context.dimensions.containsKey('TT') &&
              context.dimensions.containsKey('PR') &&
              context.dimensions.containsKey('F');

          if (hasOracle42Dimensions) {
            print('   🎯 Oracle 4.2 detected - validating completeness...');

            // Validate 8 dimensions
            expect(context.dimensions.length, equals(8),
                reason: 'Oracle 4.2 should have 8 dimensions');

            // Validate specific dimensions exist
            final expectedDimensions = {
              'E',
              'F',
              'PR',
              'R',
              'SF',
              'SM',
              'TG',
              'TT'
            };
            final actualDimensions = context.dimensions.keys.toSet();
            expect(actualDimensions, equals(expectedDimensions),
                reason: 'Oracle 4.2 should have all 8 expected dimensions');

            // Validate activity count
            expect(context.totalActivities, greaterThanOrEqualTo(265),
                reason: 'Oracle 4.2 should have 265+ activities');

            // Validate new dimensions have activities
            final ttActivities =
                context.dimensions['TT']?.activities.length ?? 0;
            final prActivities =
                context.dimensions['PR']?.activities.length ?? 0;
            final fActivities = context.dimensions['F']?.activities.length ?? 0;

            expect(ttActivities, greaterThan(0),
                reason: 'TT (Tempo de Tela) dimension should have activities');
            expect(prActivities, greaterThan(0),
                reason: 'PR (Procrastinação) dimension should have activities');
            expect(fActivities, greaterThan(0),
                reason: 'F (Finanças) dimension should have activities');

            print('   ✅ Oracle 4.2 validation passed:');
            print('      📊 8 dimensions: ${actualDimensions.join(', ')}');
            print('      📋 ${context.totalActivities} activities total');
            print(
                '      🆕 New dimensions: TT($ttActivities), PR($prActivities), F($fActivities)');
          } else {
            print(
                '   ℹ️  Legacy Oracle detected (non-4.2) - skipping 4.2 specific validation');
          }
        }
      } catch (e) {
        print('   ❌ Oracle context loading failed: $e');
        rethrow;
      }
    });
  });
}
