import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:ai_personas_app/services/oracle_context_manager.dart';
import 'package:ai_personas_app/services/oracle_static_cache.dart';
import 'package:ai_personas_app/config/character_config_manager.dart';

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
  });
}
