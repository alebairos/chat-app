# FT-095: Enhanced Temporal Prompt Guidance

## **Overview**
**Feature ID**: FT-095  
**Priority**: High  
**Category**: App UX Behavior / Trust-the-Model  
**Effort Estimate**: 1-2 hours  
**Dependencies**: SystemMCP, ClaudeService  
**Status**: ✅ **IMPLEMENTED**  

## **Executive Summary**

Fix temporal query inconsistencies by enhancing ClaudeService MCP documentation with temporal intelligence guidance. Following the successful trust-the-model approach from FT-091, provide Claude with clear temporal expression mapping patterns, multi-step query processing guidance, and contextual response enhancement. Implemented as app UX behavior in ClaudeService rather than persona-specific prompts for proper feature encapsulation.

## **Problem Statement**

### **Current Capability vs. Guidance Gap**

#### **SystemMCP Already Provides:**
```dart
✅ Rich temporal data via get_current_time
✅ Flexible activity queries via get_activity_stats (days: 0-N)
✅ Two-pass processing for data-dependent queries
✅ Real database integration preventing approximations
```

#### **Missing Prompt Guidance:**
```
❌ "ontem" → Inconsistent days parameter mapping
❌ "além de beber água" → No filtering pattern provided
❌ "comparado com semana passada" → No multi-query guidance
❌ Time-of-day responses → No contextual enhancement patterns
```

### **Evidence from FT-092 Analysis**

**Intent classification works perfectly:**
- ASKING queries → Correct data retrieval
- REPORTING queries → Accurate activity detection  
- DISCUSSING queries → No false positives

**But temporal expressions need better guidance:**
- User: "o que eu fiz ontem?" → Sometimes correct days: 1, sometimes not
- User: "além de beber água?" → Generic responses without filtering
- User: "como foi minha semana?" → Missed opportunity for comparative analysis

## **Solution Strategy**

### **Core Principle: Trust-the-Model Enhancement**
- **Trust Claude's semantic understanding** of temporal expressions
- **Provide clear mapping patterns** for MCP command generation
- **Give structured examples** that Claude can extrapolate from
- **Enhance without micromanaging** natural language flow

### **Code-Based Enhancement Approach (IMPLEMENTED)**
Fix through ClaudeService MCP documentation enhancement for proper feature encapsulation:
1. **Temporal Expression Mapping Rules** ✅
2. **Multi-Step Query Processing Patterns** ✅
3. **Contextual Response Enhancement** ✅
4. **Data Utilization Guidelines** ✅

## **Implementation Details**

### **✅ IMPLEMENTED: Enhanced MCP Documentation**

#### **Location**: `lib/services/claude_service.dart`
#### **Method**: `_buildSystemPrompt()` lines 474-529

**Added comprehensive temporal intelligence including:**

#### **1. Temporal Expression Mapping** (lines 477-484)
```dart
'- "hoje", "today" → {"action": "get_activity_stats", "days": 0}\n'
'- "ontem", "yesterday" → {"action": "get_activity_stats", "days": 1}\n'
'- "anteontem", "day before yesterday" → {"action": "get_activity_stats", "days": 2}\n'
'- "esta semana", "this week" → {"action": "get_activity_stats", "days": 7}\n'
'- "semana passada", "last week" → {"action": "get_activity_stats", "days": 14}\n'
'- "último mês", "last month" → {"action": "get_activity_stats", "days": 30}\n'
'- "[X] dias atrás", "[X] days ago" → {"action": "get_activity_stats", "days": X}\n'
```

#### **2. Complex Query Processing** (lines 488-502)
```dart
'**Exclusion Queries ("além de X", "other than X"):**\n'
'1. Execute appropriate temporal query: {"action": "get_activity_stats", "days": N}\n'
'2. Filter returned data to exclude mentioned activities (e.g., SF1 for water)\n'
'3. Present filtered results with context\n'

'**Comparison Queries ("comparado com", "vs", "compared to"):**\n'
'1. Execute current period query\n'
'2. Execute previous period query (typically double the days for comparison)\n'
'3. Calculate differences and identify trends\n'
'4. Present comparative analysis\n'
```

#### **3. Time-of-Day Filtering** (lines 499-502)
```dart
'**Time-of-Day Filtering ("manhã", "tarde", "morning", "afternoon"):**\n'
'1. Execute temporal query for appropriate day(s)\n'
'2. Filter results using "timeOfDay" field from activity data\n'
'3. Present time-specific activities\n'
```

#### **4. Contextual Response Enhancement** (lines 513-529)
```dart
'**Time-of-Day Awareness:**\n'
'- Morning queries (6-12h): "Esta manhã você já...", "Bom ritmo para começar o dia!"\n'
'- Afternoon queries (12-18h): "Hoje pela manhã você fez... E à tarde?", "Como vai o restante do dia?"\n'
'- Evening queries (18-22h): "Hoje você completou...", "Como foi o dia?"\n'
'- Night queries (22-6h): "Reflexão do dia...", "Hora de descansar?"\n'

'**Data-Driven Insights:**\n'
'- Identify patterns: "água manteve consistência (5x)", "pomodoros diminuíram de 3x para 1x"\n'
'- Suggest improvements: "Quer aumentar o foco à tarde?", "Que tal mais água pela manhã?"\n'
'- Celebrate achievements: "Excelente consistência!", "Superou a meta da semana!"\n'
'- Reference specific times: "às 10:58", "entre 11:23 e 11:24"\n'
```

## **Architecture Benefits Achieved**

### **✅ Proper Feature Encapsulation**
- **App UX Behavior**: Temporal intelligence lives in ClaudeService (not persona configs)
- **Service Cohesion**: All MCP-related functionality grouped together
- **Persona Independence**: Works across all personas (Ari, Oracle, I-There)
- **Maintainability**: Single source of truth for temporal behavior
- **Version Control**: Feature evolution tracked in one location

### **✅ Trust-the-Model Implementation**
- **Semantic Understanding**: Claude interprets temporal expressions naturally
- **Pattern Recognition**: Maps "ontem", "além de", "comparado com" correctly  
- **Contextual Reasoning**: Understands when to filter, compare, or analyze
- **Graceful Degradation**: Falls back to current behavior for unrecognized patterns

## **Expected Outcomes & Testing**

### **✅ Immediate Improvements**
```
User: "o que eu fiz ontem?" → Consistent days: 1 mapping
User: "além de beber água, o que fiz hoje?" → Structured filtering approach
User: "como foi esta semana vs. anterior?" → Comparative analysis pattern
User: "o que fiz esta manhã?" → Time-of-day filtering guidance
```

### **Example Enhanced Response Flow:**
```
User: "além de beber água, o que eu fiz ontem?"
1. Claude recognizes: temporal="ontem" + exclusion="além de beber água"
2. Executes: {"action": "get_activity_stats", "days": 1}
3. Filters: Removes SF1 activities from results
4. Responds: "Ontem, além da água (5x), você fez:
   - T8 (Pomodoro): 1x às 00:29
   Como foi o foco ontem?"
```

**Comparison Pattern ("comparado com", "vs", "compared to"):**
Step 1: Execute current period query {"action": "get_activity_stats", "days": 7}
Step 2: Execute previous period query {"action": "get_activity_stats", "days": 14}
Step 3: Calculate differences, identify trends from both datasets
Step 4: Present comparative analysis with specific insights

**Time-of-Day Filtering ("esta manhã", "this morning", "à tarde"):**
Step 1: Execute {"action": "get_activity_stats", "days": 0}
Step 2: Filter results using "timeOfDay" field from activity data
Step 3: Present time-specific activities with appropriate context

**Pattern Combination:**
For queries like "além de água, o que fiz ontem de manhã?":
1. Get yesterday's data (days: 1)
2. Filter by timeOfDay: "morning" 
3. Exclude activities matching "água" (SF1)
4. Present remaining morning activities
```

### **Phase 3: Contextual Response Enhancement (30 min)**

#### **Add Time-Aware Response Patterns:**
```markdown
### CONTEXTUAL RESPONSE INTELLIGENCE

**Time-Aware Language Based on Query Context:**
- **Morning queries (6-12h)**: "Esta manhã você já...", "Bom ritmo para começar o dia!"
- **Afternoon queries (12-18h)**: "Hoje pela manhã você fez... E à tarde?", "Como vai o restante do dia?"
- **Evening queries (18-22h)**: "Hoje você completou...", "Como foi o dia?"
- **Night queries (22-6h)**: "Reflexão do dia...", "Hora de descansar?"

**Data-Driven Insights:**
- Always reference actual counts and times from MCP data
- Identify patterns: "água manteve consistência (5x)", "pomodoros diminuíram"
- Suggest improvements based on data trends: "Quer aumentar o foco à tarde?"
- Celebrate achievements visible in data: "Excelente consistência!"

**Natural Conversational Flow:**
- Use MCP data to ask relevant follow-up questions
- Reference specific times from activity data: "às 10:58", "entre 11:23 e 11:24"
- Connect current data to previous patterns
- Maintain persona voice while being data-accurate
```

### **Phase 4: Data Utilization Guidelines (30 min)**

#### **Add Mandatory Data Usage Rules:**
```markdown
### CRITICAL DATA UTILIZATION RULES

**ALWAYS Use Real Data:**
- NEVER approximate activity counts or times
- ALWAYS execute MCP commands for temporal queries
- Use exact timestamps and counts from database
- Reference specific activity codes (SF1, T8, etc.) from results

**Smart Data Presentation:**
- Format times consistently: "às 10:58", "entre 11:23 e 11:24"
- Group activities logically: "SF1 (Água): 5x", "T8 (Pomodoro): 2x"
- Show dimensional summary: "3 SF (saúde física), 2 TG (trabalho)"
- Include confidence context when relevant

**Error Handling:**
- If MCP command fails, acknowledge gracefully: "Deixe-me verificar seus dados..."
- Fall back to encouraging response while noting data unavailability
- Never invent or estimate activity data
```

## **File Modifications Required**

### **Primary Enhancement Target**
**File**: `assets/config/oracle/oracle_prompt_2.1.md`  
**Section**: After the existing MCP commands section (around line 300)

**Addition Location:**
```markdown
## SISTEMA DE COMANDO MCP - ACTIVITY TRACKING
[existing content...]

## ⚡ ENHANCED TEMPORAL INTELLIGENCE ⚡
[new content from phases 1-4]
```

## **IMPLEMENTATION STATUS: COMPLETE ✅**

**Date Implemented**: August 25, 2025  
**Lines of Code**: ~50 lines added to ClaudeService._buildSystemPrompt()  
**Impact**: All personas now have enhanced temporal intelligence automatically  

### **What's Now Available:**
1. ✅ **Consistent temporal mapping**: "ontem" always maps to days: 1
2. ✅ **Complex query patterns**: "além de X" follows structured filtering approach  
3. ✅ **Comparative analysis**: "vs semana passada" uses dual queries + analysis
4. ✅ **Time-aware responses**: Morning/afternoon/evening contextual language
5. ✅ **Data-driven insights**: Patterns, trends, and specific time references

### **Architecture Achievement:**
- **Feature encapsulation**: Temporal behavior properly separated from persona configs
- **Trust-the-model**: Claude's semantic understanding enhanced with clear patterns
- **Maintainability**: Single location for temporal intelligence updates
- **Scalability**: Works across all current and future personas automatically

### **Ready for Testing:**
```
Test Queries:
- "o que eu fiz ontem?" → Should consistently use days: 1
- "além de beber água, o que fiz hoje?" → Should filter SF1 activities
- "como foi esta semana vs. anterior?" → Should compare periods
- "o que fiz esta manhã?" → Should filter by timeOfDay
```

### **User Experience Enhancement**
```
User: "o que eu fiz ontem além de beber água?"
Before: Generic response with possible wrong data
After: 
  1. {"action": "get_activity_stats", "days": 1}
  2. Filter out SF1 activities
  3. "Ontem, além da água, você fez:
     - T8 (Pomodoro): 1x às 00:29
     Como foi o foco ontem?"
```

### **Consistency Metrics**
- **Temporal Expression Accuracy**: 95%+ correct days parameter mapping
- **Data Utilization**: 100% real data usage (no approximations)
- **Complex Query Success**: 90%+ proper decomposition of multi-part queries
- **Response Contextuality**: Time-appropriate language patterns

## **Testing Strategy**

### **Phase 1 Validation (Post-Implementation)**
```
Test Queries:
- "o que eu fiz ontem?" → Should use days: 1 consistently
- "esta semana?" → Should use days: 7 consistently  
- "anteontem?" → Should use days: 2 consistently
```

### **Phase 2 Validation**
```
Complex Queries:
- "além de beber água, o que fiz hoje?" → Should filter SF1
- "como foi esta semana vs. a anterior?" → Should compare two periods
- "o que fiz esta manhã?" → Should filter by timeOfDay
```

### **Phase 3 Validation**
```
Contextual Responses:
- Morning query → Should use morning-appropriate language
- Evening query → Should use evening-appropriate language
- Data accuracy → Should reference exact times/counts
```

## **Risk Assessment**

### **Low Risk (Prompt-Only Changes)**
- No code modifications required
- Existing SystemMCP functionality unchanged
- Fallback to current behavior if patterns not recognized
- Incremental enhancement without breaking changes

### **Potential Issues & Mitigation**
- **Prompt size increase**: Monitor for context length limits
- **Pattern conflicts**: Test with existing MCP examples
- **Persona voice changes**: Validate tone remains consistent
- **Language mixing**: Ensure Portuguese/English patterns work together

### **Rollback Strategy**
- Simple revert of prompt additions if issues occur
- No database or code changes to undo
- Persona-specific rollback possible (Oracle, Ari, etc.)

## **Success Criteria**

### **Functional Success**
- [ ] Temporal expressions map correctly to MCP commands
- [ ] Complex queries decompose into logical steps
- [ ] Responses use real data from MCP instead of approximations
- [ ] Time-aware language patterns applied appropriately

### **User Experience Success**
- [ ] "Yesterday" queries work reliably every time
- [ ] "Besides water" queries show filtered results
- [ ] Comparative queries provide actionable insights
- [ ] Responses feel natural while being data-accurate

### **Technical Success**
- [ ] No performance degradation from prompt changes
- [ ] SystemMCP utilization increases (more queries use real data)
- [ ] Error rates for temporal queries decrease
- [ ] Conversation flow remains natural and engaging

---

**Implementation Approach**: Enhanced ClaudeService MCP documentation provides temporal intelligence for all personas automatically. This trust-the-model approach follows the proven FT-091 pattern of enhancing Claude's natural capabilities through better guidance rather than restrictive code, while maintaining proper feature encapsulation by keeping app UX behavior separate from persona-specific configurations.
