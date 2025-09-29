import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:ai_personas_app/widgets/chat_message.dart';
import 'package:ai_personas_app/models/chat_message_model.dart';
import 'package:ai_personas_app/models/message_type.dart';

void main() {
  group('FT-160: Message Timestamps Display', () {
    testWidgets('should display timestamp below text message', (tester) async {
      // Arrange
      final timestamp = DateTime(2025, 9, 29, 13, 30, 0);
      const messageText = 'Hello, how are you?';
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: messageText,
              isUser: true,
              timestamp: timestamp,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(messageText), findsOneWidget);
      expect(find.text('2025/09/29, 13:30'), findsOneWidget);
    });

    testWidgets('should display timestamp below AI message', (tester) async {
      // Arrange
      final timestamp = DateTime(2025, 9, 29, 14, 45, 30);
      const messageText = 'I am doing well, thank you!';
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: messageText,
              isUser: false,
              timestamp: timestamp,
              personaKey: 'ariLifeCoach',
              personaDisplayName: 'Ari Life Coach',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(messageText), findsOneWidget);
      expect(find.text('2025/09/29, 14:45'), findsOneWidget);
    });

    testWidgets('should not display timestamp when null', (tester) async {
      // Arrange
      const messageText = 'Message without timestamp';
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: messageText,
              isUser: true,
              timestamp: null, // No timestamp
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(messageText), findsOneWidget);
      // Should not find any timestamp text
      expect(find.textContaining('2025/'), findsNothing);
      expect(find.textContaining('/'), findsNothing);
    });

    testWidgets('should format timestamp correctly for different times', (tester) async {
      // Test different timestamp formats
      final testCases = [
        {
          'timestamp': DateTime(2025, 1, 1, 0, 0, 0),
          'expected': '2025/01/01, 00:00'
        },
        {
          'timestamp': DateTime(2025, 12, 31, 23, 59, 59),
          'expected': '2025/12/31, 23:59'
        },
        {
          'timestamp': DateTime(2025, 6, 15, 12, 30, 45),
          'expected': '2025/06/15, 12:30'
        },
      ];

      for (final testCase in testCases) {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatMessage(
                text: 'Test message',
                isUser: true,
                timestamp: testCase['timestamp'] as DateTime,
              ),
            ),
          ),
        );

        // Assert
        expect(find.text(testCase['expected'] as String), findsOneWidget);
        
        // Clean up for next test
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('should display timestamp with correct styling', (tester) async {
      // Arrange
      final timestamp = DateTime(2025, 9, 29, 13, 30, 0);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: 'Test message',
              isUser: true,
              timestamp: timestamp,
            ),
          ),
        ),
      );

      // Assert - Find the timestamp text widget
      final timestampFinder = find.text('2025/09/29, 13:30');
      expect(timestampFinder, findsOneWidget);
      
      // Check styling
      final timestampWidget = tester.widget<Text>(timestampFinder);
      expect(timestampWidget.style?.fontSize, equals(11));
      expect(timestampWidget.style?.color, equals(Colors.grey[600]));
    });

    testWidgets('should work with audio messages', (tester) async {
      // Arrange
      final timestamp = DateTime(2025, 9, 29, 15, 20, 0);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: 'Audio transcription',
              isUser: true,
              timestamp: timestamp,
              audioPath: 'test_audio.m4a',
              duration: const Duration(seconds: 30),
            ),
          ),
        ),
      );

      // Assert - Timestamp should still be displayed for audio messages
      expect(find.text('2025/09/29, 15:20'), findsOneWidget);
    });

    test('DateFormat should match expected format', () {
      // Arrange
      final timestamp = DateTime(2025, 9, 29, 13, 30, 45);
      
      // Act
      final formatted = DateFormat('yyyy/MM/dd, HH:mm').format(timestamp);
      
      // Assert
      expect(formatted, equals('2025/09/29, 13:30'));
    });
  });

  group('FT-160: ChatMessage Integration', () {
    testWidgets('should display timestamp when created from ChatMessageModel', (tester) async {
      // This test ensures the integration with ChatMessageModel works correctly
      
      // Arrange
      final timestamp = DateTime(2025, 9, 29, 16, 45, 0);
      final model = ChatMessageModel(
        text: 'Integration test message',
        isUser: true,
        type: MessageType.text,
        timestamp: timestamp,
      );

      // Act - Simulate how _createChatMessage works
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              text: model.text,
              isUser: model.isUser,
              timestamp: model.timestamp, // This is the key integration point
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Integration test message'), findsOneWidget);
      expect(find.text('2025/09/29, 16:45'), findsOneWidget);
    });
  });
}
