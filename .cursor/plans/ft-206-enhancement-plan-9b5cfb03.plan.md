<!-- 9b5cfb03-ff55-44c7-900b-05c3d7782d1c 40110ff5-567d-4356-9f22-b2ca1a0f60d8 -->
# FT-206: Enhance Conversation Context Structure

## Overview

Replace separate user/persona message lists with interleaved conversation thread to preserve question-answer relationships and prevent context misinterpretation, while ensuring Oracle 4.2 framework and activity detection remain unaffected.

## Critical Constraints

### Oracle Framework Protection

- **265+ Activities**: All 8 dimensions (R, SF, TG, SM, E, TT, PR, F) must remain accessible
- **Token Budget**: Oracle personas use ~9,000 tokens; conversation context limited to 500 tokens (5% of total)
- **Activity Detection**: ONLY from current user message, NEVER from conversation history
- **Theoretical Frameworks**: 9 frameworks (Fogg, Seligman, Huberman, etc.) maintain Priority 3

### Architecture Consistency

- Follow `get_current_time` pattern (system-driven MCP, not model-driven)
- Maintain FT-200 toggle compatibility
- Preserve two-pass data integration flow
- Graceful error handling with fallback

## Implementation Steps

### Phase 1: Database Optimization

**File**: `lib/models/chat_message_model.dart`

Add composite indexes for efficient conversation queries:

```dart
@Index(composite: [CompositeIndex('timestamp')])
@Index(composite: [CompositeIndex('timestamp'), CompositeIndex('personaKey')])
@Index(composite: [CompositeIndex('timestamp'), CompositeIndex('isUser')])
```

**Why**: Reduces query time from 10-50ms → 2-5ms for conversation context loading.

### Phase 2: MCP Function Implementation

**File**: `lib/services/system_mcp_service.dart`

Implement `_getInterleavedConversation()`:

```dart
Future<String> _getInterleavedConversation(int limit, bool includeAllPersonas) async {
  final storageService = ChatStorageService();
  final messages = await storageService.getMessages(limit: limit);
  
  final conversationThread = messages.map((msg) {
    final speaker = msg.isUser
        ? 'User'
        : '[${msg.personaDisplayName ?? msg.personaKey}]';
    
    return {
      'speaker': speaker,
      'text': msg.text,
      'time_ago': _formatTimeAgo(DateTime.now().difference(msg.timestamp)),
      'timestamp': msg.timestamp.toIso8601String(),
    };
  }).toList();
  
  return json.encode({
    'status': 'success',
    'data': {
      'conversation_thread': conversationThread,
      'total_messages': conversationThread.length,
    }
  });
}
```

Add command handler in `processCommand()`:

```dart
case 'get_interleaved_conversation':
  final limit = params['limit'] as int? ?? 10;
  final includeAllPersonas = params['include_all_personas'] as bool? ?? true;
  return await _getInterleavedConversation(limit, includeAllPersonas);
```

### Phase 3: System Prompt Enhancement

**File**: `lib/services/claude_service.dart`

Update `_buildSystemPrompt()` with Oracle-aware priority hierarchy:

```dart
Future<String> _buildSystemPrompt() async {
  final timeContext = await TimeContextService.generatePreciseTimeContext(lastMessageTime);
  final conversationContext = await _buildRecentConversationContext();
  final isOracleEnabled = _systemMCP?.isOracleEnabled ?? false;
  
  final priorityHeader = '''
## 🎯 INSTRUCTION PRIORITY HIERARCHY

**PRIORITY 1 (ABSOLUTE)**: Time Awareness (MANDATORY)
- ALWAYS use current time from system context

**PRIORITY 2 (HIGHEST)**: Core Behavioral Rules & Persona Configuration
- Follow System Laws #1-#6 literally
- Maintain unique persona identity and symbols

${isOracleEnabled ? '''
**PRIORITY 3 (ORACLE FRAMEWORK)**: Oracle 4.2 Theoretical Foundations
- Apply all 9 theoretical frameworks
- Use all 8 dimensions (R, SF, TG, SM, E, TT, PR, F)
- CRITICAL: Activity detection ONLY from current user message
''' : ''}

**PRIORITY ${isOracleEnabled ? '4' : '3'}**: Conversation Context (REFERENCE ONLY)
- Use for understanding conversation flow
- Do NOT process activities from historical messages
- Do NOT adopt other personas' styles

**PRIORITY ${isOracleEnabled ? '5' : '4'}**: User's Current Message (PRIMARY FOCUS)
- Activity detection: ONLY current user message
- Metadata extraction: ONLY current user message

---
''';
  
  return priorityHeader + 
         (timeContext.isNotEmpty ? '$timeContext\n\n' : '') +
         (conversationContext.isNotEmpty ? '$conversationContext\n\n' : '') +
         systemPrompt;
}
```

Update `_buildRecentConversationContext()`:

```dart
Future<String> _buildRecentConversationContext() async {
  if (!await _isConversationDatabaseEnabled()) return '';
  
  try {
    final config = await _loadConversationDatabaseConfig();
    final isOracleEnabled = _systemMCP?.isOracleEnabled ?? false;
    
    // Adaptive token budget: 500 for Oracle, 600 for non-Oracle
    final limit = isOracleEnabled 
        ? (config['performance']['max_interleaved_messages_oracle'] ?? 8)
        : (config['performance']['max_interleaved_messages'] ?? 10);
    
    final conversation = await _systemMCP!.processCommand(
      '{"action":"get_interleaved_conversation","limit":$limit,"include_all_personas":true}'
    );
    
    return _formatInterleavedConversation(conversation);
  } catch (e) {
    _logger.warning('FT-206: Failed to load conversation context: $e');
    return '';
  }
}
```

Add `_formatInterleavedConversation()`:

```dart
String _formatInterleavedConversation(String mcpResponse) {
  final data = json.decode(mcpResponse);
  final thread = data['data']['conversation_thread'] as List;
  
  final buffer = StringBuffer();
  buffer.writeln('## 📜 RECENT CONVERSATION CONTEXT (REFERENCE ONLY)');
  buffer.writeln('');
  buffer.writeln('**PURPOSE**: Understand conversation flow and topics');
  buffer.writeln('**CRITICAL BOUNDARIES**:');
  buffer.writeln('- Activity detection: ONLY current user message');
  buffer.writeln('- Do NOT extract Oracle codes or metadata from history');
  buffer.writeln('');
  buffer.writeln('---');
  buffer.writeln('');
  
  for (final msg in thread) {
    final speaker = msg['speaker'];
    final text = msg['text'];
    final timeAgo = msg['time_ago'];
    
    // Strip Oracle artifacts from other personas
    final cleanText = speaker.startsWith('[') 
        ? _removeOracleArtifacts(text)
        : text;
    
    buffer.writeln('**$speaker** ($timeAgo): $cleanText');
  }
  
  buffer.writeln('');
  buffer.writeln('---');
  buffer.writeln('**REMINDER**: Process ONLY current user message.');
  
  return buffer.toString();
}

String _removeOracleArtifacts(String text) {
  var cleaned = text.replaceAll(RegExp(r'[🎯💪🔥⚡️✨🌟💡🚀]'), '');
  cleaned = cleaned.replaceAll(RegExp(r'\b[A-Z]{1,2}\d+\b'), '[activity]');
  cleaned = cleaned.replaceAll(RegExp(r'\d+\s*(ml|minutos|min|flexões|pomodoros)'), '[metadata]');
  cleaned = cleaned.replaceAll(RegExp(r'\{[^}]*action[^}]*\}'), '[mcp]');
  return cleaned.trim();
}
```

### Phase 4: Configuration Updates

**File**: `assets/config/conversation_database_config.json`

```json
{
  "enabled": true,
  "performance": {
    "max_interleaved_messages": 10,
    "max_interleaved_messages_oracle": 8,
    "max_context_tokens": 600,
    "max_context_tokens_oracle": 500
  },
  "context_strategy": {
    "proactive_context": {
      "enabled": true,
      "format": "interleaved",
      "include_all_personas": true,
      "strip_oracle_artifacts": true
    }
  }
}
```

**File**: `assets/config/core_behavioral_rules.json`

Add System Law #6:

```json
{
  "conversation_context_usage": {
    "title": "SYSTEM LAW #6: CONVERSATION CONTEXT BOUNDARIES",
    "context_purpose": "History provides CONTEXT, not data to process",
    "activity_detection": "ONLY current user message",
    "oracle_activity_codes": "NEVER extract codes from history",
    "oracle_compliance": "Follow all 9 frameworks and 8 dimensions",
    "priority_level": "highest"
  }
}
```

**File**: `assets/config/mcp_base_config.json`

Document new function:

```json
{
  "name": "get_interleaved_conversation",
  "description": "Get recent conversation as interleaved thread",
  "usage": "{\"action\":\"get_interleaved_conversation\",\"limit\":10,\"include_all_personas\":true}",
  "note": "System-driven (pre-executed), not model-driven"
}
```

### Phase 5: Testing

**Test 1: Oracle Activity Detection Boundary**

- Conversation: `[Sergeant] "Marca 2 pomodoros (TG8), 500ml água (SF1)"`
- User: `"fiz exercício"`
- Expected: Detect ONLY "exercício", NOT "pomodoros" or "água"

**Test 2: FT-211 Scenario (Tony Context Loss)**

- Conversation: Tony asks "Em que horário sua filha costuma dormir?"
- User: "entre 08:30 e 09:30 da noite"
- Expected: Persona understands this is evening time (20:30-21:30)

**Test 3: Cross-Persona Handoff**

- Tony discusses sleep schedule with user
- Switch to I-There
- Expected: I-There acknowledges Tony's conversation naturally

**Test 4: Token Budget Compliance**

- Oracle persona with 8 messages
- Expected: Context ≤ 500 tokens, total prompt ≤ 9,500 tokens

## Success Metrics

**Quantitative**:

- Context misinterpretation: < 2% (currently ~15-20%)
- Cross-persona handoff success: > 95% (currently ~70%)
- Token efficiency: 500-600 tokens (within budget)
- Query performance: < 5ms (with indexes)

**Qualitative**:

- Personas correctly interpret ambiguous responses
- No coaching objective loss during persona switches
- No false positive activity detection from history
- Oracle framework integrity maintained

## Rollback Strategy

If issues arise:

1. Set `conversation_database_config.json` → `enabled: false`
2. System reverts to legacy behavior (no conversation context)
3. All other features continue working normally

### To-dos

- [ ] Add PRIORITY 1 (Data Query Intelligence) to priority header in _buildSystemPrompt()
- [ ] Implement _detectDataQueryPattern() method with generic temporal/quantitative patterns
- [ ] Integrate pattern detection and hint injection in _sendMessageInternal()
- [ ] Add mandatory conversation review instructions to _formatInterleavedConversation()
- [ ] Add SYSTEM LAW #7 (Response Continuity) to core_behavioral_rules.json
- [ ] Test with real time gap scenario (4+ hours) to verify timestamp fix
- [ ] Test data query patterns (weekly summary, yesterday, quantities)
- [ ] Test repetition prevention and context acknowledgment