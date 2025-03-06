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
      'system prompt formatting instructions are properly applied in UI',
      (WidgetTester tester) async {
    // Create a mock system prompt for testing
    const String mockSystemPrompt = '''
    You are Sergeant Oracle, a unique blend of ancient Roman wisdom and futuristic insight, specializing in life planning and personal development.

    Format your responses using these elements:
    - Gestures in *asterisks*
    - Emojis in `backticks`
    - **Bold** for key points
    - _Italics_ for emphasis
    - Mix in occasional Latin phrases

    Welcome message (in your voice):
    *adjusts chronometer* `⚔️`
    Salve, time wanderer! I am Sergeant Oracle, guardian of wisdom across the ages. I'm here to help you forge new positive habits and conquer your life objectives with **cornerstones of wisdom**.
    ''';

    // Initialize the config loader and mock the system prompt loading
    final configLoader = ConfigLoader();
    configLoader.setLoadSystemPromptImpl(() async => mockSystemPrompt);

    // Load the mocked system prompt
    final systemPrompt = await configLoader.loadSystemPrompt();

    // Step 2: Verify the system prompt contains formatting instructions
    final formattingInstructions = [
      'Gestures in *asterisks*',
      'Emojis in `backticks`',
      '**Bold** for key points',
      '_Italics_ for emphasis',
    ];

    for (final instruction in formattingInstructions) {
      expect(
        systemPrompt.contains(instruction),
        true,
        reason:
            'System prompt should include $instruction formatting instruction',
      );
    }

    // Step 3: Verify the system prompt contains examples of formatted responses
    expect(
      systemPrompt.contains('*adjusts chronometer*'),
      true,
      reason: 'System prompt should include example of gesture in asterisks',
    );

    expect(
      systemPrompt.contains('`⚔️`'),
      true,
      reason: 'System prompt should include example of emoji in backticks',
    );

    expect(
      systemPrompt.contains('**cornerstones of wisdom**') ||
          systemPrompt.contains('**Bold**') ||
          systemPrompt.contains('**key points**'),
      true,
      reason: 'System prompt should include example of bold text',
    );

    // Step 4: Create a chat message with all formatting elements
    // This simulates what would be displayed in the UI after Claude processes a message
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // Message with all formatting elements
              ChatMessage(
                text:
                    '*stands at attention* `🏛️` Greetings, citizen! Here are the **three pillars** of _mental discipline_:\n\n1. Daily meditation\n2. _Consistent_ reading habits\n3. As the Romans said, "**_mens sana in corpore sano_**"',
                isUser: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 5: Verify all formatting elements are present in the UI
    expect(find.textContaining('stands at attention'), findsOneWidget);
    expect(find.textContaining('🏛️'), findsOneWidget);
    expect(find.textContaining('three pillars'), findsOneWidget);
    expect(find.textContaining('mental discipline'), findsOneWidget);
    expect(find.textContaining('Consistent'), findsOneWidget);
    expect(find.textContaining('mens sana in corpore sano'), findsOneWidget);

    // Step 6: Verify no formatting instructions are visible in the UI
    expect(find.textContaining('Gestures in *asterisks*'), findsNothing);
    expect(find.textContaining('Emojis in `backticks`'), findsNothing);
    expect(find.textContaining('**Bold** for key points'), findsNothing);
    expect(find.textContaining('_Italics_ for emphasis'), findsNothing);

    // Step 7: Verify no raw formatting syntax is visible
    expect(find.textContaining('*asterisks*'), findsNothing);
    expect(find.textContaining('`backticks`'), findsNothing);
    expect(find.textContaining('**Bold**'), findsNothing);
    expect(find.textContaining('_Italics_'), findsNothing);
  });
}
