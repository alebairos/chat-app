import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/language_detection_service.dart';

void main() {
  group('LanguageDetectionService', () {
    group('detectLanguage', () {
      test('should detect Portuguese from common words', () {
        final messages = [
          'Olá, como você está?',
          'Preciso fazer exercícios hoje',
          'Obrigado pela ajuda'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('pt_BR'));
      });

      test('should detect English from common words', () {
        final messages = [
          'Hello, how are you?',
          'I need to exercise today',
          'Thank you for the help'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('en_US'));
      });

      test('should detect Portuguese from Portuguese-specific characters', () {
        final messages = [
          'Vou fazer meditação hoje',
          'Preciso dormir mais cedo',
          'Obrigação de cuidar da saúde'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('pt_BR'));
      });

      test('should detect English from English patterns', () {
        final messages = [
          'I\'m going to exercise',
          'Need to sleep earlier',
          'Working on my goals'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('en_US'));
      });

      test('should handle mixed language content', () {
        final messages = [
          'Hello, como você está?',
          'I need fazer exercícios',
          'Thank you, obrigado'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        // Should detect the language with higher confidence
        expect(result, isIn(['pt_BR', 'en_US']));
      });

      test('should return default language for empty messages', () {
        final messages = <String>[];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('pt_BR')); // Default language
      });

      test('should return default language for unclear content', () {
        final messages = ['xyz abc def', '123 456 789', 'test test test'];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('pt_BR')); // Default language
      });

      test('should prioritize recent messages', () {
        final messages = [
          'Hello, how are you?',
          'I need to exercise today',
          'Olá, como você está?', // More recent Portuguese
          'Preciso fazer exercícios hoje',
          'Obrigado pela ajuda'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('pt_BR'));
      });

      test('should handle health and coaching terms in Portuguese', () {
        final messages = [
          'Vou meditar por 10 minutos',
          'Preciso melhorar meus hábitos',
          'Meu objetivo é dormir melhor'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('pt_BR'));
      });

      test('should handle health and coaching terms in English', () {
        final messages = [
          'I will meditate for 10 minutes',
          'Need to improve my habits',
          'My goal is to sleep better'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('en_US'));
      });
    });

    group('getDetectionConfidence', () {
      test('should return high confidence for clear Portuguese', () {
        final messages = [
          'Olá, como você está?',
          'Preciso fazer exercícios hoje',
          'Obrigado pela ajuda'
        ];

        final confidence =
            LanguageDetectionService.getDetectionConfidence(messages);

        expect(confidence, greaterThan(0.6));
      });

      test('should return high confidence for clear English', () {
        final messages = [
          'Hello, how are you?',
          'I need to exercise today',
          'Thank you for the help'
        ];

        final confidence =
            LanguageDetectionService.getDetectionConfidence(messages);

        expect(confidence, greaterThan(0.6));
      });

      test('should return low confidence for unclear content', () {
        final messages = ['xyz abc def', '123 456 789'];

        final confidence =
            LanguageDetectionService.getDetectionConfidence(messages);

        expect(confidence, lessThan(0.6));
      });

      test('should return zero confidence for empty messages', () {
        final messages = <String>[];

        final confidence =
            LanguageDetectionService.getDetectionConfidence(messages);

        expect(confidence, equals(0.0));
      });
    });

    group('isDetectionConfident', () {
      test('should return true for confident Portuguese detection', () {
        final messages = [
          'Olá, como você está?',
          'Preciso fazer exercícios hoje',
          'Obrigado pela ajuda'
        ];

        final isConfident =
            LanguageDetectionService.isDetectionConfident(messages);

        expect(isConfident, isTrue);
      });

      test('should return true for confident English detection', () {
        final messages = [
          'Hello, how are you?',
          'I need to exercise today',
          'Thank you for the help'
        ];

        final isConfident =
            LanguageDetectionService.isDetectionConfident(messages);

        expect(isConfident, isTrue);
      });

      test('should return false for unclear content', () {
        final messages = ['xyz abc def', '123 456 789'];

        final isConfident =
            LanguageDetectionService.isDetectionConfident(messages);

        expect(isConfident, isFalse);
      });

      test('should return false for empty messages', () {
        final messages = <String>[];

        final isConfident =
            LanguageDetectionService.isDetectionConfident(messages);

        expect(isConfident, isFalse);
      });
    });

    group('getDetailedAnalysis', () {
      test('should return detailed analysis for Portuguese content', () {
        final messages = [
          'Olá, como você está?',
          'Preciso fazer exercícios hoje'
        ];

        final analysis = LanguageDetectionService.getDetailedAnalysis(messages);

        expect(analysis, contains('detectedLanguage'));
        expect(analysis, contains('confidence'));
        expect(analysis, contains('languageScores'));
        expect(analysis, contains('messagesAnalyzed'));
        expect(analysis['detectedLanguage'], equals('pt_BR'));
        expect(analysis['confidence'], greaterThan(0.0));
        expect(analysis['messagesAnalyzed'], equals(2));
      });

      test('should return detailed analysis for English content', () {
        final messages = ['Hello, how are you?', 'I need to exercise today'];

        final analysis = LanguageDetectionService.getDetailedAnalysis(messages);

        expect(analysis, contains('detectedLanguage'));
        expect(analysis, contains('confidence'));
        expect(analysis, contains('languageScores'));
        expect(analysis, contains('messagesAnalyzed'));
        expect(analysis['detectedLanguage'], equals('en_US'));
        expect(analysis['confidence'], greaterThan(0.0));
        expect(analysis['messagesAnalyzed'], equals(2));
      });

      test('should handle empty messages in analysis', () {
        final messages = <String>[];

        final analysis = LanguageDetectionService.getDetailedAnalysis(messages);

        expect(analysis, contains('detectedLanguage'));
        expect(analysis, contains('confidence'));
        expect(analysis, contains('languageScores'));
        expect(analysis, contains('messagesAnalyzed'));
        expect(analysis['detectedLanguage'], equals('pt_BR')); // Default
        expect(analysis['confidence'], equals(0.0));
        expect(analysis['messagesAnalyzed'], equals(0));
      });
    });

    group('edge cases', () {
      test('should handle very short messages', () {
        final messages = ['oi', 'hi', 'que'];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, isIn(['pt_BR', 'en_US']));
      });

      test('should handle messages with only numbers', () {
        final messages = ['123', '456', '789'];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('pt_BR')); // Default for unclear content
      });

      test('should handle messages with mixed case', () {
        final messages = [
          'OLÁ, COMO VOCÊ ESTÁ?',
          'preciso fazer exercícios hoje',
          'ObRiGaDo PeLa AjUdA'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('pt_BR'));
      });

      test('should handle messages with punctuation', () {
        final messages = [
          'Olá! Como você está?',
          'Preciso fazer exercícios hoje...',
          'Obrigado pela ajuda!!!'
        ];

        final result = LanguageDetectionService.detectLanguage(messages);

        expect(result, equals('pt_BR'));
      });
    });
  });
}
