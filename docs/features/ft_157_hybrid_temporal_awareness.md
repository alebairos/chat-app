# FT-157: Hybrid Temporal Awareness for Natural Coaching Memory

**Feature ID:** FT-157  
**Priority:** Critical  
**Category:** Memory Enhancement / Coaching Experience  
**Effort Estimate:** 60 minutes  
**Status:** Specification  
**Dependencies:** FT-150-Simple (Conversation History Loading) - Already Implemented  

## Problem Statement

**Critical API Error**: Claude API rejects `timestamp` field in conversation history, breaking the app.
**Temporal Context Gap**: Oracle lacks conversation memory for natural coaching references.

**Current Broken State:**
```
❌ API Error: "messages.0.timestamp: Extra inputs are not permitted"
❌ Oracle: "Como foi o hemi sync ontem à noite?" (5 minutes ≠ last night)
```

## Solution

**Hybrid Approach**: System prompt context (immediate) + MCP function (deep history) for optimal coaching experience.

## Requirements

### Functional Requirements

**FR-157.1: API Compliance**
- Remove `timestamp` field from conversation history messages
- Maintain Claude API compatibility

**FR-157.2: System Prompt Context**
- Include recent 6 messages (3 exchanges) in system prompt
- Natural conversation format with temporal references
- Both user and assistant messages included

**FR-157.3: Deep Context MCP Function**
- Add `get_conversation_context` MCP function
- Fetch conversation history by time range (hours parameter)
- Return formatted conversation with timestamps

**FR-157.4: Intelligent Context Usage**
- Oracle uses system prompt for immediate references
- Oracle calls MCP for deeper history when needed
- Natural triggers for MCP usage (patterns, themes, "earlier")

### Non-Functional Requirements

**NFR-157.1: Performance**
- System prompt context: No additional API calls
- MCP function: Only called when needed
- Leverage existing storage service

**NFR-157.2: Natural Experience**
- Conversational format (not mechanical timeline)
- Oracle decides when to fetch deeper context
- Seamless integration with two-pass flow

## Implementation

### Phase 1: Fix API Error (5 minutes)
```dart
// lib/services/claude_service.dart - Remove timestamp field
_conversationHistory.add({
  'role': message.isUser ? 'user' : 'assistant',
  'content': [{'type': 'text', 'text': message.text}],
  // Remove: 'timestamp': message.timestamp.toIso8601String(),
});
```

### Phase 2: System Prompt Context (20 minutes)
```dart
// lib/services/claude_service.dart - Add to _buildEnhancedSystemPrompt()
Future<String> _buildRecentConversationContext() async {
  final messages = await _storageService?.getMessages(limit: 6) ?? [];
  final contextLines = <String>[];
  
  for (final msg in messages.reversed) {
    final timeAgo = _formatNaturalTime(DateTime.now().difference(msg.timestamp));
    final speaker = msg.isUser ? 'User' : 'You';
    contextLines.add('$timeAgo: $speaker: "${msg.text}"');
  }
  
  return '''## RECENT CONVERSATION
${contextLines.join('\n')}

For deeper history, use: {"action": "get_conversation_context", "hours": N}''';
}
```

### Phase 3: MCP Function (15 minutes)
```dart
// lib/services/system_mcp_service.dart
case 'get_conversation_context':
  final hours = parsedCommand['hours'] as int? ?? 24;
  return await _getConversationContext(hours);

Future<String> _getConversationContext(int hours) async {
  final cutoff = DateTime.now().subtract(Duration(hours: hours));
  final messages = await ChatStorageService().getMessages(limit: 50, since: cutoff);
  
  final conversations = messages.map((msg) {
    final timeAgo = _formatDetailedTime(DateTime.now().difference(msg.timestamp));
    final speaker = msg.isUser ? 'User' : 'Assistant';
    return '[$timeAgo] $speaker: "${msg.text}"';
  }).toList();
  
  return json.encode({
    'status': 'success',
    'data': {'conversation_history': conversations, 'total_messages': messages.length}
  });
}
```

### Phase 4: MCP Instructions (10 minutes)
```json
// assets/config/mcp_base_config.json
"conversation_memory": {
  "immediate_context": "Recent conversation provided in system prompt",
  "deep_context": "Use get_conversation_context for references beyond recent messages",
  "triggers": ["User asks about patterns", "References to 'earlier'", "Complex coaching context"]
}
```

## Expected Outcome

**Fixed Behavior:**
```
✅ API works without timestamp errors
✅ Oracle: "Há poucos minutos você voltou do hemi sync! Como foi?"
✅ Deep context: Oracle can reference conversations from hours/days ago when relevant
```

## Success Criteria

- ✅ App runs without API errors
- ✅ Oracle makes accurate temporal references for recent conversations
- ✅ Oracle can fetch deeper context when coaching requires it
- ✅ Natural conversation flow maintained
- ✅ Two-pass flow compatibility preserved

## Testing Strategy

1. **API Fix**: Verify app starts and sends messages without errors
2. **Recent Context**: Test temporal references for conversations within 30 minutes
3. **Deep Context**: Test MCP function with various time ranges
4. **Coaching Flow**: Verify natural coaching conversation with memory references
