# FT-206: Working Version vs Current Implementation Comparison

**Date**: 2025-10-24  
**Working Version**: aa8d769 (v2.0.1, build 25) - "Pre-refactoring backup: FT-174 goals implementation"  
**Current Version**: develop branch (v2.3.1, build 28+)  

---

## 🎯 Key Finding

**The working version (aa8d769) had a MUCH SIMPLER system prompt structure** compared to the current implementation.

---

## 📊 Comparison: `_buildSystemPrompt()` Method

### **Working Version (aa8d769)** ✅

```dart
Future<String> _buildSystemPrompt() async {
  final lastMessageTime = await _getLastMessageTimestamp();
  final timeContext = await TimeContextService.generatePreciseTimeContext(lastMessageTime);
  final conversationContext = await _buildRecentConversationContext();
  
  String systemPrompt = _systemPrompt ?? '';
  
  // 1. Add conversation context first
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
        '- get_message_stats: Chat statistics\n\n'
        '**Session Rules**:\n'
        '- Always use fresh data from MCP commands\n'
        '- Never rely on conversation memory for activity data\n'
        '- Calculate precise temporal offsets based on current time\n'
        '- Present data naturally while maintaining accuracy';
    
    systemPrompt += sessionMcpContext;
  }
  
  return systemPrompt;
}
```

**Structure**:
1. Time Context
2. Conversation Context (simple format)
3. Original System Prompt (persona + Oracle)
4. Session MCP Context

**Total Additional Lines**: ~30-40 lines

---

### **Current Version (develop)** ❌

```dart
Future<String> _buildSystemPrompt() async {
  final lastMessageTime = await _getLastMessageTimestamp();
  final timeContext = await TimeContextService.generatePreciseTimeContext(lastMessageTime);
  final conversationContext = await _buildRecentConversationContext();
  
  String systemPrompt = _systemPrompt ?? '';
  final isOracleEnabled = _systemMCP?.isOracleEnabled ?? false;
  
  // 1. Add 50+ line priority header
  final priorityHeader = '''
## 🎯 INSTRUCTION PRIORITY HIERARCHY

**PRIORITY 1 (ABSOLUTE)**: Data Query Intelligence (MANDATORY)
[... 20 lines of instructions ...]

**PRIORITY 2 (ABSOLUTE)**: Time Awareness (MANDATORY)
[... 3 lines ...]

**PRIORITY 3 (HIGHEST)**: Core Behavioral Rules & Persona Configuration
[... 3 lines ...]

**PRIORITY 4 (ORACLE FRAMEWORK)**: Oracle 4.2 Framework
[... 5 lines ...]

**PRIORITY 5**: Conversation Context (REFERENCE ONLY)
[... 4 lines ...]

**PRIORITY 6**: User's Current Message (PRIMARY FOCUS)
[... 3 lines ...]
''';
  
  // 2. Add conversation context
  if (conversationContext.isNotEmpty) {
    systemPrompt = '$conversationContext\n\n$systemPrompt';
  }
  
  // 3. Add time context
  if (timeContext.isNotEmpty) {
    systemPrompt = '$timeContext\n\n$systemPrompt';
  }
  
  // 4. Add priority header at the very beginning
  systemPrompt = '$priorityHeader$systemPrompt';
  
  // 5. Add session MCP context
  [... same as working version ...]
  
  return systemPrompt;
}
```

**Structure**:
1. **Priority Header (50+ lines)** ← NEW, NOT IN WORKING VERSION
2. Time Context
3. Conversation Context (with 50+ lines of instructions)
4. Original System Prompt (persona + Oracle)
5. Session MCP Context

**Total Additional Lines**: ~150+ lines (vs ~30-40 in working version)

---

## 📊 Comparison: `_buildRecentConversationContext()` Method

### **Working Version (aa8d769)** ✅

```dart
Future<String> _buildRecentConversationContext() async {
  if (_storageService == null) return '';
  
  try {
    final messages = await _storageService!.getMessages(limit: 30);
    if (messages.isEmpty) return '';
    
    final now = DateTime.now();
    final contextLines = <String>[];
    
    for (final msg in messages.reversed) {
      final timeDiff = now.difference(msg.timestamp);
      final timeAgo = _formatNaturalTime(timeDiff);
      final speaker = msg.isUser ? 'User' : 'You';
      contextLines.add('$timeAgo: $speaker: "${msg.text}"');
    }
    
    return '''## RECENT CONVERSATION
${contextLines.join('\n')}

For deeper conversation history, use: {"action": "get_conversation_context", "hours": N}''';
  } catch (e) {
    return '';
  }
}
```

**Format**:
```
## RECENT CONVERSATION
Just now: User: "sim, quero. Comecei!"
A minute ago: You: "quer começar? vou cronometrar os 25 minutos pra você."
5 minutes ago: User: "me ajuda que vai dar bom"
...

For deeper conversation history, use: {"action": "get_conversation_context", "hours": N}
```

**Total**: ~35 lines for 30 messages

---

### **Current Version (develop)** ❌

```dart
Future<String> _buildRecentConversationContext() async {
  if (!await _isConversationDatabaseEnabled()) return '';
  
  try {
    final config = await _loadConversationDatabaseConfig();
    final isOracleEnabled = _systemMCP?.isOracleEnabled ?? false;
    final limit = isOracleEnabled ? 8 : 10;
    
    final conversation = await _systemMCP!.processCommand(
        '{"action":"get_interleaved_conversation","limit":$limit,"include_all_personas":true}');
    
    return _formatInterleavedConversation(conversation);
  } catch (e) {
    return '';
  }
}

String _formatInterleavedConversation(String mcpResponse) {
  // ... parsing ...
  
  final buffer = StringBuffer();
  buffer.writeln('## 📜 RECENT CONVERSATION CONTEXT (REFERENCE ONLY)');
  buffer.writeln('');
  buffer.writeln('**MANDATORY REVIEW BEFORE RESPONDING**:');
  buffer.writeln('1. What was just discussed in the conversation above?');
  buffer.writeln('2. What did you already say in your previous responses?');
  buffer.writeln('3. What is the user\'s current context and what are they referring to?');
  buffer.writeln('4. CRITICAL: Check if you already gave this exact response - if yes, provide a DIFFERENT response');
  buffer.writeln('');
  buffer.writeln('**YOUR RESPONSE MUST**:');
  buffer.writeln('- Acknowledge and build on recent conversation flow');
  buffer.writeln('- Provide NEW information or insights (NEVER repeat previous responses word-for-word)');
  buffer.writeln('- If user gives a short answer, acknowledge it and move the conversation forward');
  buffer.writeln('- Reference what user mentioned (e.g., if they say "I was talking with X", acknowledge it)');
  buffer.writeln('- Maintain conversation continuity without starting fresh');
  buffer.writeln('');
  buffer.writeln('**NATURAL CONVERSATION FLOW**:');
  buffer.writeln('- Vary your transition phrases and openings between responses');
  buffer.writeln('- Use "deixa eu ver seus registros" ONLY when actually fetching data via MCP');
  buffer.writeln('- When not querying data, acknowledge patterns naturally without implying a data fetch');
  buffer.writeln('- Avoid formulaic phrases (e.g., "Estou aqui pra explorar...") in consecutive messages');
  buffer.writeln('- Lead with what\'s most relevant to the user\'s current message');
  buffer.writeln('- Each response should feel fresh and context-driven, not template-based');
  buffer.writeln('');
  buffer.writeln('**CRITICAL BOUNDARIES**:');
  buffer.writeln('- Activity detection: ONLY current user message');
  buffer.writeln('- Do NOT extract codes or metadata from history');
  buffer.writeln('- Do NOT adopt other personas\' communication styles');
  buffer.writeln('');
  buffer.writeln('---');
  buffer.writeln('');
  
  for (final msg in thread) {
    buffer.writeln('**${msg['speaker']}** (${msg['time_ago']}): ${msg['text']}');
  }
  
  buffer.writeln('');
  buffer.writeln('---');
  buffer.writeln('**REMINDER**: Process activities ONLY from current user message.');
  buffer.writeln('');
  
  return buffer.toString();
}
```

**Format**:
```
## 📜 RECENT CONVERSATION CONTEXT (REFERENCE ONLY)

**MANDATORY REVIEW BEFORE RESPONDING**:
1. What was just discussed in the conversation above?
2. What did you already say in your previous responses?
3. What is the user's current context and what are they referring to?
4. CRITICAL: Check if you already gave this exact response - if yes, provide a DIFFERENT response

**YOUR RESPONSE MUST**:
- Acknowledge and build on recent conversation flow
- Provide NEW information or insights (NEVER repeat previous responses word-for-word)
- If user gives a short answer, acknowledge it and move the conversation forward
- Reference what user mentioned (e.g., if they say "I was talking with X", acknowledge it)
- Maintain conversation continuity without starting fresh

**NATURAL CONVERSATION FLOW**:
- Vary your transition phrases and openings between responses
- Use "deixa eu ver seus registros" ONLY when actually fetching data via MCP
- When not querying data, acknowledge patterns naturally without implying a data fetch
- Avoid formulaic phrases (e.g., "Estou aqui pra explorar...") in consecutive messages
- Lead with what's most relevant to the user's current message
- Each response should feel fresh and context-driven, not template-based

**CRITICAL BOUNDARIES**:
- Activity detection: ONLY current user message
- Do NOT extract codes or metadata from history
- Do NOT adopt other personas' communication styles

---

**[I-There 4.2]** (A minute ago): quer começar? vou cronometrar os 25 minutos pra você.
**User** (Just now): sim, quero. Comecei!
...

---
**REMINDER**: Process activities ONLY from current user message.
```

**Total**: ~60 lines for 8-10 messages (vs ~35 lines for 30 messages in working version)

---

## 🔍 Key Differences

### 1. **Priority Header** (NEW in current, NOT in working)
- **Working**: No priority header
- **Current**: 50+ lines of priority instructions
- **Impact**: Adds cognitive load, creates instruction overload

### 2. **Conversation Context Format**
- **Working**: Simple, clean format with time stamps
  ```
  Just now: User: "message"
  A minute ago: You: "response"
  ```
- **Current**: 50+ lines of instructions BEFORE the actual conversation
- **Impact**: Actual conversation buried under instructions

### 3. **Number of Messages**
- **Working**: 30 messages
- **Current**: 8-10 messages
- **Impact**: Less context, but less noise

### 4. **Instruction Density**
- **Working**: ~30-40 lines of additional context
- **Current**: ~150+ lines of additional context
- **Impact**: 4x more instructions, model confusion

---

## 💡 Key Insights

### **Why Working Version Worked Better**

1. **Simplicity**: Clean, minimal instructions
2. **Clear Hierarchy**: Time → Conversation → Persona → Session
3. **Conversation First**: Actual conversation visible immediately
4. **No Instruction Overload**: Model could focus on conversation, not rules
5. **Natural Format**: Simple speaker/message format

### **Why Current Version Has Issues**

1. **Instruction Overload**: 150+ lines of rules before conversation
2. **Buried Context**: Actual conversation hidden under instructions
3. **Conflicting Priorities**: Multiple "PRIORITY 1" sections
4. **Over-Engineering**: Too many safeguards, too much guidance
5. **Repetitive**: Same concepts repeated multiple times

---

## 🎯 Recommendation

**Option 1: Revert to Working Version Structure** (Quick Fix)
- Remove priority header
- Simplify conversation context format
- Keep only essential session context
- Expected: Immediate improvement

**Option 2: Implement Universal Laws** (Long-term Fix)
- Use 8 Universal Laws framework
- Simplify to ~300 lines total
- Clear hierarchy without repetition
- Expected: Better than working version

**Option 3: Hybrid Approach** (Balanced)
- Keep working version structure
- Add ONLY essential elements from current version
- Minimal priority guidance (5-10 lines max)
- Expected: Best of both worlds

---

## 📋 Specific Changes to Revert

### 1. Remove Priority Header
```dart
// DELETE THIS ENTIRE SECTION (lines 757-808)
final priorityHeader = '''
## 🎯 INSTRUCTION PRIORITY HIERARCHY
...
''';
```

### 2. Simplify Conversation Context
```dart
// REPLACE _formatInterleavedConversation() with simple format
String _formatSimpleConversation(List messages) {
  final contextLines = <String>[];
  final now = DateTime.now();
  
  for (final msg in messages.reversed) {
    final timeDiff = now.difference(msg.timestamp);
    final timeAgo = _formatNaturalTime(timeDiff);
    final speaker = msg.isUser ? 'User' : 'You';
    contextLines.add('$timeAgo: $speaker: "${msg.text}"');
  }
  
  return '''## RECENT CONVERSATION
${contextLines.join('\n')}''';
}
```

### 3. Increase Message Limit
```dart
// Change from 8-10 to 30
final messages = await _storageService!.getMessages(limit: 30);
```

---

## 🧪 Testing Plan

1. **Create test branch**: `fix/ft-206-revert-to-simple-structure`
2. **Revert changes**: Apply working version structure
3. **Test scenario**: Replay message #121 ("sim, quero. Comecei!")
4. **Compare**: Working version vs current vs reverted
5. **Measure**: Repetition rate, context awareness, response quality

---

**Conclusion**: The working version's simplicity was its strength. The current version's attempt to prevent issues through extensive instructions actually created more problems by overwhelming the model with guidance.

**Next Step**: Should we revert to the working version structure, or proceed with Universal Laws implementation?

