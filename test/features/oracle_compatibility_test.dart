import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/config/character_config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Oracle Compatibility Tests', () {
    late CharacterConfigManager configManager;

    setUp(() {
      configManager = CharacterConfigManager();
    });

    test('should identify Oracle-compatible personas', () async {
      print('\n🧪 Testing Oracle compatibility detection...');

      // Test known Oracle-compatible personas from personas_config.json
      final oraclePersonas = ['ariWithOracle21', 'iThereWithOracle21'];

      for (final personaKey in oraclePersonas) {
        print('📋 Testing persona: $personaKey');

        // Set the persona as active
        configManager.setActivePersona(personaKey);

        // Check Oracle compatibility
        final oracleConfigPath = await configManager.getOracleConfigPath();

        expect(oracleConfigPath, isNotNull,
            reason: 'Persona $personaKey should have Oracle config');
        expect(oracleConfigPath, contains('oracle_prompt_2.1.md'),
            reason: 'Should reference Oracle 2.1 config');

        print('✓ $personaKey is Oracle-compatible: $oracleConfigPath');
      }
    });

    test('should identify non-Oracle personas', () async {
      print('\n🧪 Testing non-Oracle persona detection...');

      // Test known non-Oracle personas from personas_config.json
      final nonOraclePersonas = [
        'ariLifeCoach',
        'sergeantOracle',
        'iThereClone'
      ];

      for (final personaKey in nonOraclePersonas) {
        print('📋 Testing persona: $personaKey');

        // Set the persona as active
        configManager.setActivePersona(personaKey);

        // Check Oracle compatibility
        final oracleConfigPath = await configManager.getOracleConfigPath();

        expect(oracleConfigPath, isNull,
            reason: 'Persona $personaKey should not have Oracle config');

        print('✓ $personaKey is non-Oracle (no activity memory)');
      }
    });

    test('should handle persona switching correctly', () async {
      print('\n🧪 Testing persona switching behavior...');

      // Start with Oracle persona
      configManager.setActivePersona('ariWithOracle21');
      var oracleConfigPath = await configManager.getOracleConfigPath();
      expect(oracleConfigPath, isNotNull,
          reason: 'Should have Oracle config initially');
      print('✓ Oracle persona active: ${configManager.activePersonaKey}');

      // Switch to non-Oracle persona
      configManager.setActivePersona('ariLifeCoach');
      oracleConfigPath = await configManager.getOracleConfigPath();
      expect(oracleConfigPath, isNull,
          reason: 'Should not have Oracle config after switch');
      print('✓ Non-Oracle persona active: ${configManager.activePersonaKey}');

      // Switch back to Oracle persona
      configManager.setActivePersona('iThereWithOracle21');
      oracleConfigPath = await configManager.getOracleConfigPath();
      expect(oracleConfigPath, isNotNull,
          reason: 'Should have Oracle config again');
      print('✓ Oracle persona active again: ${configManager.activePersonaKey}');
    });

    test('should provide correct display names', () async {
      print('\n🧪 Testing display name consistency...');

      final testCases = [
        {'key': 'ariLifeCoach', 'expectedName': 'Ari - Life Coach'},
        {'key': 'ariWithOracle21', 'expectedName': 'Ari 2.1'},
        {'key': 'iThereClone', 'expectedName': 'I-There'},
        {'key': 'iThereWithOracle21', 'expectedName': 'I-There 2.1'},
      ];

      for (final testCase in testCases) {
        final personaKey = testCase['key'] as String;
        final expectedName = testCase['expectedName'] as String;

        configManager.setActivePersona(personaKey);
        final displayName = await configManager.personaDisplayName;

        expect(displayName, equals(expectedName),
            reason: 'Display name should match for $personaKey');

        print('✓ $personaKey → "$displayName"');
      }
    });
  });
}
