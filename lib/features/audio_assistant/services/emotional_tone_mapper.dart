/// Service for extracting emotional context from text and mapping it to voice parameters.
///
/// This service analyzes action descriptions that are removed from TTS text
/// and extracts emotional context to adjust the voice synthesis parameters
/// for more natural and expressive speech.
class EmotionalToneMapper {
  /// Extract emotional context from text and return voice parameter adjustments
  ///
  /// [text] The original text containing action descriptions
  /// Returns a map of voice parameter adjustments based on detected emotions
  static Map<String, dynamic> extractEmotionalTone(String text) {
    final emotions = _detectEmotions(text);
    return _mapEmotionsToVoiceParams(emotions);
  }

  /// Detect emotions from action descriptions in the text
  static List<String> _detectEmotions(String text) {
    final emotions = <String>[];

    // First, temporarily replace double asterisks to avoid regex conflicts
    final tempText = text.replaceAll('**', '〈〈DOUBLE_ASTERISK〉〉');

    // Extract all action descriptions (content within single asterisks)
    final actionMatches = RegExp(r'\*([^*]+)\*').allMatches(tempText);

    for (final match in actionMatches) {
      final action = match.group(1)!.toLowerCase();

      // Skip if this is just whitespace or non-action content
      if (action.trim().isEmpty || action.length > 80) {
        continue;
      }

      // Map actions to emotional categories
      if (_isThoughtfulAction(action)) {
        emotions.add('thoughtful');
      }
      if (_isWarmAction(action)) {
        emotions.add('warm');
      }
      if (_isPlayfulAction(action)) {
        emotions.add('playful');
      }
      if (_isSeriousAction(action)) {
        emotions.add('serious');
      }
      if (_isConfidentAction(action)) {
        emotions.add('confident');
      }
    }

    return emotions.toSet().toList(); // Remove duplicates
  }

  /// Check if action indicates thoughtful/contemplative emotion
  static bool _isThoughtfulAction(String action) {
    final thoughtfulIndicators = [
      'pensativamente',
      'thoughtfully',
      'pensa',
      'contempla',
      'reflete',
      'inclina a cabeça',
      'esperando',
      'strokes chin',
      'pauses',
      'considers'
    ];

    return thoughtfulIndicators.any((indicator) => action.contains(indicator));
  }

  /// Check if action indicates warm/friendly emotion
  static bool _isWarmAction(String action) {
    final warmIndicators = [
      'warmly',
      'warmth',
      'sorri',
      'smiles',
      'chuckles',
      'pats',
      'shoulder',
      'friendly',
      'kindly',
      'gently'
    ];

    return warmIndicators.any((indicator) => action.contains(indicator));
  }

  /// Check if action indicates playful/mischievous emotion
  static bool _isPlayfulAction(String action) {
    final playfulIndicators = [
      'smirk',
      'with a smirk',
      'winks',
      'grins',
      'leans in',
      'taps',
      'playfully',
      'mischievously',
      'with a grin'
    ];

    return playfulIndicators.any((indicator) => action.contains(indicator));
  }

  /// Check if action indicates serious/authoritative emotion
  static bool _isSeriousAction(String action) {
    final seriousIndicators = [
      'seriously',
      'sternly',
      'firmly',
      'gravely',
      'solemnly',
      'with authority',
      'commanding',
      'decisively'
    ];

    return seriousIndicators.any((indicator) => action.contains(indicator));
  }

  /// Check if action indicates confident/assertive emotion
  static bool _isConfidentAction(String action) {
    final confidentIndicators = [
      'confidently',
      'boldly',
      'assertively',
      'proudly',
      'with conviction',
      'stands tall',
      'chest out'
    ];

    return confidentIndicators.any((indicator) => action.contains(indicator));
  }

  /// Map detected emotions to ElevenLabs voice parameter adjustments
  static Map<String, dynamic> _mapEmotionsToVoiceParams(List<String> emotions) {
    // Default voice settings (baseline)
    Map<String, dynamic> params = {
      'stability': 0.5,
      'similarity_boost': 0.75,
      'style': 0.0,
      'speaker_boost': true,
    };

    // Apply emotional adjustments
    for (final emotion in emotions) {
      switch (emotion) {
        case 'thoughtful':
          // More contemplative, slower, more deliberate
          params['stability'] =
              (params['stability'] as double) * 0.8; // More variable
          params['style'] =
              (params['style'] as double) + 0.1; // Slightly more expressive
          break;

        case 'warm':
          // Friendlier, more approachable
          params['similarity_boost'] =
              (params['similarity_boost'] as double) + 0.1;
          params['style'] =
              (params['style'] as double) + 0.2; // More expressive
          break;

        case 'playful':
          // More dynamic, expressive
          params['stability'] =
              (params['stability'] as double) * 0.7; // More variable
          params['style'] =
              (params['style'] as double) + 0.3; // Much more expressive
          break;

        case 'serious':
          // More authoritative, stable
          params['stability'] =
              (params['stability'] as double) + 0.2; // More stable
          params['style'] =
              (params['style'] as double) - 0.1; // Less expressive
          break;

        case 'confident':
          // More assertive, clear
          params['similarity_boost'] =
              (params['similarity_boost'] as double) + 0.15;
          params['speaker_boost'] = true; // Ensure clarity
          break;
      }
    }

    // Ensure parameters stay within valid ranges (0.0 - 1.0)
    params['stability'] = (params['stability'] as double).clamp(0.0, 1.0);
    params['similarity_boost'] =
        (params['similarity_boost'] as double).clamp(0.0, 1.0);
    params['style'] = (params['style'] as double).clamp(0.0, 1.0);

    return params;
  }

  /// Get a human-readable description of detected emotions (for debugging)
  static String getEmotionalDescription(String text) {
    final emotions = _detectEmotions(text);
    if (emotions.isEmpty) {
      return 'neutral tone';
    }

    return 'detected emotions: ${emotions.join(', ')}';
  }

  /// Check if text contains emotional context that would affect voice parameters
  static bool hasEmotionalContext(String text) {
    return _detectEmotions(text).isNotEmpty;
  }
}
