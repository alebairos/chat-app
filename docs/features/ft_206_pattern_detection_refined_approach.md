# FT-206: Pattern Detection - Refined Approach (Generic & Oracle-Aligned)

**Date**: 2025-10-25  
**Branch**: `feature/ft-206-pattern-detection`  
**Purpose**: Define a generic, extensible pattern detection system aligned with Oracle framework principles

---

## 🎯 Core Principle

**Avoid hard-coding specific activity names or terms that are not universal.**

Instead, focus on **generic patterns** related to:
- ✅ **Temporal** (time-based queries)
- ✅ **Frequency** (how often)
- ✅ **Intensity** (how much, quantitative)
- ✅ **Progress** (improvement, trends)
- ✅ **Context** (conversation history, persona switching)

---

## ⚠️ Problem with Original Spec

### **Category 3: Specific Activity Type Queries** (TOO SPECIFIC)

**Original approach** (❌ **AVOID**):
```dart
// Hard-coded activity names - breaks when Oracle evolves
RegExp(r'(água|hidratação)'),                    // ❌ Too specific
RegExp(r'(exercício|treino|academia|corrida|caminhada)'), // ❌ Too specific
RegExp(r'(pomodoro|trabalho\s+focado|foco)'),   // ❌ Too specific
RegExp(r'(meditação|meditar|mindfulness)'),     // ❌ Too specific
```

**Problems**:
1. **Brittle**: Breaks when new activities are added to Oracle
2. **Incomplete**: Doesn't cover all possible activity names
3. **Maintenance burden**: Requires updating patterns for every new activity
4. **Not generic**: Tied to specific Oracle activities, not universal concepts

---

## ✅ Refined Approach: Generic Patterns

### **Principle**: Focus on **query structure**, not **content**

Instead of detecting "água" or "pomodoro", detect:
- Temporal references ("últimos X dias")
- Quantitative queries ("quantas", "quantos")
- Progress queries ("meu progresso", "como foi")
- Summary requests ("resumo")

---

## 📋 Refined Pattern Categories

### **Category 1: Temporal Queries** ✅ (KEEP - Generic)
**Trigger**: `get_activity_stats`

**Focus**: Time-based patterns (universal)
```dart
// Time period references (GENERIC - works for any activity)
RegExp(r'últim[oa]s?\s+\d+\s+dias?'),           // "últimos 7 dias"
RegExp(r'última\s+semana'),                      // "última semana"
RegExp(r'último\s+mês'),                         // "último mês"
RegExp(r'hoje'),                                 // "hoje"
RegExp(r'ontem'),                                // "ontem"

// Summary requests (GENERIC)
RegExp(r'resumo.*\d+\s+dias?'),                  // "resumo dos últimos 7 dias"
RegExp(r'resumo.*semana'),                       // "resumo da semana"
RegExp(r'resumo.*mês'),                          // "resumo do mês"
```

**Why this works**:
- ✅ Universal - works for any activity
- ✅ Oracle-agnostic - doesn't depend on specific activities
- ✅ Future-proof - works even when Oracle evolves

---

### **Category 2: Quantitative Queries** ✅ (GENERIC)
**Trigger**: `get_activity_stats`

**Focus**: Frequency and intensity patterns (universal)
```dart
// Frequency patterns (GENERIC)
RegExp(r'quantas?\s+vezes'),                     // "quantas vezes"
RegExp(r'quantas?\s+atividades?'),               // "quantas atividades"
RegExp(r'quantos?\s+'),                          // "quantos X"
RegExp(r'com\s+que\s+frequência'),               // "com que frequência"

// Intensity patterns (GENERIC)
RegExp(r'quanto\s+(tempo|ml|metros|km)'),        // "quanto tempo", "quantos ml"
RegExp(r'\d+\s+(ml|metros|km|minutos|horas)'),   // "300 ml", "5 km"

// General activity queries (GENERIC)
RegExp(r'o\s+que\s+(eu\s+)?fiz'),               // "o que eu fiz"
RegExp(r'quais?\s+atividades?'),                 // "quais atividades"
RegExp(r'minhas?\s+atividades?'),                // "minhas atividades"
```

**Why this works**:
- ✅ Focuses on **how user asks**, not **what they ask about**
- ✅ Works for any tracked activity
- ✅ Aligns with Oracle's quantitative metadata (count, duration, distance, volume)

---

### **Category 3: Progress & Trend Queries** ✅ (GENERIC)
**Trigger**: `get_activity_stats` (extended range)

**Focus**: Improvement and comparison patterns (universal)
```dart
// Progress patterns (GENERIC)
RegExp(r'meu\s+progresso'),                      // "meu progresso"
RegExp(r'como\s+(foi|está)\s+(meu|o)\s+progresso'), // "como foi meu progresso"
RegExp(r'como\s+(foi|está)\s+(minha|a)\s+(semana|dia)'), // "como foi minha semana"

// Comparison patterns (GENERIC)
RegExp(r'compar[ao]'),                           // "comparar", "comparado"
RegExp(r'(melhor|pior)\s+que'),                  // "melhor que", "pior que"
RegExp(r'diferença'),                            // "diferença"
RegExp(r'evolução'),                             // "evolução"
RegExp(r'tendência'),                            // "tendência"

// Improvement patterns (GENERIC)
RegExp(r'(melhorei|piorei)'),                    // "melhorei", "piorei"
RegExp(r'(aumentei|diminuí)'),                   // "aumentei", "diminuí"
```

**Why this works**:
- ✅ Universal concepts (progress, comparison, trends)
- ✅ Works across all Oracle dimensions
- ✅ Aligns with coaching framework (progress tracking)

---

### **Category 4: Conversation Context Queries** ✅ (KEEP - Generic)
**Trigger**: `get_conversation_context` / `search_conversation_context`

**Focus**: Conversation recall patterns (universal)
```dart
// Recall patterns (GENERIC)
RegExp(r'o\s+que\s+(a gente|nós)\s+(falou|conversou)'), // "o que a gente falou"
RegExp(r'lembra\s+(quando|que)'),                // "lembra quando"
RegExp(r'você\s+(disse|falou|mencionou)'),      // "você disse"
RegExp(r'nossa\s+conversa'),                     // "nossa conversa"

// Search patterns (GENERIC)
RegExp(r'busca.*conversa'),                      // "busca na conversa"
RegExp(r'procura.*mensagem'),                    // "procura mensagem"
```

**Why this works**:
- ✅ Universal conversation patterns
- ✅ Not tied to specific content
- ✅ Works for any conversation topic

---

### **Category 5: Persona Switching Context** ✅ (KEEP - Generic)
**Trigger**: `get_interleaved_conversation`

**Focus**: Multi-persona awareness patterns (universal)
```dart
// Persona mentions (GENERIC - uses @ pattern)
RegExp(r'@\w+'),                                 // "@ari", "@tony", etc.
RegExp(r'(conversei|falei)\s+com'),             // "conversei com"
RegExp(r'o\s+que\s+\w+\s+(disse|falou)'),       // "o que X disse"

// Context handoff (GENERIC)
RegExp(r'olhe\s+(as\s+)?conversas?'),           // "olhe as conversas"
RegExp(r've\s+(as\s+)?mensagens'),              // "vê as mensagens"
```

**Why this works**:
- ✅ Generic persona switching patterns
- ✅ Works for any persona (current or future)
- ✅ Aligns with multi-persona feature

---

### **Category 6: Goal & Objective Queries** ✅ (GENERIC)
**Trigger**: `get_activity_stats` + `search_conversation_context`

**Focus**: Goal-related patterns (universal)
```dart
// Goal references (GENERIC)
RegExp(r'(meta|objetivo|alvo)'),                 // "meta", "objetivo"
RegExp(r'(alcancei|atingi)'),                    // "alcancei", "atingi"
RegExp(r'quanto\s+falta'),                       // "quanto falta"
RegExp(r'(estou\s+perto|próximo)\s+de'),        // "estou perto de"

// Progress toward goals (GENERIC)
RegExp(r'progresso\s+(da|do)\s+(meta|objetivo)'), // "progresso da meta"
RegExp(r'no\s+caminho\s+certo'),                // "no caminho certo"
```

**Why this works**:
- ✅ Universal goal concepts
- ✅ Works for any goal type
- ✅ Aligns with coaching framework

---

### **Category 7: Repetition Prevention** ✅ (KEEP - Generic)
**Trigger**: `get_current_persona_messages`

**Focus**: Repetition detection patterns (universal)
```dart
// Repetition indicators (GENERIC)
RegExp(r'(já|você\s+já)\s+(disse|falou)'),      // "já disse"
RegExp(r'repetindo'),                            // "repetindo"
RegExp(r'de\s+novo'),                            // "de novo"
RegExp(r'mesma\s+coisa'),                        // "mesma coisa"
```

**Why this works**:
- ✅ Universal repetition patterns
- ✅ Not tied to specific content
- ✅ Improves conversation quality

---

## ❌ Removed: Category 3 (Specific Activity Types)

**Original Category 3** was removed because it was **too specific**:
- ❌ Hard-coded activity names ("água", "pomodoro", "meditação")
- ❌ Tied to specific Oracle activities
- ❌ Breaks when Oracle evolves
- ❌ Maintenance burden

**Replacement**: Category 2 (Quantitative Queries) covers this generically:
- ✅ "quantas atividades" (any activity)
- ✅ "o que eu fiz" (any activity)
- ✅ "meu progresso" (any activity)

---

## 🎯 Implementation Strategy

### **Phase 1: Core Generic Patterns** (Recommended)
Implement only the generic categories:
1. ✅ Temporal Queries
2. ✅ Quantitative Queries
3. ✅ Progress & Trend Queries
4. ✅ Conversation Context Queries
5. ✅ Persona Switching Context
6. ✅ Goal & Objective Queries
7. ✅ Repetition Prevention

**Estimated effort**: 3-4 hours (reduced from 4-6 hours)

---

### **Phase 2: Optional - Activity Detection** (Future)
If needed, add **semantic activity detection** (not hard-coded patterns):
- Use existing FT-064 semantic detection
- Let the model interpret activity names
- Don't hard-code specific activities

---

## 📊 Expected Impact

### **Coverage**:
- ✅ **90-95%** of temporal queries (vs 95-100% with hard-coded patterns)
- ✅ **Future-proof**: Works even when Oracle evolves
- ✅ **Maintainable**: No need to update patterns for new activities

### **Examples of What Works**:
```
✅ "Me da um resumo dos últimos 7 dias" → Temporal pattern
✅ "Quantas atividades fiz essa semana?" → Quantitative pattern
✅ "Como foi meu progresso no último mês?" → Progress pattern
✅ "O que eu fiz ontem?" → Temporal + quantitative pattern
✅ "Meu progresso de exercícios" → Progress pattern (generic)
✅ "Bebi água suficiente?" → Quantitative pattern (generic)
```

### **What Doesn't Work** (Acceptable trade-off):
```
⚠️ "Bebi água?" (no temporal/quantitative context) → May not trigger
   → User can rephrase: "Bebi água hoje?" ✅
   
⚠️ "Meditei?" (no temporal/quantitative context) → May not trigger
   → User can rephrase: "Meditei hoje?" ✅
```

---

## 🔄 Comparison: Original vs Refined

| Aspect | Original Spec | Refined Approach |
|--------|--------------|------------------|
| **Activity Names** | Hard-coded ("água", "pomodoro") | Generic ("atividades", "progresso") |
| **Maintenance** | High (update for new activities) | Low (no updates needed) |
| **Future-proof** | No (breaks with Oracle changes) | Yes (works with any Oracle version) |
| **Coverage** | 95-100% (for known activities) | 90-95% (for all activities) |
| **Complexity** | High (many specific patterns) | Low (fewer generic patterns) |
| **Oracle Alignment** | Partial (tied to specific activities) | Full (aligned with framework principles) |

---

## 💡 Key Insights from Discussion

### **1. Focus on Query Structure, Not Content**
- ✅ "últimos 7 dias" → Temporal pattern (works for any activity)
- ❌ "água" → Specific activity (breaks when Oracle evolves)

### **2. Align with Oracle Principles**
- ✅ Temporal (time-based)
- ✅ Frequency (how often)
- ✅ Intensity (how much)
- ✅ Progress (improvement)
- ❌ Specific activity names (not a universal principle)

### **3. Let the Model Handle Semantics**
- ✅ Pattern detection forces MCP command generation
- ✅ Model interprets activity names from context
- ✅ Existing FT-064 semantic detection handles activity recognition

---

## 🎯 Recommended Implementation

### **Step 1: Implement Generic Patterns Only**
- Categories 1, 2, 3, 4, 5, 6, 7 (all generic)
- No hard-coded activity names
- Focus on temporal, frequency, intensity, progress patterns

### **Step 2: Test with Real Queries**
- "Me da um resumo dos últimos 7 dias" ✅
- "Quantas atividades fiz essa semana?" ✅
- "Como foi meu progresso?" ✅
- "O que eu fiz ontem?" ✅

### **Step 3: Monitor & Iterate**
- Use FT-220 context logging to track success rates
- Identify missing patterns (if any)
- Add generic patterns as needed (avoid specific activity names)

---

## ✅ Benefits of Refined Approach

1. **Future-proof**: Works with any Oracle version
2. **Maintainable**: No need to update patterns for new activities
3. **Generic**: Aligns with universal concepts (temporal, frequency, intensity)
4. **Oracle-aligned**: Follows framework principles
5. **Simpler**: Fewer patterns to implement and test
6. **Extensible**: Easy to add new generic patterns

---

## 📝 Next Steps

1. **Review this refined approach** with user
2. **Confirm alignment** with Oracle framework principles
3. **Implement generic patterns** only
4. **Test with real queries**
5. **Monitor success rates** via FT-220
6. **Iterate based on data** (add generic patterns as needed)

---

**Key Takeaway**: Focus on **how users ask** (temporal, frequency, intensity), not **what they ask about** (specific activities).

