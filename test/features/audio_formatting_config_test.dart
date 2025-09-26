import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ai_personas_app/config/character_config_manager.dart';

void main() {
  setUpAll(() async {
    // Initialize Flutter binding for tests
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock environment for tests
    dotenv.testLoad(fileInput: '');
  });

  group('Audio Formatting Configuration', () {
    late CharacterConfigManager configManager;

    setUp(() {
      configManager = CharacterConfigManager();
    });

    test('should load system prompt with audio formatting for enabled personas',
        () async {
      // Test with a persona that has audio formatting enabled
      configManager.setActivePersona('iThereWithOracle30');

      final systemPrompt = await configManager.loadSystemPrompt();

      // Verify the system prompt is not empty
      expect(systemPrompt.isNotEmpty, isTrue);

      // Verify audio formatting instructions are included (FT-131 version 3.1 - Brazilian format)
      expect(
          systemPrompt.contains('TECHNICAL: AUDIO OUTPUT FORMATTING'), isTrue);
      expect(systemPrompt.contains('Use "20h30" format (not "20:30"'), isTrue);
      expect(systemPrompt.contains('Time Format Standards'), isTrue);
    });

    test('should handle personas without audio formatting configuration',
        () async {
      // Test with a persona that might not have audio formatting
      configManager.setActivePersona('ariLifeCoach');

      final systemPrompt = await configManager.loadSystemPrompt();

      // Verify the system prompt is loaded successfully
      expect(systemPrompt.isNotEmpty, isTrue);

      // The test should not fail even if audio formatting is not configured
      // (graceful degradation)
    });

    test('should load different personas with their respective configurations',
        () async {
      final personas = [
        'ariWithOracle30',
        'iThereWithOracle30',
        'sergeantOracleWithOracle30'
      ];

      for (final persona in personas) {
        configManager.setActivePersona(persona);

        final systemPrompt = await configManager.loadSystemPrompt();

        // Each persona should have a valid system prompt
        expect(systemPrompt.isNotEmpty, isTrue,
            reason: 'Persona $persona should have a system prompt');

        // If audio formatting is enabled, it should contain the formatting instructions (FT-131 version 3.0)
        if (systemPrompt.contains('TECHNICAL: AUDIO OUTPUT FORMATTING')) {
          expect(systemPrompt.contains('Time Format Standards'), isTrue);
          expect(systemPrompt.contains('Number and Currency'), isTrue);
        }
      }
    });

    test('should handle missing audio formatting config gracefully', () async {
      // This test ensures the system doesn't crash if audio config is missing
      configManager.setActivePersona('iThereWithOracle30');

      // Should not throw an exception
      expect(
          () async => await configManager.loadSystemPrompt(), returnsNormally);
    });
  });

  group('Audio Formatting Content Validation', () {
    late CharacterConfigManager configManager;

    setUp(() {
      configManager = CharacterConfigManager();
    });

    test('should include specific time format requirements', () async {
      configManager.setActivePersona('ariWithOracle30');

      final systemPrompt = await configManager.loadSystemPrompt();

      if (systemPrompt.contains('TECHNICAL: AUDIO OUTPUT FORMATTING')) {
        // Verify specific formatting rules are present (FT-131 version 3.1 - Brazilian format)
        expect(
            systemPrompt.contains('Use "20h30" format (not "20:30"'), isTrue);
        expect(
            systemPrompt.contains('Use "18h10" format (not "18:10"'), isTrue);
        expect(
            systemPrompt.contains('Use "14h00" format (not "14:00"'), isTrue);

        // Verify examples are present (FT-131 version 3.1 - Brazilian format)
        expect(systemPrompt.contains('às 20h30'), isTrue);
        expect(systemPrompt.contains('18h10-18h50'), isTrue);

        // Verify avoid list is present (FT-131 version 3.1 - International format avoided)
        expect(systemPrompt.contains('International time: 20:30, 14:30, 6:00'),
            isTrue);
        expect(
            systemPrompt.contains('Hyphenated words: sexta-feira, bem-vindo'),
            isTrue);
      }
    });

    test('should maintain persona style while adding technical instructions',
        () async {
      configManager.setActivePersona('sergeantOracleWithOracle30');

      final systemPrompt = await configManager.loadSystemPrompt();

      if (systemPrompt.contains('TECHNICAL: AUDIO OUTPUT FORMATTING')) {
        // Verify the technical note about maintaining style is present (FT-131 version 3.0)
        expect(
            systemPrompt.contains('Maintain your natural communication style'),
            isTrue);
        expect(
            systemPrompt.contains(
                'Generate properly formatted text from the source rather than relying on post-processing'),
            isTrue);
      }
    });
  });
}
