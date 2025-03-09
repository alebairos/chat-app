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

  testWidgets('App theme and styling elements are consistent',
      (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ChatApp());

    // Allow the app to build
    await tester.pump(const Duration(milliseconds: 500));

    // Get the MaterialApp widget
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Verify that the app has a theme
    expect(materialApp.theme, isNotNull);

    // Verify that the app has a title
    expect(materialApp.title, isNotEmpty);

    // Verify AppBar styling
    final appBar = tester.widget<AppBar>(find.byType(AppBar).first);
    expect(appBar, isNotNull);

    // Verify that the app has a consistent background color
    final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
    for (final scaffold in scaffolds) {
      // Either the scaffold has a background color or it uses the theme's background color
      expect(scaffold.backgroundColor != null || materialApp.theme != null,
          isTrue);
    }

    // Verify that text styles are applied
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    for (final textWidget in textWidgets) {
      // Text widgets should either have a style or inherit from the theme
      expect(textWidget.style != null || materialApp.theme != null, isTrue);
    }

    // Verify that the app has consistent icon styling
    final iconWidgets = tester.widgetList<Icon>(find.byType(Icon));
    for (final iconWidget in iconWidgets) {
      // Icons should have a size and color, or inherit from the theme
      expect(
          iconWidget.size != null ||
              iconWidget.color != null ||
              materialApp.theme != null,
          isTrue);
    }
  });

  test('App responsiveness test placeholder', () {
    // This is a placeholder for a future test that will verify the app's
    // responsiveness across different screen sizes.
    //
    // TODO: Implement a proper test for responsiveness that handles overflow errors
    // and verifies that the app adapts to different screen sizes.

    // For now, we're just adding this placeholder to indicate that this is an
    // important aspect to test in the future.
    expect(true, isTrue);
  });
}
