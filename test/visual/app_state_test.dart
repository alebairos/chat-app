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
}
