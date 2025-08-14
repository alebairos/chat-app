import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../lib/config/character_config_manager.dart';

void main() {
  group('CharacterConfigManager - Ari Life Coach Tests', () {
    late CharacterConfigManager manager;

    setUp(() {
      manager = CharacterConfigManager();
    });

    test('Should include ariLifeCoach in CharacterPersona enum', () {
      expect(CharacterPersona.values, contains(CharacterPersona.ariLifeCoach));
    });

    test('Default persona should be Ari Life Coach', () {
      expect(manager.activePersona, CharacterPersona.ariLifeCoach);
    });

    test('Should return correct config path for Ari', () {
      manager.setActivePersona(CharacterPersona.ariLifeCoach);
      // With Oracle enabled, Ari uses 2.0 overlay; fallback may use 1.0
      expect(
          manager.configFilePath,
          anyOf('assets/config/ari_life_coach_config_1.0.json',
              'assets/config/ari_life_coach_config_2.0.json'));
    });

    test('Should return correct display name for Ari', () {
      manager.setActivePersona(CharacterPersona.ariLifeCoach);
      expect(manager.personaDisplayName, 'Ari - Life Coach');
    });

    test('Should handle persona switching correctly', () {
      // Start with Ari as default
      expect(manager.activePersona, CharacterPersona.ariLifeCoach);

      // Switch to Sergeant Oracle
      manager.setActivePersona(CharacterPersona.sergeantOracle);
      expect(manager.activePersona, CharacterPersona.sergeantOracle);
      expect(manager.personaDisplayName, 'Sergeant Oracle');

      // Switch back to Ari
      manager.setActivePersona(CharacterPersona.ariLifeCoach);
      expect(manager.activePersona, CharacterPersona.ariLifeCoach);
      expect(manager.personaDisplayName, 'Ari - Life Coach');
    });

    test('Should return correct system prompt path for Ari', () {
      manager.setActivePersona(CharacterPersona.ariLifeCoach);
      // This is testing the private method through the public interface
      // The actual path would be used in loadSystemPrompt()
      expect(
          manager.configFilePath,
          anyOf('assets/config/ari_life_coach_config_1.0.json',
              'assets/config/ari_life_coach_config_2.0.json'));
    });

    test('All personas should have unique display names', () {
      final displayNames = <String>{};

      for (final persona in CharacterPersona.values) {
        manager.setActivePersona(persona);
        final displayName = manager.personaDisplayName;
        expect(displayNames.contains(displayName), false,
            reason: 'Display name "$displayName" is not unique');
        displayNames.add(displayName);
      }
    });

    test('All personas should have unique config file paths', () {
      final configPaths = <String>{};

      for (final persona in CharacterPersona.values) {
        manager.setActivePersona(persona);
        final configPath = manager.configFilePath;
        expect(configPaths.contains(configPath), false,
            reason: 'Config path "$configPath" is not unique');
        configPaths.add(configPath);
      }
    });

    test('Should maintain singleton behavior with Ari as default', () {
      final manager1 = CharacterConfigManager();
      final manager2 = CharacterConfigManager();

      expect(identical(manager1, manager2), true);
      expect(manager1.activePersona, CharacterPersona.ariLifeCoach);
      expect(manager2.activePersona, CharacterPersona.ariLifeCoach);

      // Changing one should affect the other (singleton behavior)
      manager1.setActivePersona(CharacterPersona.sergeantOracle);
      expect(manager2.activePersona, CharacterPersona.sergeantOracle);
    });
  });
}
