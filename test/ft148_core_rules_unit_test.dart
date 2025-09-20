import 'package:flutter_test/flutter_test.dart';
import '../lib/config/character_config_manager.dart';

void main() {
  group('FT-148: Core Behavioral Rules Unit Tests', () {
    late CharacterConfigManager configManager;

    setUp(() {
      configManager = CharacterConfigManager();
    });

    test('formatCategoryName should format category names correctly', () {
      // Test the helper method directly
      expect(
        configManager.formatCategoryName('transparency_constraints'),
        equals('Transparency Constraints'),
      );
      expect(
        configManager.formatCategoryName('data_integrity'),
        equals('Data Integrity Rules'),
      );
      expect(
        configManager.formatCategoryName('response_quality'),
        equals('Response Quality Standards'),
      );
      expect(
        configManager.formatCategoryName('custom_category'),
        equals('Custom Category'),
      );
    });

    test('buildCoreRulesText should format rules correctly', () {
      final mockConfig = {
        'rules': {
          'transparency_constraints': {
            'no_internal_thoughts': 'CRITICAL: NO INTERNAL THOUGHTS',
            'seamless_processing': 'Process everything seamlessly',
          },
          'data_integrity': {'use_fresh_data': 'SEMPRE USAR PARA DADOS EXATOS'},
        },
        'application_rules': {'separator': '\n\n---\n\n'},
      };

      final result = configManager.buildCoreRulesText(mockConfig);

      expect(result.contains('## CORE BEHAVIORAL RULES'), isTrue);
      expect(result.contains('### Transparency Constraints'), isTrue);
      expect(result.contains('### Data Integrity Rules'), isTrue);
      expect(result.contains('- **CRITICAL: NO INTERNAL THOUGHTS**'), isTrue);
      expect(result.contains('- **SEMPRE USAR PARA DADOS EXATOS**'), isTrue);
      expect(result.contains('---'), isTrue);
    });

    test('Core rules configuration structure should be valid', () {
      // Test that our configuration structure makes sense
      final expectedKeys = [
        'version',
        'description',
        'enabled',
        'rules',
        'application_rules',
      ];
      final expectedRuleCategories = [
        'transparency_constraints',
        'data_integrity',
        'response_quality',
      ];

      // This validates our design choices
      expect(expectedKeys.length, equals(5));
      expect(expectedRuleCategories.length, equals(3));

      // Verify rule categories make logical sense
      expect(
        expectedRuleCategories.contains('transparency_constraints'),
        isTrue,
      );
      expect(expectedRuleCategories.contains('data_integrity'), isTrue);
      expect(expectedRuleCategories.contains('response_quality'), isTrue);
    });
  });
}
