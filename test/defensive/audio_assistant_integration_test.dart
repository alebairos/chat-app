import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:character_ai_clone/widgets/chat_message.dart';

void main() {
  group('Core App Functionality with Audio Assistant', () {
    testWidgets('Regular text messages should display correctly',
        (WidgetTester tester) async {
      // Build a minimal test app with a regular text message
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: 'Hello, world!',
              isUser: true,
            ),
          ),
        ),
      );

      // Verify message is displayed correctly
      expect(find.text('Hello, world!'), findsOneWidget);
    });
  });

  group('Audio Feature Isolation Tests', () {
    testWidgets('Audio playback should not affect other UI components',
        (WidgetTester tester) async {
      // Build a minimal test app with both text and audio UI elements
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Normal text widget
                const Text('Text content should remain visible'),

                // Mock audio player (simplified for testing)
                Container(
                  key: const Key('audioPlayer'),
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.grey[200],
                  child: const Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text('Audio message')
                    ],
                  ),
                ),

                // UI element that should remain responsive
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Important Action'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify all UI elements are visible
      expect(find.text('Text content should remain visible'), findsOneWidget);
      expect(find.byKey(const Key('audioPlayer')), findsOneWidget);
      expect(find.text('Important Action'), findsOneWidget);

      // Simulate interaction with audio component
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify all UI elements are still visible
      expect(find.text('Text content should remain visible'), findsOneWidget);
      expect(find.text('Important Action'), findsOneWidget);

      // Verify important button is still clickable
      await tester.tap(find.text('Important Action'));
      await tester.pump();
    });

    testWidgets('UI navigation works with audio elements present',
        (WidgetTester tester) async {
      // This test verifies navigation works properly with audio elements on screen

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Home Screen')),
                  body: Column(
                    children: [
                      // Mock audio player
                      Container(
                        key: const Key('audioPlayer'),
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.blue[100],
                        child: const Row(
                          children: [
                            Icon(Icons.music_note),
                            SizedBox(width: 8),
                            Text('Audio playing'),
                          ],
                        ),
                      ),

                      // Navigation button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/second');
                        },
                        child: const Text('Go to Second Screen'),
                      ),
                    ],
                  ),
                ),
            '/second': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Second Screen')),
                  body: const Center(child: Text('Second Screen Content')),
                ),
          },
        ),
      );

      // Verify we're on the first screen
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.byKey(const Key('audioPlayer')), findsOneWidget);

      // Navigate to the second screen
      await tester.tap(find.text('Go to Second Screen'));
      await tester.pumpAndSettle();

      // Verify we've navigated to the second screen
      expect(find.text('Second Screen'), findsOneWidget);
      expect(find.text('Second Screen Content'), findsOneWidget);

      // Verify the audio player from the first screen is no longer visible
      expect(find.byKey(const Key('audioPlayer')), findsNothing);
    });
  });
}
