import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/config/character_config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CharacterConfigManager Tests', () {
    test('Default persona should be Ari Life Coach', () {
      final manager = CharacterConfigManager();
      expect(manager.activePersona, CharacterPersona.ariLifeCoach);
      expect(manager.personaDisplayName, 'Ari - Life Coach');
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
      expect(manager.configFilePath, 'assets/config/claude_config.json');

      manager.setActivePersona(CharacterPersona.sergeantOracle);
      expect(
          manager.configFilePath, 'assets/config/sergeant_oracle_config.json');

      manager.setActivePersona(CharacterPersona.zenGuide);
      expect(manager.configFilePath, 'assets/config/zen_guide_config.json');

      manager.setActivePersona(CharacterPersona.ariLifeCoach);
      expect(
          manager.configFilePath, 'assets/config/ari_life_coach_config.json');
    });

    test('Should return list of available personas', () async {
      final manager = CharacterConfigManager();
      final personas = await manager.availablePersonas;

      expect(personas.length, 2); // Ari and Sergeant Oracle are enabled
      expect(
          personas.any((p) => p['displayName'] == 'Ari - Life Coach'), isTrue);
      expect(
          personas.any((p) => p['displayName'] == 'Sergeant Oracle'), isTrue);
    });
  });
}
