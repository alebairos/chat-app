import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/features/audio_assistant/services/tts_text_processor.dart';

void main() {
  group('TTSTextProcessor', () {
    group('processForTTS', () {
      test('should remove action descriptions in asterisks', () {
        // Arrange
        const text = '*ajusta o elmo pensativamente* Olá jovem aprendiz.';

        // Act
        final result = TTSTextProcessor.processForTTS(text);

        // Assert
        expect(result, 'Olá jovem aprendiz.');
      });

      test('should clean emphasis markers while preserving content', () {
        // Arrange
        const text =
            'Entendo. *é devorando nossos obstáculos internos que fortalecemos nossos hábitos.*';

        // Act
        final result = TTSTextProcessor.processForTTS(text);

        // Assert
        expect(result,
            'Entendo. é devorando nossos obstáculos internos que fortalecemos nossos hábitos.');
      });

      test('should clean underscore markers around Latin phrases', () {
        // Arrange
        const text =
            '_Sic gorgeamus allos subjectatos nunc_ - ou, em linguagem moderna: algo importante.';

        // Act
        final result = TTSTextProcessor.processForTTS(text);

        // Assert
        expect(result,
            'Sic gorgeamus allos subjectatos nunc - ou, em linguagem moderna: algo importante.');
      });

      test('should handle Oracle message with multiple formatting elements',
          () {
        // Arrange - This is the exact message from the Oracle in the image
        const oracleMessage = '''*ajusta o elmo pensativamente*

Entendo, jovem aprendiz. Criar novos hábitos pode parecer uma batalha árdua, digna das mais desafiadoras campanhas militares. Mas permita-me compartilhar uma pérola de sabedoria...

_Sic gorgeamus allos subjectatos nunc_ - ou, em linguagem moderna: *é devorando nossos obstáculos internos que fortalecemos nossos hábitos.*

Afinal, assim como o valoroso legionário precisa superar seus''';

        // Act
        final result = TTSTextProcessor.processForTTS(oracleMessage);

        // Assert
        expect(result, contains('Entendo, jovem aprendiz'));
        expect(result, contains('Criar novos hábitos'));
        expect(result, contains('Sic gorgeamus allos subjectatos nunc'));
        expect(
            result,
            contains(
                'é devorando nossos obstáculos internos que fortalecemos nossos hábitos'));
        expect(result, contains('Afinal, assim como o valoroso legionário'));

        // Should NOT contain formatting markers
        expect(result, isNot(contains('*ajusta o elmo pensativamente*')));
        expect(result, isNot(contains('*é devorando')));
        expect(result, isNot(contains('_Sic gorgeamus')));
      });

      test('should normalize whitespace correctly', () {
        // Arrange
        const text =
            'Texto   com    espaços   múltiplos .  E pontuação   estranha  !';

        // Act
        final result = TTSTextProcessor.processForTTS(text);

        // Assert
        expect(result, 'Texto com espaços múltiplos. E pontuação estranha!');
      });

      test('should handle empty and null-like inputs', () {
        // Test empty string
        expect(TTSTextProcessor.processForTTS(''), '');

        // Test whitespace only
        expect(TTSTextProcessor.processForTTS('   '), '');

        // Test only formatting
        expect(TTSTextProcessor.processForTTS('*action*'), '');
      });

      test('should preserve content without formatting', () {
        // Arrange
        const text = 'Este é um texto normal sem formatação especial.';

        // Act
        final result = TTSTextProcessor.processForTTS(text);

        // Assert
        expect(result, text);
      });

      test('should handle mixed Portuguese and Latin text', () {
        // Arrange
        const text =
            'Como diziam os romanos: _Carpe diem_ - aproveite o dia! *sorri com sabedoria*';

        // Act
        final result = TTSTextProcessor.processForTTS(text);

        // Assert
        expect(result, 'Como diziam os romanos: Carpe diem - aproveite o dia!');
      });
    });

    group('containsFormattingElements', () {
      test('should detect asterisk formatting', () {
        expect(TTSTextProcessor.containsFormattingElements('*action*'), isTrue);
        expect(
            TTSTextProcessor.containsFormattingElements('text with *emphasis*'),
            isTrue);
      });

      test('should detect underscore formatting', () {
        expect(TTSTextProcessor.containsFormattingElements('_latin phrase_'),
            isTrue);
        expect(
            TTSTextProcessor.containsFormattingElements(
                'text with _special_ phrase'),
            isTrue);
      });

      test('should detect multiple spaces', () {
        expect(
            TTSTextProcessor.containsFormattingElements('text  with   spaces'),
            isTrue);
      });

      test('should return false for clean text', () {
        expect(
            TTSTextProcessor.containsFormattingElements(
                'Clean text without formatting'),
            isFalse);
      });
    });

    group('getProcessingPreview', () {
      test('should provide before and after preview', () {
        // Arrange
        const text = '*action* Some _emphasized_ text.';

        // Act
        final preview = TTSTextProcessor.getProcessingPreview(text);

        // Assert
        expect(preview['original'], text);
        expect(preview['processed'], 'Some emphasized text.');
      });
    });

    group('specific Oracle patterns', () {
      test('should remove helmet adjustment action', () {
        const text = '*ajusta o elmo pensativamente*';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result, '');
      });

      test('should handle thoughtful actions', () {
        const text = '*olha pensativamente para o horizonte*';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result, '');
      });

      test('should preserve emphasized dialogue', () {
        const text = '*é importante manter a disciplina*';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result, 'é importante manter a disciplina');
      });

      test('should clean Latin phrases properly', () {
        const text = '_Veni, vidi, vici_ - I came, I saw, I conquered.';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result, 'Veni, vidi, vici - I came, I saw, I conquered.');
      });

      test('should handle double asterisks for strong emphasis', () {
        const text = '**empire of excellence!**';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result, 'empire of excellence!');
      });

      test('should remove English action descriptions', () {
        const text = '*strokes chin thoughtfully*';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result, '');
      });

      test('should remove chuckling action', () {
        const text = '*chuckles warmly*';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result, '');
      });

      test('should handle mixed formatting in Oracle response', () {
        const text =
            '''*strokes chin thoughtfully* Ah, habit formation - the key to success! **empire of excellence!** *chuckles warmly*''';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result,
            'Ah, habit formation - the key to success! empire of excellence!');
      });

      test('should remove new action patterns from Oracle responses', () {
        const text =
            '*leans in with a smirk* Of course! *chuckles and pats you on the shoulder*';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result, 'Of course!');
      });

      test('should handle complex Oracle message with multiple actions', () {
        const text =
            '''*strokes chin thoughtfully* Ah, the art of forging new habits! **The key is consistency, my friend.** *leans in with a smirk* Of course, the real punchline is this: *chuckles and pats you on the shoulder*''';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result,
            'Ah, the art of forging new habits! The key is consistency, my friend. Of course, the real punchline is this:');
      });

      test('should remove Portuguese action descriptions', () {
        const text =
            '*cruza os braços e inclina a cabeça, esperando sua pergunta* Como um verdadeiro legionário romano, **O conhecimento não tem fronteiras!**';
        final result = TTSTextProcessor.processForTTS(text);
        expect(result,
            'Como um verdadeiro legionário romano, O conhecimento não tem fronteiras!');
      });
    });
  });
}
