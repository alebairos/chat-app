/// FT-207: Persona Mention Autocomplete
/// Parser for detecting @mentions in text input
import '../models/persona_option.dart';

class PersonaMentionParser {
  /// Extract current @mention from text at cursor position
  /// Returns null if no valid mention is found at cursor
  static PersonaMention? extractMention(String text, int cursorPosition) {
    // Validate input
    if (text.isEmpty || cursorPosition < 0 || cursorPosition > text.length) {
      return null;
    }

    // Find the last @ symbol before or at cursor position
    int atIndex = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      }
      // Stop if we hit whitespace or newline (not part of mention)
      if (text[i] == ' ' || text[i] == '\n' || text[i] == '\t') {
        break;
      }
    }

    // No @ symbol found
    if (atIndex == -1) {
      return null;
    }

    // Find the end of the mention (next whitespace or end of text)
    int endIndex = text.length;
    for (int i = atIndex + 1; i < text.length; i++) {
      if (text[i] == ' ' || text[i] == '\n' || text[i] == '\t') {
        endIndex = i;
        break;
      }
    }

    // Ensure cursor is within the mention range
    if (cursorPosition < atIndex || cursorPosition > endIndex) {
      return null;
    }

    // Extract the partial name after @
    final partialName = text.substring(atIndex + 1, endIndex);

    // Validate mention format (allow empty for showing all personas)
    if (!_isValidMentionText(partialName)) {
      return null;
    }

    return PersonaMention(
      startIndex: atIndex,
      endIndex: endIndex,
      partialName: partialName,
    );
  }

  /// Check if the text after @ is valid for a mention
  /// Allows letters, numbers, and common characters
  static bool _isValidMentionText(String text) {
    // Empty is valid (shows all personas)
    if (text.isEmpty) {
      return true;
    }

    // Check for valid characters (letters, numbers, underscore, dash)
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]*$');
    return validPattern.hasMatch(text);
  }

  /// Replace @mention in text with selected persona name
  /// Returns the new text with the mention replaced
  static String replaceMention(
    String originalText,
    PersonaMention mention,
    String replacementText, {
    bool addSpace = true,
  }) {
    final replacement = addSpace ? '$replacementText ' : replacementText;

    return originalText.replaceRange(
      mention.startIndex,
      mention.endIndex,
      replacement,
    );
  }

  /// Get cursor position after mention replacement
  /// Useful for maintaining cursor position after replacement
  static int getCursorAfterReplacement(
    PersonaMention mention,
    String replacementText, {
    bool addSpace = true,
  }) {
    final replacement = addSpace ? '$replacementText ' : replacementText;
    return mention.startIndex + replacement.length;
  }

  /// Check if text contains any @mentions (for validation)
  static bool containsMentions(String text) {
    return text.contains('@');
  }

  /// Extract all @mentions from text (for advanced use cases)
  static List<PersonaMention> extractAllMentions(String text) {
    final mentions = <PersonaMention>[];

    for (int i = 0; i < text.length; i++) {
      if (text[i] == '@') {
        // Find end of this mention
        int endIndex = text.length;
        for (int j = i + 1; j < text.length; j++) {
          if (text[j] == ' ' || text[j] == '\n' || text[j] == '\t') {
            endIndex = j;
            break;
          }
        }

        final partialName = text.substring(i + 1, endIndex);
        if (_isValidMentionText(partialName)) {
          mentions.add(PersonaMention(
            startIndex: i,
            endIndex: endIndex,
            partialName: partialName,
          ));
        }

        // Skip to end of this mention
        i = endIndex - 1;
      }
    }

    return mentions;
  }
}
