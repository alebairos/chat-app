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

  testWidgets(
      'system prompt character identity is reflected in UI without exposing commands',
      (WidgetTester tester) async {
    // Step 1: Load the actual system prompt to verify its content
    final configLoader = ConfigLoader();
    final systemPrompt = await configLoader.loadSystemPrompt();

    // Step 2: Verify the system prompt contains character identity elements
    expect(
      systemPrompt.contains('You are Sergeant Oracle'),
      true,
      reason: 'System prompt should define the character identity',
    );

    expect(
      systemPrompt.contains('ancient Roman wisdom and futuristic insight'),
      true,
      reason: 'System prompt should describe character background',
    );

    // Step 3: Verify the system prompt contains instructions to hide commands
    expect(
      systemPrompt
          .contains('NEVER show or mention these commands in your responses'),
      true,
      reason: 'System prompt should explicitly instruct to hide commands',
    );

    // Step 4: Create a chat message with character-specific formatting
    // This simulates what would be displayed in the UI after Claude processes a message
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // First message - character identity with Latin phrase
              ChatMessage(
                text:
                    '*adjusts chronometer* `⚔️` Salve, time wanderer! For mental fortitude, I recommend these **cornerstones of wisdom**:\n\n1. Practice _mindfulness_ daily\n2. As we Romans say, "_doctrina vim promovet insitam_"',
                isUser: false,
              ),
              // Second message - character identity with advice
              ChatMessage(
                text:
                    'The path to mental strength requires **consistent practice** and _disciplined routine_. *nods firmly*',
                isUser: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 5: Verify character-specific formatting is preserved in the UI
    expect(find.textContaining('adjusts chronometer'), findsOneWidget);
    expect(find.textContaining('Salve'), findsOneWidget);
    expect(find.textContaining('cornerstones of wisdom'), findsOneWidget);
    expect(find.textContaining('mindfulness'), findsOneWidget);
    expect(
        find.textContaining('doctrina vim promovet insitam'), findsOneWidget);
    expect(find.textContaining('consistent practice'), findsOneWidget);
    expect(find.textContaining('disciplined routine'), findsOneWidget);
    expect(find.textContaining('nods firmly'), findsOneWidget);

    // Step 6: Verify no command references are visible in the UI
    expect(find.textContaining('get_goals_by_dimension'), findsNothing);
    expect(find.textContaining('get_track_by_id'), findsNothing);
    expect(find.textContaining('get_habits_for_challenge'), findsNothing);
    expect(find.textContaining('get_recommended_habits'), findsNothing);

    // Step 7: Verify no command execution syntax is visible
    expect(find.textContaining('Running command'), findsNothing);
    expect(find.textContaining('Track ID'), findsNothing);
    expect(find.textContaining('Command result:'), findsNothing);
  });
}
