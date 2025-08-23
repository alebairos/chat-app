import '../utils/logger.dart';
import 'time_format_localizer.dart';

/// Service for preprocessing text before TTS generation to improve audio quality
class TTSPreprocessingService {
  static final Logger _logger = Logger();

  /// Preprocess text to improve TTS audio quality
  static String preprocessForTTS(String text, String language) {
    try {
      String processedText = text;

      // Clean quotes for better TTS (FT-080 fix)
      processedText = _cleanQuotesForTTS(processedText);

      // Localize time formats first (new functionality for time format issue)
      processedText =
          TimeFormatLocalizer.localizeTimeFormats(processedText, language);

      // Remove acronyms in parentheses (existing functionality)
      processedText = _removeAcronymsInParentheses(processedText);

      // Convert numbers to words
      processedText = _convertNumbersToWords(processedText, language);

      // Expand abbreviations
      processedText = _expandAbbreviations(processedText, language);

      // Fix author-book list patterns (functionality for author-book issue)
      processedText = _fixAuthorBookLists(processedText);

      // Add other preprocessing rules as needed
      processedText = _addGeneralPauses(processedText);

      // Normalize whitespace
      processedText = _normalizeWhitespace(processedText);

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
    // But preserve normal parentheses content like (30 minutes)
    String result = text.replaceAll(RegExp(r'\s*\([A-Z]+\d*\)\s*'), ' ');

    // Fix comma spacing issues that might arise
    result = result.replaceAll(RegExp(r'\s*,\s*'), ', ');

    return result.trim();
  }

  /// Convert numbers to words based on language
  static String _convertNumbersToWords(String text, String language) {
    // Maps for number conversion
    final Map<int, String> portugueseNumbers = {
      0: 'zero',
      1: 'um',
      2: 'dois',
      3: 'três',
      4: 'quatro',
      5: 'cinco',
      6: 'seis',
      7: 'sete',
      8: 'oito',
      9: 'nove',
      10: 'dez',
      11: 'onze',
      12: 'doze',
      13: 'treze',
      14: 'quatorze',
      15: 'quinze',
      16: 'dezesseis',
      17: 'dezessete',
      18: 'dezoito',
      19: 'dezenove',
      20: 'vinte',
      30: 'trinta',
      40: 'quarenta',
      50: 'cinquenta',
      60: 'sessenta',
      70: 'setenta',
      80: 'oitenta',
      90: 'noventa'
    };

    final Map<int, String> englishNumbers = {
      0: 'zero',
      1: 'one',
      2: 'two',
      3: 'three',
      4: 'four',
      5: 'five',
      6: 'six',
      7: 'seven',
      8: 'eight',
      9: 'nine',
      10: 'ten',
      11: 'eleven',
      12: 'twelve',
      13: 'thirteen',
      14: 'fourteen',
      15: 'fifteen',
      16: 'sixteen',
      17: 'seventeen',
      18: 'eighteen',
      19: 'nineteen',
      20: 'twenty',
      30: 'thirty',
      40: 'forty',
      50: 'fifty',
      60: 'sixty',
      70: 'seventy',
      80: 'eighty',
      90: 'ninety'
    };

    final numberMap =
        language.startsWith('pt') ? portugueseNumbers : englishNumbers;

    return text.replaceAllMapped(RegExp(r'\b(\d+)\b'), (match) {
      final num = int.tryParse(match.group(1)!);
      if (num != null && numberMap.containsKey(num)) {
        return numberMap[num]!;
      }
      return match.group(0)!;
    });
  }

  /// Expand abbreviations based on language
  static String _expandAbbreviations(String text, String language) {
    if (language.startsWith('pt')) {
      return text
          .replaceAll(RegExp(r'\bmin\b'), 'minutos')
          .replaceAll(RegExp(r'\bhr\b'), 'horas');
    } else {
      return text
          .replaceAll(RegExp(r'\bmin\b'), 'minutes')
          .replaceAll(RegExp(r'\bhr\b'), 'hours');
    }
  }

  /// Normalize whitespace
  static String _normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
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

    // Check for numbers
    if (RegExp(r'\b\d+\b').hasMatch(text)) return true;

    // Check for abbreviations
    if (RegExp(r'\b(min|hr)\b').hasMatch(text)) return true;

    // Check for author-book patterns
    if (RegExp(r'^[^-]+\s*[-–—]\s*.+$', multiLine: true).hasMatch(text)) {
      return true;
    }

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

  /// Clean quotes for better TTS pronunciation (FT-080)
  /// 
  /// Removes unnecessary quote escaping and wrapping that can cause
  /// pronunciation issues or audio artifacts in speech synthesis.
  static String _cleanQuotesForTTS(String text) {
    try {
      String cleaned = text.trim();
      
      // Handle wrapped double quotes: "entire response"
      // Only remove if quotes wrap the entire response
      if (cleaned.startsWith('"') && cleaned.endsWith('"') && 
          cleaned.indexOf('"', 1) == cleaned.length - 1) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }
      
      // Remove escape characters for TTS
      cleaned = cleaned.replaceAll('\\"', '"');
      cleaned = cleaned.replaceAll("\\'", "'");
      
      // Remove all quotes entirely for cleaner speech
      // This prevents awkward pauses or pronunciation issues
      cleaned = cleaned.replaceAll('"', '');
      cleaned = cleaned.replaceAll("'", '');
      
      return cleaned.trim();
    } catch (e) {
      _logger.error('Error cleaning quotes for TTS: $e');
      return text; // Return original text if cleaning fails
    }
  }
}
