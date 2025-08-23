import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/tts_preprocessing_service.dart';

void main() {
  group('TTSPreprocessingService', () {
    group('preprocessForTTS', () {
      test('should remove acronyms in parentheses', () {
        const input = 'Complete exercise (SF1233) today';
        const expected = 'Complete exercise today';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should remove multiple acronyms', () {
        const input = 'Track habits (SM13) and goals (R1) daily';
        const expected = 'Track habits and goals daily';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should remove various acronym patterns', () {
        const input = 'Review (TG45), meditate (E7), and sleep (SF2)';
        const expected = 'Review, meditate, and sleep';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should keep normal parentheses content but convert numbers', () {
        const input = 'Exercise (30 minutes) and meditate (10 minutes)';
        const expected = 'Exercise (trinta minutes) and meditate (dez minutes)';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should convert numbers to Portuguese words', () {
        const input = 'Complete 5 exercises and drink 8 glasses of water';
        const expected =
            'Complete cinco exercises and drink oito glasses of water';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should convert numbers to English words', () {
        const input = 'Complete 3 exercises and drink 6 glasses of water';
        const expected =
            'Complete three exercises and drink six glasses of water';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'en_US');

        expect(result, equals(expected));
      });

      test('should handle Portuguese abbreviations', () {
        const input = 'Exercise for 30 min and sleep 8 hr';
        const expected = 'Exercise for trinta minutos and sleep oito horas';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should handle English abbreviations', () {
        const input = 'Exercise for 45 min and sleep 8 hr';
        const expected = 'Exercise for 45 minutes and sleep eight hours';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'en_US');

        expect(result, equals(expected));
      });

      test('should normalize whitespace', () {
        const input = 'Complete   exercise  (SF1)   today';
        const expected = 'Complete exercise today';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should handle complex text with multiple optimizations', () {
        const input = 'Complete 3 exercises (SF1233) for 20 min today';
        const expected = 'Complete três exercises for vinte minutos today';

        final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should handle empty and null text', () {
        expect(
            TTSPreprocessingService.preprocessForTTS('', 'pt_BR'), equals(''));
        expect(TTSPreprocessingService.preprocessForTTS('   ', 'pt_BR'),
            equals(''));
      });
    });

    group('containsProcessableElements', () {
      test('should detect text with acronyms', () {
        const input = 'Exercise (SF1233) today';

        final result =
            TTSPreprocessingService.containsProcessableElements(input);

        expect(result, isTrue);
      });

      test('should detect text with numbers', () {
        const input = 'Complete 5 exercises today';

        final result =
            TTSPreprocessingService.containsProcessableElements(input);

        expect(result, isTrue);
      });

      test('should detect text with abbreviations', () {
        const input = 'Exercise for 30 min';

        final result =
            TTSPreprocessingService.containsProcessableElements(input);

        expect(result, isTrue);
      });

      test('should return false for clean text', () {
        const input = 'Clean text without processable elements';

        final result =
            TTSPreprocessingService.containsProcessableElements(input);

        expect(result, isFalse);
      });

      test('should handle empty text', () {
        const input = '';

        final result =
            TTSPreprocessingService.containsProcessableElements(input);

        expect(result, isFalse);
      });
    });

    group('getProcessingPreview', () {
      test('should return processing preview for text with acronyms', () {
        const input = 'Complete exercise (SF1233) today';

        final result =
            TTSPreprocessingService.getProcessingPreview(input, 'pt_BR');

        expect(result, contains('original'));
        expect(result, contains('processed'));
        expect(result['original'], equals(input));
        expect(result['processed'], equals('Complete exercise today'));
      });

      test('should return processing preview for text with numbers', () {
        const input = 'Complete 5 exercises';

        final result =
            TTSPreprocessingService.getProcessingPreview(input, 'pt_BR');

        expect(result, contains('original'));
        expect(result, contains('processed'));
        expect(result['original'], equals(input));
        expect(result['processed'], equals('Complete cinco exercises'));
      });

      test('should return same text for clean input', () {
        const input = 'Clean text';

        final result =
            TTSPreprocessingService.getProcessingPreview(input, 'pt_BR');

        expect(result['original'], equals(input));
        expect(result['processed'], equals(input));
      });
    });

    group('logProcessingStats', () {
      test('should not throw exception when logging stats', () {
        expect(() {
          TTSPreprocessingService.logProcessingStats(
              'Original text (SF1) with 5 items',
              'Original text with cinco items',
              'pt_BR');
        }, returnsNormally);
      });

      test('should handle empty strings', () {
        expect(() {
          TTSPreprocessingService.logProcessingStats('', '', 'pt_BR');
        }, returnsNormally);
      });
    });
  });
}
