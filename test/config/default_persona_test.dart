import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:character_ai_clone/config/character_config_manager.dart';

void main() {
  group('Default Persona Configuration Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUpAll(() async {
      // Mock the personas_config.json file
      const String mockConfig = '''
{
  "defaultPersona": "ariWithOracle21",
  "personas": {
    "ariLifeCoach": {
      "enabled": true,
      "displayName": "Ari - Life Coach",
      "description": "TARS-inspired life coach",
      "configPath": "assets/config/ari_life_coach_config_2.0.json"
    },
    "ariWithOracle21": {
      "enabled": true,
      "displayName": "Ari 2.1",
      "description": "Life coach with Oracle 2.1 knowledge base",
      "configPath": "assets/config/ari_life_coach_config_2.0.json",
      "oracleConfigPath": "assets/config/oracle/oracle_prompt_2.1.md"
    }
  }
}
''';

      // Set up the mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        return ByteData.view(Uint8List.fromList(mockConfig.codeUnits).buffer);
      });
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('should read defaultPersona from config and set as active', () async {
      // Create a new instance for testing
      final manager = CharacterConfigManager();
      
      // Verify initial state (should be hardcoded default)
      expect(manager.activePersonaKey, equals('ariLifeCoach'));
      expect(manager.isInitialized, isFalse);
      
      // Initialize the manager
      await manager.initialize();
      
      // Verify it was initialized
      expect(manager.isInitialized, isTrue);
      
      // Verify the default persona was read and set
      expect(manager.activePersonaKey, equals('ariWithOracle21'));
    });

    test('should handle missing defaultPersona gracefully', () async {
      // Mock config without defaultPersona
      const String mockConfigNoDefault = '''
{
  "personas": {
    "ariLifeCoach": {
      "enabled": true,
      "displayName": "Ari - Life Coach",
      "description": "TARS-inspired life coach",
      "configPath": "assets/config/ari_life_coach_config_2.0.json"
    }
  }
}
''';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        return ByteData.view(Uint8List.fromList(mockConfigNoDefault.codeUnits).buffer);
      });

      final manager = CharacterConfigManager();
      final initialPersona = manager.activePersonaKey;
      
      await manager.initialize();
      
      // Should keep the initial persona if no defaultPersona is specified
      expect(manager.activePersonaKey, equals(initialPersona));
      expect(manager.isInitialized, isTrue);
    });

    test('should handle invalid defaultPersona gracefully', () async {
      // Mock config with invalid defaultPersona
      const String mockConfigInvalid = '''
{
  "defaultPersona": "nonexistentPersona",
  "personas": {
    "ariLifeCoach": {
      "enabled": true,
      "displayName": "Ari - Life Coach",
      "description": "TARS-inspired life coach",
      "configPath": "assets/config/ari_life_coach_config_2.0.json"
    }
  }
}
''';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        return ByteData.view(Uint8List.fromList(mockConfigInvalid.codeUnits).buffer);
      });

      final manager = CharacterConfigManager();
      final initialPersona = manager.activePersonaKey;
      
      await manager.initialize();
      
      // Should keep the initial persona if defaultPersona doesn't exist
      expect(manager.activePersonaKey, equals(initialPersona));
      expect(manager.isInitialized, isTrue);
    });

    test('should handle config loading errors gracefully', () async {
      // Mock config that will cause an error
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        throw Exception('Mock error loading config');
      });

      final manager = CharacterConfigManager();
      final initialPersona = manager.activePersonaKey;
      
      await manager.initialize();
      
      // Should keep the initial persona if config loading fails
      expect(manager.activePersonaKey, equals(initialPersona));
      expect(manager.isInitialized, isTrue);
    });
  });
}

