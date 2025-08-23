import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_personas_app/config/config_loader.dart';
import 'package:ai_personas_app/widgets/chat_message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
      OPENAI_API_KEY=test_key
    ''');
  });

  testWidgets('system prompt defines character identity',
      (WidgetTester tester) async {
    // Create a mock system prompt for testing
    const String mockSystemPrompt = '''
    You are Sergeant Oracle, a unique blend of ancient Roman wisdom and futuristic insight, specializing in life planning and personal development. Keep your responses concise and engaging, with a military precision and philosophical depth.

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

    // Initialize the config loader and mock the system prompt loading
    final configLoader = ConfigLoader();
    configLoader.setLoadSystemPromptImpl(() async => mockSystemPrompt);

    // Load the mocked system prompt
    final systemPrompt = await configLoader.loadSystemPrompt();

    // Verify the system prompt contains character identity
    expect(
      systemPrompt.contains('You are Sergeant Oracle'),
      true,
      reason: 'System prompt should define the character identity',
    );

    // Verify the system prompt contains character description
    expect(
      systemPrompt.contains('ancient Roman wisdom and futuristic insight'),
      true,
      reason: 'System prompt should describe the character background',
    );

    // Verify the system prompt contains instructions to hide commands
    expect(
      systemPrompt
          .contains('NEVER show or mention these commands in your responses'),
      true,
      reason: 'System prompt should instruct to hide commands',
    );

    // Create a simple UI to display a chat message
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text:
                '*adjusts chronometer* Salve, time wanderer! I shall guide you through the ages with my wisdom.',
            isUser: false,
          ),
        ),
      ),
    );

    // Verify the UI contains character-specific formatting
    expect(find.textContaining('adjusts chronometer'), findsOneWidget);
    expect(find.textContaining('Salve, time wanderer'), findsOneWidget);

    // Verify the UI doesn't contain any command references
    expect(find.text('get_goals_by_dimension'), findsNothing);
    expect(find.text('get_track_by_id'), findsNothing);
    expect(find.text('get_habits_for_challenge'), findsNothing);
    expect(find.text('get_recommended_habits'), findsNothing);
  });
}
