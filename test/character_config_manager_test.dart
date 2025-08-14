import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/config/character_config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CharacterConfigManager Tests', () {
    test('Default persona should be ariLifeCoach', () async {
      final manager = CharacterConfigManager();
      expect(manager.activePersonaKey, 'ariLifeCoach');
      final displayName = await manager.personaDisplayName;
      expect(displayName, contains('Ari'));
    });

    test('Should change active persona', () async {
      final manager = CharacterConfigManager();
      manager.setActivePersona('sergeantOracle');
      expect(manager.activePersonaKey, 'sergeantOracle');
      final displayName = await manager.personaDisplayName;
      expect(displayName, contains('Oracle'));
    });

    test('Should return correct config file path', () async {
      final manager = CharacterConfigManager();

      manager.setActivePersona('ariLifeCoach');
      final ariPath = await manager.configFilePath;
      expect(ariPath, contains('ari_life_coach_config'));

      manager.setActivePersona('sergeantOracle');
      final oraclePath = await manager.configFilePath;
      expect(oraclePath, contains('sergeant_oracle_config'));
    });

    test('Should return list of available personas', () async {
      final manager = CharacterConfigManager();
      final personas = await manager.availablePersonas;

      expect(personas.length,
          greaterThanOrEqualTo(2)); // At least Ari and Sergeant Oracle
      expect(personas.any((p) => p['displayName'].toString().contains('Ari')),
          isTrue);
      expect(
          personas.any((p) => p['displayName'].toString().contains('Oracle')),
          isTrue);
    });

    test('Should maintain singleton behavior', () {
      final manager1 = CharacterConfigManager();
      final manager2 = CharacterConfigManager();

      expect(identical(manager1, manager2), isTrue);

      manager1.setActivePersona('sergeantOracle');
      expect(manager2.activePersonaKey, 'sergeantOracle');
    });
  });
}
