import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/models/chat_message_model.dart';
import 'package:ai_personas_app/models/message_type.dart';
import 'package:ai_personas_app/widgets/chat_message.dart';

void main() {
  group('FT-160: ChatScreen Timestamp Integration', () {
    testWidgets(
        'should create ChatMessage with timestamp from ChatMessageModel',
        (tester) async {
      // This test verifies the integration pattern used in _createChatMessage
      // by testing the same widget creation logic

      // Arrange
      final timestamp = DateTime(2025, 9, 29, 14, 30, 0);
      final model = ChatMessageModel(
        text: 'Integration test message',
        isUser: true,
        type: MessageType.text,
        timestamp: timestamp,
      );

      // Act - Simulate the _createChatMessage logic
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              key: ValueKey(model.id),
              text: model.text,
              isUser: model.isUser,
              audioPath: model.mediaPath,
              duration: model.duration,
              personaKey: model.personaKey,
              personaDisplayName: model.personaDisplayName,
              timestamp: model.timestamp, // FT-160: Key integration point
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Integration test message'), findsOneWidget);
      expect(find.text('2025/09/29, 14:30'), findsOneWidget);
    });

    testWidgets('should handle null timestamp in integration', (tester) async {
      // Test the integration when timestamp is null

      // Arrange
      final model = ChatMessageModel(
        text: 'Message without timestamp',
        isUser: false,
        type: MessageType.text,
        timestamp: DateTime.now(), // Will be set to null in widget
      );

      // Act - Test with null timestamp
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              key: ValueKey(model.id),
              text: model.text,
              isUser: model.isUser,
              timestamp: null, // Explicitly null
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Message without timestamp'), findsOneWidget);
      expect(find.textContaining('2025/'), findsNothing);
    });
  });
}
