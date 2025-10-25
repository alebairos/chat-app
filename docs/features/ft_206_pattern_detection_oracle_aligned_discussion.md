# FT-206: Pattern Detection - Oracle-Aligned Discussion

**Date**: 2025-10-25  
**Branch**: `feature/ft-206-pattern-detection`  
**Purpose**: Align pattern detection with existing Oracle framework and metadata extraction

---

## 🔍 Analysis of Existing Implementation

### **What's Already Working (FT-149 Metadata Extraction)**

The system already has a **sophisticated, generic metadata extraction** system:

#### **1. Flat Key-Value Structure** (Revolutionary Approach)
```dart
// Metadata format: quantitative_{type}_value and quantitative_{type}_unit
{
  "quantitative_volume_value": 250,
  "quantitative_volume_unit": "ml",
  "quantitative_distance_value": 432,
  "quantitative_distance_unit": "meters",
  "quantitative_steps_value": 7000,
  "quantitative_steps_unit": "steps"
}
```

**Benefits**:
- ✅ **Zero structure ambiguity**
- ✅ **Trivial parsing** (just filter keys starting with `quantitative_`)
- ✅ **LLM-proof** (impossible to generate wrong structure)
- ✅ **Lightning fast performance**
- ✅ **Generic** (works for any measurement type)

#### **2. Supported Measurement Types** (Generic)
From `FlatMetadataParser`:
- `steps` → 👣 steps
- `distance` → 📏 m/km
- `volume` → 💧 ml/L
- `weight` → 🏋️ kg
- `duration` → ⏱️ min
- `reps` → 🔄 reps
- `sets` → 📊 sets
- `calories` → 🔥 kcal
- `heartrate` → ❤️ bpm
- `count` → 📈 (generic counter)

**Key Insight**: The system already handles **ANY** quantitative measurement type generically!

#### **3. MCP Detection Prompt** (Already Generic)
From `SystemMCPService._oracleDetectActivities()`:
```
9. EXTRACT quantitative data using flat keys: "quantitative_{type}_value" and "quantitative_{type}_unit"

Required JSON format:
{"activities": [{"code": "SF1", "confidence": "high", "catalog_name": "Beber água", "quantitative_volume_value": 250, "quantitative_volume_unit": "ml"}]}

EXAMPLES:
✅ CORRECT: {"code": "SF1", "catalog_name": "Beber água", "quantitative_volume_value": 250, "quantitative_volume_unit": "ml"}
✅ CORRECT: {"code": "SF15", "catalog_name": "Caminhar 7000 passos", "quantitative_distance_value": 432, "quantitative_distance_unit": "meters"}
```

**Key Insight**: The LLM already extracts quantitative metadata **automatically** during activity detection!

---

## 💡 Key Realization

### **The System Already Does What We Need!**

When a user says:
- "Bebi 500ml de água" → Detected as SF1 with `quantitative_volume_value: 500, quantitative_volume_unit: "ml"`
- "Caminhei 2km" → Detected with `quantitative_distance_value: 2000, quantitative_distance_unit: "m"`
- "Fiz 3 séries de 12 flexões" → Detected with `quantitative_sets_value: 3, quantitative_reps_value: 12`

**The metadata extraction is ALREADY GENERIC and ORACLE-ALIGNED!**

---

## 🎯 Refined Pattern Detection Strategy

### **Core Principle Confirmed**

**Focus on TEMPORAL, FREQUENCY, INTENSITY patterns - NOT specific activity names**

The existing metadata system proves this works:
- ✅ It doesn't hard-code "água", "pomodoro", "meditação"
- ✅ It uses generic measurement types: `volume`, `distance`, `duration`, `count`
- ✅ It works for ANY activity that has quantitative data
- ✅ It's future-proof and Oracle-agnostic

---

## 📋 Pattern Detection Categories (Oracle-Aligned)

### **Category 1: Temporal Queries** ✅
**Trigger**: `get_activity_stats`

**Patterns**: Time-based references (universal)
```dart
RegExp(r'últim[oa]s?\s+\d+\s+dias?'),     // "últimos 7 dias"
RegExp(r'última\s+semana'),                // "última semana"
RegExp(r'último\s+mês'),                   // "último mês"
RegExp(r'hoje'),                           // "hoje"
RegExp(r'ontem'),                          // "ontem"
RegExp(r'resumo.*\d+\s+dias?'),            // "resumo dos últimos 7 dias"
```

**Why this aligns with Oracle**:
- ✅ Time is a universal dimension
- ✅ Works for any activity type
- ✅ Matches Oracle's temporal tracking

---

### **Category 2: Quantitative Queries** ✅
**Trigger**: `get_activity_stats`

**Patterns**: Frequency and intensity (universal)
```dart
// Frequency patterns
RegExp(r'quantas?\s+vezes'),               // "quantas vezes"
RegExp(r'quantas?\s+atividades?'),         // "quantas atividades"
RegExp(r'com\s+que\s+frequência'),         // "com que frequência"

// Intensity patterns (aligns with quantitative_{type})
RegExp(r'quanto\s+(tempo|ml|metros|km)'),  // "quanto tempo", "quantos ml"
RegExp(r'\d+\s+(ml|metros|km|minutos)'),   // "300 ml", "5 km"

// General activity queries
RegExp(r'o\s+que\s+(eu\s+)?fiz'),         // "o que eu fiz"
RegExp(r'quais?\s+atividades?'),           // "quais atividades"
```

**Why this aligns with Oracle**:
- ✅ Matches `FlatMetadataParser` measurement types
- ✅ Generic (volume, distance, duration, count)
- ✅ Works for any tracked activity
- ✅ Aligns with `quantitative_{type}_value` structure

---

### **Category 3: Progress & Trend Queries** ✅
**Trigger**: `get_activity_stats` (extended range)

**Patterns**: Improvement and comparison (universal)
```dart
// Progress patterns
RegExp(r'meu\s+progresso'),                // "meu progresso"
RegExp(r'como\s+(foi|está)\s+meu\s+progresso'), // "como foi meu progresso"

// Comparison patterns
RegExp(r'compar[ao]'),                     // "comparar", "comparado"
RegExp(r'(melhor|pior)\s+que'),            // "melhor que", "pior que"
RegExp(r'evolução'),                       // "evolução"
RegExp(r'tendência'),                      // "tendência"

// Improvement patterns
RegExp(r'(melhorei|piorei)'),              // "melhorei", "piorei"
RegExp(r'(aumentei|diminuí)'),             // "aumentei", "diminuí"
```

**Why this aligns with Oracle**:
- ✅ Universal coaching concepts
- ✅ Works across all Oracle dimensions (R, SF, TG, E, SM)
- ✅ Aligns with coaching framework principles

---

### **Category 4: Conversation Context** ✅
**Trigger**: `get_conversation_context` / `search_conversation_context`

**Patterns**: Conversation recall (universal)
```dart
RegExp(r'o\s+que\s+(a gente|nós)\s+(falou|conversou)'), // "o que a gente falou"
RegExp(r'lembra\s+(quando|que)'),          // "lembra quando"
RegExp(r'você\s+(disse|falou)'),           // "você disse"
RegExp(r'busca.*conversa'),                // "busca na conversa"
```

**Why this aligns with Oracle**:
- ✅ Universal conversation patterns
- ✅ Not tied to specific content
- ✅ Supports coaching memory (FT-156)

---

### **Category 5: Persona Switching** ✅
**Trigger**: `get_interleaved_conversation`

**Patterns**: Multi-persona awareness (universal)
```dart
RegExp(r'@\w+'),                           // "@ari", "@tony"
RegExp(r'(conversei|falei)\s+com'),       // "conversei com"
RegExp(r'olhe\s+(as\s+)?conversas?'),     // "olhe as conversas"
```

**Why this aligns with Oracle**:
- ✅ Generic persona switching patterns
- ✅ Works for any persona (current or future)
- ✅ Supports multi-persona feature

---

### **Category 6: Goal & Objective** ✅
**Trigger**: `get_activity_stats` + `search_conversation_context`

**Patterns**: Goal-related (universal)
```dart
RegExp(r'(meta|objetivo|alvo)'),           // "meta", "objetivo"
RegExp(r'(alcancei|atingi)'),              // "alcancei", "atingi"
RegExp(r'quanto\s+falta'),                 // "quanto falta"
RegExp(r'progresso\s+(da|do)\s+(meta|objetivo)'), // "progresso da meta"
```

**Why this aligns with Oracle**:
- ✅ Universal goal concepts
- ✅ Works for any goal type
- ✅ Aligns with coaching framework

---

### **Category 7: Repetition Prevention** ✅
**Trigger**: `get_current_persona_messages`

**Patterns**: Repetition detection (universal)
```dart
RegExp(r'(já|você\s+já)\s+(disse|falou)'), // "já disse"
RegExp(r'repetindo'),                      // "repetindo"
RegExp(r'de\s+novo'),                      // "de novo"
```

**Why this aligns with Oracle**:
- ✅ Universal repetition patterns
- ✅ Improves conversation quality
- ✅ Not tied to specific content

---

## ✅ What We Should NOT Do

### **❌ AVOID: Hard-Coding Specific Activity Names**

**Bad approach** (from original spec):
```dart
// ❌ DON'T DO THIS
RegExp(r'(água|hidratação)'),              // Too specific
RegExp(r'(pomodoro|trabalho\s+focado)'),   // Too specific
RegExp(r'(meditação|meditar)'),            // Too specific
RegExp(r'(exercício|treino|academia)'),    // Too specific
```

**Why this is wrong**:
1. **Breaks Oracle principles**: Oracle activities are defined in the catalog, not in pattern detection
2. **Maintenance burden**: Need to update patterns for every new activity
3. **Not future-proof**: Breaks when Oracle evolves
4. **Redundant**: The LLM already detects activities semantically via FT-064/FT-119

---

## 🎯 How It All Works Together

### **User Query Flow**:

1. **User**: "Me da um resumo dos últimos 7 dias"
   - ✅ **Pattern Detection**: Detects temporal pattern ("últimos 7 dias")
   - ✅ **Injects Hint**: `[SYSTEM HINT: Temporal activity query detected. Use: {"action": "get_activity_stats", "days": 7}]`
   - ✅ **Model Generates MCP**: `{"action": "get_activity_stats", "days": 7}`
   - ✅ **System Fetches Data**: Gets all activities from last 7 days
   - ✅ **Model Responds**: "Nos últimos 7 dias você fez X atividades..."

2. **User**: "Bebi água suficiente essa semana?"
   - ✅ **Pattern Detection**: Detects temporal ("essa semana") + quantitative ("suficiente")
   - ✅ **Injects Hint**: `[SYSTEM HINT: Temporal activity query detected. Use: {"action": "get_activity_stats", "days": 7}]`
   - ✅ **Model Generates MCP**: `{"action": "get_activity_stats", "days": 7}`
   - ✅ **System Fetches Data**: Gets activities, **including metadata** (`quantitative_volume_value`)
   - ✅ **Model Responds**: "Você bebeu X ml de água essa semana..." (uses metadata!)

3. **User**: "Como foi meu progresso de exercícios?"
   - ✅ **Pattern Detection**: Detects progress pattern ("meu progresso")
   - ✅ **Injects Hint**: `[SYSTEM HINT: Progress query detected. Use: {"action": "get_activity_stats", "days": 30}]`
   - ✅ **Model Generates MCP**: `{"action": "get_activity_stats", "days": 30}`
   - ✅ **System Fetches Data**: Gets exercise activities with metadata (distance, duration, reps, sets)
   - ✅ **Model Responds**: "Seu progresso de exercícios melhorou..." (interprets metadata!)

---

## 💡 Key Insights

### **1. Pattern Detection ≠ Activity Detection**

- **Pattern Detection**: Forces MCP command generation for temporal/quantitative queries
- **Activity Detection**: Semantic understanding of what activity was done (already working via FT-064/FT-119)

**They are complementary, not overlapping!**

### **2. Metadata Extraction is Already Generic**

The `quantitative_{type}_value` structure is **perfectly aligned** with our pattern detection approach:
- ✅ Generic measurement types (volume, distance, duration, count)
- ✅ Works for any activity
- ✅ Future-proof
- ✅ Oracle-agnostic

### **3. Focus on Query Structure, Not Content**

**Good patterns**:
- ✅ "últimos 7 dias" → Temporal
- ✅ "quantas atividades" → Quantitative
- ✅ "meu progresso" → Progress

**Bad patterns**:
- ❌ "água" → Specific activity (let semantic detection handle this)
- ❌ "pomodoro" → Specific activity (let semantic detection handle this)

---

## 📊 Expected Behavior Examples

### **Example 1: Temporal Query**
```
User: "Me da um resumo dos últimos 7 dias"

Pattern Detection: ✅ Temporal pattern detected
MCP Command: {"action": "get_activity_stats", "days": 7}
Data Fetched: All activities from last 7 days (with metadata)
Model Response: "Nos últimos 7 dias você:
- Bebeu 3.5L de água (quantitative_volume metadata)
- Caminhou 15km (quantitative_distance metadata)
- Fez 12 pomodoros (quantitative_count metadata)
- Meditou 5 vezes (activity count)"
```

### **Example 2: Quantitative Query**
```
User: "Quantas atividades fiz essa semana?"

Pattern Detection: ✅ Quantitative + Temporal patterns detected
MCP Command: {"action": "get_activity_stats", "days": 7}
Data Fetched: All activities from last 7 days
Model Response: "Você completou 42 atividades essa semana, incluindo..."
```

### **Example 3: Progress Query**
```
User: "Como foi meu progresso de exercícios?"

Pattern Detection: ✅ Progress pattern detected
MCP Command: {"action": "get_activity_stats", "days": 30}
Data Fetched: Exercise activities from last 30 days (with metadata)
Model Response: "Seu progresso de exercícios melhorou:
- Distância média aumentou de 2km para 3.5km
- Frequência subiu de 2x/semana para 4x/semana"
```

---

## ✅ Conclusion

### **Pattern Detection Should Be**:
1. ✅ **Generic** (temporal, frequency, intensity, progress)
2. ✅ **Oracle-aligned** (follows framework principles)
3. ✅ **Future-proof** (works with any Oracle version)
4. ✅ **Complementary** (works with existing metadata extraction)
5. ✅ **Simple** (focuses on query structure, not content)

### **Pattern Detection Should NOT Be**:
1. ❌ **Specific** (hard-coded activity names)
2. ❌ **Redundant** (duplicating semantic detection)
3. ❌ **Brittle** (breaking when Oracle evolves)
4. ❌ **Complex** (trying to detect every possible query)

---

## 🔄 Next Steps

1. **Confirm this approach** aligns with your vision
2. **Implement generic patterns** only (Categories 1-7)
3. **Test with real queries**
4. **Monitor success rates** via FT-220
5. **Iterate based on data**

---

**Key Takeaway**: The existing metadata extraction system (FT-149) already proves that **generic, Oracle-aligned patterns work perfectly**. We should follow the same principle for pattern detection.

