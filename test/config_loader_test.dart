import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/config/config_loader.dart';
import 'dart:convert';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('config file has valid structure for Claude API', () async {
    // Initialize the config loader
    final configLoader = ConfigLoader();
    final systemPrompt = await configLoader.loadSystemPrompt();

    // Verify we got a valid string
    expect(systemPrompt, isA<String>());
    expect(systemPrompt.isNotEmpty, true);

    // Verify it has the required content
    expect(
      systemPrompt.contains('You are Sergeant Oracle'),
      true,
      reason: 'System prompt should define the AI character identity',
    );

    // Verify it contains all required commands
    final requiredCommands = [
      'get_goals_by_dimension',
      'get_track_by_id',
      'get_habits_for_challenge',
      'get_recommended_habits'
    ];

    for (final command in requiredCommands) {
      expect(
        systemPrompt.contains(command),
        true,
        reason: 'System prompt should include the $command command',
      );
    }

    // Verify it contains formatting instructions
    final formattingElements = [
      'Gestures in *asterisks*',
      'Emojis in `backticks`',
      '**Bold**',
      '_Italics_'
    ];

    for (final element in formattingElements) {
      expect(
        systemPrompt.contains(element),
        true,
        reason: 'System prompt should include $element formatting instruction',
      );
    }
  });

  test('config file contains exploration prompts for all dimensions', () async {
    // Initialize the config loader
    final configLoader = ConfigLoader();
    final explorationPrompts = await configLoader.loadExplorationPrompts();

    // Verify we got a valid map
    expect(explorationPrompts, isA<Map<String, String>>());
    expect(explorationPrompts.isNotEmpty, true);

    // Verify it contains prompts for all dimensions
    final requiredDimensions = [
      'physical',
      'mental',
      'relationships',
      'spirituality',
      'work'
    ];

    for (final dimension in requiredDimensions) {
      expect(
        explorationPrompts.containsKey(dimension),
        true,
        reason: 'Exploration prompts should include the $dimension dimension',
      );
      expect(
        explorationPrompts[dimension]!.isNotEmpty,
        true,
        reason: 'Exploration prompt for $dimension should not be empty',
      );
    }

    // Verify prompts contain required instructions
    for (final prompt in explorationPrompts.values) {
      expect(
        prompt.contains(
            'Use ONLY the goals and tracks data from the MCP database'),
        true,
        reason: 'Exploration prompts should instruct to use only MCP data',
      );
      expect(
        prompt
            .contains('DO NOT invent or generate any goals, tracks, or habits'),
        true,
        reason: 'Exploration prompts should instruct not to invent content',
      );
    }
  });
}
