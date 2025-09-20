import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/config/character_config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FT-144 Persona Configuration Optimization Tests', () {
    test('Aristios 4.2 should load with new Ari 3.0 config', () async {
      final manager = CharacterConfigManager();

      // Set to Aristios 4.2 persona
      manager.setActivePersona('ariWithOracle42');
      expect(manager.activePersonaKey, 'ariWithOracle42');

      // Verify display name loads correctly
      final displayName = await manager.personaDisplayName;
      expect(displayName, 'Aristios 4.2');

      // Verify new config path is used
      final configPath = await manager.configFilePath;
      expect(configPath, 'assets/config/ari_life_coach_config_3.0.json');

      print('✅ Aristios 4.2 loads with new Ari 3.0 config: $configPath');
    });

    test('I-There 4.2 should load with new I-There 2.0 config', () async {
      final manager = CharacterConfigManager();

      // Set to I-There 4.2 persona
      manager.setActivePersona('iThereWithOracle42');
      expect(manager.activePersonaKey, 'iThereWithOracle42');

      // Verify display name loads correctly
      final displayName = await manager.personaDisplayName;
      expect(displayName, 'I-There 4.2');

      // Verify new config path is used
      final configPath = await manager.configFilePath;
      expect(configPath, 'assets/config/i_there_config_2.0.json');

      print('✅ I-There 4.2 loads with new I-There 2.0 config: $configPath');
    });

    test('Oracle 4.2 personas maintain Oracle integration', () async {
      final manager = CharacterConfigManager();

      // Test Aristios 4.2
      manager.setActivePersona('ariWithOracle42');
      final ariOraclePath = await manager.getOracleConfigPath();
      expect(ariOraclePath, 'assets/config/oracle/oracle_prompt_4.2.md');

      // Test I-There 4.2
      manager.setActivePersona('iThereWithOracle42');
      final iThereOraclePath = await manager.getOracleConfigPath();
      expect(iThereOraclePath, 'assets/config/oracle/oracle_prompt_4.2.md');

      print('✅ Oracle 4.2 integration preserved for both personas');
    });

    test('Other persona versions unaffected by changes', () async {
      final manager = CharacterConfigManager();

      // Test I-There 3.0 still uses original config
      manager.setActivePersona('iThereWithOracle30');
      final iThereOriginalPath = await manager.configFilePath;
      expect(iThereOriginalPath, 'assets/config/i_there_config.json');

      // Test Aristios 3.0 still uses original config
      manager.setActivePersona('ariWithOracle30');
      final ariOriginalPath = await manager.configFilePath;
      expect(ariOriginalPath, 'assets/config/ari_life_coach_config_2.0.json');

      print('✅ Other persona versions maintain original configurations');
    });

    test('Available personas include Oracle 4.2 with new configs', () async {
      final manager = CharacterConfigManager();
      final personas = await manager.availablePersonas;

      // Find Oracle 4.2 personas
      final aristios42 = personas.firstWhere(
        (p) => p['key'] == 'ariWithOracle42',
        orElse: () => <String, dynamic>{},
      );
      final iThere42 = personas.firstWhere(
        (p) => p['key'] == 'iThereWithOracle42',
        orElse: () => <String, dynamic>{},
      );

      expect(aristios42.isNotEmpty, isTrue);
      expect(iThere42.isNotEmpty, isTrue);
      expect(aristios42['displayName'], 'Aristios 4.2');
      expect(iThere42['displayName'], 'I-There 4.2');

      print('✅ Oracle 4.2 personas available in persona list');
    });
  });
}
