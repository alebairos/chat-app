# FT-221: Conversation Context Conditional Fix

**Feature ID:** FT-221  
**Priority:** Critical  
**Category:** Bug Fix / Context Optimization  
**Effort Estimate:** 30 minutes  
**Status:** Specification  
**Created:** 2025-10-25  
**Related Features:** FT-200, FT-206, FT-220

---

## 📋 Problem Statement

### **Issue**
FT-200 (Conversation Database Queries) is enabled, which removes conversation history from the messages array. However, `_buildSystemPrompt()` still unconditionally includes conversation context via `_buildRecentConversationContext()`, creating disconnected information that causes "mental fog" in the model.

### **Symptoms**
- ✅ Messages array contains ONLY current user message (FT-200 behavior)
- ❌ System prompt contains 20 messages of conversation context
- ❌ Model sees conversation in system prompt but not in message flow
- ❌ Results in repetitive responses, poor continuity, confused behavior

### **Evidence from Context Logs (FT-220)**
```
flutter: 🔍 [FT-200] Using conversation database queries - no history injection
flutter: ℹ️ [INFO] System prompt includes: ## RECENT CONVERSATION (20 messages)
```

**Root Cause**: System prompt building logic doesn't respect FT-200 toggle state.

---

## 💡 Solution

### **Core Principle**
System prompt conversation context should be **conditional** based on FT-200 status:

- **FT-200 Disabled** (Legacy): Include conversation context in system prompt ✅
- **FT-200 Enabled** (Database Queries): Exclude conversation context from system prompt ✅

This ensures **coherent information architecture**:
- Legacy mode: Conversation in both messages array AND system prompt
- Database mode: Clean context, model queries conversation via MCP when needed

---

## 🔧 Implementation

### **File**: `lib/services/claude_service.dart`

### **Method**: `_buildSystemPrompt()`

**Current Code** (Lines ~797-820):
```dart
Future<String> _buildSystemPrompt() async {
  // Generate enhanced time-aware context (FT-060)
  final lastMessageTime = await _getLastMessageTimestamp();
  final timeContext = await TimeContextService.generatePreciseTimeContext(
    lastMessageTime,
  );

  // FT-206: Add recent conversation context (simplified format)
  final conversationContext = await _buildRecentConversationContext();  // ❌ ALWAYS runs

  // Build enhanced system prompt with time context
  String systemPrompt = _systemPrompt ?? '';

  // FT-206: Simple structure (like 2.0.1)
  // 1. Add conversation context first
  if (conversationContext.isNotEmpty) {  // ❌ ALWAYS added if not empty
    systemPrompt = '$conversationContext\n\n$systemPrompt';
  }
  
  // ... rest of method
}
```

**Fixed Code**:
```dart
Future<String> _buildSystemPrompt() async {
  // Generate enhanced time-aware context (FT-060)
  final lastMessageTime = await _getLastMessageTimestamp();
  final timeContext = await TimeContextService.generatePreciseTimeContext(
    lastMessageTime,
  );

  // FT-221: Add conversation context ONLY if FT-200 is disabled (legacy mode)
  String conversationContext = '';
  if (!await _isConversationDatabaseEnabled()) {
    conversationContext = await _buildRecentConversationContext();
  }

  // Build enhanced system prompt with time context
  String systemPrompt = _systemPrompt ?? '';

  // FT-206: Simple structure (like 2.0.1)
  // 1. Add conversation context first (only in legacy mode)
  if (conversationContext.isNotEmpty) {
    systemPrompt = '$conversationContext\n\n$systemPrompt';
  }
  
  // 2. Add time context at the beginning
  if (timeContext.isNotEmpty) {
    systemPrompt = '$timeContext\n\n$systemPrompt';
  }

  // 3. Add session MCP context
  if (_systemMCP != null) {
    String sessionMcpContext = '\n\n## SESSION CONTEXT\n'
        '**Current Session**: Active MCP functions available\n'
        '**Data Source**: Real-time database queries\n'
        '**Temporal Context**: Use current time for accurate day calculations\n\n'
        '**Session Functions**:\n'
        '- get_current_time: Current temporal information\n'
        '- get_device_info: Device and system information\n'
        '- get_activity_stats: Activity tracking data\n'
        '- get_message_stats: Chat statistics\n'
        '- get_conversation_context: Query conversation history\n\n'
        '**Session Rules**:\n'
        '- Always use fresh data from MCP commands\n'
        '- Query conversation history via get_conversation_context when needed\n'
        '- Never rely on pre-loaded conversation memory\n'
        '- Calculate precise temporal offsets based on current time\n'
        '- Present data naturally while maintaining accuracy';

    systemPrompt += sessionMcpContext;
  }

  return systemPrompt;
}
```

### **Key Changes**
1. **Line ~806**: Add conditional check before building conversation context
2. **Line ~807**: Only call `_buildRecentConversationContext()` if FT-200 is disabled
3. **Session MCP Context**: Update to mention `get_conversation_context` command

---

## 📊 Expected Behavior

### **Scenario A: FT-200 Disabled (Legacy Mode)**

**Configuration**: `conversation_database_config.json` → `"enabled": false`

**Messages Array**:
```dart
[
  {'role': 'user', 'content': 'message 1'},
  {'role': 'assistant', 'content': 'response 1'},
  {'role': 'user', 'content': 'message 2'},
  // ... 25 messages total
  {'role': 'user', 'content': 'current message'}
]
```

**System Prompt**:
```
## RECENT CONVERSATION
A minute ago: User: "message 2"
2 minutes ago: [I-There 4.2]: "response 1"
...

[Time Context]
[Persona Configuration]
[Session MCP Context]
```

**Result**: ✅ Coherent - conversation in both messages array AND system prompt

---

### **Scenario B: FT-200 Enabled (Database Queries)**

**Configuration**: `conversation_database_config.json` → `"enabled": true`

**Messages Array**:
```dart
[
  {'role': 'user', 'content': 'current message'}
]
```

**System Prompt**:
```
[Time Context]
[Persona Configuration]
[Session MCP Context]
  - get_conversation_context: Query conversation history
```

**Result**: ✅ Coherent - clean context, model queries conversation via MCP when needed

---

## ✅ Benefits

### **1. Eliminates "Mental Fog"**
- ✅ Information is now **conexa, estruturada, inter-relacionada** (connected, structured, interrelated)
- ✅ No more disconnected data (conversation in system prompt but not in messages)
- ✅ Model has clear, coherent context in both modes

### **2. Respects FT-200 Architecture**
- ✅ Legacy mode: Full history injection (proven, stable)
- ✅ Database mode: Clean context with on-demand queries (scalable, efficient)
- ✅ Proper separation of concerns

### **3. Fixes Repetition Bug**
- ✅ Model no longer confused by seeing conversation in system prompt but not in flow
- ✅ Responses are contextually aware and non-repetitive
- ✅ Persona switching works correctly

### **4. Token Efficiency**
- ✅ FT-200 enabled: Saves ~500-800 tokens per request (no conversation context in system prompt)
- ✅ FT-200 disabled: Same as before (no change)
- ✅ Optimal token usage for each mode

---

## 🧪 Testing

### **Test 1: FT-200 Disabled (Legacy Mode)**

**Setup**:
```json
// conversation_database_config.json
{"enabled": false}
```

**Test**:
1. Send message: "opa"
2. Send follow-up: "vamos continuar a conversa anterior?"

**Expected**:
- ✅ System prompt includes conversation context
- ✅ Messages array includes full history
- ✅ Model responds with continuity

---

### **Test 2: FT-200 Enabled (Database Queries)**

**Setup**:
```json
// conversation_database_config.json
{"enabled": true}
```

**Test**:
1. Send message: "opa"
2. Send follow-up: "vamos continuar a conversa anterior?"

**Expected**:
- ✅ System prompt does NOT include conversation context
- ✅ Messages array contains only current message
- ✅ Model responds naturally (no repetition)
- ✅ Model can query conversation via MCP if needed

---

### **Test 3: Repetition Bug Fix**

**Setup**: FT-200 enabled

**Test**:
1. Send message: "me ajuda nos pomodoros?"
2. Model responds
3. Send: "aviso sim"
4. Model responds

**Expected**:
- ✅ No repetition of previous response
- ✅ Natural conversation flow
- ✅ Contextually aware responses

---

### **Test 4: Context Logging Verification (FT-220)**

**Setup**: Enable context logging

**Test**:
1. Send any message with FT-200 enabled
2. Check logged context

**Expected**:
- ✅ System prompt does NOT contain "## RECENT CONVERSATION"
- ✅ Messages array contains only current message
- ✅ Logs show: "FT-200: Using conversation database queries - no history injection"

---

## 📈 Performance Impact

### **Token Savings (FT-200 Enabled)**

| Component | Before Fix | After Fix | Savings |
|-----------|------------|-----------|---------|
| **Messages Array** | Current only | Current only | 0 |
| **System Prompt** | +500-800 tokens | 0 | 500-800 |
| **Total per Request** | ~9,000 tokens | ~8,200 tokens | ~9% |

### **Cost Savings (FT-200 Enabled)**

| Volume | Before Fix | After Fix | Savings |
|--------|------------|-----------|---------|
| 100 messages | $2.70 | $2.46 | $0.24 (9%) |
| 1,000 messages | $27.00 | $24.60 | $2.40 (9%) |
| 10,000 messages | $270.00 | $246.00 | $24.00 (9%) |

**Note**: Savings apply only when FT-200 is enabled. Legacy mode unchanged.

---

## 🚀 Deployment

### **Steps**

1. **Implement Fix**
   ```bash
   # Edit lib/services/claude_service.dart
   # Add conditional check in _buildSystemPrompt()
   ```

2. **Run Tests**
   ```bash
   flutter test
   ```

3. **Manual Testing**
   - Test with FT-200 enabled
   - Test with FT-200 disabled
   - Verify no repetition bugs

4. **Deploy**
   ```bash
   git add lib/services/claude_service.dart
   git commit -m "FT-221: Fix conversation context conditional logic
   
   - Make conversation context conditional on FT-200 status
   - Eliminates mental fog from disconnected information
   - Fixes repetition bug
   - Improves token efficiency when FT-200 enabled"
   ```

---

## 🔍 Verification

### **Success Criteria**

- ✅ FT-200 disabled: Conversation context in system prompt
- ✅ FT-200 enabled: No conversation context in system prompt
- ✅ No repetition bugs
- ✅ Natural conversation flow
- ✅ All tests pass
- ✅ Context logs show correct behavior (FT-220)

### **Monitoring**

Use FT-220 context logging to verify:
1. System prompt structure (with/without conversation context)
2. Messages array content (full history vs current only)
3. Token usage (before/after comparison)
4. Model response quality

---

## 📝 Related Documentation

- **FT-200**: Conversation History Database Queries (parent feature)
- **FT-206**: Context Optimization & Pattern Detection (related)
- **FT-220**: Context Logging for Debugging (monitoring tool)
- **FT-221**: This fix (conversation context conditional logic)

---

## 🎯 Conclusion

FT-221 fixes a critical architectural inconsistency where system prompt conversation context was not respecting FT-200 toggle state. The fix ensures:

1. ✅ **Coherent Information Architecture**: Context is consistent across messages array and system prompt
2. ✅ **Eliminates Mental Fog**: No more disconnected information causing model confusion
3. ✅ **Fixes Repetition Bug**: Model responds naturally without repetition
4. ✅ **Improves Token Efficiency**: 9% savings when FT-200 enabled
5. ✅ **Respects Feature Toggle**: Proper conditional logic based on configuration

**Implementation Time**: 30 minutes  
**Risk Level**: Very Low (single conditional check)  
**Impact**: High (fixes critical bug, improves UX)  
**Ready for Implementation**: ✅ Yes

---

**Created**: 2025-10-25  
**Status**: Ready for Implementation  
**Estimated Completion**: 30 minutes

