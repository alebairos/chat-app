import 'package:flutter_test/flutter_test.dart';
import '../../lib/config/character_config_manager.dart';
import '../../lib/config/config_loader.dart';
import 'dart:convert';

void main() {
  group('Ari Brevity Compliance Tests (ft_013)', () {
    late Map<String, dynamic> ariConfig;
    late String systemPrompt;
    late Map<String, dynamic> explorationPrompts;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Load Ari configuration
      final configManager = CharacterConfigManager();
      configManager.setActivePersona('ariLifeCoach');

      try {
        systemPrompt = await configManager.loadSystemPrompt();
        explorationPrompts = await configManager.loadExplorationPrompts();

        // Create a mock config structure for compatibility
        ariConfig = {
          'system_prompt': {'content': systemPrompt},
          'exploration_prompts': explorationPrompts
        };
      } catch (e) {
        throw Exception('Failed to load Ari configuration: $e');
      }
    });

    group('Welcome Message Compliance', () {
      test('should have welcome message with 3-6 words', () {
        // Extract welcome message from system prompt
        final welcomeMessageMatch =
            RegExp(r"Welcome message: '([^']+)'").firstMatch(systemPrompt);
        expect(welcomeMessageMatch, isNotNull,
            reason: 'Welcome message not found in system prompt');

        final welcomeMessage = welcomeMessageMatch!.group(1)!;
        final wordCount = welcomeMessage.split(' ').length;

        expect(wordCount, greaterThanOrEqualTo(3),
            reason: 'Welcome message too short: "$welcomeMessage"');
        expect(wordCount, lessThanOrEqualTo(6),
            reason: 'Welcome message too long: "$welcomeMessage"');
        expect(welcomeMessage, equals('What needs fixing first?'));
      });
    });

    group('Exploration Prompts Brevity', () {
      test('should have exploration prompts with ≤6 words each', () {
        explorationPrompts.forEach((dimension, prompt) {
          final wordCount = prompt.toString().split(' ').length;
          expect(wordCount, lessThanOrEqualTo(6),
              reason:
                  'Exploration prompt for $dimension too long: "$prompt" ($wordCount words)');
        });
      });

      test('should have exploration prompts ending with question marks', () {
        explorationPrompts.forEach((dimension, prompt) {
          expect(prompt.toString().endsWith('?'), isTrue,
              reason:
                  'Exploration prompt for $dimension should end with ?: "$prompt"');
        });
      });
    });

    group('Communication Pattern Rules', () {
      test('should contain TARS-inspired brevity section', () {
        expect(
            systemPrompt
                .contains('COMMUNICATION PATTERN - TARS-INSPIRED BREVITY'),
            isTrue);
      });

      test('should specify first message 3-6 words maximum', () {
        expect(systemPrompt.contains('First message:** 3-6 words maximum'),
            isTrue);
      });

      test('should specify messages 2-3 single sentence responses', () {
        expect(
            systemPrompt.contains('Messages 2-3:** Single sentence responses'),
            isTrue);
      });

      test('should specify maximum 2 short paragraphs ever', () {
        expect(systemPrompt.contains('Maximum ever:** 2 short paragraphs'),
            isTrue);
      });

      test('should include engagement progression stages', () {
        expect(systemPrompt.contains('ENGAGEMENT PROGRESSION'), isTrue);
        expect(systemPrompt.contains('Opening:** "What needs fixing first?"'),
            isTrue);
        expect(
            systemPrompt
                .contains('Validation:** "How long has this bothered you?"'),
            isTrue);
        expect(
            systemPrompt.contains(
                'Precision:** "What\'s the smallest change you\'d notice?"'),
            isTrue);
        expect(
            systemPrompt.contains('Action:** "When will you start?"'), isTrue);
        expect(systemPrompt.contains('Support:** Only then provide frameworks'),
            isTrue);
      });
    });

    group('Forbidden Phrases Detection', () {
      final forbiddenPhrases = [
        'I understand that...',
        'It\'s important to note...',
        'As a life coach...',
        'Based on research...',
        'Let me explain...',
        'What I\'m hearing is...',
        'In addition to that...',
        'Furthermore...',
        'On the other hand...',
        'It\'s worth mentioning...',
      ];

      test('should include all forbidden phrases in system prompt', () {
        expect(systemPrompt.contains('FORBIDDEN PHRASES'), isTrue);

        for (final phrase in forbiddenPhrases) {
          expect(systemPrompt.contains(phrase), isTrue,
              reason: 'Forbidden phrase not found in system prompt: "$phrase"');
        }
      });

      test('should specify no phrases longer than 4 words without value', () {
        expect(
            systemPrompt.contains(
                'Any phrase longer than 4 words that doesn\'t add direct value'),
            isTrue);
      });
    });

    group('Approved Response Patterns', () {
      final discoveryPatterns = [
        'What\'s broken?',
        'Since when?',
        'How often?',
        'What\'s working?',
      ];

      final actionPatterns = [
        'Next step?',
        'When?',
        'Why that?',
        'How to know?',
      ];

      final supportPatterns = [
        'Try this: [specific habit ID]',
        'Track: [specific metric]',
        'Celebrate: [specific achievement]',
      ];

      test('should include discovery phase patterns', () {
        expect(systemPrompt.contains('APPROVED RESPONSE PATTERNS'), isTrue);
        expect(systemPrompt.contains('Discovery Phase:'), isTrue);

        for (final pattern in discoveryPatterns) {
          expect(systemPrompt.contains(pattern), isTrue,
              reason: 'Discovery pattern not found: "$pattern"');
        }
      });

      test('should include action phase patterns', () {
        expect(systemPrompt.contains('Action Phase:'), isTrue);

        for (final pattern in actionPatterns) {
          expect(systemPrompt.contains(pattern), isTrue,
              reason: 'Action pattern not found: "$pattern"');
        }
      });

      test('should include support phase patterns', () {
        expect(systemPrompt.contains('Support Phase:'), isTrue);

        for (final pattern in supportPatterns) {
          expect(systemPrompt.contains(pattern), isTrue,
              reason: 'Support pattern not found: "$pattern"');
        }
      });

      test(
          'should have approved patterns with ≤3 words each (excluding templates)',
          () {
        final allPatterns = [...discoveryPatterns, ...actionPatterns];

        for (final pattern in allPatterns) {
          final wordCount = pattern.split(' ').length;
          expect(wordCount, lessThanOrEqualTo(3),
              reason:
                  'Approved pattern too long: "$pattern" ($wordCount words)');
        }
      });
    });

    group('Word Economy Principles', () {
      test('should include word economy principles section', () {
        expect(systemPrompt.contains('WORD ECONOMY PRINCIPLES'), isTrue);
      });

      test('should specify cutting filler words', () {
        expect(systemPrompt.contains('Cut all filler words'), isTrue);
        expect(
            systemPrompt.contains('"I think", "perhaps", "it seems"'), isTrue);
      });

      test('should specify active voice exclusively', () {
        expect(systemPrompt.contains('Use active voice exclusively'), isTrue);
      });

      test('should specify one idea per sentence', () {
        expect(systemPrompt.contains('One idea per sentence'), isTrue);
      });

      test('should specify questions > statements ratio', () {
        expect(systemPrompt.contains('Questions > statements'), isTrue);
      });

      test('should specify concrete > abstract language', () {
        expect(systemPrompt.contains('Concrete > abstract language'), isTrue);
      });

      test('should specify present > future tense', () {
        expect(systemPrompt.contains('Present > future tense'), isTrue);
      });
    });

    group('Interaction Style Enforcement', () {
      test('should enforce TARS-like brevity in interaction style', () {
        expect(systemPrompt.contains('INTERACTION STYLE'), isTrue);
        expect(systemPrompt.contains('Start with maximum brevity'), isTrue);
        expect(systemPrompt.contains('Apply TARS-like intelligent brevity'),
            isTrue);
        expect(systemPrompt.contains('Never use forbidden phrases'), isTrue);
        expect(
            systemPrompt
                .contains('Follow engagement progression stages strictly'),
            isTrue);
      });

      test('should specify question-heavy early conversations', () {
        expect(systemPrompt.contains('Question-heavy early conversations'),
            isTrue);
      });

      test('should specify evidence-light initially', () {
        expect(systemPrompt.contains('Evidence-light initially'), isTrue);
      });
    });

    group('Configuration Consistency', () {
      test('should have consistent configuration between assets and lib',
          () async {
        // This test ensures the configuration can be loaded successfully
        final configManager = CharacterConfigManager();
        configManager.setActivePersona('ariLifeCoach');

        // Test that configuration loads without error
        expect(
            () async => await configManager.loadSystemPrompt(), returnsNormally,
            reason: 'Ari system prompt should load without errors');

        expect(() async => await configManager.loadExplorationPrompts(),
            returnsNormally,
            reason: 'Ari exploration prompts should load without errors');

        // Verify the loaded configuration has the expected structure
        final loadedSystemPrompt = await configManager.loadSystemPrompt();
        final loadedExplorationPrompts =
            await configManager.loadExplorationPrompts();

        expect(loadedSystemPrompt.isNotEmpty, isTrue,
            reason: 'System prompt should not be empty');
        expect(loadedExplorationPrompts.isNotEmpty, isTrue,
            reason: 'Exploration prompts should not be empty');
      });
    });
  });
}
