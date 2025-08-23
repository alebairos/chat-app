import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/time_format_localizer.dart';

void main() {
  group('TimeFormatLocalizer', () {
    group('localizeTimeFormats', () {
      test('should convert 12-hour PM times to 24-hour format in Portuguese',
          () {
        const input =
            'Para dormir às 11pm:\n- 10:30pm: Desligar telas\n- 10:40pm: Preparar quarto\n- 10:50pm: Relaxamento';
        const expected =
            'Para dormir às 23:00:\n- 22:30: Desligar telas\n- 22:40: Preparar quarto\n- 22:50: Relaxamento';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should convert 12-hour AM times to 24-hour format in Portuguese',
          () {
        const input = 'Acordar às 6:30am e meditar às 7:00am';
        const expected = 'Acordar às 06:30 e meditar às 07:00';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should handle midnight and noon correctly', () {
        const input = 'Dormir às 12:00am e almoçar às 12:00pm';
        const expected = 'Dormir às 00:00 e almoçar às 12:00';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should preserve 24-hour format times', () {
        const input = 'Reunião às 14:30 e jantar às 19:00';
        const expected = 'Reunião às 14:30 e jantar às 19:00';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should handle case-insensitive AM/PM', () {
        const input = 'Exercitar às 6:00AM e trabalhar às 9:00pm';
        const expected = 'Exercitar às 06:00 e trabalhar às 21:00';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should keep English times unchanged for English language', () {
        const input = 'Sleep at 10:30pm and wake up at 6:30am';
        const expected = 'Sleep at 10:30pm and wake up at 6:30am';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'en_US');

        expect(result, equals(expected));
      });

      test('should handle single-digit hours', () {
        const input = 'Café às 7:15am e lanche às 3:45pm';
        const expected = 'Café às 07:15 e lanche às 15:45';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should handle multiple times in the same text', () {
        const input =
            'Rotina: 6:00am acordar, 8:30am trabalho, 12:30pm almoço, 6:00pm jantar, 10:30pm dormir';
        const expected =
            'Rotina: 06:00 acordar, 08:30 trabalho, 12:30 almoço, 18:00 jantar, 22:30 dormir';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });
    });

    group('containsTimePatterns', () {
      test('should detect 12-hour time patterns', () {
        const input = 'Reunião às 10:30pm';

        final result = TimeFormatLocalizer.containsTimePatterns(input);

        expect(result, isTrue);
      });

      test('should detect 24-hour time patterns', () {
        const input = 'Reunião às 14:30';

        final result = TimeFormatLocalizer.containsTimePatterns(input);

        expect(result, isTrue);
      });

      test('should return false for text without time patterns', () {
        const input = 'Vamos nos encontrar hoje';

        final result = TimeFormatLocalizer.containsTimePatterns(input);

        expect(result, isFalse);
      });

      test('should detect multiple time patterns', () {
        const input = 'Café às 7:00am e jantar às 7:00pm';

        final result = TimeFormatLocalizer.containsTimePatterns(input);

        expect(result, isTrue);
      });
    });

    group('extractTimePatterns', () {
      test('should extract all time patterns from text', () {
        const input = 'Rotina: 6:00am, 12:30pm, 10:30pm';

        final result = TimeFormatLocalizer.extractTimePatterns(input);

        expect(result, equals(['6:00am', '12:30pm', '10:30pm']));
      });

      test('should return empty list for text without time patterns', () {
        const input = 'Vamos nos encontrar hoje';

        final result = TimeFormatLocalizer.extractTimePatterns(input);

        expect(result, isEmpty);
      });

      test('should extract 24-hour format times', () {
        const input = 'Reunião às 14:30 e 16:45';

        final result = TimeFormatLocalizer.extractTimePatterns(input);

        expect(result, equals(['14:30', '16:45']));
      });
    });

    group('neutralizeTimeForLanguageDetection', () {
      test('should replace time patterns with neutral placeholder', () {
        const input = 'Para dormir às 11pm: 10:30pm desligar telas';
        const expected = 'Para dormir às HORA: HORA desligar telas';

        final result =
            TimeFormatLocalizer.neutralizeTimeForLanguageDetection(input);

        expect(result, equals(expected));
      });

      test('should preserve non-time content', () {
        const input = 'Vamos nos encontrar hoje para conversar';
        const expected = 'Vamos nos encontrar hoje para conversar';

        final result =
            TimeFormatLocalizer.neutralizeTimeForLanguageDetection(input);

        expect(result, equals(expected));
      });

      test('should handle mixed content with multiple time patterns', () {
        const input =
            'Rotina matinal: 6:00am acordar, 7:30am café, 8:00am trabalho';
        const expected =
            'Rotina matinal: HORA acordar, HORA café, HORA trabalho';

        final result =
            TimeFormatLocalizer.neutralizeTimeForLanguageDetection(input);

        expect(result, equals(expected));
      });
    });

    group('edge cases', () {
      test('should handle invalid time formats gracefully', () {
        const input = 'Reunião às 25:70pm'; // Invalid time
        const expected = 'Reunião às 25:70pm'; // Should remain unchanged

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should handle empty text', () {
        const input = '';
        const expected = '';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should handle text with only spaces', () {
        const input = '   ';
        const expected = '   ';

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'pt_BR');

        expect(result, equals(expected));
      });

      test('should handle unknown language codes', () {
        const input = 'Meeting at 10:30pm';
        const expected = 'Meeting at 10:30pm'; // Should remain unchanged

        final result = TimeFormatLocalizer.localizeTimeFormats(input, 'fr_FR');

        expect(result, equals(expected));
      });
    });
  });
}
