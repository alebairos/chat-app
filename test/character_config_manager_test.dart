import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/config/character_config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CharacterConfigManager Tests', () {
    test('Default persona should be Sergeant Oracle', () {
      final manager = CharacterConfigManager();
      expect(manager.activePersona, CharacterPersona.sergeantOracle);
      expect(manager.personaDisplayName, 'Sergeant Oracle');
    });

    test('Should change active persona', () {
      final manager = CharacterConfigManager();
      manager.setActivePersona(CharacterPersona.sergeantOracle);
      expect(manager.activePersona, CharacterPersona.sergeantOracle);
      expect(manager.personaDisplayName, 'Sergeant Oracle');
    });

    test('Should return correct config file path', () {
      final manager = CharacterConfigManager();

      manager.setActivePersona(CharacterPersona.personalDevelopmentAssistant);
      expect(manager.configFilePath, 'lib/config/claude_config.json');

      manager.setActivePersona(CharacterPersona.sergeantOracle);
      expect(manager.configFilePath, 'lib/config/sergeant_oracle_config.json');

      manager.setActivePersona(CharacterPersona.zenGuide);
      expect(manager.configFilePath, 'lib/config/zen_guide_config.json');
    });

    test('Should return list of available personas', () async {
      final manager = CharacterConfigManager();
      final personas = await manager.availablePersonas;

      expect(
          personas.length, 1); // Only Sergeant Oracle is enabled in our config
      expect(personas[0]['displayName'], 'Sergeant Oracle');
    });
  });
}
