import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_personas_app/config/character_config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CharacterConfigManager - Dynamic Persona Tests', () {
    late CharacterConfigManager manager;

    setUp(() {
      manager = CharacterConfigManager();
    });

    test('Default persona should be ariLifeCoach', () {
      expect(manager.activePersonaKey, 'ariLifeCoach');
    });

    test('Should return correct config path for Ari', () async {
      manager.setActivePersona('ariLifeCoach');
      final configPath = await manager.configFilePath;
      expect(configPath, contains('ari_life_coach_config'));
    });

    test('Should return correct display name for Ari', () async {
      manager.setActivePersona('ariLifeCoach');
      final displayName = await manager.personaDisplayName;
      expect(displayName, contains('Ari'));
    });

    test('Should handle persona switching correctly', () async {
      // Start with Ari as default
      expect(manager.activePersonaKey, 'ariLifeCoach');

      // Switch to Sergeant Oracle
      manager.setActivePersona('sergeantOracle');
      expect(manager.activePersonaKey, 'sergeantOracle');
      final oracleDisplayName = await manager.personaDisplayName;
      expect(oracleDisplayName, contains('Oracle'));

      // Switch back to Ari
      manager.setActivePersona('ariLifeCoach');
      expect(manager.activePersonaKey, 'ariLifeCoach');
      final ariDisplayName = await manager.personaDisplayName;
      expect(ariDisplayName, contains('Ari'));
    });

    test('Should return config path for any valid persona', () async {
      manager.setActivePersona('ariLifeCoach');
      final ariPath = await manager.configFilePath;
      expect(ariPath, isNotEmpty);

      manager.setActivePersona('sergeantOracle');
      final oraclePath = await manager.configFilePath;
      expect(oraclePath, isNotEmpty);
      expect(oraclePath, isNot(equals(ariPath)));
    });

    test('Should load available personas from config', () async {
      final personas = await manager.availablePersonas;
      expect(personas, isNotEmpty);

      // Should have at least Ari and Sergeant Oracle
      final personaKeys = personas.map((p) => p['key']).toList();
      expect(personaKeys, contains('ariLifeCoach'));
      expect(personaKeys, contains('sergeantOracle'));
    });

    test('Should maintain singleton behavior', () {
      final manager1 = CharacterConfigManager();
      final manager2 = CharacterConfigManager();

      expect(identical(manager1, manager2), true);
      expect(manager1.activePersonaKey, manager2.activePersonaKey);

      // Changing one should affect the other (singleton behavior)
      manager1.setActivePersona('sergeantOracle');
      expect(manager2.activePersonaKey, 'sergeantOracle');
    });

    test('Should handle unknown persona keys gracefully', () async {
      manager.setActivePersona('unknownPersona');
      final configPath = await manager.configFilePath;
      expect(configPath, isNotEmpty); // Should fallback to default
    });
  });
}
