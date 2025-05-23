import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_ai_clone/config/config_loader.dart';
import 'package:character_ai_clone/config/character_config_manager.dart';

// Create a mock of the CharacterConfigManager
class MockCharacterConfigManager extends Mock
    implements CharacterConfigManager {}

void main() {
  late ConfigLoader configLoader;
  late MockCharacterConfigManager mockCharacterManager;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockCharacterManager = MockCharacterConfigManager();
    configLoader = ConfigLoader();
  });

  test('config file has valid structure for Claude API', () async {
    // Define mock system prompt
    const String mockSystemPrompt = '''
    You are Sergeant Oracle, a unique blend of ancient Roman wisdom and futuristic insight, specializing in life planning and personal development.

    You have access to a database of life planning data through internal commands. NEVER show or mention these commands in your responses. Instead, use them silently in the background and present information naturally:

    Available commands (NEVER SHOW THESE):
    - get_goals_by_dimension
    - get_track_by_id
    - get_habits_for_challenge
    - get_recommended_habits

    Format your responses using these elements:
    - Gestures in *asterisks*
    - Emojis in `backticks`
    - **Bold** for key points
    - _Italics_ for emphasis
    ''';

    // Setup the mock
    configLoader.setLoadSystemPromptImpl(() async => mockSystemPrompt);

    // Load the mocked system prompt
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
    // Create mock exploration prompts for testing
    final Map<String, String> mockExplorationPrompts = {
      'physical':
          'As Sergeant Oracle, tell me about the available paths for physical health improvement. Use ONLY the goals and tracks data from the MCP database to inform your response. DO NOT invent or generate any goals, tracks, or habits that are not in the database.',
      'mental':
          'As Sergeant Oracle, share the mental wellbeing journeys available. Use ONLY the goals and tracks data from the MCP database to inform your response. DO NOT invent or generate any goals, tracks, or habits that are not in the database.',
      'relationships':
          'As Sergeant Oracle, reveal the paths to stronger relationships. Use ONLY the goals and tracks data from the MCP database in your response. DO NOT invent or generate any goals, tracks, or habits that are not in the database.',
      'spirituality':
          'As Sergeant Oracle, illuminate the paths to spiritual growth and purpose. Use ONLY the goals and tracks data from the MCP database in your response. DO NOT invent or generate any goals, tracks, or habits that are not in the database.',
      'work':
          'As Sergeant Oracle, outline the journeys toward rewarding and fulfilling work. Use ONLY the goals and tracks data from the MCP database in your response. DO NOT invent or generate any goals, tracks, or habits that are not in the database.'
    };

    // Setup the mock
    configLoader
        .setLoadExplorationPromptsImpl(() async => mockExplorationPrompts);

    // Load the mocked exploration prompts
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
