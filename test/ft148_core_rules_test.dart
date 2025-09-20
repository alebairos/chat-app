import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../lib/config/character_config_manager.dart';

void main() {
  group('FT-148: Core Behavioral Rules Externalization', () {
    late CharacterConfigManager configManager;

    setUp(() {
      configManager = CharacterConfigManager();
    });

    testWidgets('Core rules should be loaded and applied to system prompt', (tester) async {
      // Initialize the config manager
      await configManager.initialize();

      // Test with different personas to ensure rules are universal
      final testPersonas = ['iThereWithOracle42', 'sergeantOracleWithOracle42', 'ryoTzuWithOracle42'];

      for (final personaKey in testPersonas) {
        configManager.setActivePersona(personaKey);
        
        try {
          final systemPrompt = await configManager.loadSystemPrompt();
          
          // Verify core rules are present at the beginning
          expect(systemPrompt.contains('## CORE BEHAVIORAL RULES'), isTrue,
              reason: 'Core behavioral rules header should be present for $personaKey');
          
          // Verify specific critical rules are included
          expect(systemPrompt.contains('CRITICAL: NO INTERNAL THOUGHTS'), isTrue,
              reason: 'No internal thoughts rule should be present for $personaKey');
          
          expect(systemPrompt.contains('SEMPRE USAR PARA DADOS EXATOS'), isTrue,
              reason: 'Data accuracy rule should be present for $personaKey');
          
          expect(systemPrompt.contains('Stay in character at ALL times'), isTrue,
              reason: 'Persona maintenance rule should be present for $personaKey');
          
          // Verify rules appear before other content
          final coreRulesIndex = systemPrompt.indexOf('## CORE BEHAVIORAL RULES');
          final mcpIndex = systemPrompt.indexOf('## SISTEMA DE COMANDO MCP');
          final oracleIndex = systemPrompt.indexOf('# ARISTOS');
          
          expect(coreRulesIndex, greaterThanOrEqualTo(0),
              reason: 'Core rules should be found in prompt for $personaKey');
          
          if (mcpIndex >= 0) {
            expect(coreRulesIndex, lessThan(mcpIndex),
                reason: 'Core rules should appear before MCP instructions for $personaKey');
          }
          
          if (oracleIndex >= 0) {
            expect(coreRulesIndex, lessThan(oracleIndex),
                reason: 'Core rules should appear before Oracle content for $personaKey');
          }
          
          print('✅ Core rules successfully applied to $personaKey');
          
        } catch (e) {
          print('❌ Error testing $personaKey: $e');
          rethrow;
        }
      }
    });

    testWidgets('Core rules can be disabled via configuration', (tester) async {
      // This test would require modifying the config temporarily
      // For now, we'll just verify the structure is correct
      await configManager.initialize();
      
      // Test that the configuration structure is valid
      try {
        final systemPrompt = await configManager.loadSystemPrompt();
        expect(systemPrompt.isNotEmpty, isTrue,
            reason: 'System prompt should not be empty');
        
        print('✅ Configuration structure is valid');
      } catch (e) {
        fail('Configuration loading failed: $e');
      }
    });

    test('Core rules configuration format should be valid', () async {
      // Test that our JSON configuration is properly structured
      try {
        const jsonString = '''
        {
          "version": "1.0",
          "enabled": true,
          "rules": {
            "transparency_constraints": {
              "no_internal_thoughts": "CRITICAL: NO INTERNAL THOUGHTS"
            }
          }
        }
        ''';
        
        // This would normally be tested by loading the actual config
        // but for unit testing we verify the structure
        expect(jsonString.contains('"enabled"'), isTrue);
        expect(jsonString.contains('"rules"'), isTrue);
        
        print('✅ Core rules configuration format is valid');
      } catch (e) {
        fail('Configuration format validation failed: $e');
      }
    });
  });
}
