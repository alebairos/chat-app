import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/tts_preprocessing_service.dart';

void main() {
  group('FT-080: TTS Quote Preprocessing Fix', () {
    test('should remove wrapping quotes from entire response', () {
      const input = '"Exatamente! Como planejar seu fim de semana para manter esse momentum?"';
      const expected = 'Exatamente! Como planejar seu fim de semana para manter esse momentum?';
      
      final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');
      
      expect(result, expected);
    });

    test('should remove escape characters', () {
      const input = '\\"Hello world\\"';
      const expected = 'Hello world';
      
      final result = TTSPreprocessingService.preprocessForTTS(input, 'en_US');
      
      expect(result, expected);
    });

    test('should remove internal quotes', () {
      const input = 'He said "hello" to me';
      const expected = 'He said hello to me';
      
      final result = TTSPreprocessingService.preprocessForTTS(input, 'en_US');
      
      expect(result, expected);
    });

    test('should handle mixed quotes', () {
      const input = '"She replied \'yes\' confidently"';
      const expected = 'She replied yes confidently';
      
      final result = TTSPreprocessingService.preprocessForTTS(input, 'en_US');
      
      expect(result, expected);
    });

    test('should preserve text without quotes', () {
      const input = 'Regular text without quotes';
      
      final result = TTSPreprocessingService.preprocessForTTS(input, 'en_US');
      
      // Should contain the original text (may have other preprocessing applied)
      expect(result, contains('Regular text without quotes'));
    });

    test('should handle empty quotes', () {
      const input = '""';
      const expected = '';
      
      final result = TTSPreprocessingService.preprocessForTTS(input, 'en_US');
      
      expect(result.trim(), expected);
    });

    test('should not remove quotes that do not wrap entire response', () {
      const input = 'Start "quoted text" end';
      
      final result = TTSPreprocessingService.preprocessForTTS(input, 'en_US');
      
      // Internal quotes should be removed, but structure preserved
      expect(result, contains('Start'));
      expect(result, contains('quoted text'));
      expect(result, contains('end'));
      expect(result, isNot(contains('"')));
    });

    test('should handle the original bug case', () {
      // This is the exact case from the logs that was causing the issue
      const input = '"Exatamente! Como planejar seu fim de semana para manter esse momentum?"';
      
      final result = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');
      
      // Should not contain quotes or escape characters
      expect(result, isNot(contains('"')));
      expect(result, isNot(contains('\\"')));
      expect(result, contains('Exatamente'));
      expect(result, contains('momentum'));
    });
  });
}
