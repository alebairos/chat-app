import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:character_ai_clone/widgets/audio_recorder.dart';

void main() {
  testWidgets('all buttons use circle shape', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioRecorder(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
    for (final button in buttons) {
      expect(button.style?.shape?.resolve({}), isA<CircleBorder>());
    }
  });
}
