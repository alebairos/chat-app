import '../utils/logger.dart';
import 'time_format_localizer.dart';

/// Service for detecting conversation language from user messages.
///
/// This service analyzes recent user messages to determine the primary
/// language being used in the conversation, enabling language-aware TTS processing.
class LanguageDetectionService {
  static final Logger _logger = Logger();

  /// Default language to use when detection is uncertain
  static const String _defaultLanguage = 'pt_BR';

  /// Minimum confidence threshold for language detection
  static const double _confidenceThreshold = 0.6;

  /// Detect language from a list of recent messages
  ///
  /// [recentMessages] List of recent user messages (most recent first)
  /// [maxMessages] Maximum number of messages to analyze (default: 5)
  /// Returns detected language code (e.g., 'pt_BR', 'en_US')
  static String detectLanguage(List<String> recentMessages,
      {int maxMessages = 5}) {
    if (recentMessages.isEmpty) {
      _logger.debug(
          'Language Detection - No messages provided, using default: $_defaultLanguage');
      return _defaultLanguage;
    }

    // Analyze up to maxMessages recent messages
    final messagesToAnalyze = recentMessages.take(maxMessages).toList();

    _logger.debug(
        'Language Detection - Analyzing ${messagesToAnalyze.length} messages');

    // Calculate language scores
    final languageScores = _calculateLanguageScores(messagesToAnalyze);

    // Determine the most likely language
    final detectedLanguage = _selectLanguage(languageScores);

    _logger.debug('Language Detection - Detected language: $detectedLanguage');
    _logger.debug('Language Detection - Scores: $languageScores');

    return detectedLanguage;
  }

  /// Calculate language scores based on message content
  ///
  /// [messages] List of messages to analyze
  /// Returns a map of language codes to confidence scores
  static Map<String, double> _calculateLanguageScores(List<String> messages) {
    final scores = <String, double>{
      'pt_BR': 0.0,
      'en_US': 0.0,
    };

    for (String message in messages) {
      final messageScores = _analyzeMessage(message);

      // Add weighted scores (more recent messages have higher weight)
      final weight = 1.0 / (messages.indexOf(message) + 1);

      messageScores.forEach((language, score) {
        scores[language] = (scores[language] ?? 0.0) + (score * weight);
      });
    }

    // Normalize scores
    final totalScore = scores.values.fold(0.0, (sum, score) => sum + score);
    if (totalScore > 0) {
      scores.forEach((language, score) {
        scores[language] = score / totalScore;
      });
    }

    return scores;
  }

  /// Analyze a single message for language indicators
  ///
  /// [message] The message to analyze
  /// Returns a map of language codes to raw scores
  static Map<String, double> _analyzeMessage(String message) {
    final scores = <String, double>{
      'pt_BR': 0.0,
      'en_US': 0.0,
    };

    if (message.trim().isEmpty) {
      return scores;
    }

    // Pre-process message to neutralize time patterns for better language detection
    String processedMessage = message;
    bool hasTimePatterns = TimeFormatLocalizer.containsTimePatterns(message);

    if (hasTimePatterns) {
      processedMessage =
          TimeFormatLocalizer.neutralizeTimeForLanguageDetection(message);
      // Boost Portuguese score when time patterns are found in mixed content
      // This helps when Portuguese content contains English time formats
      scores['pt_BR'] = (scores['pt_BR'] ?? 0.0) + 1.5;
      _logger.debug(
          'Language Detection - Time patterns detected, boosting Portuguese score');
    }

    final lowerMessage = processedMessage.toLowerCase();

    // Portuguese indicators
    final portugueseIndicators = _getPortugueseIndicators();
    final englishIndicators = _getEnglishIndicators();

    // Count Portuguese indicators
    for (String indicator in portugueseIndicators.keys) {
      if (lowerMessage.contains(indicator)) {
        scores['pt_BR'] =
            (scores['pt_BR'] ?? 0.0) + portugueseIndicators[indicator]!;
      }
    }

    // Count English indicators
    for (String indicator in englishIndicators.keys) {
      if (lowerMessage.contains(indicator)) {
        scores['en_US'] =
            (scores['en_US'] ?? 0.0) + englishIndicators[indicator]!;
      }
    }

    // Additional analysis based on character patterns
    scores['pt_BR'] =
        (scores['pt_BR'] ?? 0.0) + _analyzePortuguesePatterns(message);
    scores['en_US'] =
        (scores['en_US'] ?? 0.0) + _analyzeEnglishPatterns(message);

    return scores;
  }

  /// Get Portuguese language indicators with their weights
  ///
  /// Returns a map of Portuguese words/phrases to their confidence weights
  static Map<String, double> _getPortugueseIndicators() {
    return {
      // Common Portuguese words (high confidence)
      'que': 3.0,
      'como': 2.5,
      'para': 2.0,
      'com': 2.0,
      'uma': 2.0,
      'seu': 2.0,
      'meu': 2.0,
      'não': 3.0,
      'sim': 2.0,
      'você': 3.0,
      'eu': 2.0,
      'ele': 2.0,
      'ela': 2.0,
      'isso': 2.0,
      'este': 2.0,
      'esta': 2.0,
      'muito': 2.0,
      'mais': 2.0,
      'menos': 2.0,
      'bem': 2.0,
      'bom': 2.0,
      'boa': 2.0,
      'melhor': 2.0,
      'pior': 2.0,
      'quando': 2.0,
      'onde': 2.0,
      'porque': 2.5,
      'porquê': 2.5,
      'por que': 2.5,
      'qual': 2.0,
      'quais': 2.0,
      'quem': 2.0,
      'quanto': 2.0,
      'quanta': 2.0,
      'quantos': 2.0,
      'quantas': 2.0,

      // Portuguese articles and prepositions
      'da': 2.0,
      'do': 2.0,
      'das': 2.0,
      'dos': 2.0,
      'na': 2.0,
      'no': 2.0,
      'nas': 2.0,
      'nos': 2.0,
      'pela': 2.0,
      'pelo': 2.0,
      'pelas': 2.0,
      'pelos': 2.0,

      // Portuguese verbs (common forms)
      'é': 2.5,
      'são': 2.0,
      'está': 2.0,
      'estão': 2.0,
      'tem': 2.0,
      'têm': 2.0,
      'ter': 2.0,
      'ser': 2.0,
      'estar': 2.0,
      'fazer': 2.0,
      'faz': 2.0,
      'fazem': 2.0,
      'posso': 2.0,
      'pode': 2.0,
      'podem': 2.0,
      'quero': 2.0,
      'quer': 2.0,
      'querem': 2.0,
      'preciso': 2.0,
      'precisa': 2.0,
      'precisam': 2.0,

      // Portuguese-specific phrases
      'obrigado': 3.0,
      'obrigada': 3.0,
      'por favor': 2.5,
      'de nada': 2.5,
      'tudo bem': 2.5,
      'oi': 2.0,
      'olá': 2.0,
      'tchau': 2.0,
      'até logo': 2.0,
      'bom dia': 2.0,
      'boa tarde': 2.0,
      'boa noite': 2.0,

      // Health and coaching terms in Portuguese
      'saúde': 2.0,
      'hábito': 2.0,
      'hábitos': 2.0,
      'exercício': 2.0,
      'exercícios': 2.0,
      'treino': 2.0,
      'alimentação': 2.0,
      'sono': 2.0,
      'dormir': 2.0,
      'meditar': 2.0,
      'meditação': 2.0,
      'objetivo': 2.0,
      'objetivos': 2.0,
      'meta': 2.0,
      'metas': 2.0,
    };
  }

  /// Get English language indicators with their weights
  ///
  /// Returns a map of English words/phrases to their confidence weights
  static Map<String, double> _getEnglishIndicators() {
    return {
      // Common English words (high confidence)
      'what': 3.0,
      'how': 2.5,
      'with': 2.0,
      'your': 2.0,
      'my': 2.0,
      'the': 2.0,
      'and': 2.0,
      'for': 2.0,
      'you': 2.0,
      'are': 2.0,
      'can': 2.0,
      'will': 2.0,
      'would': 2.0,
      'should': 2.0,
      'could': 2.0,
      'this': 2.0,
      'that': 2.0,
      'these': 2.0,
      'those': 2.0,
      'when': 2.0,
      'where': 2.0,
      'why': 2.0,
      'which': 2.0,
      'who': 2.0,
      'whom': 2.0,
      'whose': 2.0,

      // English verbs
      'is': 2.5,
      'am': 2.0,
      'was': 2.0,
      'were': 2.0,
      'have': 2.0,
      'has': 2.0,
      'had': 2.0,
      'do': 2.0,
      'does': 2.0,
      'did': 2.0,
      'make': 2.0,
      'makes': 2.0,
      'made': 2.0,
      'get': 2.0,
      'gets': 2.0,
      'got': 2.0,
      'want': 2.0,
      'wants': 2.0,
      'wanted': 2.0,
      'need': 2.0,
      'needs': 2.0,
      'needed': 2.0,

      // English greetings and phrases
      'hello': 2.0,
      'hi': 2.0,
      'goodbye': 2.0,
      'bye': 2.0,
      'thank you': 2.5,
      'thanks': 2.0,
      'please': 2.0,
      'sorry': 2.0,
      'excuse me': 2.0,
      'good morning': 2.0,
      'good afternoon': 2.0,
      'good evening': 2.0,
      'good night': 2.0,

      // Health and coaching terms in English
      'health': 2.0,
      'habit': 2.0,
      'habits': 2.0,
      'exercise': 2.0,
      'workout': 2.0,
      'nutrition': 2.0,
      'sleep': 2.0,
      'meditation': 2.0,
      'meditate': 2.0,
      'goal': 2.0,
      'goals': 2.0,
      'objective': 2.0,
      'objectives': 2.0,
    };
  }

  /// Analyze Portuguese-specific character patterns
  ///
  /// [message] The message to analyze
  /// Returns a score indicating Portuguese likelihood
  static double _analyzePortuguesePatterns(String message) {
    double score = 0.0;

    // Portuguese-specific characters
    final portugueseChars = [
      'ã',
      'õ',
      'ç',
      'á',
      'é',
      'í',
      'ó',
      'ú',
      'â',
      'ê',
      'ô',
      'à'
    ];

    for (String char in portugueseChars) {
      if (message.contains(char)) {
        score += 1.0;
      }
    }

    // Portuguese word endings
    final portugueseEndings = ['ção', 'são', 'mente', 'ável', 'ível'];

    for (String ending in portugueseEndings) {
      if (message.contains(ending)) {
        score += 0.5;
      }
    }

    return score;
  }

  /// Analyze English-specific character patterns
  ///
  /// [message] The message to analyze
  /// Returns a score indicating English likelihood
  static double _analyzeEnglishPatterns(String message) {
    double score = 0.0;

    // English word endings
    final englishEndings = [
      'ing',
      'tion',
      'ness',
      'ment',
      'able',
      'ible',
      'ful',
      'less'
    ];

    for (String ending in englishEndings) {
      if (message.contains(ending)) {
        score += 0.5;
      }
    }

    // English contractions
    final englishContractions = ["'t", "'s", "'re", "'ve", "'ll", "'d"];

    for (String contraction in englishContractions) {
      if (message.contains(contraction)) {
        score += 0.5;
      }
    }

    return score;
  }

  /// Select the most likely language based on scores
  ///
  /// [languageScores] Map of language codes to confidence scores
  /// Returns the selected language code
  static String _selectLanguage(Map<String, double> languageScores) {
    if (languageScores.isEmpty) {
      return _defaultLanguage;
    }

    // Find the language with the highest score
    String bestLanguage = _defaultLanguage;
    double bestScore = 0.0;

    languageScores.forEach((language, score) {
      if (score > bestScore) {
        bestScore = score;
        bestLanguage = language;
      }
    });

    // If confidence is too low, use default
    if (bestScore < _confidenceThreshold) {
      _logger.debug(
          'Language Detection - Confidence too low ($bestScore < $_confidenceThreshold), using default');
      return _defaultLanguage;
    }

    return bestLanguage;
  }

  /// Get language detection confidence for a given set of messages
  ///
  /// [recentMessages] List of recent user messages
  /// Returns confidence score (0.0 to 1.0)
  static double getDetectionConfidence(List<String> recentMessages) {
    if (recentMessages.isEmpty) {
      return 0.0;
    }

    final languageScores = _calculateLanguageScores(recentMessages);

    if (languageScores.isEmpty) {
      return 0.0;
    }

    // Return the highest confidence score
    return languageScores.values.reduce((a, b) => a > b ? a : b);
  }

  /// Check if language detection is confident enough
  ///
  /// [recentMessages] List of recent user messages
  /// Returns true if detection confidence is above threshold
  static bool isDetectionConfident(List<String> recentMessages) {
    return getDetectionConfidence(recentMessages) >= _confidenceThreshold;
  }

  /// Get detailed language analysis for debugging
  ///
  /// [recentMessages] List of recent user messages
  /// Returns detailed analysis including scores and confidence
  static Map<String, dynamic> getDetailedAnalysis(List<String> recentMessages) {
    final languageScores = _calculateLanguageScores(recentMessages);
    final detectedLanguage = _selectLanguage(languageScores);
    final confidence = getDetectionConfidence(recentMessages);

    return {
      'detectedLanguage': detectedLanguage,
      'confidence': confidence,
      'languageScores': languageScores,
      'messagesAnalyzed': recentMessages.length,
      'isConfident': confidence >= _confidenceThreshold,
      'threshold': _confidenceThreshold,
    };
  }
}
