import 'logger.dart';

/// Centralized language utilities for consistent language detection and mapping
class LanguageUtils {
  static final Logger _logger = Logger();

  /// Default fallback language
  static const String defaultLanguage = 'en_US';
  static const String defaultLanguageCode = 'en';

  /// Normalize language code to ElevenLabs-compatible format
  ///
  /// Maps detected language codes to ElevenLabs API language codes.
  /// Returns null if language is not supported.
  static String? normalizeToLanguageCode(String? detectedLanguage) {
    if (detectedLanguage == null) {
      return null;
    }

    switch (detectedLanguage) {
      case 'pt_BR':
      case 'pt':
        return 'pt';
      case 'en_US':
      case 'en':
        return 'en';
      case 'es':
      case 'es_ES':
        return 'es';
      case 'fr':
      case 'fr_FR':
        return 'fr';
      default:
        // Conservative fallback to English for unknown languages
        _logger.debug(
            'LanguageUtils: Unknown language "$detectedLanguage", using fallback "$defaultLanguageCode"');
        return defaultLanguageCode;
    }
  }

  /// Check if language is Portuguese (any variant)
  static bool isPortuguese(String language) {
    return language.startsWith('pt') || language == 'pt_BR';
  }

  /// Check if language is English (any variant)
  static bool isEnglish(String language) {
    return language.startsWith('en') || language == 'en_US';
  }

  /// Check if language requires localization for time formats
  static bool requiresTimeLocalization(String language) {
    return isPortuguese(language);
  }

  /// Get appropriate number mapping for language
  static bool usePortugueseNumbers(String language) {
    return isPortuguese(language);
  }
}
