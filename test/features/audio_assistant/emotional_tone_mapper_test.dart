import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/features/audio_assistant/services/emotional_tone_mapper.dart';

void main() {
  group('EmotionalToneMapper', () {
    group('extractEmotionalTone', () {
      test('should detect thoughtful emotion and adjust voice parameters', () {
        const text = '*strokes chin thoughtfully* Interesting question.';
        final result = EmotionalToneMapper.extractEmotionalTone(text);

        expect(
            result['stability'], lessThan(0.5)); // More variable for thoughtful
        expect(result['style'], greaterThan(0.0)); // More expressive
      });

      test('should detect warm emotion and adjust voice parameters', () {
        const text = '*chuckles warmly* That\'s a great point!';
        final result = EmotionalToneMapper.extractEmotionalTone(text);

        expect(result['similarity_boost'], greaterThan(0.75)); // Warmer
        expect(result['style'], greaterThan(0.0)); // More expressive
      });

      test('should detect playful emotion and adjust voice parameters', () {
        const text = '*leans in with a smirk* Want to know a secret?';
        final result = EmotionalToneMapper.extractEmotionalTone(text);

        expect(result['stability'], lessThan(0.5)); // More variable for playful
        expect(result['style'], greaterThan(0.2)); // Much more expressive
      });

      test('should handle multiple emotions and combine adjustments', () {
        const text =
            '*chuckles warmly* *leans in with a smirk* This is interesting.';
        final result = EmotionalToneMapper.extractEmotionalTone(text);

        // Should have adjustments from both warm and playful emotions
        expect(result['similarity_boost'], greaterThan(0.75)); // From warm
        expect(result['style'], greaterThan(0.2)); // From playful
      });

      test('should return default parameters for neutral text', () {
        const text = 'This is a normal sentence without emotions.';
        final result = EmotionalToneMapper.extractEmotionalTone(text);

        expect(result['stability'], 0.5);
        expect(result['similarity_boost'], 0.75);
        expect(result['style'], 0.0);
        expect(result['speaker_boost'], true);
      });

      test('should keep parameters within valid ranges', () {
        const text =
            '*chuckles warmly* *leans in with a smirk* *confidently* *proudly*';
        final result = EmotionalToneMapper.extractEmotionalTone(text);

        expect(result['stability'], greaterThanOrEqualTo(0.0));
        expect(result['stability'], lessThanOrEqualTo(1.0));
        expect(result['similarity_boost'], greaterThanOrEqualTo(0.0));
        expect(result['similarity_boost'], lessThanOrEqualTo(1.0));
        expect(result['style'], greaterThanOrEqualTo(0.0));
        expect(result['style'], lessThanOrEqualTo(1.0));
      });
    });

    group('hasEmotionalContext', () {
      test('should detect emotional context in text with actions', () {
        const text = '*chuckles* This is funny.';
        expect(EmotionalToneMapper.hasEmotionalContext(text), isTrue);
      });

      test('should not detect emotional context in neutral text', () {
        const text = 'This is a normal sentence.';
        expect(EmotionalToneMapper.hasEmotionalContext(text), isFalse);
      });
    });

    group('getEmotionalDescription', () {
      test('should provide description of detected emotions', () {
        const text = '*chuckles warmly* *thoughtfully*';
        final description = EmotionalToneMapper.getEmotionalDescription(text);

        expect(description, contains('warm'));
        expect(description, contains('thoughtful'));
      });

      test('should return neutral description for text without emotions', () {
        const text = 'Normal text without emotions.';
        final description = EmotionalToneMapper.getEmotionalDescription(text);

        expect(description, 'neutral tone');
      });
    });

    group('Oracle-specific emotion detection', () {
      test('should detect emotions from Oracle message patterns', () {
        const oracleText =
            '''*strokes chin thoughtfully* Ah, the art of forging new habits! **The key is consistency, my friend.** *leans in with a smirk* Of course, the real punchline is this: *chuckles and pats you on the shoulder*''';

        final result = EmotionalToneMapper.extractEmotionalTone(oracleText);
        final description =
            EmotionalToneMapper.getEmotionalDescription(oracleText);

        expect(description, contains('thoughtful'));
        expect(description, contains('playful'));
        expect(description, contains('warm'));

        // Voice should be adjusted for multiple emotions
        expect(result['stability'], lessThan(0.5)); // More expressive
        expect(result['style'], greaterThan(0.2)); // More dynamic
      });

      test('should detect emotions from Portuguese Oracle patterns', () {
        const portugueseText =
            '*cruza os braços e inclina a cabeça, esperando sua pergunta* Como um verdadeiro legionário romano, **O conhecimento não tem fronteiras!**';

        final result = EmotionalToneMapper.extractEmotionalTone(portugueseText);
        final description =
            EmotionalToneMapper.getEmotionalDescription(portugueseText);

        expect(description, contains('thoughtful'));

        // Voice should be adjusted for thoughtful emotion
        expect(
            result['stability'], lessThan(0.5)); // More variable for thoughtful
        expect(result['style'], greaterThan(0.0)); // More expressive
      });
    });
  });
}
