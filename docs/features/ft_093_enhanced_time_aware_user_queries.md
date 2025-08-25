# FT-093: Enhanced Time-Aware User Queries

## **Overview**
**Feature ID**: FT-093  
**Priority**: High  
**Category**: Query Enhancement / User Experience  
**Effort Estimate**: 1-2 days  
**Dependencies**: TimeContextService, SystemMCP, ActivityMemoryService  
**Status**: Specification  

## **Executive Summary**

Enhance the system's ability to understand and process temporal user queries with improved natural language parsing, accurate date calculations, and contextual responses. Build upon the successful intent-first approach (FT-091) to provide seamless temporal data access.

## **Problem Statement**

### **Current Gaps Identified**

#### **1. Temporal Query Parsing**
```
User: "o que eu fiz ontem?" (what did I do yesterday?)
Current: AI must manually parse and generate {"action": "get_activity_stats", "days": 1}
Issue: Inconsistent temporal understanding, manual MCP command generation
```

#### **2. Date Calculation Accuracy (FT-083)**
```
User: "yesterday" query → days: 1 → queries TODAY instead of yesterday
Root cause: `subtract(Duration(days: days - 1))` logic error
Impact: Wrong data returned, user confusion
```

#### **3. Limited Temporal Context**
```
Current: Basic time gaps (yesterday, this week, etc.)
Missing: Relative time expressions, specific date ranges, pattern recognition
Examples: "last Monday", "two days ago", "this morning", "since Wednesday"
```

#### **4. Conversational Temporal Flow**
```
User: "além de beber água, o que mais fiz hoje?"
Current: Requires manual filtering and context understanding
Needed: Intelligent query expansion and result filtering
```

### **Evidence from Recent Logs**

From FT-092 analysis:
- ✅ Intent classification working correctly (ASKING vs REPORTING)
- ✅ Activity detection accuracy improved
- ❌ Temporal queries still require manual AI interpretation
- ❌ Date calculation bug persists (FT-083)
- ❌ Limited support for complex temporal expressions

## **Solution Strategy**

### **Core Principle**
Extend the successful intent-first approach to include temporal intelligence, making time-aware queries as natural as activity reporting.

### **Three-Phase Enhancement**

#### **Phase 1: Fix Foundation Issues** (30 minutes)
- Resolve FT-083 date calculation bug
- Ensure accurate yesterday/last week queries

#### **Phase 2: Enhanced Temporal Parsing** (1 day)
- Intelligent temporal expression recognition
- Automatic MCP command generation for time queries
- Contextual response enhancement

#### **Phase 3: Advanced Temporal Features** (0.5 day)
- Pattern recognition and insights
- Comparative temporal analysis
- Predictive suggestions based on time patterns

## **Functional Requirements**

### **FR-1: Accurate Date Calculations**

#### **Current Behavior (Broken)**
```dart
// ActivityMemoryService.getActivityStats()
final startDate = today.subtract(Duration(days: days - 1));

// When days = 1 (yesterday):
// startDate = today.subtract(Duration(days: 0)) = TODAY ❌
```

#### **Required Behavior (Fixed)**
```dart
// Corrected logic
if (days == 0) {
  // Today only
  startDate = today;
  endDate = now;
} else {
  // Previous days (exclude today)
  startDate = today.subtract(Duration(days: days));
  endDate = today.subtract(Duration(days: 1, milliseconds: -1));
}

// When days = 1 (yesterday):
// startDate = today.subtract(Duration(days: 1)) = YESTERDAY ✅
```

### **FR-2: Temporal Expression Recognition**

#### **Enhanced System Prompt**
```markdown
## Temporal Query Processing

When users ask about activities with time references, automatically generate appropriate MCP commands:

### Temporal Expressions Map:
- "hoje", "today" → {"action": "get_activity_stats", "days": 0}
- "ontem", "yesterday" → {"action": "get_activity_stats", "days": 1}
- "semana passada", "last week" → {"action": "get_activity_stats", "days": 7}
- "dois dias atrás", "two days ago" → {"action": "get_activity_stats", "days": 2}

### Context-Aware Queries:
- "além de X, o que mais?" → Filter results excluding mentioned activity
- "como está meu progresso?" → Compare current period to previous
- "o que fiz esta manhã?" → Filter by time of day
```

### **FR-3: Intelligent Query Enhancement**

#### **Query Pattern Examples**
```
Input: "o que eu fiz ontem além de beber água?"
Processing:
  1. Detect temporal: "ontem" → days: 1
  2. Detect exclusion: "além de beber água" → exclude SF1
  3. Generate: {"action": "get_activity_stats", "days": 1}
  4. Filter: Remove SF1 activities from results
  5. Respond: Contextual list without water activities
```

#### **Comparative Analysis**
```
Input: "como foi minha semana comparado com a anterior?"
Processing:
  1. Current week: {"action": "get_activity_stats", "days": 7}
  2. Previous week: {"action": "get_activity_stats", "days": 14}
  3. Compare: Calculate differences and trends
  4. Respond: "Esta semana: X atividades vs. anterior: Y (-Z%)"
```

### **FR-4: Enhanced Response Contextuality**

#### **Time-Aware Response Patterns**
```dart
// Morning queries (6-12 PM)
"Esta manhã você já completou..."
"Bom ritmo para começar o dia!"

// Afternoon queries (12-18 PM)  
"Hoje pela manhã você fez... E à tarde?"
"Como vai o restante do dia?"

// Evening queries (18-22 PM)
"Hoje você completou... Como foi o dia?"
"Planejando alguma atividade para a noite?"

// Night queries (22-6 AM)
"Hoje você fez... Hora de descansar?"
"Reflexão do dia: conseguiu seus objetivos?"
```

## **Technical Implementation Plan**

### **1. Fix Date Calculation Bug (30 min)**

**File**: `lib/services/activity_memory_service.dart`  
**Method**: `getActivityStats()`

```dart
// Enhanced date calculation logic
if (days == 0) {
  // Special case: Today only
  startDate = today;
  queryEndDate = now;
  print('🔍 Querying TODAY\'s activities');
} else {
  // Query previous days (exclude today)
  startDate = today.subtract(Duration(days: days));
  final endDate = today.subtract(Duration(days: 1));
  queryEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
  print('🔍 Querying PREVIOUS $days days (excluding today)');
}
```

### **2. Enhanced Temporal Parsing (1 day)**

**File**: `lib/services/temporal_query_processor.dart` (new)

```dart
class TemporalQueryProcessor {
  static const Map<String, int> _temporalExpressions = {
    // Portuguese
    'hoje': 0,
    'ontem': 1,
    'anteontem': 2,
    'semana passada': 7,
    'última semana': 7,
    
    // English
    'today': 0,
    'yesterday': 1,
    'last week': 7,
    'this week': 7,
  };

  /// Parse temporal expressions and return MCP command
  static Map<String, dynamic>? parseTemporalQuery(String query) {
    final lowerQuery = query.toLowerCase();
    
    for (final expression in _temporalExpressions.keys) {
      if (lowerQuery.contains(expression)) {
        return {
          'action': 'get_activity_stats',
          'days': _temporalExpressions[expression],
          'temporal_context': expression,
        };
      }
    }
    
    return null;
  }
  
  /// Enhanced response based on time context
  static String enhanceTemporalResponse(Map<String, dynamic> data, String temporalContext) {
    // Context-aware response generation
  }
}
```

### **3. System Prompt Enhancement**

**File**: `assets/config/ari_life_coach_config.json`

Add temporal intelligence section:
```json
{
  "temporal_query_instructions": {
    "auto_detect": true,
    "supported_expressions": ["hoje", "ontem", "semana passada", "today", "yesterday", "last week"],
    "response_patterns": {
      "morning": "Esta manhã você já...",
      "afternoon": "Hoje pela manhã você fez... E à tarde?",
      "evening": "Hoje você completou...",
      "night": "Reflexão do dia..."
    }
  }
}
```

### **4. Integration with Existing Systems**

#### **ClaudeService Enhancement**
```dart
// In ClaudeService.sendMessage()
// Check for temporal queries before general processing
final temporalCommand = TemporalQueryProcessor.parseTemporalQuery(message);
if (temporalCommand != null) {
  // Automatically process temporal query
  final response = await _systemMCP!.processCommand(jsonEncode(temporalCommand));
  // Generate enhanced response with temporal context
  return TemporalQueryProcessor.enhanceTemporalResponse(response, temporalCommand['temporal_context']);
}
```

## **Enhanced User Experience Examples**

### **Example 1: Simple Yesterday Query**
```
User: "o que eu fiz ontem?"
System: 
  1. Auto-detects: "ontem" → days: 1
  2. Queries: Yesterday's activities (correctly calculated)
  3. Responds: "Ontem você completou 8 atividades: 
     - SF1 (Água): 4x entre 9:00 e 18:30
     - T8 (Pomodoro): 2x às 10:15 e 15:45
     Como foi o dia?"
```

### **Example 2: Filtered Query**
```
User: "além de beber água, o que mais fiz hoje?"
System:
  1. Detects: temporal = "hoje", exclusion = "beber água" 
  2. Queries: Today's activities
  3. Filters: Remove SF1 (water) activities
  4. Responds: "Hoje, além da água, você fez:
     - T8 (Trabalho focado): 1x às 12:29
     Quer adicionar mais atividades à tarde?"
```

### **Example 3: Comparative Analysis**
```
User: "como foi minha semana?"
System:
  1. Queries: This week vs last week
  2. Analyzes: Trends and patterns
  3. Responds: "Esta semana: 47 atividades vs. semana passada: 52 (-5)
     Destaque: Água manteve consistência (35x)
     Oportunidade: Pomodoros diminuíram (8x → 5x)
     Como podemos melhorar?"
```

## **Success Metrics**

### **Accuracy Metrics**
- ✅ "Yesterday" queries return correct date range (not today)
- ✅ Temporal expressions parsed automatically (no manual MCP commands)
- ✅ Response context matches query time period

### **User Experience Metrics**
- ✅ Natural language temporal queries work seamlessly
- ✅ Contextual responses based on time of day
- ✅ Comparative insights when requesting trends

### **Technical Metrics**
- ✅ Zero false positives in temporal parsing
- ✅ Graceful degradation for unrecognized expressions
- ✅ Consistent API response times for temporal queries

## **Implementation Phases**

### **Phase 1: Foundation Fix (30 min) - IMMEDIATE**
- [ ] Fix FT-083 date calculation bug in ActivityMemoryService
- [ ] Test yesterday queries return correct data
- [ ] Verify week queries exclude today properly

### **Phase 2: Enhanced Parsing (1 day)**
- [ ] Create TemporalQueryProcessor service
- [ ] Implement automatic temporal expression detection
- [ ] Enhance system prompt with temporal intelligence
- [ ] Add time-aware response patterns

### **Phase 3: Advanced Features (0.5 day)**
- [ ] Implement query filtering ("além de X")
- [ ] Add comparative analysis capabilities
- [ ] Create pattern recognition for insights
- [ ] Enhanced contextual responses by time of day

## **Risk Assessment**

### **Low Risk**
- Foundation fix (Phase 1) - simple date calculation correction
- Temporal parsing - extends existing successful patterns

### **Medium Risk**
- System prompt changes - require careful testing with personas
- Response pattern changes - may affect conversational tone

### **Mitigation**
- Incremental rollout with existing test patterns
- Fallback to current behavior for unrecognized expressions
- Maintain compatibility with existing MCP commands

---
**Next Steps**: Start with Phase 1 foundation fix, then implement temporal parsing enhancements building on the successful intent-first approach from FT-091.
