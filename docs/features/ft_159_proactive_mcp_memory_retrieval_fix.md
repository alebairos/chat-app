# FT-159: Proactive MCP Memory Retrieval Fix

**Feature ID:** FT-159  
**Priority:** High  
**Category:** Memory Enhancement / Bug Fix  
**Effort Estimate:** 2 hours  
**Status:** Specification  
**Created:** September 29, 2025  

## Problem Statement

Current MCP functions exist but AI personas don't use them proactively, causing memory failures like the workout plan scenario (lines 1354-1356 in chat export):

**User**: *"me lembra rapidinho do plano que a gente montou pra semana?"*  
**I-There 4.2**: *"não consigo ver nas nossas conversas recentes o plano específico"*

**Root Cause**: Missing prompt engineering for proactive MCP usage triggers.

## Current vs Enhanced System

### Current (Reactive)
- MCP functions available but unused
- AI relies only on 55-message context window
- Memory failures when conversations exceed context

### Enhanced (Proactive)  
- AI automatically triggers MCP functions when needed
- Unlimited historical access via `get_conversation_context`
- No memory gaps regardless of conversation length

## Implementation Plan

### 1. Enhance MCP Base Config (15 min)
**File**: `assets/config/mcp_base_config.json`

**Add proactive triggers to lines 102-107**:
```json
"when_to_use_mcp": [
  "User asks about patterns or themes across multiple sessions",
  "User references something from 'earlier today', 'this morning', 'yesterday'",
  "Complex coaching requiring full conversation history", 
  "User asks 'what did I say about X?' and it's not in recent context",
  "User asks 'remember the plan we made?'",
  "User references past conversations not in current context",
  "User switches personas and expects continuity",
  "User asks about previous activities or discussions"
]
```

### 2. Add Proactive Memory Section (10 min)
**Add new section after line 114**:
```json
"proactive_memory_triggers": {
  "title": "### 🧠 PROACTIVE MEMORY RETRIEVAL",
  "critical_rule": "AUTOMATICALLY use get_conversation_context when memory gaps detected",
  "trigger_patterns": [
    "\"lembra do plano\" → get_conversation_context REQUIRED",
    "\"remember the plan\" → get_conversation_context REQUIRED",
    "\"what did we discuss\" → get_conversation_context REQUIRED", 
    "\"me lembra rapidinho\" → get_conversation_context REQUIRED",
    "User references past conversations not in context → get_conversation_context REQUIRED"
  ],
  "cross_persona_rule": "When switching personas, if user expects continuity, ALWAYS use get_conversation_context"
}
```

### 3. Fix MCP Function Limits (30 min)
**File**: `lib/services/system_mcp_service.dart`

**A. Increase conversation context limit (line 321)**:
```dart
// Before: final messages = await storageService.getMessages(limit: 50);
final messages = await storageService.getMessages(limit: 200);
```

**B. Add configurable full text option (lines 270-272)**:
```dart
Future<String> _getMessageStats(int limit, {bool fullText = false}) async {
  // ...
  'text': fullText 
      ? message.text
      : (message.text.length > 100
          ? '${message.text.substring(0, 100)}...'
          : message.text),
}
```

**C. Update MCP command handler (line 72)**:
```dart
case 'get_message_stats':
  final limit = parsedCommand['limit'] as int? ?? 10;
  final fullText = parsedCommand['full_text'] as bool? ?? false;
  return await _getMessageStats(limit, fullText: fullText);
```

### 4. Update Config Builder (30 min)
**File**: `lib/config/character_config_manager.dart`

**Add proactive triggers to buildMcpInstructionsText() method around line 550**:
```dart
// Add proactive memory triggers section
final proactiveTriggers = instructions['proactive_memory_triggers'] ?? {};
if (proactiveTriggers['title'] != null) {
  buffer.writeln(proactiveTriggers['title']);
  buffer.writeln();
}
if (proactiveTriggers['critical_rule'] != null) {
  buffer.writeln('**${proactiveTriggers['critical_rule']}**');
  buffer.writeln();
}
if (proactiveTriggers['trigger_patterns'] != null) {
  final List<dynamic> patterns = proactiveTriggers['trigger_patterns'];
  for (final pattern in patterns) {
    buffer.writeln('- $pattern');
  }
  buffer.writeln();
}
```

## Expected Results

### Before Fix
- Memory failures: *"não consigo ver nas nossas conversas recentes o plano específico"*
- Lost context across persona switches
- Limited to 55-message window

### After Fix  
- Automatic memory retrieval: `{"action": "get_conversation_context", "hours": 24}`
- Seamless persona switching with full context
- Unlimited conversation history access
- Zero memory failures

## Testing Strategy

1. **Unit Test**: Verify config loads proactive triggers
2. **Integration Test**: Confirm MCP functions trigger on memory gaps
3. **Scenario Test**: Recreate exact workout plan failure - should auto-retrieve
4. **Cross-Persona Test**: Switch personas expecting continuity - should work

## Complementary Features

- **FT-150 Enhanced**: Provides 55-message baseline context
- **FT-159**: Adds unlimited historical access when needed
- **Together**: Bulletproof memory system with no gaps

## Risk Assessment

- **Breaking Changes**: None (only adding instructions)
- **Performance**: Minimal (functions already exist)
- **Rollback**: Simple JSON revert
- **Risk Level**: Very Low

## Success Metrics

- Zero memory failure responses like "não consigo ver"
- Automatic MCP function usage in conversation logs
- Successful cross-persona context continuity
- User satisfaction with memory consistency
