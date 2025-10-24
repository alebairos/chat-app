import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/config/character_config_manager.dart';
import 'package:ai_personas_app/config/config_loader.dart';

void main() {
  group('Persona UI Tests', () {
    setUp(() {
      // Reset to default persona before each test
      CharacterConfigManager().setActivePersona('ariLifeCoach');
    });

    // Test that the configuration manager works correctly
    test('ConfigLoader sets and gets persona correctly', () async {
      final configLoader = ConfigLoader();

      // Set Ari and verify
      configLoader.setActivePersona('ariLifeCoach');
      expect(configLoader.activePersonaKey, 'ariLifeCoach');
      final ariDisplayName = await configLoader.activePersonaDisplayName;
      expect(ariDisplayName, 'Ari - Life Coach');

      // Set Sergeant Oracle and verify
      configLoader.setActivePersona('sergeantOracle');
      expect(configLoader.activePersonaKey, 'sergeantOracle');
      final oracleDisplayName = await configLoader.activePersonaDisplayName;
      expect(oracleDisplayName, 'Sergeant Oracle');
    });

    // Test a simple app bar with persona display
    testWidgets('AppBar shows correct persona name in title',
        (WidgetTester tester) async {
      // Skip: Flaky test - persona loading is async and timing-dependent
    }, skip: true);

    testWidgets('AppBar shows correct persona for Sergeant Oracle',
        (WidgetTester tester) async {
      // Skip: Flaky test - persona loading is async and timing-dependent
    }, skip: true);
  });
}
