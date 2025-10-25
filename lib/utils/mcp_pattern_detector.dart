import '../utils/logger.dart';

/// FT-206: MCP Pattern Detector
///
/// Detects natural language patterns that should trigger MCP command generation.
/// Uses generic patterns aligned with Oracle framework principles:
/// - Temporal (time-based queries)
/// - Frequency (how often)
/// - Intensity (how much)
/// - Progress (improvement, trends)
/// - Context (conversation history, persona switching)
///
/// Avoids hard-coding specific activity names to remain future-proof and
/// maintainable as Oracle framework evolves.
class MCPPatternDetector {
  static final Logger _logger = Logger();

  /// Detect patterns and return appropriate MCP command hint
  ///
  /// Returns null if no pattern is detected.
  /// Returns a system hint string to inject into the user message if a pattern is detected.
  static String? detectPattern(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    _logger.debug('FT-206: Analyzing message for patterns: "$userMessage"');

    // Category 1: Temporal Activity Queries
    if (_detectTemporalActivityQuery(lowerMessage)) {
      final days = _extractDays(lowerMessage);
      final hint =
          '[SYSTEM HINT: Temporal activity query detected. Use: {"action": "get_activity_stats", "days": $days}]';
      _logger.info('FT-206: Temporal pattern detected (days: $days)');
      return hint;
    }

    // Category 2: Quantitative Queries
    if (_detectQuantitativeQuery(lowerMessage)) {
      final days = _extractDays(lowerMessage);
      final hint =
          '[SYSTEM HINT: Quantitative query detected. Use: {"action": "get_activity_stats", "days": $days}]';
      _logger.info('FT-206: Quantitative pattern detected (days: $days)');
      return hint;
    }

    // Category 3: Progress & Trend Queries
    if (_detectProgressQuery(lowerMessage)) {
      final hint =
          '[SYSTEM HINT: Progress query detected. Use: {"action": "get_activity_stats", "days": 30}]';
      _logger.info('FT-206: Progress pattern detected');
      return hint;
    }

    // Category 4: Conversation Context Queries
    if (_detectConversationContextQuery(lowerMessage)) {
      if (_detectSearchQuery(lowerMessage)) {
        final keyword = _extractKeyword(lowerMessage);
        final hint =
            '[SYSTEM HINT: Conversation search query detected. Use: {"action": "search_conversation_context", "query": "$keyword"}]';
        _logger.info('FT-206: Conversation search pattern detected');
        return hint;
      }
      final hint =
          '[SYSTEM HINT: Conversation history query detected. Use: {"action": "get_conversation_context", "hours": 168}]';
      _logger.info('FT-206: Conversation history pattern detected');
      return hint;
    }

    // Category 5: Persona Switching Context
    if (_detectPersonaSwitchQuery(lowerMessage)) {
      final hint =
          '[SYSTEM HINT: Persona context query detected. Use: {"action": "get_interleaved_conversation", "limit": 20}]';
      _logger.info('FT-206: Persona switching pattern detected');
      return hint;
    }

    // Category 6: Goal & Objective Queries
    if (_detectGoalQuery(lowerMessage)) {
      final hint =
          '[SYSTEM HINT: Goal query detected. Use: {"action": "get_activity_stats", "days": 30} and {"action": "search_conversation_context", "query": "meta objetivo"}]';
      _logger.info('FT-206: Goal pattern detected');
      return hint;
    }

    // Category 7: Repetition Prevention
    if (_detectRepetitionQuery(lowerMessage)) {
      final hint =
          '[SYSTEM HINT: Repetition check requested. Use: {"action": "get_current_persona_messages", "limit": 10}]';
      _logger.info('FT-206: Repetition pattern detected');
      return hint;
    }

    _logger.debug('FT-206: No pattern detected');
    return null; // No pattern detected
  }

  /// Category 1: Detect temporal activity queries
  ///
  /// Focuses on time-based references (universal, Oracle-aligned)
  static bool _detectTemporalActivityQuery(String message) {
    final patterns = [
      // Time period references (GENERIC)
      RegExp(r'últim[oa]s?\s+\d+\s+dias?'), // "últimos 7 dias"
      RegExp(r'última\s+semana'), // "última semana"
      RegExp(r'último\s+mês'), // "último mês"
      RegExp(r'últimas?\s+\d+\s+semanas?'), // "últimas 2 semanas"
      RegExp(r'este\s+mês'), // "este mês"
      RegExp(r'essa\s+semana'), // "essa semana"
      RegExp(r'hoje'), // "hoje"
      RegExp(r'ontem'), // "ontem"
      RegExp(r'anteontem'), // "anteontem"

      // Summary requests with temporal context (GENERIC)
      RegExp(r'resumo.*\d+\s+dias?'), // "resumo dos últimos 7 dias"
      RegExp(r'resumo.*semana'), // "resumo da semana"
      RegExp(r'resumo.*mês'), // "resumo do mês"
      RegExp(r'resumo.*hoje'), // "resumo de hoje"

      // English patterns
      RegExp(r'last\s+\d+\s+days?'), // "last 7 days"
      RegExp(r'last\s+week'), // "last week"
      RegExp(r'last\s+month'), // "last month"
      RegExp(r'this\s+week'), // "this week"
      RegExp(r'this\s+month'), // "this month"
      RegExp(r'today'), // "today"
      RegExp(r'yesterday'), // "yesterday"
      RegExp(r'summary.*\d+\s+days?'), // "summary of last 7 days"
      RegExp(r'summary.*week'), // "summary of the week"
    ];

    return patterns.any((pattern) => pattern.hasMatch(message));
  }

  /// Category 2: Detect quantitative queries
  ///
  /// Focuses on frequency and intensity patterns (universal, Oracle-aligned)
  static bool _detectQuantitativeQuery(String message) {
    final patterns = [
      // Frequency patterns (GENERIC)
      RegExp(r'quantas?\s+vezes'), // "quantas vezes"
      RegExp(r'quantas?\s+atividades?'), // "quantas atividades"
      RegExp(r'quantos?\s+'), // "quantos X"
      RegExp(r'com\s+que\s+frequência'), // "com que frequência"

      // General activity queries (GENERIC)
      RegExp(r'o\s+que\s+(eu\s+)?fiz'), // "o que eu fiz", "o que fiz"
      RegExp(r'quais?\s+atividades?'), // "quais atividades"
      RegExp(r'minhas?\s+atividades?'), // "minhas atividades"

      // English patterns
      RegExp(r'how\s+many\s+(times|activities)'), // "how many times"
      RegExp(r'what\s+did\s+i\s+do'), // "what did I do"
      RegExp(r'my\s+activities'), // "my activities"
    ];

    return patterns.any((pattern) => pattern.hasMatch(message));
  }

  /// Category 3: Detect progress and trend queries
  ///
  /// Focuses on improvement and comparison patterns (universal, Oracle-aligned)
  static bool _detectProgressQuery(String message) {
    final patterns = [
      // Progress patterns (GENERIC)
      RegExp(r'meu\s+progresso'), // "meu progresso"
      RegExp(
          r'como\s+(foi|está)\s+(meu|o)\s+progresso'), // "como foi meu progresso"
      RegExp(
          r'como\s+(foi|está)\s+(minha|a)\s+(semana|dia)'), // "como foi minha semana"

      // Comparison patterns (GENERIC)
      RegExp(r'compar[ao]'), // "comparar", "comparado"
      RegExp(r'(melhor|pior)\s+que'), // "melhor que", "pior que"
      RegExp(r'diferença'), // "diferença"
      RegExp(r'evolução'), // "evolução"
      RegExp(r'tendência'), // "tendência"

      // Improvement patterns (GENERIC)
      RegExp(r'(melhorei|piorei)'), // "melhorei", "piorei"
      RegExp(r'(aumentei|diminuí)'), // "aumentei", "diminuí"

      // English patterns
      RegExp(r'my\s+progress'), // "my progress"
      RegExp(r'how\s+(is|was)\s+my\s+progress'), // "how is my progress"
      RegExp(r'compar[ed]\s+(to|with)'), // "compared to"
      RegExp(r'(better|worse)\s+than'), // "better than"
      RegExp(r'trend'), // "trend"
      RegExp(r'evolution'), // "evolution"
    ];

    return patterns.any((pattern) => pattern.hasMatch(message));
  }

  /// Category 4: Detect conversation context queries
  ///
  /// Focuses on conversation recall patterns (universal)
  static bool _detectConversationContextQuery(String message) {
    final patterns = [
      // Recall patterns (GENERIC)
      RegExp(
          r'o\s+que\s+(a gente|nós)\s+(falou|conversou|discutiu)'), // "o que a gente falou"
      RegExp(r'lembra\s+(quando|que|da\s+vez)'), // "lembra quando"
      RegExp(r'você\s+(disse|falou|mencionou)'), // "você disse"
      RegExp(r'eu\s+(disse|falei|mencionei)'), // "eu disse"
      RegExp(r'nossa\s+(conversa|discussão)'), // "nossa conversa"
      RegExp(r'conversamos\s+sobre'), // "conversamos sobre"
      RegExp(r'falamos\s+sobre'), // "falamos sobre"

      // Search patterns (GENERIC)
      RegExp(r'busca.*conversa'), // "busca na conversa"
      RegExp(r'procura.*mensagem'), // "procura mensagem"

      // English patterns
      RegExp(
          r'what\s+did\s+(we|you|i)\s+(talk|discuss|say)'), // "what did we talk about"
      RegExp(r'remember\s+when'), // "remember when"
      RegExp(r'you\s+(said|mentioned|told)'), // "you said"
      RegExp(r'our\s+conversation'), // "our conversation"
      RegExp(r'search.*conversation'), // "search conversation"
    ];

    return patterns.any((pattern) => pattern.hasMatch(message));
  }

  /// Detect search queries (for conversation context)
  static bool _detectSearchQuery(String message) {
    return message.contains('busca') ||
        message.contains('procura') ||
        message.contains('search') ||
        message.contains('sobre') ||
        message.contains('about');
  }

  /// Category 5: Detect persona switching context queries
  ///
  /// Focuses on multi-persona awareness patterns (universal)
  static bool _detectPersonaSwitchQuery(String message) {
    final patterns = [
      // Persona mentions (GENERIC - uses @ pattern)
      RegExp(r'@\w+'), // "@ari", "@tony", etc.
      RegExp(r'(conversei|falei)\s+com'), // "conversei com"
      RegExp(r'o\s+que\s+\w+\s+(disse|falou)'), // "o que X disse"

      // Context handoff (GENERIC)
      RegExp(r'olhe\s+(as\s+)?conversas?'), // "olhe as conversas"
      RegExp(r've\s+(as\s+)?mensagens'), // "vê as mensagens"
      RegExp(
          r'contexto\s+das?\s+outras?\s+conversas?'), // "contexto das outras conversas"

      // English patterns
      RegExp(r'(talked|spoke)\s+with'), // "talked with"
      RegExp(r'what\s+did\s+\w+\s+say'), // "what did X say"
      RegExp(r'check\s+(the\s+)?conversations?'), // "check the conversations"
    ];

    return patterns.any((pattern) => pattern.hasMatch(message));
  }

  /// Category 6: Detect goal and objective queries
  ///
  /// Focuses on goal-related patterns (universal)
  static bool _detectGoalQuery(String message) {
    final patterns = [
      // Goal references (GENERIC)
      RegExp(r'(meta|objetivo|alvo)'), // "meta", "objetivo"
      RegExp(r'(alcancei|atingi|completei)\s+(meta|objetivo)'), // "alcancei meta"
      RegExp(r'quanto\s+falta'), // "quanto falta"
      RegExp(r'(estou\s+perto|próximo)\s+de'), // "estou perto de"

      // Progress toward goals (GENERIC)
      RegExp(
          r'progresso\s+(da|do)\s+(meta|objetivo)'), // "progresso da meta"
      RegExp(r'(consegui|vou\s+conseguir)'), // "consegui"
      RegExp(r'no\s+caminho\s+certo'), // "no caminho certo"

      // English patterns
      RegExp(r'(goal|target|objective)'), // "goal", "target"
      RegExp(r'(reached|achieved|completed)\s+(goal|target)'), // "reached goal"
      RegExp(r'how\s+(close|far)'), // "how close"
      RegExp(r'progress\s+toward'), // "progress toward"
      RegExp(r'on\s+track'), // "on track"
    ];

    return patterns.any((pattern) => pattern.hasMatch(message));
  }

  /// Category 7: Detect repetition prevention queries
  ///
  /// Focuses on repetition detection patterns (universal)
  static bool _detectRepetitionQuery(String message) {
    final patterns = [
      // Repetition indicators (GENERIC)
      RegExp(r'(já|você\s+já)\s+(disse|falou|mencionou)'), // "já disse"
      RegExp(r'repetindo'), // "repetindo"
      RegExp(r'de\s+novo'), // "de novo"
      RegExp(r'outra\s+vez'), // "outra vez"
      RegExp(r'mesma\s+coisa'), // "mesma coisa"

      // English patterns
      RegExp(r'(already|you\s+already)\s+(said|mentioned)'), // "already said"
      RegExp(r'repeating'), // "repeating"
      RegExp(r'again'), // "again"
      RegExp(r'same\s+thing'), // "same thing"
    ];

    return patterns.any((pattern) => pattern.hasMatch(message));
  }

  /// Extract number of days from temporal reference
  ///
  /// Returns appropriate number of days based on temporal context.
  /// Defaults to 7 days if no specific period is found.
  static int _extractDays(String message) {
    // "últimos 7 dias" → 7
    final daysMatch = RegExp(r'(\d+)\s+dias?').firstMatch(message);
    if (daysMatch != null) {
      return int.parse(daysMatch.group(1)!);
    }

    // "últimas 2 semanas" → 14
    final weeksMatch = RegExp(r'(\d+)\s+semanas?').firstMatch(message);
    if (weeksMatch != null) {
      return int.parse(weeksMatch.group(1)!) * 7;
    }

    // "última semana" or "last week" → 7
    if (message.contains('semana') || message.contains('week')) {
      return 7;
    }

    // "último mês" or "last month" → 30
    if (message.contains('mês') || message.contains('month')) {
      return 30;
    }

    // "hoje" or "today" → 0
    if (message.contains('hoje') || message.contains('today')) {
      return 0;
    }

    // "ontem" or "yesterday" → 1
    if (message.contains('ontem') || message.contains('yesterday')) {
      return 1;
    }

    // "anteontem" → 2
    if (message.contains('anteontem')) {
      return 2;
    }

    // Default: 7 days (last week)
    return 7;
  }

  /// Extract keyword from search query
  ///
  /// Simple extraction - can be improved with more sophisticated parsing.
  static String _extractKeyword(String message) {
    // Try to extract keyword after "sobre" or "about"
    final sobreMatch = RegExp(r'sobre\s+(\w+)').firstMatch(message);
    if (sobreMatch != null) {
      return sobreMatch.group(1)!;
    }

    final aboutMatch = RegExp(r'about\s+(\w+)').firstMatch(message);
    if (aboutMatch != null) {
      return aboutMatch.group(1)!;
    }

    // Default: use "context" as generic keyword
    return 'context';
  }
}

