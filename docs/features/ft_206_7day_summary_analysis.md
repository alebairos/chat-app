# FT-206: 7-Day Summary Request - Context Analysis

**Date**: 2025-10-25  
**Branch**: `fix/ft-206-quick-revert-to-simplicity`  
**Analysis Type**: MCP Command Intelligence Evaluation  
**Context Log**: `ctx_018_1761367105733.json`

---

## 📊 Executive Summary

**Status**: ⚠️ **CRITICAL ISSUE** - MCP intelligence layer not working

### Key Finding:
When the user requested "Me da um resumo dos ultimas 7 dias" (Give me a summary of the last 7 days), Aristios **DID NOT** generate the appropriate MCP command to fetch historical activity data.

---

## 🔍 Detailed Analysis

### **User Request**
```
"Voltei. Me da um resumo dos ultimas 7 dias"
```
Translation: "I'm back. Give me a summary of the last 7 days"

### **Expected Behavior**
The persona should have:
1. **Recognized** the temporal query pattern ("ultimas 7 dias")
2. **Generated MCP command**: `{"action": "get_activity_stats", "days": 7}`
3. **Waited** for the data response
4. **Provided** a comprehensive summary based on actual data

### **Actual Behavior**
Aristios responded **WITHOUT** generating any MCP command:
- ✅ Acknowledged the request naturally ("deixa eu verificar seus registros dos últimos 7 dias...")
- ❌ **Did NOT generate MCP command**
- ❌ Only reported today's data (already in recent conversation context)
- ❌ Stated "não encontro registros de atividades dos dias anteriores no sistema"

---

## 🧠 Context Analysis

### **System Prompt Structure** (Simplified - Post Quick Revert)

**1. Time Context** (at the top):
```
Current context: Today is sábado, 25 de outubro de 2025 às 01:38.
```

**2. Recent Conversation Context**:
- 20 messages loaded
- Includes all recent interactions with Tony and Aristios
- Shows today's activities mentioned in conversation

**3. Core Behavioral Rules**:
- ✅ Data Integrity: "SEMPRE USAR PARA DADOS EXATOS - NUNCA USE DADOS APROXIMADOS"
- ✅ "NEVER rely on conversation memory for activity data - ALWAYS query fresh data"
- ✅ MCP Command Priority: "SYSTEM LAW #5: MANDATORY CONVERSATION AWARENESS"

**4. MCP Base Config**:
```
**get_activity_stats**:
- Get activity tracking data from database
- Usage: {"action": "get_activity_stats", "days": 7}
```

**5. Session Context**:
```
**Session Functions**:
- get_current_time: Current temporal information
- get_device_info: Device and system information
- get_activity_stats: Activity tracking data
- get_message_stats: Chat statistics

**Session Rules**:
- Always use fresh data from MCP commands
- Never rely on conversation memory for activity data
- Calculate precise temporal offsets based on current time
- Present data naturally while maintaining accuracy
```

---

## ❌ Root Cause Analysis

### **Why MCP Command Was NOT Generated**

**1. Lack of Explicit Pattern Matching**:
- The system prompt does NOT have explicit instructions to detect temporal queries like:
  - "últimos 7 dias"
  - "última semana"
  - "resumo dos últimos X dias"
- The model must infer this from general rules

**2. Instruction Overload Paradox**:
- Despite simplification, the system prompt is still **very long** (16,079 input tokens)
- The MCP instructions are buried deep in the prompt
- The persona's identity, manifesto, and coaching framework dominate the context

**3. Conflicting Instructions**:
- "SYSTEM LAW #5" says "Generate conversation MCP commands BEFORE every response"
- But the examples given are **conversation-focused**:
  - `get_recent_user_messages`
  - `get_current_persona_messages`
  - `search_conversation_context`
- **No mention** of `get_activity_stats` in the mandatory commands list

**4. Recent Conversation Context Interference**:
- The recent conversation already mentions today's activities:
  - "3 pomodoros completos"
  - "400ml de água consumida"
  - "400 metros de caminhada em zona 2"
- The model may have assumed this was sufficient context

**5. Natural Language Ambiguity**:
- "Me da um resumo dos ultimas 7 dias" could be interpreted as:
  - "Summarize the last 7 days of **activities**" (requires MCP)
  - "Summarize the last 7 days of **our conversation**" (already in context)
- The model chose the second interpretation

---

## 🎯 Comparison: What Was Removed vs. What Was Kept

### **Removed in Quick Revert**:
- ❌ **Priority Header** with explicit MCP command triggers
- ❌ **Data Query Pattern Detection** in `_detectDataQueryPattern()`
- ❌ **Proactive MCP instructions** in `_formatInterleavedConversation()`

### **Kept in Quick Revert**:
- ✅ Core Behavioral Rules (including data integrity rules)
- ✅ MCP Base Config (function descriptions)
- ✅ Session Context (MCP functions available)
- ✅ Recent Conversation Context (20 messages)

### **The Missing Link**:
The **Priority Header** that was removed had explicit instructions like:
```
PRIORITY HIERARCHY:
1. MANDATORY DATA QUERIES (HIGHEST PRIORITY)
   - Activity data queries (get_activity_stats)
   - Conversation context queries (get_conversation_context)
   - User message queries (get_recent_user_messages)
   
When user asks about:
- "últimos X dias" → MUST use get_activity_stats
- "última semana" → MUST use get_activity_stats
- "resumo" + temporal reference → MUST use get_activity_stats
```

---

## 📈 Token Analysis

### **Context Size**:
- **Input Tokens**: 16,079
- **Output Tokens**: 204
- **Total**: 16,283 tokens

### **Breakdown** (estimated):
- **Time Context**: ~50 tokens
- **Recent Conversation**: ~1,500 tokens (20 messages)
- **Core Behavioral Rules**: ~500 tokens
- **Persona Configuration**: ~12,000 tokens (Aristios manifesto, coaching framework, Oracle framework)
- **MCP Base Config**: ~300 tokens
- **Session Context**: ~100 tokens
- **Audio Formatting**: ~1,500 tokens

### **Insight**:
The **Persona Configuration** (12,000 tokens) dominates the context, potentially diluting the importance of MCP instructions.

---

## 🔄 Comparison with Working Version (2.0.1)

### **What 2.0.1 Had**:
- **Simpler System Prompt**: ~8,000-10,000 tokens (estimated)
- **Explicit MCP Triggers**: Pattern-based detection
- **Proactive Data Fetching**: Automatic MCP generation for known patterns

### **What Current Version Has**:
- **Simplified but Still Large**: ~16,000 tokens
- **Generic MCP Instructions**: No explicit pattern triggers
- **Reactive Data Fetching**: Model must infer when to use MCP

---

## 💡 Proposed Solutions

### **Option 1: Add Explicit Pattern Triggers (Minimal Change)**
Add a small section to the system prompt:

```markdown
## TEMPORAL QUERY DETECTION (CRITICAL)

When user mentions temporal periods, ALWAYS use MCP commands:
- "últimos X dias" → {"action": "get_activity_stats", "days": X}
- "última semana" → {"action": "get_activity_stats", "days": 7}
- "último mês" → {"action": "get_activity_stats", "days": 30}
- "resumo" + temporal reference → {"action": "get_activity_stats", "days": N}

MANDATORY: Generate MCP command BEFORE responding to temporal queries.
```

**Pros**:
- ✅ Minimal change
- ✅ Explicit and clear
- ✅ Easy to test

**Cons**:
- ⚠️ Adds more instructions (token cost)
- ⚠️ May not cover all edge cases

---

### **Option 2: Restore Pattern Detection in Code (Recommended)**
Restore the `_detectDataQueryPattern()` method in `claude_service.dart`:

```dart
/// FT-206: Detect temporal queries and force MCP command generation
bool _detectDataQueryPattern(String userMessage) {
  final lowerMessage = userMessage.toLowerCase();
  
  // Temporal patterns
  final temporalPatterns = [
    RegExp(r'últim[oa]s?\s+\d+\s+dias?'),
    RegExp(r'última\s+semana'),
    RegExp(r'último\s+mês'),
    RegExp(r'resumo.*\d+\s+dias?'),
    RegExp(r'resumo.*semana'),
    RegExp(r'resumo.*mês'),
  ];
  
  return temporalPatterns.any((pattern) => pattern.hasMatch(lowerMessage));
}
```

Then inject a hint in `_sendMessageInternal()`:

```dart
if (_detectDataQueryPattern(userMessage)) {
  userMessage += '\n\n[SYSTEM HINT: This query requires historical data. Use get_activity_stats MCP command.]';
}
```

**Pros**:
- ✅ **Deterministic** - guaranteed to work
- ✅ **No token cost** - hint is small
- ✅ **Scalable** - easy to add more patterns
- ✅ **Testable** - can write unit tests

**Cons**:
- ⚠️ Requires code change (not just prompt)
- ⚠️ May feel like "hard-coding"

---

### **Option 3: Two-Pass Architecture (Future)**
Implement a true two-pass flow:
1. **First Pass**: Model analyzes request and generates MCP commands
2. **Data Fetch**: System executes MCP commands
3. **Second Pass**: Model responds with data

**Pros**:
- ✅ **Intelligent** - model decides what data to fetch
- ✅ **Flexible** - works for all query types
- ✅ **Scalable** - no pattern matching needed

**Cons**:
- ❌ **Complex** - requires significant refactoring
- ❌ **Latency** - two API calls per message
- ❌ **Cost** - double token usage

---

## 🎯 Recommended Immediate Action

**Implement Option 2: Restore Pattern Detection**

### **Why**:
1. **Quick Win**: Can be implemented in 30 minutes
2. **Deterministic**: Guaranteed to work for known patterns
3. **Low Risk**: Minimal code change, easy to test
4. **Scalable**: Easy to add more patterns as needed

### **Implementation Steps**:
1. Add `_detectDataQueryPattern()` method to `claude_service.dart`
2. Inject system hint in `_sendMessageInternal()` when pattern detected
3. Test with various temporal queries
4. Commit and push

### **Expected Result**:
When user says "Me da um resumo dos ultimas 7 dias", the system will:
1. Detect the pattern
2. Inject hint: `[SYSTEM HINT: This query requires historical data. Use get_activity_stats MCP command.]`
3. Model generates: `{"action": "get_activity_stats", "days": 7}`
4. System fetches data
5. Model responds with comprehensive 7-day summary

---

## 📝 Testing Plan

### **Test Cases**:
1. "Me da um resumo dos últimos 7 dias"
2. "Como foi minha última semana?"
3. "Resumo dos últimos 30 dias"
4. "O que eu fiz nos últimos 3 dias?"
5. "Atividades da última semana"

### **Expected Behavior**:
- ✅ MCP command generated for each query
- ✅ Comprehensive summary based on actual data
- ✅ Natural language response (no meta-commentary)

---

## 🔗 Related Issues

- **FT-084**: Two-Pass Data Integration (existing feature for data queries)
- **FT-206**: System Prompt Simplification (this fix)
- **FT-220**: Context Logging (used for this analysis)

---

## 📊 Success Metrics

### **Before Fix**:
- ❌ 0% success rate on temporal queries
- ❌ Model only reports conversation context
- ❌ No MCP commands generated

### **After Fix** (Expected):
- ✅ 100% success rate on known temporal patterns
- ✅ Model fetches and reports actual activity data
- ✅ MCP commands generated automatically

---

## 🎉 Conclusion

The **Quick Revert** successfully simplified the system prompt and improved conversation continuity, but it **removed the intelligence layer** that was responsible for detecting temporal queries and forcing MCP command generation.

**The fix is straightforward**: Restore pattern detection in code (Option 2) to ensure deterministic behavior for known query patterns.

This is a **high-priority fix** because:
1. **User Expectation**: Users expect the system to provide historical data when requested
2. **Core Feature**: Activity tracking and summarization is a core feature of the app
3. **Easy Fix**: Can be implemented quickly with minimal risk

---

**Next Steps**:
1. Implement Option 2 (Pattern Detection)
2. Test with various temporal queries
3. Commit and push
4. Update this document with results

