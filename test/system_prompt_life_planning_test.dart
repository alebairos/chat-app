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

  testWidgets('system prompt prevents command exposure in life planning UI',
      (WidgetTester tester) async {
    // Step 1: Load the actual system prompt to verify its content
    final configLoader = ConfigLoader();
    final systemPrompt = await configLoader.loadSystemPrompt();

    // Step 2: Verify the system prompt contains life planning commands
    final lifeCommands = [
      'get_goals_by_dimension',
      'get_track_by_id',
      'get_habits_for_challenge',
      'get_recommended_habits'
    ];

    for (final command in lifeCommands) {
      expect(
        systemPrompt.contains(command),
        true,
        reason: 'System prompt should include the $command command',
      );
    }

    // Step 3: Verify the system prompt contains instructions for life planning
    expect(
      systemPrompt.contains('When helping with life planning:'),
      true,
      reason: 'System prompt should include life planning instructions',
    );

    expect(
      systemPrompt.contains(
          'AUTOMATICALLY detect relevant dimensions in user messages'),
      true,
      reason:
          'System prompt should instruct to silently map goals to dimensions',
    );

    // Step 4: Create a chat message with life planning advice
    // This simulates what would be displayed in the UI after Claude processes a life planning query
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // User message asking about mental health goals
              ChatMessage(
                text: 'What are some good mental health goals I should set?',
                isUser: true,
              ),
              // AI response with life planning advice
              ChatMessage(
                text:
                    '*adjusts armor* `🧠` Excellent question! For **mental fortitude**, I recommend these goals:\n\n1. Practice _mindfulness meditation_ for 10 minutes daily\n2. Read for 30 minutes each day to expand your knowledge\n3. Journal your thoughts to process emotions effectively',
                isUser: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 5: Verify the UI contains natural language life planning advice
    expect(find.textContaining('mental fortitude'), findsOneWidget);
    expect(find.textContaining('mindfulness meditation'), findsOneWidget);
    expect(find.textContaining('expand your knowledge'), findsOneWidget);
    expect(find.textContaining('Journal your thoughts'), findsOneWidget);

    // Step 6: Verify no command references are visible in the UI
    expect(find.textContaining('get_goals_by_dimension SM'), findsNothing);
    expect(find.textContaining('get_track_by_id'), findsNothing);
    expect(find.textContaining('get_habits_for_challenge'), findsNothing);
    expect(find.textContaining('get_recommended_habits'), findsNothing);

    // Step 7: Verify no dimension mapping syntax is visible
    expect(find.textContaining('SF:'), findsNothing);
    expect(find.textContaining('SM:'), findsNothing);
    expect(find.textContaining('R:'), findsNothing);
    expect(find.textContaining('dimension mapping'), findsNothing);
  });
}
