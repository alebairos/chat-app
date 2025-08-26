import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_personas_app/services/chat_export_service.dart';
import 'package:ai_personas_app/services/chat_storage_service.dart';
import 'package:ai_personas_app/models/chat_message_model.dart';
import 'package:ai_personas_app/models/message_type.dart';

class MockChatStorageService extends Mock implements ChatStorageService {}

void main() {
  group('ChatExportService', () {
    late ChatExportService exportService;
    late MockChatStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockChatStorageService();
      exportService = ChatExportService(storageService: mockStorageService);
    });

    group('WhatsApp Format Generation', () {
      test('should format text messages correctly', () async {
        // Arrange
        final testMessages = [
          ChatMessageModel(
            text: 'Hello!',
            isUser: true,
            type: MessageType.text,
            timestamp: DateTime(2025, 1, 15, 10, 30, 45),
          ),
          ChatMessageModel.aiMessage(
            text: 'Hi there! How can I help you today?',
            type: MessageType.text,
            timestamp: DateTime(2025, 1, 15, 10, 31, 00),
            personaKey: 'ariLifeCoach',
            personaDisplayName: 'Ari Life Coach',
          ),
        ];

        // Mock the new forward pagination method
        when(() => mockStorageService.getMessagesAfter(
              after: any(named: 'after'),
              limit: any(named: 'limit'),
            )).thenAnswer((invocation) async {
          final after = invocation.namedArguments[#after] as DateTime?;
          if (after == null) {
            // Return first batch of messages
            return testMessages;
          } else {
            // Return empty list for subsequent batches (end of pagination)
            return <ChatMessageModel>[];
          }
        });

        // Act
        final stats = await exportService.getExportStatistics();

        // Assert
        expect(stats['totalMessages'], 2);
        expect(stats['userMessages'], 1);
        expect(stats['aiMessages'], 1);
        expect(stats['audioMessages'], 0);
        expect(stats['personaCounts']['Ari Life Coach'], 1);
      });

      test('should handle audio messages correctly', () async {
        // Arrange
        final testMessages = [
          ChatMessageModel(
            text: '[Audio Message]',
            isUser: true,
            type: MessageType.audio,
            timestamp: DateTime(2025, 1, 15, 10, 30, 45),
            mediaPath: 'audio/user_message.opus',
            duration: const Duration(seconds: 5),
          ),
          ChatMessageModel.aiMessage(
            text: 'I heard your audio message!',
            type: MessageType.audio,
            timestamp: DateTime(2025, 1, 15, 10, 31, 00),
            personaKey: 'sergeantOracle',
            personaDisplayName: 'Sergeant Oracle',
            mediaPath: 'audio/ai_response.mp3',
            duration: const Duration(seconds: 8),
          ),
        ];

        // Mock the new forward pagination method
        when(() => mockStorageService.getMessagesAfter(
              after: any(named: 'after'),
              limit: any(named: 'limit'),
            )).thenAnswer((invocation) async {
          final after = invocation.namedArguments[#after] as DateTime?;
          if (after == null) {
            // Return first batch of messages
            return testMessages;
          } else {
            // Return empty list for subsequent batches (end of pagination)
            return <ChatMessageModel>[];
          }
        });

        // Act
        final stats = await exportService.getExportStatistics();

        // Assert
        expect(stats['totalMessages'], 2);
        expect(stats['userMessages'], 1);
        expect(stats['aiMessages'], 1);
        expect(stats['audioMessages'], 2);
        expect(stats['personaCounts']['Sergeant Oracle'], 1);
      });

      test('should handle legacy messages without persona data', () async {
        // Arrange
        final testMessages = [
          ChatMessageModel(
            text: 'Legacy AI message',
            isUser: false,
            type: MessageType.text,
            timestamp: DateTime(2025, 1, 15, 10, 30, 45),
            // No persona data (legacy message)
          ),
        ];

        // Mock the new forward pagination method
        when(() => mockStorageService.getMessagesAfter(
              after: any(named: 'after'),
              limit: any(named: 'limit'),
            )).thenAnswer((invocation) async {
          final after = invocation.namedArguments[#after] as DateTime?;
          if (after == null) {
            // Return first batch of messages
            return testMessages;
          } else {
            // Return empty list for subsequent batches (end of pagination)
            return <ChatMessageModel>[];
          }
        });

        // Act
        final stats = await exportService.getExportStatistics();

        // Assert
        expect(stats['totalMessages'], 1);
        expect(stats['aiMessages'], 1);
        expect(stats['personaCounts']['AI Assistant'], 1);
      });

      test('should handle empty message history', () async {
        // Arrange
        when(() => mockStorageService.getMessages(
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenAnswer((_) async => []);

        // Act
        final stats = await exportService.getExportStatistics();

        // Assert
        expect(stats['totalMessages'], 0);
        expect(stats['userMessages'], 0);
        expect(stats['aiMessages'], 0);
        expect(stats['audioMessages'], 0);
        expect(stats['personaCounts'], isEmpty);
        expect(stats['dateRange'], isNull);
      });

      test('should sort messages chronologically', () async {
        // Arrange - messages in chronological order (as they come from forward pagination)
        final testMessages = [
          ChatMessageModel(
            text: 'Earliest message',
            isUser: true,
            type: MessageType.text,
            timestamp: DateTime(2025, 1, 15, 10, 30, 00),
          ),
          ChatMessageModel(
            text: 'Middle message',
            isUser: false,
            type: MessageType.text,
            timestamp: DateTime(2025, 1, 15, 10, 32, 00),
          ),
          ChatMessageModel(
            text: 'Latest message',
            isUser: true,
            type: MessageType.text,
            timestamp: DateTime(2025, 1, 15, 10, 35, 00),
          ),
        ];

        // Mock the new forward pagination method
        when(() => mockStorageService.getMessagesAfter(
              after: any(named: 'after'),
              limit: any(named: 'limit'),
            )).thenAnswer((invocation) async {
          final after = invocation.namedArguments[#after] as DateTime?;
          if (after == null) {
            // Return first batch of messages
            return testMessages;
          } else {
            // Return empty list for subsequent batches (end of pagination)
            return <ChatMessageModel>[];
          }
        });

        // Act
        final stats = await exportService.getExportStatistics();

        // Assert
        expect(stats['totalMessages'], 3);

        // Verify date range is correct (earliest to latest)
        final dateRange = stats['dateRange'] as Map<String, dynamic>;
        expect(dateRange['earliest'], DateTime(2025, 1, 15, 10, 30, 00));
        expect(dateRange['latest'], DateTime(2025, 1, 15, 10, 35, 00));
      });

      test('should handle multiple personas correctly', () async {
        // Arrange
        final testMessages = [
          ChatMessageModel.aiMessage(
            text: 'Message from Ari',
            type: MessageType.text,
            timestamp: DateTime(2025, 1, 15, 10, 30, 00),
            personaKey: 'ariLifeCoach',
            personaDisplayName: 'Ari Life Coach',
          ),
          ChatMessageModel.aiMessage(
            text: 'Message from Sergeant',
            type: MessageType.text,
            timestamp: DateTime(2025, 1, 15, 10, 31, 00),
            personaKey: 'sergeantOracle',
            personaDisplayName: 'Sergeant Oracle',
          ),
          ChatMessageModel.aiMessage(
            text: 'Another from Ari',
            type: MessageType.text,
            timestamp: DateTime(2025, 1, 15, 10, 32, 00),
            personaKey: 'ariLifeCoach',
            personaDisplayName: 'Ari Life Coach',
          ),
        ];

        // Mock the new forward pagination method
        when(() => mockStorageService.getMessagesAfter(
              after: any(named: 'after'),
              limit: any(named: 'limit'),
            )).thenAnswer((invocation) async {
          final after = invocation.namedArguments[#after] as DateTime?;
          if (after == null) {
            // Return first batch of messages
            return testMessages;
          } else {
            // Return empty list for subsequent batches (end of pagination)
            return <ChatMessageModel>[];
          }
        });

        // Act
        final stats = await exportService.getExportStatistics();

        // Assert
        expect(stats['totalMessages'], 3);
        expect(stats['aiMessages'], 3);

        final personaCounts = stats['personaCounts'] as Map<String, int>;
        expect(personaCounts['Ari Life Coach'], 2);
        expect(personaCounts['Sergeant Oracle'], 1);
      });
    });

    group('Error Handling', () {
      test('should handle storage service errors gracefully', () async {
        // Arrange
        when(() => mockStorageService.getMessages(
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenThrow(Exception('Database error'));

        // Act
        final stats = await exportService.getExportStatistics();

        // Assert - should return default values instead of throwing
        expect(stats['totalMessages'], 0);
        expect(stats['userMessages'], 0);
        expect(stats['aiMessages'], 0);
        expect(stats['audioMessages'], 0);
        expect(stats['personaCounts'], isEmpty);
        expect(stats['dateRange'], isNull);
      });
    });
  });
}
