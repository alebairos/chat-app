/// FT-156: Message Linking Test
/// 
/// Tests the message linking functionality for coaching memory.
/// Verifies that activities are properly linked to their source messages.

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/models/activity_model.dart';
import 'package:ai_personas_app/services/activity_memory_service.dart';
import 'package:ai_personas_app/utils/message_id_generator.dart';

void main() {
  group('FT-156 Message Linking', () {
    setUp(() {
      // Reset message ID sequence for predictable tests
      MessageIdGenerator.resetSequence();
    });

    test('MessageIdGenerator should generate unique IDs', () {
      final id1 = MessageIdGenerator.generate();
      final id2 = MessageIdGenerator.generate();
      
      expect(id1, isNotNull);
      expect(id2, isNotNull);
      expect(id1, isNot(equals(id2)));
      expect(id1, startsWith('msg_'));
      expect(id2, startsWith('msg_'));
    });

    test('MessageIdGenerator should have sequential counters', () {
      MessageIdGenerator.resetSequence();
      
      final id1 = MessageIdGenerator.generate();
      final id2 = MessageIdGenerator.generate();
      
      expect(id1, endsWith('_0001'));
      expect(id2, endsWith('_0002'));
    });

    test('ActivityModel should accept message linking parameters', () {
      final messageId = MessageIdGenerator.generate();
      final messageText = 'Acabei de beber água';
      
      final activity = ActivityModel.fromDetection(
        activityCode: 'SF1',
        activityName: 'Beber água',
        dimension: 'saude_fisica',
        source: 'Test',
        completedAt: DateTime.now(),
        dayOfWeek: 'Monday',
        timeOfDay: 'morning',
        sourceMessageId: messageId,
        sourceMessageText: messageText,
      );
      
      expect(activity.sourceMessageId, equals(messageId));
      expect(activity.sourceMessageText, equals(messageText));
    });

    test('ActivityModel custom constructor should accept message linking', () {
      final messageId = MessageIdGenerator.generate();
      final messageText = 'Fiz exercício hoje';
      
      final activity = ActivityModel.custom(
        activityName: 'Exercício personalizado',
        dimension: 'custom',
        completedAt: DateTime.now(),
        dayOfWeek: 'Tuesday',
        timeOfDay: 'evening',
        sourceMessageId: messageId,
        sourceMessageText: messageText,
      );
      
      expect(activity.sourceMessageId, equals(messageId));
      expect(activity.sourceMessageText, equals(messageText));
    });

    test('ActivityModel should work without message linking (backward compatibility)', () {
      final activity = ActivityModel.fromDetection(
        activityCode: 'SF2',
        activityName: 'Caminhada',
        dimension: 'saude_fisica',
        source: 'Test',
        completedAt: DateTime.now(),
        dayOfWeek: 'Wednesday',
        timeOfDay: 'afternoon',
      );
      
      expect(activity.sourceMessageId, isNull);
      expect(activity.sourceMessageText, isNull);
      expect(activity.activityName, equals('Caminhada'));
    });

    test('Message linking should enable coaching context', () {
      final messageId = MessageIdGenerator.generate();
      final messageText = 'Acabei de beber água';
      final completedAt = DateTime.now();
      
      final activity = ActivityModel.fromDetection(
        activityCode: 'SF1',
        activityName: 'Beber água',
        dimension: 'saude_fisica',
        source: 'FT-156 Test',
        completedAt: completedAt,
        dayOfWeek: 'Thursday',
        timeOfDay: 'morning',
        sourceMessageId: messageId,
        sourceMessageText: messageText,
      );
      
      // Verify coaching context can be constructed
      final coachingContext = 'Lembro que você disse "${activity.sourceMessageText}" às ${activity.formattedTime} 💧';
      
      expect(coachingContext, contains('Lembro que você disse'));
      expect(coachingContext, contains(messageText));
      expect(coachingContext, contains(activity.formattedTime));
      expect(coachingContext, contains('💧'));
    });
  });
}
