import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import the app's main file
import '../../lib/main.dart';

void main() {
  setUp(() async {
    // Initialize environment variables for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env.test');
    } catch (e) {
      // If .env.test doesn't exist, try to load .env
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        // If .env doesn't exist either, continue with the test
        print(
            'Warning: No .env file found. Tests may fail if environment variables are required.');
      }
    }
  });

  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ChatApp());

    // Verify that the app builds without crashing
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that at least one Scaffold is created
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('App contains basic UI structure', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ChatApp());

    // Allow the app to build
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the app has an AppBar
    expect(find.byType(AppBar), findsWidgets);

    // Verify that the app has at least one Icon
    expect(find.byType(Icon), findsWidgets);

    // Verify that the app has at least one Text widget
    expect(find.byType(Text), findsWidgets);

    // Verify that the app has at least one Container
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('App has essential interactive elements',
      (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ChatApp());

    // Allow the app to build
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the app has a settings icon
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Verify that the app has at least one button
    expect(find.byType(IconButton), findsWidgets);

    // Verify that the app has some text content
    expect(find.byType(Text), findsWidgets);

    // Verify that the app has an AppBar with text
    final appBarFinder = find.byType(AppBar);
    expect(appBarFinder, findsWidgets);

    // Find all Text widgets that are descendants of AppBar
    final appBarTextFinder = find.descendant(
      of: appBarFinder,
      matching: find.byType(Text),
    );
    expect(appBarTextFinder, findsWidgets);
  });
}
