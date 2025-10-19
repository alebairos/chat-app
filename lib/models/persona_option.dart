/// FT-207: Persona Mention Autocomplete
/// Data model for persona options in autocomplete suggestions
class PersonaOption {
  final String key; // "aristiosPhilosopher45"
  final String displayName; // "Aristios 4.5, The Philosopher"
  final String shortName; // "aristios"
  final String description; // Brief description
  final String icon; // "🧠"
  final bool isEnabled; // Available for selection

  const PersonaOption({
    required this.key,
    required this.displayName,
    required this.shortName,
    required this.description,
    required this.icon,
    required this.isEnabled,
  });

  /// Check if this persona matches the search query
  bool matches(String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase();

    // Check short name (primary match)
    if (shortName.toLowerCase().startsWith(lowerQuery)) {
      return true;
    }

    // Check display name (secondary match)
    if (displayName.toLowerCase().contains(lowerQuery)) {
      return true;
    }

    // Check persona key (fallback match)
    if (key.toLowerCase().contains(lowerQuery)) {
      return true;
    }

    return false;
  }

  /// Get relevance score for sorting (lower = more relevant)
  int getRelevanceScore(String query) {
    if (query.isEmpty) return 0;

    final lowerQuery = query.toLowerCase();

    // Exact short name match (highest priority)
    if (shortName.toLowerCase() == lowerQuery) {
      return 0;
    }

    // Short name starts with query
    if (shortName.toLowerCase().startsWith(lowerQuery)) {
      return 1;
    }

    // Display name starts with query
    if (displayName.toLowerCase().startsWith(lowerQuery)) {
      return 2;
    }

    // Display name contains query
    if (displayName.toLowerCase().contains(lowerQuery)) {
      return 3;
    }

    // Key contains query (lowest priority)
    return 4;
  }

  @override
  String toString() {
    return 'PersonaOption(key: $key, displayName: $displayName, shortName: $shortName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonaOption && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// FT-207: Data model for detected @mentions in text
class PersonaMention {
  final int startIndex; // Position of @ symbol
  final int endIndex; // End of mention text
  final String partialName; // Text after @ symbol

  const PersonaMention({
    required this.startIndex,
    required this.endIndex,
    required this.partialName,
  });

  /// Length of the mention text including @
  int get length => endIndex - startIndex;

  /// Full mention text including @
  String get fullText => '@$partialName';

  @override
  String toString() {
    return 'PersonaMention(startIndex: $startIndex, endIndex: $endIndex, partialName: "$partialName")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonaMention &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex &&
        other.partialName == partialName;
  }

  @override
  int get hashCode => Object.hash(startIndex, endIndex, partialName);
}
