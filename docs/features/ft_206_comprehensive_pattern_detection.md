# FT-206: Comprehensive Pattern Detection for MCP Commands

**Date**: 2025-10-25  
**Branch**: `fix/ft-206-quick-revert-to-simplicity`  
**Purpose**: Define all natural language patterns that should trigger automatic MCP data fetching

---

## 📋 Overview

This document defines a comprehensive pattern detection system that forces the model to fetch data via MCP commands when specific user query patterns are detected. This ensures deterministic, reliable data fetching for known query types.

---

## 🎯 Available MCP Commands

### **1. get_activity_stats**
- **Purpose**: Fetch activity tracking data from database
- **Usage**: `{"action": "get_activity_stats", "days": N}`
- **Returns**: Activities completed in the last N days

### **2. get_conversation_context**
- **Purpose**: Get detailed conversation history with temporal context
- **Usage**: `{"action": "get_conversation_context", "hours": N}`
- **Returns**: Messages from the last N hours with time context

### **3. get_recent_user_messages**
- **Purpose**: Get recent user messages for conversation continuity
- **Usage**: `{"action": "get_recent_user_messages", "limit": N}`
- **Returns**: Last N user messages

### **4. get_current_persona_messages**
- **Purpose**: Get recent messages from current persona
- **Usage**: `{"action": "get_current_persona_messages", "limit": N}`
- **Returns**: Last N messages from current persona

### **5. get_interleaved_conversation**
- **Purpose**: Get recent conversation as interleaved thread (all personas + user)
- **Usage**: `{"action": "get_interleaved_conversation", "limit": N}`
- **Returns**: Last N messages from all participants

### **6. search_conversation_context**
- **Purpose**: Search conversation history by keyword or topic
- **Usage**: `{"action": "search_conversation_context", "query": "keyword"}`
- **Returns**: Messages matching the search query

### **7. get_message_stats**
- **Purpose**: Get chat message statistics from database
- **Usage**: `{"action": "get_message_stats", "limit": N}`
- **Returns**: Message count, frequency, patterns

### **8. get_current_time**
- **Purpose**: Get current temporal information
- **Usage**: `{"action": "get_current_time"}`
- **Returns**: Current date, time, day of week

---

## 🔍 Pattern Detection Categories

### **Category 1: Temporal Activity Queries**
**Trigger**: `get_activity_stats`

#### **Portuguese Patterns**:
```dart
// Time period references
RegExp(r'últim[oa]s?\s+\d+\s+dias?'),           // "últimos 7 dias", "última 3 dias"
RegExp(r'última\s+semana'),                      // "última semana"
RegExp(r'último\s+mês'),                         // "último mês"
RegExp(r'últimas?\s+\d+\s+semanas?'),           // "últimas 2 semanas"
RegExp(r'este\s+mês'),                           // "este mês"
RegExp(r'essa\s+semana'),                        // "essa semana"
RegExp(r'hoje'),                                 // "hoje"
RegExp(r'ontem'),                                // "ontem"
RegExp(r'anteontem'),                            // "anteontem"

// Summary requests with temporal context
RegExp(r'resumo.*\d+\s+dias?'),                  // "resumo dos últimos 7 dias"
RegExp(r'resumo.*semana'),                       // "resumo da semana"
RegExp(r'resumo.*mês'),                          // "resumo do mês"
RegExp(r'resumo.*hoje'),                         // "resumo de hoje"

// Activity-specific queries
RegExp(r'quantas?\s+(atividades?|pomodoros?|exercícios?)'), // "quantas atividades"
RegExp(r'o\s+que\s+(eu\s+)?fiz'),               // "o que eu fiz", "o que fiz"
RegExp(r'quais?\s+atividades?'),                 // "quais atividades"
RegExp(r'minhas?\s+atividades?'),                // "minhas atividades"
RegExp(r'meu\s+progresso'),                      // "meu progresso"
RegExp(r'como\s+(foi|está)\s+(meu|o)\s+progresso'), // "como foi meu progresso"

// Progress and tracking queries
RegExp(r'como\s+(foi|está)\s+(minha|a)\s+(semana|dia)'), // "como foi minha semana"
RegExp(r'(bebi|tomei|consumi).*água'),          // "bebi água", "quantos ml de água"
RegExp(r'(fiz|completei).*pomodoro'),           // "fiz pomodoros"
RegExp(r'(fiz|pratiquei).*exercício'),          // "fiz exercício"
RegExp(r'(meditei|meditar)'),                    // "meditei", "meditar"
RegExp(r'(dormi|sono)'),                         // "dormi", "como foi meu sono"
```

#### **English Patterns**:
```dart
RegExp(r'last\s+\d+\s+days?'),                   // "last 7 days"
RegExp(r'last\s+week'),                          // "last week"
RegExp(r'last\s+month'),                         // "last month"
RegExp(r'this\s+week'),                          // "this week"
RegExp(r'this\s+month'),                         // "this month"
RegExp(r'today'),                                // "today"
RegExp(r'yesterday'),                            // "yesterday"
RegExp(r'summary.*\d+\s+days?'),                 // "summary of last 7 days"
RegExp(r'summary.*week'),                        // "summary of the week"
RegExp(r'what\s+did\s+i\s+do'),                 // "what did I do"
RegExp(r'my\s+progress'),                        // "my progress"
RegExp(r'how\s+many\s+(activities|pomodoros)'), // "how many activities"
```

#### **Examples**:
- ✅ "Me da um resumo dos últimos 7 dias"
- ✅ "O que eu fiz essa semana?"
- ✅ "Quantos pomodoros fiz hoje?"
- ✅ "Como foi meu progresso no último mês?"
- ✅ "Quais atividades completei ontem?"
- ✅ "Bebi água suficiente essa semana?"
- ✅ "Meu progresso de exercícios nos últimos 30 dias"

---

### **Category 2: Conversation History Queries**
**Trigger**: `get_conversation_context` or `search_conversation_context`

#### **Portuguese Patterns**:
```dart
// Conversation recall
RegExp(r'o\s+que\s+(a gente|nós)\s+(falou|conversou|discutiu)'), // "o que a gente falou"
RegExp(r'lembra\s+(quando|que|da\s+vez)'),      // "lembra quando", "lembra da vez"
RegExp(r'você\s+(disse|falou|mencionou)'),      // "você disse", "você falou"
RegExp(r'eu\s+(disse|falei|mencionei)'),        // "eu disse", "eu falei"
RegExp(r'nossa\s+(conversa|discussão)'),        // "nossa conversa"
RegExp(r'conversamos\s+sobre'),                  // "conversamos sobre"
RegExp(r'falamos\s+sobre'),                      // "falamos sobre"

// Topic search
RegExp(r'quando\s+(eu\s+)?(falei|mencionei)\s+sobre'), // "quando falei sobre"
RegExp(r'busca.*conversa'),                      // "busca na conversa"
RegExp(r'procura.*mensagem'),                    // "procura mensagem"

// Context requests
RegExp(r'contexto\s+(da|dessa)\s+conversa'),    // "contexto da conversa"
RegExp(r'histórico\s+(da|dessa)\s+conversa'),   // "histórico da conversa"
RegExp(r'mensagens\s+anteriores'),               // "mensagens anteriores"
```

#### **English Patterns**:
```dart
RegExp(r'what\s+did\s+(we|you|i)\s+(talk|discuss|say)'), // "what did we talk about"
RegExp(r'remember\s+when'),                      // "remember when"
RegExp(r'you\s+(said|mentioned|told)'),         // "you said", "you mentioned"
RegExp(r'i\s+(said|mentioned|told)'),           // "I said", "I mentioned"
RegExp(r'our\s+conversation'),                   // "our conversation"
RegExp(r'we\s+(talked|discussed)\s+about'),     // "we talked about"
RegExp(r'search.*conversation'),                 // "search conversation"
RegExp(r'previous\s+messages'),                  // "previous messages"
```

#### **Examples**:
- ✅ "O que a gente falou sobre exercícios?"
- ✅ "Lembra quando eu mencionei meu objetivo?"
- ✅ "Você disse algo sobre dormir cedo"
- ✅ "Busca na conversa sobre meditação"
- ✅ "Qual foi nossa última discussão sobre trabalho?"
- ✅ "Quando eu falei sobre ansiedade?"

---

### **Category 3: Specific Activity Type Queries**
**Trigger**: `get_activity_stats` with specific dimension filter

#### **Activity Dimensions**:
- **SF** - Saúde Física (Physical Health)
- **TG** - Trabalho Gratificante (Meaningful Work)
- **SM** - Saúde Mental (Mental Health)
- **E** - Espiritualidade (Spirituality)
- **R** - Relacionamentos (Relationships)

#### **Portuguese Patterns by Dimension**:

**Saúde Física (SF)**:
```dart
RegExp(r'(água|hidratação)'),                    // "água", "hidratação"
RegExp(r'(exercício|treino|academia|corrida|caminhada)'), // exercise types
RegExp(r'(sono|dormi|dormir)'),                  // "sono", "dormi"
RegExp(r'(alimentação|comida|refeição)'),       // "alimentação", "comida"
RegExp(r'(peso|emagrecer|perder\s+peso)'),      // "peso", "emagrecer"
```

**Trabalho Gratificante (TG)**:
```dart
RegExp(r'(pomodoro|trabalho\s+focado|foco)'),   // "pomodoro", "trabalho focado"
RegExp(r'(produtividade|produtivo)'),            // "produtividade"
RegExp(r'(planejamento|planejar)'),              // "planejamento"
RegExp(r'(aprendizado|estudar|curso)'),          // "aprendizado", "estudar"
```

**Saúde Mental (SM)**:
```dart
RegExp(r'(meditação|meditar|mindfulness)'),     // "meditação", "meditar"
RegExp(r'(ansiedade|estresse|stress)'),          // "ansiedade", "estresse"
RegExp(r'(leitura|ler|livro)'),                  // "leitura", "ler"
RegExp(r'(journaling|diário)'),                  // "journaling", "diário"
```

**Espiritualidade (E)**:
```dart
RegExp(r'(oração|rezar|reza)'),                  // "oração", "rezar"
RegExp(r'(gratidão|agradecer)'),                 // "gratidão", "agradecer"
RegExp(r'(igreja|celebração\s+religiosa)'),     // "igreja", "celebração"
```

**Relacionamentos (R)**:
```dart
RegExp(r'(família|familiar)'),                   // "família"
RegExp(r'(amigos|amizade)'),                     // "amigos"
RegExp(r'(relacionamento|parceiro|esposo)'),     // "relacionamento"
```

#### **Examples**:
- ✅ "Quantos pomodoros fiz essa semana?"
- ✅ "Bebi água suficiente nos últimos 3 dias?"
- ✅ "Meditei quantas vezes esse mês?"
- ✅ "Meu progresso de exercícios"
- ✅ "Como está minha leitura?"

---

### **Category 4: Comparison and Trend Queries**
**Trigger**: `get_activity_stats` with extended time range

#### **Portuguese Patterns**:
```dart
// Comparison patterns
RegExp(r'compar[ao].*semana'),                   // "comparar com semana passada"
RegExp(r'(melhor|pior)\s+que'),                  // "melhor que", "pior que"
RegExp(r'diferença\s+(entre|de)'),               // "diferença entre"
RegExp(r'evolução'),                             // "evolução"
RegExp(r'tendência'),                            // "tendência"
RegExp(r'padrão'),                               // "padrão"

// Trend patterns
RegExp(r'como\s+(está|anda)\s+(meu|o)'),        // "como está meu"
RegExp(r'(melhorei|piorei)'),                    // "melhorei", "piorei"
RegExp(r'(aumentei|diminuí)'),                   // "aumentei", "diminuí"
RegExp(r'(mais|menos)\s+que\s+(antes|ontem|semana)'), // "mais que antes"
```

#### **English Patterns**:
```dart
RegExp(r'compar[ed]\s+(to|with)'),              // "compared to", "compared with"
RegExp(r'(better|worse)\s+than'),                // "better than", "worse than"
RegExp(r'difference\s+between'),                 // "difference between"
RegExp(r'trend'),                                // "trend"
RegExp(r'pattern'),                              // "pattern"
RegExp(r'how\s+(is|are)\s+my'),                 // "how is my", "how are my"
RegExp(r'(improved|declined)'),                  // "improved", "declined"
```

#### **Examples**:
- ✅ "Melhorei em relação à semana passada?"
- ✅ "Comparar meu progresso com o mês passado"
- ✅ "Qual a tendência dos meus exercícios?"
- ✅ "Estou fazendo mais pomodoros que antes?"
- ✅ "Minha evolução nos últimos 30 dias"

---

### **Category 5: Goal and Objective Queries**
**Trigger**: `get_activity_stats` + `search_conversation_context`

#### **Portuguese Patterns**:
```dart
// Goal references
RegExp(r'(meta|objetivo|alvo)'),                 // "meta", "objetivo"
RegExp(r'(alcancei|atingi|completei)\s+(meta|objetivo)'), // "alcancei meta"
RegExp(r'(falta|faltam)\s+para'),               // "falta para", "faltam para"
RegExp(r'(estou\s+perto|próximo)\s+de'),        // "estou perto de"
RegExp(r'quanto\s+falta'),                       // "quanto falta"

// Progress toward goals
RegExp(r'progresso\s+(da|do)\s+(meta|objetivo)'), // "progresso da meta"
RegExp(r'(consegui|vou\s+conseguir)'),          // "consegui", "vou conseguir"
RegExp(r'no\s+caminho\s+certo'),                // "no caminho certo"
```

#### **English Patterns**:
```dart
RegExp(r'(goal|target|objective)'),              // "goal", "target"
RegExp(r'(reached|achieved|completed)\s+(goal|target)'), // "reached goal"
RegExp(r'how\s+(close|far)'),                    // "how close", "how far"
RegExp(r'progress\s+toward'),                    // "progress toward"
RegExp(r'on\s+track'),                           // "on track"
```

#### **Examples**:
- ✅ "Estou perto de alcançar minha meta?"
- ✅ "Quanto falta para completar meu objetivo?"
- ✅ "Progresso da meta de exercícios"
- ✅ "Consegui bater minha meta essa semana?"
- ✅ "Estou no caminho certo?"

---

### **Category 6: Persona Switching Context**
**Trigger**: `get_interleaved_conversation` + `get_current_persona_messages`

#### **Portuguese Patterns**:
```dart
// Persona mentions
RegExp(r'@(ari|tony|aristios|ithere|sergeant|ryo)'), // "@ari", "@tony"
RegExp(r'(conversei|falei)\s+com\s+(ari|tony|aristios)'), // "conversei com ari"
RegExp(r'o\s+que\s+(ari|tony|aristios)\s+(disse|falou)'), // "o que ari disse"
RegExp(r'(ari|tony|aristios)\s+(mencionou|sugeriu)'), // "tony mencionou"

// Context handoff
RegExp(r'olhe\s+(as\s+)?conversas?'),           // "olhe as conversas"
RegExp(r've\s+(as\s+)?mensagens'),              // "vê as mensagens"
RegExp(r'contexto\s+das?\s+outras?\s+conversas?'), // "contexto das outras conversas"
```

#### **English Patterns**:
```dart
RegExp(r'@(ari|tony|aristios|ithere|sergeant|ryo)'), // "@ari", "@tony"
RegExp(r'(talked|spoke)\s+with\s+(ari|tony)'),  // "talked with ari"
RegExp(r'what\s+did\s+(ari|tony)\s+say'),       // "what did ari say"
RegExp(r'check\s+(the\s+)?conversations?'),     // "check the conversations"
```

#### **Examples**:
- ✅ "@aristios o dia hoje foi uma saga. olhe as conversas"
- ✅ "O que o Tony disse sobre exercícios?"
- ✅ "Conversei com Ari sobre ansiedade"
- ✅ "Vê as mensagens anteriores"
- ✅ "Contexto das outras conversas"

---

### **Category 7: Repetition Prevention**
**Trigger**: `get_current_persona_messages`

#### **Portuguese Patterns**:
```dart
// Repetition indicators
RegExp(r'(já|você\s+já)\s+(disse|falou|mencionou)'), // "já disse", "você já falou"
RegExp(r'repetindo'),                            // "repetindo"
RegExp(r'de\s+novo'),                            // "de novo"
RegExp(r'outra\s+vez'),                          // "outra vez"
RegExp(r'mesma\s+coisa'),                        // "mesma coisa"
```

#### **English Patterns**:
```dart
RegExp(r'(already|you\s+already)\s+(said|mentioned)'), // "already said"
RegExp(r'repeating'),                            // "repeating"
RegExp(r'again'),                                // "again"
RegExp(r'same\s+thing'),                         // "same thing"
```

#### **Examples**:
- ✅ "Você já disse isso"
- ✅ "Está repetindo"
- ✅ "Mesma coisa de novo"

---

## 💻 Implementation Strategy

### **Phase 1: Core Pattern Detection Method**

```dart
/// FT-206: Comprehensive pattern detection for MCP command generation
class MCPPatternDetector {
  /// Detect patterns and return appropriate MCP command hint
  static String? detectPattern(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    // Category 1: Temporal Activity Queries
    if (_detectTemporalActivityQuery(lowerMessage)) {
      final days = _extractDays(lowerMessage);
      return '[SYSTEM HINT: Temporal activity query detected. Use: {"action": "get_activity_stats", "days": $days}]';
    }
    
    // Category 2: Conversation History Queries
    if (_detectConversationHistoryQuery(lowerMessage)) {
      if (_detectSearchQuery(lowerMessage)) {
        final keyword = _extractKeyword(lowerMessage);
        return '[SYSTEM HINT: Conversation search query detected. Use: {"action": "search_conversation_context", "query": "$keyword"}]';
      }
      return '[SYSTEM HINT: Conversation history query detected. Use: {"action": "get_conversation_context", "hours": 168}]';
    }
    
    // Category 3: Specific Activity Type Queries
    if (_detectSpecificActivityQuery(lowerMessage)) {
      final days = _extractDays(lowerMessage);
      return '[SYSTEM HINT: Specific activity query detected. Use: {"action": "get_activity_stats", "days": $days}]';
    }
    
    // Category 4: Comparison and Trend Queries
    if (_detectComparisonQuery(lowerMessage)) {
      return '[SYSTEM HINT: Comparison query detected. Use: {"action": "get_activity_stats", "days": 30}]';
    }
    
    // Category 5: Goal and Objective Queries
    if (_detectGoalQuery(lowerMessage)) {
      return '[SYSTEM HINT: Goal query detected. Use: {"action": "get_activity_stats", "days": 30} and {"action": "search_conversation_context", "query": "meta objetivo"}]';
    }
    
    // Category 6: Persona Switching Context
    if (_detectPersonaSwitchQuery(lowerMessage)) {
      return '[SYSTEM HINT: Persona context query detected. Use: {"action": "get_interleaved_conversation", "limit": 20}]';
    }
    
    // Category 7: Repetition Prevention
    if (_detectRepetitionQuery(lowerMessage)) {
      return '[SYSTEM HINT: Repetition check requested. Use: {"action": "get_current_persona_messages", "limit": 10}]';
    }
    
    return null; // No pattern detected
  }
  
  /// Extract number of days from temporal reference
  static int _extractDays(String message) {
    // "últimos 7 dias" → 7
    final daysMatch = RegExp(r'(\d+)\s+dias?').firstMatch(message);
    if (daysMatch != null) {
      return int.parse(daysMatch.group(1)!);
    }
    
    // "última semana" → 7
    if (message.contains('semana') || message.contains('week')) {
      return 7;
    }
    
    // "último mês" → 30
    if (message.contains('mês') || message.contains('month')) {
      return 30;
    }
    
    // "hoje" → 0
    if (message.contains('hoje') || message.contains('today')) {
      return 0;
    }
    
    // "ontem" → 1
    if (message.contains('ontem') || message.contains('yesterday')) {
      return 1;
    }
    
    // Default: 7 days
    return 7;
  }
  
  /// Extract keyword from search query
  static String _extractKeyword(String message) {
    // Simple extraction - can be improved
    final searchMatch = RegExp(r'sobre\s+(\w+)').firstMatch(message);
    if (searchMatch != null) {
      return searchMatch.group(1)!;
    }
    return 'context';
  }
  
  /// Detect temporal activity queries
  static bool _detectTemporalActivityQuery(String message) {
    final patterns = [
      RegExp(r'últim[oa]s?\s+\d+\s+dias?'),
      RegExp(r'última\s+semana'),
      RegExp(r'último\s+mês'),
      RegExp(r'resumo.*\d+\s+dias?'),
      RegExp(r'resumo.*semana'),
      RegExp(r'resumo.*mês'),
      RegExp(r'o\s+que\s+(eu\s+)?fiz'),
      RegExp(r'quantas?\s+(atividades?|pomodoros?)'),
      RegExp(r'meu\s+progresso'),
      RegExp(r'last\s+\d+\s+days?'),
      RegExp(r'last\s+week'),
      RegExp(r'summary.*days?'),
      RegExp(r'what\s+did\s+i\s+do'),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(message));
  }
  
  /// Detect conversation history queries
  static bool _detectConversationHistoryQuery(String message) {
    final patterns = [
      RegExp(r'o\s+que\s+(a gente|nós)\s+(falou|conversou)'),
      RegExp(r'lembra\s+(quando|que)'),
      RegExp(r'você\s+(disse|falou|mencionou)'),
      RegExp(r'nossa\s+conversa'),
      RegExp(r'what\s+did\s+(we|you)\s+(talk|say)'),
      RegExp(r'remember\s+when'),
      RegExp(r'our\s+conversation'),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(message));
  }
  
  /// Detect search queries
  static bool _detectSearchQuery(String message) {
    return message.contains('busca') || 
           message.contains('procura') || 
           message.contains('search') ||
           message.contains('sobre') ||
           message.contains('about');
  }
  
  /// Detect specific activity type queries
  static bool _detectSpecificActivityQuery(String message) {
    final activityPatterns = [
      RegExp(r'(água|hidratação)'),
      RegExp(r'(exercício|treino|academia)'),
      RegExp(r'(sono|dormi)'),
      RegExp(r'(pomodoro|trabalho\s+focado)'),
      RegExp(r'(meditação|meditar)'),
      RegExp(r'(leitura|ler)'),
    ];
    
    return activityPatterns.any((pattern) => pattern.hasMatch(message));
  }
  
  /// Detect comparison and trend queries
  static bool _detectComparisonQuery(String message) {
    final patterns = [
      RegExp(r'compar[ao]'),
      RegExp(r'(melhor|pior)\s+que'),
      RegExp(r'evolução'),
      RegExp(r'tendência'),
      RegExp(r'(melhorei|piorei)'),
      RegExp(r'compar[ed]'),
      RegExp(r'(better|worse)\s+than'),
      RegExp(r'trend'),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(message));
  }
  
  /// Detect goal and objective queries
  static bool _detectGoalQuery(String message) {
    final patterns = [
      RegExp(r'(meta|objetivo|alvo)'),
      RegExp(r'(alcancei|atingi)'),
      RegExp(r'quanto\s+falta'),
      RegExp(r'(goal|target|objective)'),
      RegExp(r'(reached|achieved)'),
      RegExp(r'on\s+track'),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(message));
  }
  
  /// Detect persona switching context queries
  static bool _detectPersonaSwitchQuery(String message) {
    final patterns = [
      RegExp(r'@(ari|tony|aristios|ithere|sergeant|ryo)'),
      RegExp(r'(conversei|falei)\s+com'),
      RegExp(r'olhe\s+(as\s+)?conversas?'),
      RegExp(r've\s+(as\s+)?mensagens'),
      RegExp(r'check\s+(the\s+)?conversations?'),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(message));
  }
  
  /// Detect repetition prevention queries
  static bool _detectRepetitionQuery(String message) {
    final patterns = [
      RegExp(r'(já|você\s+já)\s+(disse|falou)'),
      RegExp(r'repetindo'),
      RegExp(r'de\s+novo'),
      RegExp(r'(already|you\s+already)\s+said'),
      RegExp(r'repeating'),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(message));
  }
}
```

### **Phase 2: Integration in ClaudeService**

```dart
/// In _sendMessageInternal() method
Future<String> _sendMessageInternal(String userMessage) async {
  // FT-206: Detect patterns and inject MCP command hints
  final patternHint = MCPPatternDetector.detectPattern(userMessage);
  if (patternHint != null) {
    userMessage = '$userMessage\n\n$patternHint';
    _logger.info('FT-206: Pattern detected, hint injected: $patternHint');
  }
  
  // Continue with normal flow...
}
```

---

## 📊 Expected Impact

### **Before Pattern Detection**:
- ❌ 0-30% success rate on temporal queries (model-dependent)
- ❌ Inconsistent data fetching
- ❌ User frustration with "I don't have that data"

### **After Pattern Detection**:
- ✅ 95-100% success rate on known patterns
- ✅ Deterministic, reliable data fetching
- ✅ Improved user experience and trust

---

## 🧪 Testing Plan

### **Test Cases by Category**:

**Category 1: Temporal Activity Queries**
1. "Me da um resumo dos últimos 7 dias"
2. "O que eu fiz essa semana?"
3. "Quantos pomodoros fiz hoje?"
4. "Meu progresso no último mês"

**Category 2: Conversation History Queries**
1. "O que a gente falou sobre exercícios?"
2. "Lembra quando eu mencionei meu objetivo?"
3. "Busca na conversa sobre meditação"

**Category 3: Specific Activity Type Queries**
1. "Bebi água suficiente essa semana?"
2. "Quantas vezes meditei esse mês?"
3. "Meu progresso de exercícios"

**Category 4: Comparison and Trend Queries**
1. "Melhorei em relação à semana passada?"
2. "Qual a tendência dos meus exercícios?"
3. "Estou fazendo mais pomodoros que antes?"

**Category 5: Goal and Objective Queries**
1. "Estou perto de alcançar minha meta?"
2. "Quanto falta para completar meu objetivo?"
3. "Progresso da meta de exercícios"

**Category 6: Persona Switching Context**
1. "@aristios o dia hoje foi uma saga. olhe as conversas"
2. "O que o Tony disse sobre exercícios?"

**Category 7: Repetition Prevention**
1. "Você já disse isso"
2. "Está repetindo"

---

## 📈 Success Metrics

### **Quantitative**:
- **Pattern Detection Rate**: % of queries correctly identified
- **MCP Command Generation Rate**: % of detected patterns that generate MCP commands
- **Data Fetch Success Rate**: % of MCP commands that return data
- **User Satisfaction**: Reduction in "I don't have that data" responses

### **Qualitative**:
- **User Trust**: Users feel the system "remembers" and "understands"
- **Conversation Flow**: Natural, seamless data integration
- **Persona Intelligence**: Personas appear more aware and helpful

---

## 🔗 Related Features

- **FT-084**: Two-Pass Data Integration (existing)
- **FT-206**: System Prompt Simplification (this fix)
- **FT-220**: Context Logging (debugging tool)
- **FT-064**: Semantic Activity Detection (activity tracking)

---

## 🎯 Implementation Priority

### **Phase 1 (Immediate)**: Core Patterns
- ✅ Category 1: Temporal Activity Queries
- ✅ Category 6: Persona Switching Context

### **Phase 2 (Short-term)**: Extended Patterns
- ✅ Category 2: Conversation History Queries
- ✅ Category 3: Specific Activity Type Queries

### **Phase 3 (Medium-term)**: Advanced Patterns
- ✅ Category 4: Comparison and Trend Queries
- ✅ Category 5: Goal and Objective Queries
- ✅ Category 7: Repetition Prevention

---

## 📝 Notes

- Patterns are case-insensitive
- Patterns support both Portuguese and English
- Patterns can be extended without code changes (add to config file in future)
- Pattern detection is deterministic and testable
- False positives are acceptable (model can ignore hint if not relevant)
- False negatives are critical (must be minimized)

---

**Next Steps**:
1. Implement `MCPPatternDetector` class
2. Integrate in `ClaudeService._sendMessageInternal()`
3. Write unit tests for each pattern category
4. Test with real user queries
5. Monitor success rates via FT-220 context logging
6. Iterate and refine patterns based on data

