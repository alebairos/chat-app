import '../utils/logger.dart';
import '../utils/language_utils.dart';

/// Service for localizing time formats in text for better TTS pronunciation
class TimeFormatLocalizer {
  static final Logger _logger = Logger();

  /// Localize time formats in text based on target language
  ///
  /// [text] The text containing time formats to localize
  /// [language] Target language code (e.g., 'pt_BR', 'en_US')
  /// Returns text with localized time formats
  static String localizeTimeFormats(String text, String language) {
    // Use centralized language detection for consistency
    if (!LanguageUtils.requiresTimeLocalization(language)) {
      return text;
    }

    if (LanguageUtils.isPortuguese(language)) {
      return _localizeToPortuguese(text);
    }

    // Default: no localization for unknown languages
    return text;
  }

  /// Convert time formats to Portuguese representation
  ///
  /// [text] Text containing time formats
  /// Returns text with Portuguese time formats
  static String _localizeToPortuguese(String text) {
    String localizedText = text;

    // Pattern 1: Match HH:MM[am/pm] and H:MM[am/pm]
    final timeWithMinutesPattern = RegExp(
      r'\b(\d{1,2}):(\d{2})\s*(am|pm|AM|PM)\b',
      caseSensitive: false,
    );

    // Pattern 2: Match H[am/pm] (like 11pm) - but not if preceded by a colon
    final timeWithoutMinutesPattern = RegExp(
      r'(?<!:)(?<!\d:)\b(\d{1,2})\s*(am|pm|AM|PM)\b',
      caseSensitive: false,
    );

    // First, handle times with minutes (HH:MM am/pm)
    localizedText =
        localizedText.replaceAllMapped(timeWithMinutesPattern, (match) {
      final hourStr = match.group(1)!;
      final minuteStr = match.group(2)!;
      final period = match.group(3)!.toLowerCase();

      int hour = int.parse(hourStr);
      final minute = int.parse(minuteStr);

      // Validate time ranges
      if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
        return match.group(0)!;
      }

      // Convert 12-hour to 24-hour format
      if (period == 'pm' && hour != 12) {
        hour += 12;
      } else if (period == 'am' && hour == 12) {
        hour = 0;
      }

      final formattedHour = hour.toString().padLeft(2, '0');
      final formattedMinute = minute.toString().padLeft(2, '0');

      _logger.debug(
          'Time localization: ${match.group(0)} → $formattedHour:$formattedMinute');

      return '$formattedHour:$formattedMinute';
    });

    // Then, handle times without minutes (H am/pm)
    localizedText =
        localizedText.replaceAllMapped(timeWithoutMinutesPattern, (match) {
      final hourStr = match.group(1)!;
      final period = match.group(2)!.toLowerCase();

      int hour = int.parse(hourStr);

      // Validate time ranges
      if (hour < 1 || hour > 12) {
        return match.group(0)!;
      }

      // Convert 12-hour to 24-hour format
      if (period == 'pm' && hour != 12) {
        hour += 12;
      } else if (period == 'am' && hour == 12) {
        hour = 0;
      }

      final formattedHour = hour.toString().padLeft(2, '0');

      _logger.debug('Time localization: ${match.group(0)} → $formattedHour:00');

      return '$formattedHour:00';
    });

    return localizedText;
  }

  /// Detect if text contains time patterns that might affect language detection
  ///
  /// [text] Text to analyze
  /// Returns true if time patterns are detected
  static bool containsTimePatterns(String text) {
    // Pattern for HH:MM with optional am/pm
    final timeWithMinutesPattern = RegExp(
      r'\b\d{1,2}:\d{2}(?:\s*(?:am|pm|AM|PM))?\b',
      caseSensitive: false,
    );

    // Pattern for H am/pm (like 11pm) - but not if preceded by a colon
    final timeWithoutMinutesPattern = RegExp(
      r'(?<!:)(?<!\d:)\b\d{1,2}\s*(?:am|pm|AM|PM)\b',
      caseSensitive: false,
    );

    return timeWithMinutesPattern.hasMatch(text) ||
        timeWithoutMinutesPattern.hasMatch(text);
  }

  /// Get time patterns found in text for analysis
  ///
  /// [text] Text to analyze
  /// Returns list of time pattern matches
  static List<String> extractTimePatterns(String text) {
    final patterns = <String>[];

    // Pattern for HH:MM with optional am/pm
    final timeWithMinutesPattern = RegExp(
      r'\b\d{1,2}:\d{2}(?:\s*(?:am|pm|AM|PM))?\b',
      caseSensitive: false,
    );

    // Pattern for H am/pm (like 11pm) - but not if preceded by a colon
    final timeWithoutMinutesPattern = RegExp(
      r'(?<!:)(?<!\d:)\b\d{1,2}\s*(?:am|pm|AM|PM)\b',
      caseSensitive: false,
    );

    patterns.addAll(timeWithMinutesPattern
        .allMatches(text)
        .map((match) => match.group(0)!.trim()));
    patterns.addAll(timeWithoutMinutesPattern
        .allMatches(text)
        .map((match) => match.group(0)!.trim()));

    return patterns;
  }

  /// Pre-process text for language detection by neutralizing time formats
  ///
  /// This helps language detection focus on actual language content
  /// rather than being influenced by English time format patterns
  ///
  /// [text] Text to pre-process
  /// Returns text with time patterns neutralized for language detection
  static String neutralizeTimeForLanguageDetection(String text) {
    String neutralizedText = text;

    // Replace HH:MM patterns with neutral placeholders
    final timeWithMinutesPattern = RegExp(
      r'\b\d{1,2}:\d{2}(?:\s*(?:am|pm|AM|PM))?\b',
      caseSensitive: false,
    );

    // Replace H am/pm patterns with neutral placeholders - but not if preceded by a colon
    final timeWithoutMinutesPattern = RegExp(
      r'(?<!:)(?<!\d:)\b\d{1,2}\s*(?:am|pm|AM|PM)\b',
      caseSensitive: false,
    );

    neutralizedText =
        neutralizedText.replaceAll(timeWithMinutesPattern, 'HORA');
    neutralizedText =
        neutralizedText.replaceAll(timeWithoutMinutesPattern, 'HORA');

    return neutralizedText;
  }
}
