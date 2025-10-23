# FT-210: Complete Context Building Process Analysis

## Overview

This document traces the complete flow of how conversation context is built and passed to Claude's API, identifying where the duplicate message bug occurs.

## Context Building Architecture

### Key Components

1. **`_conversationHistory`** (Line 58): In-memory list storing conversation turns
2. **`_systemPrompt`** (Line 59): Base persona/system instructions
3. **`_buildSystemPrompt()`** (Line 726): Assembles final system prompt
4. **`_buildRecentConversationContext()`** (Line 774): Loads MCP conversation data
5. **`messages` array** (Line 405): Final messages sent to Claude API

### Configuration Flags

- **FT-200 Enabled**: Uses database queries, no history injection
- **FT-200 Disabled**: Uses legacy `_conversationHistory` injection

---

## Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ INITIALIZATION (Once per app session)                           │
└─────────────────────────────────────────────────────────────────┘
  initialize() [Line 278]
    ↓
  _loadRecentHistory(limit: 25) [Line 186]
    ↓
  Loads last 25 messages from database
    ↓
  Populates _conversationHistory with:
    [msg1_user, msg1_ai, msg2_user, msg2_ai, ..., msg25_ai]
    
    
┌─────────────────────────────────────────────────────────────────┐
│ USER SENDS MESSAGE: "quarta"                                     │
└─────────────────────────────────────────────────────────────────┘
  sendMessage("quarta") [Line 356]
    ↓
  _retryWithBackoff(() => _sendMessageInternal("quarta"))
    ↓
    
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: Add User Message to History                             │
└─────────────────────────────────────────────────────────────────┘
  _sendMessageInternal("quarta") [Line 361]
    ↓
  Line 393-399: ⚠️ FIRST ADDITION
    _conversationHistory.add({
      'role': 'user',
      'content': [{'type': 'text', 'text': 'quarta'}]
    })
    
  _conversationHistory now:
    [...previous 25 messages, "quarta"]
    
    
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Prepare Messages for API Call                           │
└─────────────────────────────────────────────────────────────────┘
  Line 405-424: Prepare messages array
    ↓
  Check: await _isConversationDatabaseEnabled()
    ↓
  ┌─────────────────────────────────────────────────────────────┐
  │ IF FT-200 ENABLED (conversation_database_config.json)      │
  └─────────────────────────────────────────────────────────────┘
    Line 408-418:
      messages = [
        {
          'role': 'user',
          'content': [{'type': 'text', 'text': 'quarta'}]
        }
      ]
      // Only current message, NO history injection
      
  ┌─────────────────────────────────────────────────────────────┐
  │ IF FT-200 DISABLED (legacy mode)                           │
  └─────────────────────────────────────────────────────────────┘
    Line 420-423:
      messages = [..._conversationHistory]
      // All 26 messages (25 loaded + current "quarta")
      
      
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: Build System Prompt                                     │
└─────────────────────────────────────────────────────────────────┘
  _buildSystemPrompt() [Line 726]
    ↓
  ┌─────────────────────────────────────────────────────────────┐
  │ 3A: Build Conversation Context (FT-206)                     │
  └─────────────────────────────────────────────────────────────┘
    _buildRecentConversationContext() [Line 774]
      ↓
    IF FT-200 ENABLED:
      Execute MCP commands:
        - get_recent_user_messages (last 5)
        - get_current_persona_messages (last 3)
      ↓
      Format as text summary:
        "## Recent User Messages:
         - 2 minutes ago: 'durmo tarde...'
         - 5 minutes ago: 'ok. dormir mais cedo'
         
         ## Your Previous Responses:
         - 3 minutes ago: 'Como você está lidando...'"
    
    IF FT-200 DISABLED:
      Returns empty string
      
  ┌─────────────────────────────────────────────────────────────┐
  │ 3B: Build Time Context (FT-060)                             │
  └─────────────────────────────────────────────────────────────┘
    TimeContextService.generatePreciseTimeContext()
      ↓
    "Current time: 2025-10-22 14:58:09
     Last message: 3 minutes ago
     Time gap: Short (< 5 minutes)"
     
  ┌─────────────────────────────────────────────────────────────┐
  │ 3C: Assemble Final System Prompt                            │
  └─────────────────────────────────────────────────────────────┘
    systemPrompt = 
      [Time Context]
      [Conversation Context]
      [Base Persona Prompt]
      [MCP Documentation]
      
      
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: First API Call to Claude                                │
└─────────────────────────────────────────────────────────────────┘
  Line 445-460: POST to Claude API
    {
      'model': 'claude-3-5-sonnet-latest',
      'max_tokens': 1024,
      'messages': messages,  // From Step 2
      'system': systemPrompt // From Step 3
    }
    ↓
  Claude responds with:
    "Entendo. O desafio é equilibrar trabalho noturno...
     {"action":"get_activity_stats","category":"sleep"}
     Qual seria o dia mais tranquilo?"
     
     
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: Detect MCP Command (Two-Pass Flow)                      │
└─────────────────────────────────────────────────────────────────┘
  Line 478: _containsMCPCommand(assistantMessage)
    ↓
  Returns TRUE (found MCP command)
    ↓
  Line 482-483: Call _processDataRequiredQuery()
    ↓
    
┌─────────────────────────────────────────────────────────────────┐
│ STEP 6: Process Data Required Query (TWO-PASS)                  │
└─────────────────────────────────────────────────────────────────┘
  _processDataRequiredQuery("quarta", initialResponse, messageId)
    ↓
  ┌─────────────────────────────────────────────────────────────┐
  │ 6A: Extract and Execute MCP Commands                        │
  └─────────────────────────────────────────────────────────────┘
    Line 624: _extractMCPCommands(initialResponse)
      → ["{"action":"get_activity_stats","category":"sleep"}"]
      ↓
    Line 640-655: Execute each command
      collectedData = "User sleep stats: avg 5.5 hours..."
      
  ┌─────────────────────────────────────────────────────────────┐
  │ 6B: Build Enriched Prompt                                   │
  └─────────────────────────────────────────────────────────────┘
    Line 658-659: _buildEnrichedPromptWithQualification()
      "User said: 'quarta'
       
       Data available:
       User sleep stats: avg 5.5 hours...
       
       Provide final response with this data."
       
  ┌─────────────────────────────────────────────────────────────┐
  │ 6C: Second API Call with Data                               │
  └─────────────────────────────────────────────────────────────┘
    Line 670: await Future.delayed(500ms) // FT-085 rate limiting
    Line 675: _callClaudeWithPrompt(enrichedPrompt)
      ↓
    Claude responds with final answer:
      "Perfeito! Quarta-feira é um ótimo dia..."
      
  ┌─────────────────────────────────────────────────────────────┐
  │ 6D: Add to Conversation History ⚠️ BUG HERE                 │
  └─────────────────────────────────────────────────────────────┘
    Line 679-684: ❌ DUPLICATE USER MESSAGE ADDITION
      _conversationHistory.add({
        'role': 'user',
        'content': [{'type': 'text', 'text': 'quarta'}]
      })
      
    _conversationHistory now:
      [...previous 25, "quarta", "quarta"] ← DUPLICATE!
      
    Line 686-691: Add assistant response
      _conversationHistory.add({
        'role': 'assistant',
        'content': [{'type': 'text', 'text': dataInformedResponse}]
      })
      
    _conversationHistory now:
      [...previous 25, "quarta", "quarta", "Perfeito! Quarta..."]
      
      
┌─────────────────────────────────────────────────────────────────┐
│ ALTERNATIVE: Regular Flow (No MCP Commands)                     │
└─────────────────────────────────────────────────────────────────┘
  IF Line 478 returns FALSE (no MCP commands):
    ↓
  Line 494: cleanedResponse = _cleanResponseForUser(assistantMessage)
    ↓
  Line 501-506: Add assistant response to history
    _conversationHistory.add({
      'role': 'assistant',
      'content': [{'type': 'text', 'text': cleanedResponse}]
    })
    
  _conversationHistory now:
    [...previous 25, "quarta", "AI response"] ← CORRECT!
    
    
┌─────────────────────────────────────────────────────────────────┐
│ NEXT USER MESSAGE: "já respondi"                                │
└─────────────────────────────────────────────────────────────────┘
  _sendMessageInternal("já respondi")
    ↓
  Line 393-399: Add to history
    _conversationHistory.add({
      'role': 'user',
      'content': [{'type': 'text', 'text': 'já respondi'}]
    })
    
  _conversationHistory now:
    [..., "quarta", "quarta", "Perfeito...", "já respondi"]
                    ↑ This duplicate confuses Claude!
    ↓
  Line 420-423: IF FT-200 DISABLED
    messages = [..._conversationHistory]
    
  Claude sees:
    User: "quarta"
    User: "quarta"  ← Thinks user repeated themselves
    AI: "Perfeito! Quarta..."
    User: "já respondi"  ← Doesn't make sense in this context
    
  Claude gets confused and repeats previous response!
```

---

## Bug Impact Analysis

### Scenario 1: FT-200 ENABLED (Current Production)

**Context Sent to Claude:**
- **System Prompt**: Includes MCP conversation summary (last 5 user msgs, last 3 AI msgs)
- **Messages Array**: Only current user message
- **Problem**: Even though messages array is clean, the duplicate is in `_conversationHistory` which affects:
  - Future sessions (loaded via `_loadRecentHistory`)
  - Internal state consistency

### Scenario 2: FT-200 DISABLED (Legacy Mode)

**Context Sent to Claude:**
- **System Prompt**: No conversation summary
- **Messages Array**: Full `_conversationHistory` with duplicates
- **Problem**: Claude directly sees duplicate messages and gets confused immediately

---

## Root Cause Summary

### Why Duplicate Happens

1. **Line 393-399**: `_sendMessageInternal()` adds user message to `_conversationHistory`
2. **Line 478**: MCP command detected → triggers two-pass flow
3. **Line 679-684**: `_processDataRequiredQuery()` adds user message AGAIN
4. **Result**: `_conversationHistory` has duplicate user message

### Why It Wasn't Caught

1. **FT-200 enabled**: Duplicate not immediately visible to Claude (only affects internal state)
2. **No test coverage**: Multi-turn conversations with MCP commands not tested
3. **Gradual degradation**: Bug accumulates over conversation, not obvious in single exchange

---

## Fix Strategy

### Simple Fix (Recommended)

**Remove duplicate addition in `_processDataRequiredQuery()`:**

```dart
// Line 678-691: BEFORE (BUGGY)
// Add to conversation history
_conversationHistory.add({
  'role': 'user',
  'content': [{'type': 'text', 'text': userMessage}]
});

_conversationHistory.add({
  'role': 'assistant',
  'content': [{'type': 'text', 'text': dataInformedResponse}]
});

// Line 678-691: AFTER (FIXED)
// NOTE: User message already added in _sendMessageInternal() at line 393-399
// Only add assistant response to avoid duplicates (FT-210)
_conversationHistory.add({
  'role': 'assistant',
  'content': [{'type': 'text', 'text': dataInformedResponse}]
});
```

### Why This Works

1. **User message already in history**: Added at line 393-399
2. **Only assistant response needed**: Complete the conversation turn
3. **Maintains correct order**: [..., user_msg, assistant_response]
4. **No breaking changes**: All existing flows continue to work

---

## Verification Points

### Before Fix
```
_conversationHistory after two-pass:
[..., "quarta", "quarta", "Perfeito! Quarta..."]
       ↑ duplicate
```

### After Fix
```
_conversationHistory after two-pass:
[..., "quarta", "Perfeito! Quarta..."]
       ↑ single, correct
```

### Test Cases

1. **Regular flow** (no MCP): Should work as before
2. **Two-pass flow** (with MCP): No duplicate user message
3. **Multi-turn conversation**: Each message appears once
4. **FT-200 enabled**: Clean internal state
5. **FT-200 disabled**: Clean messages array sent to Claude

---

## Related Configuration Files

### FT-200 Toggle
**File**: `assets/config/conversation_database_config.json`
```json
{
  "enabled": true,  // If true, uses MCP queries instead of history injection
  "description": "..."
}
```

### Multi-Persona Config
**File**: `assets/config/multi_persona_config.json`
```json
{
  "enabled": true,
  "includePersonaInHistory": true,
  "personaPrefix": "[Persona: {{displayName}}]"
}
```

---

## Implementation Priority

**Priority**: Critical
**Effort**: 5 minutes (remove 6 lines of code)
**Risk**: Very low (removing duplicate code)
**Impact**: High (fixes major UX bug)

---

## Next Steps

1. ✅ Understand complete context building flow
2. ⏭️ Implement fix (remove duplicate addition)
3. ⏭️ Test multi-turn conversations
4. ⏭️ Verify both FT-200 enabled/disabled modes
5. ⏭️ Run existing test suite
6. ⏭️ Document fix in implementation summary

