import '../utils/logger.dart';
import 'time_format_localizer.dart';

/// Service for preprocessing text before TTS generation to improve audio quality
class TTSPreprocessingService {
  static final Logger _logger = Logger();

  /// Preprocess text to improve TTS audio quality
  static String preprocessForTTS(String text, String language) {
    try {
      String processedText = text;

      // Localize time formats first (new functionality for time format issue)
      processedText =
          TimeFormatLocalizer.localizeTimeFormats(processedText, language);

      // Remove acronyms in parentheses (existing functionality)
      processedText = _removeAcronymsInParentheses(processedText);

      // Fix author-book list patterns (functionality for author-book issue)
      processedText = _fixAuthorBookLists(processedText);

      // Add other preprocessing rules as needed
      processedText = _addGeneralPauses(processedText);

      _logger.debug('TTS preprocessing completed');
      return processedText;
    } catch (e) {
      _logger.error('Error in TTS preprocessing: $e');
      return text; // Return original text if preprocessing fails
    }
  }

  /// Remove acronyms in parentheses for better TTS flow
  static String _removeAcronymsInParentheses(String text) {
    // Remove patterns like (SF1233), (SM13), (R1) etc.
    // But preserve newlines
    return text
        .replaceAll(RegExp(r'\s*\([A-Z]+\d*\)\s*'), ' ')
        .replaceAll(RegExp(r'[ \t]+'),
            ' ') // Only collapse spaces and tabs, not newlines
        .replaceAll(RegExp(r' +\n'), '\n') // Clean up spaces before newlines
        .replaceAll(RegExp(r'\n +'), '\n') // Clean up spaces after newlines
        .trim();
  }

  /// Fix author-book list patterns by adding proper punctuation
  static String _fixAuthorBookLists(String text) {
    // Split text into lines to process each line individually
    final lines = text.split('\n');
    final processedLines = <String>[];

    for (String line in lines) {
      final trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) {
        processedLines.add(line);
        continue;
      }

      // Check if line matches author-book pattern: "Author Name - Book Title"
      final authorBookMatch =
          RegExp(r'^([^-]+)\s*[-–—]\s*(.+)$').firstMatch(trimmedLine);

      if (authorBookMatch != null) {
        final author = authorBookMatch.group(1)?.trim() ?? '';
        final book = authorBookMatch.group(2)?.trim() ?? '';

        // Add period for better TTS pronunciation
        processedLines.add('$author - $book.');
      } else {
        processedLines.add(line);
      }
    }

    return processedLines.join('\n');
  }

  /// Add general pauses and improvements for TTS
  static String _addGeneralPauses(String text) {
    String processedText = text;

    // Add pause after numbered lists
    processedText = processedText.replaceAll(RegExp(r'^(\d+\.)\s*'), r'$1 ');

    // Add pause after bullet points
    processedText =
        processedText.replaceAll(RegExp(r'^[-•]\s*', multiLine: true), '- ');

    // Ensure questions end with proper punctuation
    processedText = processedText.replaceAll(RegExp(r'\?(?!\s*$)'), '? ');

    // Add pause before new paragraphs (double newlines)
    processedText = processedText.replaceAll(RegExp(r'\n\n+'), '\n\n');

    return processedText;
  }

  /// Specific preprocessing for author lists in responses
  static String preprocessAuthorList(String text) {
    // More aggressive preprocessing specifically for author-book lists
    final lines = text.split('\n');
    final processedLines = <String>[];

    for (String line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        processedLines.add(line);
        continue;
      }

      // Check if line matches author-book pattern
      final authorBookMatch =
          RegExp(r'^([^-]+)\s*[-–—]\s*(.+)$').firstMatch(trimmedLine);

      if (authorBookMatch != null) {
        final author = authorBookMatch.group(1)?.trim() ?? '';
        final book = authorBookMatch.group(2)?.trim() ?? '';

        // Format for better TTS: Author, pause, book title, period, pause
        processedLines.add('$author. $book.');
      } else {
        processedLines.add(line);
      }
    }

    return processedLines.join('\n');
  }

  /// Log processing statistics for debugging
  static void logProcessingStats(
      String originalText, String processedText, String language) {
    _logger.debug('TTS Preprocessing Stats:');
    _logger.debug('  Language: $language');
    _logger.debug('  Original length: ${originalText.length}');
    _logger.debug('  Processed length: ${processedText.length}');
    _logger.debug('  Changes made: ${originalText != processedText}');
  }

  /// Check if text contains elements that can be processed
  static bool containsProcessableElements(String text) {
    // Check for acronyms in parentheses
    if (RegExp(r'\([A-Z]+\d*\)').hasMatch(text)) return true;

    // Check for author-book patterns
    if (RegExp(r'^[^-]+\s*[-–—]\s*.+$', multiLine: true).hasMatch(text))
      return true;

    return false;
  }

  /// Get a preview of what processing would do to the text
  static Map<String, String> getProcessingPreview(
      String text, String language) {
    final processed = preprocessForTTS(text, language);
    return {
      'original': text,
      'processed': processed,
    };
  }
}
