import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';

// Import the app's main file and other necessary components
import '../../lib/main.dart';
import '../../lib/screens/chat_screen.dart';
import '../../lib/widgets/chat_input.dart';
import '../../lib/services/claude_service.dart';

class MockClaudeService extends Mock implements ClaudeService {}

void main() {
  setUp(() async {
    // Initialize environment variables for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env.test');
    } catch (e) {
      // If .env.test doesn't exist, try to load .env
      await dotenv.load(fileName: '.env');
    }
  });

  testWidgets('App launches and maintains basic functionality',
      (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ChatApp());

    // Verify app launches with the correct title
    expect(find.textContaining('Character.ai'), findsOneWidget);

    // Verify we can interact with the chat input
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    // Enter text in the chat input
    await tester.enterText(textFieldFinder, 'Test message');
    expect(find.text('Test message'), findsOneWidget);

    // Verify send button exists
    final sendButtonFinder = find.byIcon(Icons.send);
    expect(sendButtonFinder, findsOneWidget);

    // Note: We won't tap the send button in this test as it would trigger
    // actual API calls. In a real implementation, we would mock the API.
    // This test just verifies the UI elements exist and are interactive.

    // Verify other important UI elements
    expect(find.textContaining('This is A.I. and not a real person'),
        findsOneWidget);
  });

  testWidgets('Chat input handles text correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ChatApp());

    // Find the text field
    final textFieldFinder = find.byType(TextField);

    // Enter text
    await tester.enterText(textFieldFinder, 'Hello world');
    expect(find.text('Hello world'), findsOneWidget);

    // Clear text
    await tester.enterText(textFieldFinder, '');
    expect(find.text('Hello world'), findsNothing);

    // Enter new text
    await tester.enterText(textFieldFinder, 'New message');
    expect(find.text('New message'), findsOneWidget);
  });

  testWidgets('App UI layout is correct', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ChatApp());

    // Verify basic layout structure
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsWidgets);
    expect(find.byType(Column), findsWidgets);

    // Verify text field exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify send button exists
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
