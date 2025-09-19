import 'package:flutter_test/flutter_test.dart';
import '../../lib/utils/language_utils.dart';

void main() {
  group('LanguageUtils - FT-132 Tests', () {
    group('normalizeToLanguageCode', () {
      test('should map Portuguese variants to pt', () {
        expect(LanguageUtils.normalizeToLanguageCode('pt_BR'), equals('pt'));
        expect(LanguageUtils.normalizeToLanguageCode('pt'), equals('pt'));
      });

      test('should map English variants to en', () {
        expect(LanguageUtils.normalizeToLanguageCode('en_US'), equals('en'));
        expect(LanguageUtils.normalizeToLanguageCode('en'), equals('en'));
      });

      test('should map Spanish variants to es', () {
        expect(LanguageUtils.normalizeToLanguageCode('es'), equals('es'));
        expect(LanguageUtils.normalizeToLanguageCode('es_ES'), equals('es'));
      });

      test('should map French variants to fr', () {
        expect(LanguageUtils.normalizeToLanguageCode('fr'), equals('fr'));
        expect(LanguageUtils.normalizeToLanguageCode('fr_FR'), equals('fr'));
      });

      test('should fallback to en for unknown languages', () {
        expect(LanguageUtils.normalizeToLanguageCode('de'), equals('en'));
        expect(LanguageUtils.normalizeToLanguageCode('ja'), equals('en'));
        expect(LanguageUtils.normalizeToLanguageCode('unknown'), equals('en'));
      });

      test('should return null for null input', () {
        expect(LanguageUtils.normalizeToLanguageCode(null), isNull);
      });
    });

    group('language detection helpers', () {
      test('isPortuguese should detect Portuguese variants', () {
        expect(LanguageUtils.isPortuguese('pt_BR'), isTrue);
        expect(LanguageUtils.isPortuguese('pt'), isTrue);
        expect(LanguageUtils.isPortuguese('pt_PT'), isTrue);
        expect(LanguageUtils.isPortuguese('en_US'), isFalse);
        expect(LanguageUtils.isPortuguese('es'), isFalse);
      });

      test('isEnglish should detect English variants', () {
        expect(LanguageUtils.isEnglish('en_US'), isTrue);
        expect(LanguageUtils.isEnglish('en'), isTrue);
        expect(LanguageUtils.isEnglish('en_GB'), isTrue);
        expect(LanguageUtils.isEnglish('pt_BR'), isFalse);
        expect(LanguageUtils.isEnglish('es'), isFalse);
      });

      test('requiresTimeLocalization should return true for Portuguese', () {
        expect(LanguageUtils.requiresTimeLocalization('pt_BR'), isTrue);
        expect(LanguageUtils.requiresTimeLocalization('pt'), isTrue);
        expect(LanguageUtils.requiresTimeLocalization('en_US'), isFalse);
        expect(LanguageUtils.requiresTimeLocalization('es'), isFalse);
      });

      test('usePortugueseNumbers should return true for Portuguese', () {
        expect(LanguageUtils.usePortugueseNumbers('pt_BR'), isTrue);
        expect(LanguageUtils.usePortugueseNumbers('pt'), isTrue);
        expect(LanguageUtils.usePortugueseNumbers('en_US'), isFalse);
        expect(LanguageUtils.usePortugueseNumbers('es'), isFalse);
      });
    });

    group('constants', () {
      test('should have correct default values', () {
        expect(LanguageUtils.defaultLanguage, equals('en_US'));
        expect(LanguageUtils.defaultLanguageCode, equals('en'));
      });
    });
  });
}
