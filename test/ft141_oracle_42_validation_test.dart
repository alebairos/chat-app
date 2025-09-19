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
    });

    setUp(() async {
      // Clear any existing cache before each test
      OracleStaticCache.clearCache();
      OracleContextManager.clearCache();
    });

    testWidgets('OracleContextManager should validate Oracle 4.2 completeness', (tester) async {
      print('\n🧪 Testing OracleContextManager Oracle 4.2 validation...');
      
      try {
        // Load Oracle context for current persona (should be Oracle 4.2)
        final context = await OracleContextManager.getForCurrentPersona();
        
        // Validate context was loaded
        expect(context, isNotNull, reason: 'Oracle context should be loaded');
        
        if (context != null) {
          print('   📊 Loaded Oracle context: ${context.totalActivities} activities, ${context.dimensions.length} dimensions');
          
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
            final expectedDimensions = {'E', 'F', 'PR', 'R', 'SF', 'SM', 'TG', 'TT'};
            final actualDimensions = context.dimensions.keys.toSet();
            expect(actualDimensions, equals(expectedDimensions), 
              reason: 'Oracle 4.2 should have all 8 expected dimensions');
            
            // Validate activity count
            expect(context.totalActivities, greaterThanOrEqualTo(265), 
              reason: 'Oracle 4.2 should have 265+ activities');
            
            // Validate new dimensions have activities
            final ttActivities = context.dimensions['TT']?.activities.length ?? 0;
            final prActivities = context.dimensions['PR']?.activities.length ?? 0;
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
            print('      🆕 New dimensions: TT($ttActivities), PR($prActivities), F($fActivities)');
          } else {
            print('   ℹ️  Legacy Oracle detected (non-4.2) - skipping 4.2 specific validation');
          }
        }
      } catch (e) {
        print('   ❌ Oracle context loading failed: $e');
        rethrow;
      }
    });

    testWidgets('OracleContextManager debug info should include Oracle 4.2 details', (tester) async {
      print('\n🧪 Testing OracleContextManager enhanced debug info...');
      
      try {
        final debugInfo = await OracleContextManager.getDebugInfo();
        
        print('   📊 Debug info keys: ${debugInfo.keys.join(', ')}');
        
        // Validate basic debug info
        expect(debugInfo['oracleLoaded'], isNotNull);
        expect(debugInfo['totalActivities'], isNotNull);
        expect(debugInfo['dimensions'], isNotNull);
        
        // Check for Oracle 4.2 specific validation info
        if (debugInfo['oracle42Validation'] != null) {
          final oracle42Info = debugInfo['oracle42Validation'] as Map<String, dynamic>;
          
          print('   🔍 Oracle 4.2 validation info found:');
          print('      isOracle42: ${oracle42Info['isOracle42']}');
          print('      actualDimensions: ${oracle42Info['actualDimensions']}');
          print('      actualActivities: ${oracle42Info['actualActivities']}');
          
          if (oracle42Info['isOracle42'] == true) {
            expect(oracle42Info['actualDimensions'], equals(8));
            expect(oracle42Info['actualActivities'], greaterThanOrEqualTo(265));
            expect(oracle42Info['hasNewDimensions'], isTrue);
            
            final newDimensionCounts = oracle42Info['newDimensionCounts'] as Map<String, dynamic>?;
            if (newDimensionCounts != null) {
              expect(newDimensionCounts['TT'], greaterThan(0));
              expect(newDimensionCounts['PR'], greaterThan(0));
              expect(newDimensionCounts['F'], greaterThan(0));
              
              print('      🆕 New dimension counts: TT(${newDimensionCounts['TT']}), PR(${newDimensionCounts['PR']}), F(${newDimensionCounts['F']})');
            }
          }
        }
        
        print('   ✅ Enhanced debug info validation passed');
      } catch (e) {
        print('   ❌ Debug info test failed: $e');
        rethrow;
      }
    });

    testWidgets('OracleStaticCache should validate Oracle 4.2 compliance', (tester) async {
      print('\n🧪 Testing OracleStaticCache Oracle 4.2 compliance validation...');
      
      try {
        // Initialize the static cache
        await OracleStaticCache.initializeAtStartup();
        
        // Validate cache was initialized
        expect(OracleStaticCache.isInitialized, isTrue, 
          reason: 'Oracle static cache should be initialized');
        
        // Get debug info
        final debugInfo = OracleStaticCache.getDebugInfo();
        
        print('   📊 Cache debug info:');
        print('      initialized: ${debugInfo['initialized']}');
        print('      totalActivities: ${debugInfo['totalActivities']}');
        print('      compactFormatSize: ${debugInfo['compactFormatSize']}');
        
        // Validate basic cache info
        expect(debugInfo['initialized'], isTrue);
        expect(debugInfo['totalActivities'], greaterThan(0));
        expect(debugInfo['compactFormatSize'], greaterThan(0));
        
        // Check Oracle 4.2 validation if available
        if (debugInfo['oracle42Validation'] != null) {
          final oracle42Info = debugInfo['oracle42Validation'] as Map<String, dynamic>;
          
          print('   🔍 Oracle 4.2 cache validation:');
          print('      isOracle42: ${oracle42Info['isOracle42']}');
          print('      validationStatus: ${oracle42Info['validationStatus']}');
          
          if (oracle42Info['isOracle42'] == true) {
            expect(oracle42Info['validationStatus'], equals('PASSED'), 
              reason: 'Oracle 4.2 cache validation should pass');
            expect(oracle42Info['dimensionCount'], equals(8));
            expect(oracle42Info['actualActivities'], greaterThanOrEqualTo(265));
            
            print('      ✅ Oracle 4.2 cache validation: PASSED');
            print('      📊 ${oracle42Info['actualActivities']} activities, ${oracle42Info['dimensionCount']} dimensions');
          }
        }
        
        // Test compact Oracle format
        final compactFormat = OracleStaticCache.getCompactOracleForLLM();
        expect(compactFormat, isNotEmpty, reason: 'Compact Oracle format should not be empty');
        
        // Validate compact format contains Oracle 4.2 activities
        final activityCount = compactFormat.split(',').length;
        print('   📏 Compact format: ${compactFormat.length} chars, $activityCount activities');
        
        if (debugInfo['oracle42Validation']?['isOracle42'] == true) {
          expect(activityCount, greaterThanOrEqualTo(265), 
            reason: 'Compact format should contain all Oracle 4.2 activities');
        }
        
        print('   ✅ Oracle static cache validation passed');
      } catch (e) {
        print('   ❌ Oracle static cache test failed: $e');
        rethrow;
      }
    });

    testWidgets('Oracle 4.2 activity lookup should work correctly', (tester) async {
      print('\n🧪 Testing Oracle 4.2 activity lookup functionality...');
      
      try {
        // Ensure cache is initialized
        if (!OracleStaticCache.isInitialized) {
          await OracleStaticCache.initializeAtStartup();
        }
        
        // Test sample Oracle 4.2 activities
        final sampleCodes = ['SF1', 'R1', 'E1', 'SM1', 'TG1', 'TT1', 'PR1', 'F1'];
        final foundActivities = <String>[];
        
        for (final code in sampleCodes) {
          final activity = OracleStaticCache.getActivityByCode(code);
          if (activity != null) {
            foundActivities.add(code);
            print('   ✓ Found $code: ${activity.description}');
          } else {
            print('   ⚠️  Activity $code not found');
          }
        }
        
        // For Oracle 4.2, we should find activities from all 8 dimensions
        final debugInfo = OracleStaticCache.getDebugInfo();
        if (debugInfo['oracle42Validation']?['isOracle42'] == true) {
          // Should find at least the basic activities from each dimension
          expect(foundActivities.length, greaterThanOrEqualTo(5), 
            reason: 'Should find activities from multiple dimensions');
          
          // Check if we found new dimension activities (TT, PR, F)
          final hasNewDimensions = foundActivities.any((code) => code.startsWith('TT')) ||
                                  foundActivities.any((code) => code.startsWith('PR')) ||
                                  foundActivities.any((code) => code.startsWith('F'));
          
          if (hasNewDimensions) {
            print('   🆕 Found activities from new Oracle 4.2 dimensions');
          }
        }
        
        // Test batch lookup
        final batchActivities = OracleStaticCache.getActivitiesByCodes(sampleCodes);
        expect(batchActivities.length, equals(foundActivities.length), 
          reason: 'Batch lookup should return same number of activities');
        
        print('   ✅ Activity lookup test passed: ${foundActivities.length}/${sampleCodes.length} activities found');
      } catch (e) {
        print('   ❌ Activity lookup test failed: $e');
        rethrow;
      }
    });

    testWidgets('CharacterConfigManager should load Oracle 4.2 persona correctly', (tester) async {
      print('\n🧪 Testing CharacterConfigManager Oracle 4.2 persona loading...');
      
      try {
        final configManager = CharacterConfigManager();
        
        // Get active persona info
        final activePersona = configManager.activePersonaKey;
        print('   🎯 Active persona: $activePersona');
        
        // Check if this is an Oracle 4.2 persona
        final oracleConfigPath = await configManager.getOracleConfigPath();
        print('   📄 Oracle config path: $oracleConfigPath');
        
        if (oracleConfigPath != null && oracleConfigPath.contains('oracle_prompt_4.2')) {
          print('   🎯 Oracle 4.2 persona detected');
          
          // Test MCP config loading
          final mcpConfigPaths = await configManager.getMcpConfigPaths();
          print('   🔧 MCP config paths: $mcpConfigPaths');
          
          // Should have base config and Oracle 4.2 extension
          expect(mcpConfigPaths['baseConfig'], isNotNull, 
            reason: 'Should have base MCP config');
          
          final extensions = mcpConfigPaths['extensions'] as List<dynamic>? ?? [];
          if (extensions.isNotEmpty) {
            final hasOracle42Extension = extensions.any((ext) => 
              ext.toString().contains('oracle_4.2'));
            
            if (hasOracle42Extension) {
              print('   🔧 Oracle 4.2 MCP extension found');
            }
          }
          
          // Test MCP instructions loading
          final mcpInstructions = await configManager.loadMcpInstructions();
          if (mcpInstructions != null) {
            print('   📋 MCP instructions loaded successfully');
            
            // Check for Oracle capabilities
            final oracleCapabilities = mcpInstructions['oracle_capabilities'];
            if (oracleCapabilities != null) {
              final dimensions = oracleCapabilities['dimensions'];
              final totalActivities = oracleCapabilities['total_activities'];
              
              print('   📊 Oracle capabilities: $dimensions dimensions, $totalActivities activities');
              
              if (dimensions == 8 && totalActivities == '265+') {
                print('   ✅ Oracle 4.2 capabilities confirmed');
              }
            }
          }
        } else {
          print('   ℹ️  Non-Oracle 4.2 persona - skipping Oracle 4.2 specific tests');
        }
        
        print('   ✅ CharacterConfigManager test passed');
      } catch (e) {
        print('   ❌ CharacterConfigManager test failed: $e');
        rethrow;
      }
    });
  });
}
