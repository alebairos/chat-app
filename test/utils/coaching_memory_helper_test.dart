/// FT-156: Coaching Memory Helper Test
/// 
/// Tests the coaching memory helper utilities for generating
/// natural coaching responses from activity message linking data.

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/utils/coaching_memory_helper.dart';

void main() {
  group('CoachingMemoryHelper', () {
    test('should generate Portuguese coaching context', () {
      final context = CoachingMemoryHelper.generateCoachingContext(
        activityName: 'Beber água',
        sourceMessageText: 'Acabei de beber água',
        time: '20h57',
        emoji: '💧',
        language: 'pt_BR',
      );
      
      expect(context, equals("Lembro que você disse 'Acabei de beber água' às 20h57 💧"));
    });

    test('should generate English coaching context', () {
      final context = CoachingMemoryHelper.generateCoachingContext(
        activityName: 'Drink water',
        sourceMessageText: 'Just finished drinking water',
        time: '8:57 PM',
        emoji: '💧',
        language: 'en_US',
      );
      
      expect(context, equals("I remember you said 'Just finished drinking water' at 8:57 PM 💧"));
    });

    test('should generate coaching context without emoji', () {
      final context = CoachingMemoryHelper.generateCoachingContext(
        activityName: 'Custom activity',
        sourceMessageText: 'Fiz algo personalizado',
        time: '15h30',
        language: 'pt_BR',
      );
      
      expect(context, equals("Lembro que você disse 'Fiz algo personalizado' às 15h30"));
    });

    test('should get correct activity emojis by code', () {
      expect(CoachingMemoryHelper.getActivityEmoji('SF1', 'Beber água'), equals('💧'));
      expect(CoachingMemoryHelper.getActivityEmoji('SF2', 'Caminhada'), equals('🚶'));
      expect(CoachingMemoryHelper.getActivityEmoji('SF3', 'Corrida'), equals('🏃'));
      expect(CoachingMemoryHelper.getActivityEmoji('SF4', 'Exercício'), equals('💪'));
      expect(CoachingMemoryHelper.getActivityEmoji('SF5', 'Meditação'), equals('🧘'));
      expect(CoachingMemoryHelper.getActivityEmoji('SF6', 'Dormir'), equals('😴'));
      expect(CoachingMemoryHelper.getActivityEmoji('SF7', 'Alimentação'), equals('🍎'));
    });

    test('should get emojis by activity name fallback', () {
      expect(CoachingMemoryHelper.getActivityEmoji(null, 'beber água'), equals('💧'));
      expect(CoachingMemoryHelper.getActivityEmoji(null, 'exercício forte'), equals('💪'));
      expect(CoachingMemoryHelper.getActivityEmoji(null, 'caminhada matinal'), equals('🚶'));
      expect(CoachingMemoryHelper.getActivityEmoji(null, 'corrida noturna'), equals('🏃'));
      expect(CoachingMemoryHelper.getActivityEmoji(null, 'meditação zen'), equals('🧘'));
    });

    test('should return null for unknown activities', () {
      expect(CoachingMemoryHelper.getActivityEmoji('UNKNOWN', 'Atividade estranha'), isNull);
      expect(CoachingMemoryHelper.getActivityEmoji(null, 'Something random'), isNull);
    });

    test('should format time for Portuguese coaching', () {
      expect(CoachingMemoryHelper.formatTimeForCoaching('20:57', language: 'pt_BR'), equals('20h57'));
      expect(CoachingMemoryHelper.formatTimeForCoaching('08:30', language: 'pt_BR'), equals('8h30'));
      expect(CoachingMemoryHelper.formatTimeForCoaching('00:15', language: 'pt_BR'), equals('0h15'));
    });

    test('should format time for English coaching', () {
      expect(CoachingMemoryHelper.formatTimeForCoaching('20:57', language: 'en_US'), equals('8:57 PM'));
      expect(CoachingMemoryHelper.formatTimeForCoaching('08:30', language: 'en_US'), equals('8:30 AM'));
      expect(CoachingMemoryHelper.formatTimeForCoaching('12:00', language: 'en_US'), equals('12:00 PM'));
      expect(CoachingMemoryHelper.formatTimeForCoaching('00:15', language: 'en_US'), equals('12:15 AM'));
    });

    test('should handle invalid time format gracefully', () {
      expect(CoachingMemoryHelper.formatTimeForCoaching('invalid'), equals('invalid'));
      expect(CoachingMemoryHelper.formatTimeForCoaching('25:70'), equals('25:70'));
    });

    test('should create complete coaching response', () {
      final activity = {
        'name': 'Beber água',
        'source_message_text': 'Acabei de beber água',
        'time': '20:57',
        'code': 'SF1',
      };
      
      final response = CoachingMemoryHelper.createCoachingResponse(
        activity: activity,
        language: 'pt_BR',
      );
      
      expect(response, equals("Lembro que você disse 'Acabei de beber água' às 20h57 💧"));
    });

    test('should create coaching response with custom message', () {
      final activity = {
        'name': 'Exercício',
        'source_message_text': 'Terminei meu treino',
        'time': '15:30',
        'code': 'SF4',
      };
      
      final response = CoachingMemoryHelper.createCoachingResponse(
        activity: activity,
        language: 'pt_BR',
        customMessage: 'Parabéns pelo esforço!',
      );
      
      expect(response, equals("Lembro que você disse 'Terminei meu treino' às 15h30 💪. Parabéns pelo esforço!"));
    });

    test('should handle activity without message context', () {
      final activity = {
        'name': 'Atividade antiga',
        'source_message_text': null,
        'time': '10:00',
        'code': null,
      };
      
      final response = CoachingMemoryHelper.createCoachingResponse(
        activity: activity,
        language: 'pt_BR',
      );
      
      expect(response, equals("Vejo que você completou Atividade antiga às 10:00."));
    });

    test('should generate activity summary', () {
      final activities = [
        {
          'name': 'Beber água',
          'time': '20:57',
          'source_message_text': 'Acabei de beber água',
        },
        {
          'name': 'Exercício',
          'time': '15:30',
          'source_message_text': 'Terminei o treino',
        },
      ];
      
      final summary = CoachingMemoryHelper.generateActivitySummary(
        activities: activities,
        language: 'pt_BR',
      );
      
      expect(summary, equals('Hoje você já me contou sobre: Beber água (20:57), Exercício (15:30)'));
    });

    test('should handle empty activity list', () {
      final summary = CoachingMemoryHelper.generateActivitySummary(
        activities: [],
        language: 'pt_BR',
      );
      
      expect(summary, equals('Não tenho memórias recentes de atividades para referenciar.'));
    });
  });
}
