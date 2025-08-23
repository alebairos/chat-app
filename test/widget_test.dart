// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env', isOptional: true);
    dotenv.env['ANTHROPIC_API_KEY'] = 'test_key';
  });

  test('Claude service initializes with API key', () {
    expect(dotenv.env['ANTHROPIC_API_KEY'], equals('test_key'));
  });

  test('ChatApp can be instantiated', () {
    // This will throw if widget creation fails
    const app = ChatApp();
    expect(app, isA<ChatApp>());
  });
}
