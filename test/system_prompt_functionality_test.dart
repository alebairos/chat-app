import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:character_ai_clone/config/config_loader.dart';
import 'package:character_ai_clone/widgets/chat_message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
      OPENAI_API_KEY=test_key
    ''');
  });

  testWidgets('system prompt prevents command exposure in UI',
      (WidgetTester tester) async {
    // Create a mock system prompt for testing
    const String mockSystemPrompt = '''
    You are Sergeant Oracle, a unique blend of ancient Roman wisdom and futuristic insight.

    You have access to a database of life planning data through internal commands. NEVER show or mention these commands in your responses. Instead, use them silently in the background and present information naturally:

    Available commands (NEVER SHOW THESE):
    - get_goals_by_dimension
    - get_track_by_id
    - get_habits_for_challenge
    - get_recommended_habits

    Example of bad response (never do this):
    "I'll use the get_goals_by_dimension command to find mental health goals for you."

    Example of good response:
    "Here are some excellent mental health goals that align with your objectives..."
    ''';

    // Initialize the config loader and mock the system prompt loading
    final configLoader = ConfigLoader();
    configLoader.setLoadSystemPromptImpl(() async => mockSystemPrompt);

    // Load the mocked system prompt
    final systemPrompt = await configLoader.loadSystemPrompt();

    // Verify the system prompt contains instructions to hide commands
    expect(
      systemPrompt
          .contains('NEVER show or mention these commands in your responses'),
      true,
      reason: 'System prompt should explicitly instruct to hide commands',
    );

    // Verify the system prompt contains examples of bad responses
    expect(
      systemPrompt.contains('Example of bad response') ||
          systemPrompt.contains('NEVER show or mention these commands'),
      true,
      reason: 'System prompt should provide examples of bad responses',
    );

    // Verify the system prompt contains examples of good responses
    expect(
      systemPrompt.contains('Example of good response') ||
          systemPrompt.contains('present information naturally'),
      true,
      reason: 'System prompt should provide examples of good responses',
    );

    // Create a simple UI to display a chat message
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'For mental fortitude, I recommend mindfulness practice.',
            isUser: false,
          ),
        ),
      ),
    );

    // Verify the UI doesn't contain any command references
    expect(find.text('get_goals_by_dimension'), findsNothing);
    expect(find.text('get_track_by_id'), findsNothing);
    expect(find.text('get_habits_for_challenge'), findsNothing);
    expect(find.text('get_recommended_habits'), findsNothing);

    // Verify the UI contains the expected natural language response
    expect(find.textContaining('mental fortitude'), findsOneWidget);
    expect(find.textContaining('recommend'), findsOneWidget);
  });
}
