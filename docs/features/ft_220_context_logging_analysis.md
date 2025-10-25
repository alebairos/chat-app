# FT-220: Context Logging Analysis - Long-Term Memory Investigation

**Date:** October 25, 2025  
**Status:** Analysis Complete  
**Related Features:** FT-200, FT-206, FT-220, FT-221

---

## Executive Summary

Analysis of context logs revealed why time and activity detection MCPs work automatically while conversation history queries fail. The root cause is **architectural**: some MCP commands are called automatically by the codebase, while others require the model to explicitly generate them in responses.

### Key Findings

✅ **Working:** Time context (`get_current_time`) and activity detection (`oracle_detect_activities`)  
❌ **Not Working:** Conversation history queries (`get_conversation_context`)  
🔍 **Root Cause:** Automatic vs. model-triggered MCP command execution

---

## Context Logging Results (FT-220)

### ✅ What's Working Perfectly

1. **Context Logging Infrastructure**
   - Successfully capturing complete API request/response cycles
   - Clean JSON structure with metadata, API request, and API response
   - Proper file organization by session
   - API key redaction working correctly
   - File sizes reasonable (~100-130KB per context)

2. **Recent Conversation Memory (12-18 hours)**
   - Message count: 40-54 messages in array
   - Recent conversation summary in system prompt (last ~20 messages)
   - Accurate time context and persona tracking
   - No repetition or "mental fog" issues

3. **Activity Tracking**
   - Accurate tracking for today and yesterday
   - Proper activity detection via Oracle MCP
   - Correct aggregation and reporting

### ❌ Long-Term Memory Issue

**Problem:** Model cannot access conversations older than ~12-18 hours

**Evidence from Context Log (ctx_015):**
```json
{
  "metadata": {
    "context_id": "ctx_015_1761421147054",
    "message_number": 15,
    "timestamp": "2025-10-25T16:39:07"
  },
  "api_request": {
    "body": {
      "messages": 54,  // Only covers Saturday 01:35 AM onwards
      "system": "Current context: Today is sábado, 25 de outubro de 2025 às 16:39..."
    }
  }
}
```

**Oldest message in array:** "Voltei. Me da um resumo dos ultimas 7 dias" (Saturday 01:35 AM)

**Missing conversations:**
- ❌ Wednesday (Oct 22) - Sleep schedule, gym plans with Tony
- ❌ Thursday (Oct 23) - Work discussions, daughter's bedtime, spiritual conversations
- ❌ Early Friday (Oct 24) - Most of the day's activities

**Model's response was ACCURATE:**
> "Pelos registros que consigo acessar, nossas interações mais antigas documentadas começam ontem [Friday]..."

The model correctly identified it only has access to Friday night onwards.

---

## MCP Command Architecture Analysis

### Category 1: AUTOMATIC MCPs (100% Success Rate)

These are **called by the codebase**, not by the model:

#### 1. `get_current_time` - Time Context

**Trigger:** Automatic before every API request  
**Called by:** `TimeContextService.generatePreciseTimeContext()`  
**Location:** `claude_service.dart:802`

```dart
Future<String> _buildSystemPrompt() async {
  // Generate enhanced time-aware context (FT-060)
  final lastMessageTime = await _getLastMessageTimestamp();
  final timeContext = await TimeContextService.generatePreciseTimeContext(
    lastMessageTime,  // ← AUTOMATICALLY calls get_current_time
  );
  // ...
}
```

**Execution Flow:**
```
User sends message
  ↓
_sendMessageInternal()
  ↓
_buildSystemPrompt()
  ↓
TimeContextService.generatePreciseTimeContext()
  ↓
_getCurrentTimeData()
  ↓
SystemMCPService.processCommand('{"action":"get_current_time"}')  ← AUTOMATIC
  ↓
Time data injected into system prompt
```

**Log Evidence:**
```
flutter: ℹ️ [INFO] 🔍 [FT-203] SystemMCP: Processing command: {"action":"get_current_time"}
flutter: ℹ️ [INFO] SystemMCP: Current time retrieved successfully
flutter: ℹ️ [INFO] FT-060: ⏰ Current time data retrieved:
flutter: ℹ️ [INFO]   📅 Date: Saturday, sábado, 25 de outubro de 2025 às 16:39
```

#### 2. `oracle_detect_activities` - Activity Detection

**Trigger:** Automatic after every user message  
**Called by:** `_progressiveActivityDetection()`  
**Location:** `claude_service.dart:1338`

```dart
Future<void> _analyzeUserActivities(String userMessage, String messageId) async {
  // FT-140: Use progressive activity detection
  await _progressiveActivityDetection(userMessage, messageId);  // ← AUTOMATIC
}
```

**Execution Flow:**
```
User sends message
  ↓
_sendMessageInternal()
  ↓
API response received
  ↓
_analyzeUserActivities()  ← AUTOMATIC (called after response)
  ↓
_progressiveActivityDetection()
  ↓
_mcpOracleActivityDetection()
  ↓
SystemMCPService.processCommand('{"action":"oracle_detect_activities"}')  ← AUTOMATIC
  ↓
Activities detected and saved to database
```

**Log Evidence:**
```
flutter: ℹ️ [INFO] 🔍 [FT-203] SystemMCP: Processing command: {"action":"oracle_detect_activities","message":"..."}
flutter: ℹ️ [INFO] SystemMCP: Oracle detection completed - 0 activities detected
flutter: ℹ️ [INFO] FT-140: ✅ Detected 0 activities via MCP Oracle detection
```

---

### Category 2: MODEL-TRIGGERED MCPs (0-50% Success Rate)

These require **the model to explicitly generate them** in its response:

#### 3. `get_conversation_context` - Conversation History

**Trigger:** Model must include command in response  
**Success Rate:** 0% (never called)  
**Problem:** Model doesn't generate the command

**System Prompt Instructions:**
```markdown
**Session Functions**:
- get_conversation_context: Query conversation history

**Session Rules**:
- Query conversation history via get_conversation_context when needed
- Never rely on pre-loaded conversation memory
```

**Pattern Detection (FT-206):**
```
[SYSTEM HINT: Conversation history query detected. Use: {"action": "get_conversation_context", "hours": 168}]
```

**Expected Flow (NOT HAPPENING):**
```
User: "What did we talk about on Wednesday?"
  ↓
Model receives system prompt with MCP instructions
  ↓
Model SHOULD respond: {"action": "get_conversation_context", "hours": 72}
  ↓
_processMCPCommands() detects and executes it
  ↓
Conversation history retrieved and inserted into response
```

**Actual Flow:**
```
User: "What did we talk about on Wednesday?"
  ↓
Model receives system prompt + pattern hint
  ↓
Model responds: "I only have access to recent conversations..."
  ↓
No MCP command generated
  ↓
No conversation history retrieved
```

**Why It Fails:**
1. Model sees MCP instructions in system prompt ✅
2. Pattern detection injects helpful hints ✅
3. Model understands it should query history ✅
4. Model **doesn't generate the JSON command** ❌
5. Model explains its limitations instead ❌

#### 4. `get_activity_stats` - Activity Queries

**Trigger:** Model must include command in response  
**Success Rate:** ~50% (sometimes works)  
**Behavior:** Inconsistent - model sometimes generates it, sometimes doesn't

---

## Comparison Table

| MCP Command | Trigger Type | Called By | Success Rate | Why It Works/Fails |
|-------------|--------------|-----------|--------------|-------------------|
| `get_current_time` | **Automatic** | TimeContextService | 100% | Called before every API request by code |
| `oracle_detect_activities` | **Automatic** | _progressiveActivityDetection | 100% | Called after every user message by code |
| `get_conversation_context` | **Model-triggered** | Model must generate | 0% | Model doesn't generate the command |
| `get_activity_stats` | **Model-triggered** | Model must generate | ~50% | Model sometimes generates it |

---

## Root Causes

### 1. Message Array Truncation

**Current Behavior:**
- Conversation history limited to ~54 messages
- Covers approximately 12-18 hours
- Older messages not included in messages array

**Code Location:** `claude_service.dart` - conversation history loading

**Impact:**
- Model has no direct access to conversations > 12-18 hours old
- Cannot answer questions about Wednesday/Thursday conversations
- Activity data from older days not visible

### 2. Model Not Using MCP Commands

**Problem:** Despite clear instructions and hints, the model doesn't generate MCP commands for conversation history.

**System Prompt Weakness:**
```markdown
**Session Rules**:
- Query conversation history via get_conversation_context when needed
```

This is too vague. The model needs:
- Explicit examples of when/how to use commands
- Clear formatting requirements
- Understanding that commands will be replaced with data

### 3. No Proactive Context for Older Periods

**Current:** System prompt only includes last ~20 messages (recent context)  
**Missing:** Summaries or pointers to older conversation periods

---

## Solutions

### Option A: Increase Message History Window (Quick Fix)

**Implementation:**
```dart
// In claude_service.dart
final messages = await _storageService!.getMessages(
  limit: 100, // Increase from ~54 to 100-150
);
```

**Pros:**
- Simple, immediate fix
- Covers 2-3 days of conversation
- No model training needed

**Cons:**
- Higher token usage (~5,000 additional tokens)
- Still limited to 2-3 days
- Doesn't scale for longer histories

**Token Impact:**
- Current: ~54 messages × 100 tokens = ~5,400 tokens
- Proposed: ~100 messages × 100 tokens = ~10,000 tokens
- Increase: ~4,600 tokens per request

---

### Option B: Automatic Conversation Summaries (Recommended)

**Implementation:**
```dart
Future<String> _buildSystemPrompt() async {
  // ... existing code ...
  
  // Add automatic summaries for older periods
  if (lastMessageTime != null) {
    final hoursSinceLastMessage = 
        DateTime.now().difference(lastMessageTime).inHours;
    
    if (hoursSinceLastMessage > 24) {
      // Add summary of older conversations
      final olderContext = await _buildOlderConversationSummary(
        startHours: 24,
        endHours: 168, // Last week
      );
      if (olderContext.isNotEmpty) {
        systemPrompt = '$olderContext\n\n$systemPrompt';
      }
    }
  }
  
  // ... rest of code ...
}

Future<String> _buildOlderConversationSummary(
  int startHours, 
  int endHours
) async {
  // Get messages from older period
  final messages = await _storageService!.getMessagesInTimeRange(
    start: DateTime.now().subtract(Duration(hours: endHours)),
    end: DateTime.now().subtract(Duration(hours: startHours)),
  );
  
  if (messages.isEmpty) return '';
  
  // Group by day and create summaries
  final summaries = <String>[];
  final groupedByDay = _groupMessagesByDay(messages);
  
  for (var entry in groupedByDay.entries) {
    final dayName = _formatDayName(entry.key);
    final topics = _extractTopics(entry.value);
    final activities = _extractActivities(entry.value);
    
    summaries.add(
      '$dayName: Topics: ${topics.join(", ")}. '
      'Activities: ${activities.length} recorded.'
    );
  }
  
  return '''## OLDER CONVERSATION HISTORY
${summaries.join('\n')}

For detailed information about these conversations, use: {"action": "get_conversation_context", "hours": N}''';
}
```

**Pros:**
- Provides context for older periods
- Low token usage (summaries only)
- Scales to weeks/months of history
- Maintains awareness of past conversations

**Cons:**
- Requires implementation of summary generation
- May lose some detail in summaries

**Token Impact:**
- Summary: ~200-500 tokens (vs. ~5,000 for full messages)
- Net savings: ~4,500 tokens while maintaining awareness

---

### Option C: Improve MCP Command Training

**Add explicit examples in system prompt:**

```markdown
## MEMORY ACCESS - CRITICAL INSTRUCTIONS

Your conversation memory is stored in a database. The messages array only contains
recent context (last 12-18 hours). For anything older, you MUST query the database.

### When to Query

1. User asks about past conversations: "What did we talk about on Wednesday?"
2. User requests summaries: "Give me a summary of last week"
3. User references older activities: "How much water did I drink this week?"

### How to Query

Include these JSON commands in your response. The system will replace them with data:

**Example 1: Conversation History**
User: "What did we talk about on Wednesday?"
Your response: Let me check our conversation history.
{"action": "get_conversation_context", "hours": 72}
[System replaces this with actual conversation data]

**Example 2: Activity Summary**
User: "Give me a summary of last week"
Your response: Here's your weekly summary:
{"action": "get_activity_stats", "days": 7}
[System replaces this with activity data]

### IMPORTANT
- Always include the JSON command when querying
- The command will be replaced with actual data
- Continue your response naturally after the command
- Don't apologize for not having access - just query!
```

**Pros:**
- Teaches model to use existing infrastructure
- No code changes needed
- Scalable to any time period

**Cons:**
- Relies on model following instructions
- May not work 100% of the time
- Requires testing and iteration

---

### Option D: Hybrid Approach (Best Solution)

**Combine all three approaches:**

1. **Increase message window to 100** (covers 2-3 days)
2. **Add automatic summaries** for older periods (4-7 days back)
3. **Improve MCP training** with explicit examples

**Implementation Priority:**
1. Quick win: Increase message limit to 100 ✅
2. Add older conversation summaries ✅
3. Enhance MCP instructions with examples ✅

**Expected Results:**
- ✅ Immediate context: Last 2-3 days (100 messages)
- ✅ Awareness: Last 7 days (via summaries)
- ✅ On-demand: Any time period (via MCP queries)
- ✅ Token efficient: ~6,000 tokens total (vs. 10,000+ for full history)

---

## Recommendations

### Immediate Actions (Today)

1. **Increase message history limit**
   ```dart
   // claude_service.dart, line ~857
   final messages = await _storageService!.getMessages(limit: 100);
   ```

2. **Test conversation quality**
   - Verify model can access 2-3 days of history
   - Check token usage impact
   - Confirm no performance degradation

### Short-term (This Week)

3. **Implement automatic summaries**
   - Create `_buildOlderConversationSummary()` method
   - Add to system prompt building
   - Test with 7-day conversation history

4. **Enhance MCP instructions**
   - Add explicit examples to system prompt
   - Include formatting requirements
   - Show expected command/response flow

### Long-term (Next Sprint)

5. **Monitor and optimize**
   - Track MCP command success rates
   - Measure token usage vs. conversation quality
   - Iterate on summary generation

6. **Consider FT-200 re-enablement**
   - Once MCP commands work reliably
   - Implement proactive context strategy
   - Test with real users

---

## Conclusion

The context logging analysis revealed that **architectural design** determines MCP success:

- ✅ **Automatic MCPs** (time, activity detection) work perfectly because they're called by code
- ❌ **Model-triggered MCPs** (conversation history) fail because the model doesn't generate them

The solution is a **hybrid approach**:
1. Increase direct message access (100 messages = 2-3 days)
2. Add automatic summaries for older periods (4-7 days)
3. Train model to use MCP commands for deep queries (any time period)

This provides the best balance of:
- **Immediate context** (recent conversations)
- **Historical awareness** (older periods via summaries)
- **On-demand access** (MCP queries for details)
- **Token efficiency** (~6,000 tokens vs. 10,000+)

**Next Steps:** Implement Option D (Hybrid Approach) starting with quick wins today.

---

## Appendix: Context Log Examples

### Example 1: Successful Time MCP (Automatic)

**Log Entry:**
```
flutter: ℹ️ [INFO] FT-060: Generating precise time context
flutter: ℹ️ [INFO] SystemMCP: Processing command: {"action":"get_current_time"}
flutter: ℹ️ [INFO] SystemMCP: Current time retrieved successfully
flutter: ℹ️ [INFO] FT-060: ⏰ Current time data retrieved:
flutter: ℹ️ [INFO]   📅 Date: Saturday, sábado, 25 de outubro de 2025 às 16:39
flutter: ℹ️ [INFO]   🕐 Time: 16:39:07 (afternoon)
```

**Result:** Time context automatically injected into system prompt ✅

### Example 2: Successful Activity Detection MCP (Automatic)

**Log Entry:**
```
flutter: ℹ️ [INFO] SystemMCP: Processing command: {"action":"oracle_detect_activities","message":"..."}
flutter: ℹ️ [INFO] SystemMCP: Oracle detection completed - 0 activities detected
flutter: ℹ️ [INFO] FT-140: ✅ Detected 0 activities via MCP Oracle detection
```

**Result:** Activity detection automatically executed after user message ✅

### Example 3: Failed Conversation History MCP (Model-triggered)

**User Message:**
```
"quais são as memórias mais antigas que vc tem da nossa conversa? 
quero testar sua memória de longo prazo"
```

**Pattern Detection:**
```
[SYSTEM HINT: Conversation history query detected. 
Use: {"action": "get_conversation_context", "hours": 168}]
```

**Model Response:**
```
Pelos registros que consigo acessar, nossas interações mais antigas 
documentadas começam ontem, quando você estava trabalhando no sistema 
de contexto...

Não encontro registros de conversas anteriores a ontem no sistema.
```

**Result:** Model explained limitations instead of querying database ❌  
**Missing:** No MCP command generated in response

---

**Document Version:** 1.0  
**Last Updated:** October 25, 2025  
**Author:** Context Logging Analysis (FT-220)

