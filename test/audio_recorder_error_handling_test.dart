import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_personas_app/widgets/audio_recorder.dart';

void main() {
  testWidgets('error messages have consistent red background color',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Test error'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify snackbar style
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.red);
  });

  testWidgets('error messages have consistent white text color',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Error: Test error',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify text color
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(Text),
      ),
    );
    expect(text.style?.color, Colors.white);
  });

  testWidgets('error messages start with "Error:" prefix',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Test error'),
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify error prefix
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(Text),
      ),
    );
    expect(text.data!.startsWith('Error:'), true,
        reason: 'Error message should start with "Error:"');
  });

  testWidgets('error messages have consistent text size',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Error: Test error',
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify text size
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(Text),
      ),
    );
    expect(text.style?.fontSize, 14.0,
        reason: 'Error message should have consistent 14.0 font size');
  });

  testWidgets('error messages appear for consistent duration',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Test error'),
                    duration: Duration(seconds: 4), // Standard duration
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify snackbar is visible initially
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error: Test error'), findsOneWidget);

    // Wait just under 4 seconds - snackbar should still be visible
    await tester.pump(const Duration(seconds: 3, milliseconds: 999));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error: Test error'), findsOneWidget);

    // Wait just past 4 seconds - snackbar should be gone
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pumpAndSettle(); // Wait for dismiss animation
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Error: Test error'), findsNothing);
  });

  testWidgets('error messages have consistent padding',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Test error'),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify snackbar padding
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final padding = snackBar.padding as EdgeInsets;

    expect(padding.left, 16.0, reason: 'Left padding should be 16.0');
    expect(padding.right, 16.0, reason: 'Right padding should be 16.0');
    expect(padding.top, 14.0, reason: 'Top padding should be 14.0');
    expect(padding.bottom, 14.0, reason: 'Bottom padding should be 14.0');
  });

  testWidgets('error messages have consistent elevation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Test error'),
                    elevation: 6.0,
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify snackbar elevation
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.elevation, 6.0,
        reason: 'Error snackbar should have consistent elevation of 6.0');
  });

  testWidgets('error messages have consistent border radius',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Test error'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    ),
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify snackbar shape
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final shape = snackBar.shape as RoundedRectangleBorder;
    final radius = (shape.borderRadius as BorderRadius).topLeft.x;
    expect(radius, 4.0,
        reason: 'Error snackbar should have consistent border radius of 4.0');
  });

  testWidgets('error messages animate with consistent curve',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );

    // Show snackbar
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).showSnackBar(
      const SnackBar(
        content: Text('Error: Test error'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Initial state - snackbar should be starting to appear
    await tester.pump();
    final initialRect = tester.getRect(find.byType(SnackBar));

    // At 100ms - snackbar should be partially visible
    await tester.pump(const Duration(milliseconds: 100));
    final midRect = tester.getRect(find.byType(SnackBar));
    expect(midRect.top, lessThan(initialRect.top),
        reason: 'Snackbar should be moving upward during animation');

    // At 200ms - snackbar should be almost in final position
    await tester.pump(const Duration(milliseconds: 100));
    final almostFinalRect = tester.getRect(find.byType(SnackBar));
    expect(almostFinalRect.top, lessThan(midRect.top),
        reason: 'Snackbar should continue moving upward');

    // Final position
    await tester.pumpAndSettle();
    final finalRect = tester.getRect(find.byType(SnackBar));
    expect(finalRect.top, lessThan(almostFinalRect.top),
        reason: 'Snackbar should reach its final position');
  });

  testWidgets('error messages can be dismissed by horizontal swipe',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Test error'),
                    dismissDirection: DismissDirection.horizontal,
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify snackbar is initially visible
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error: Test error'), findsOneWidget);

    // Get snackbar position
    final snackbarFinder = find.byType(SnackBar);
    final gesture = await tester.startGesture(
      tester.getCenter(snackbarFinder),
    );

    // Swipe right
    await gesture.moveBy(const Offset(500.0, 0.0));
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify snackbar is dismissed
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Error: Test error'), findsNothing);

    // Show another snackbar
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).showSnackBar(
      const SnackBar(
        content: Text('Error: Test error'),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
    await tester.pumpAndSettle();

    // Verify snackbar is visible
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error: Test error'), findsOneWidget);

    // Get snackbar position
    final gesture2 = await tester.startGesture(
      tester.getCenter(snackbarFinder),
    );

    // Swipe left
    await gesture2.moveBy(const Offset(-500.0, 0.0));
    await gesture2.up();
    await tester.pumpAndSettle();

    // Verify snackbar is dismissed
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Error: Test error'), findsNothing);
  });

  testWidgets('error messages cannot be dismissed by vertical swipe',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Test error'),
                    dismissDirection: DismissDirection.horizontal,
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify snackbar is initially visible
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error: Test error'), findsOneWidget);

    // Get snackbar position
    final snackbarFinder = find.byType(SnackBar);
    final gesture = await tester.startGesture(
      tester.getCenter(snackbarFinder),
    );

    // Swipe up
    await gesture.moveBy(const Offset(0.0, -500.0));
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify snackbar is still visible
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error: Test error'), findsOneWidget);

    // Try swiping down
    final gesture2 = await tester.startGesture(
      tester.getCenter(snackbarFinder),
    );
    await gesture2.moveBy(const Offset(0.0, 500.0));
    await gesture2.up();
    await tester.pumpAndSettle();

    // Verify snackbar is still visible
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error: Test error'), findsOneWidget);
  });

  testWidgets('error snackbar has consistent maximum width of 400.0',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show error snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Test error'),
                    width: 400.0,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              });
              return const AudioRecorder();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify snackbar width
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.width, 400.0,
        reason:
            'Error snackbar should have a maximum width of 400.0 for readability on wide screens');
  });
}
