# FT-157: Temporal Awareness Enhancement for Accurate Timeline References

**Feature ID:** FT-157  
**Priority:** High  
**Category:** Memory Enhancement / Temporal Intelligence  
**Effort Estimate:** 30 minutes  
**Status:** Specification  
**Dependencies:** FT-150-Simple (Conversation History Loading) - Already Implemented  

## Problem Statement

**Oracle makes incorrect temporal references**: A 5-minute gap is incorrectly referenced as "last night" instead of "a few minutes ago", breaking coaching continuity and sounding artificial.

**Current Behavior:**
```
00:17 - User: "voltei do hemi sync"
00:22 - User: "Como foi?"
Oracle: "Como foi o hemi sync ontem à noite?" ❌ (5 minutes ≠ last night)
```

**Root Cause:** Oracle lacks access to conversation history timestamps for accurate temporal calculations.

## Solution

**WhatsApp-Style Metadata Approach**: Include timestamps as metadata (not visible text) + enhanced temporal awareness instructions.

## Requirements

### Functional Requirements

**FR-157.1: Conversation History Metadata**
- Include `timestamp` field in conversation history entries
- Timestamps remain as metadata (not embedded in message text)
- Clean message text preserved for UX

**FR-157.2: Temporal Awareness Instructions**
- Add temporal awareness guidance to MCP base configuration
- Instruct Oracle to use `get_current_time` + message timestamps
- Provide workflow for accurate temporal calculations

**FR-157.3: Accurate Temporal References**
- Oracle calculates real time differences before making references
- Use precise language: "5 minutes ago", "earlier today", "yesterday"
- Eliminate incorrect temporal assumptions

### Non-Functional Requirements

**NFR-157.1: Clean UX**
- No visible timestamps in message text (WhatsApp model)
- Maintain natural conversation flow
- No artificial-sounding embedded metadata

**NFR-157.2: Backward Compatibility**
- Preserve existing conversation history functionality
- No breaking changes to FT-150-Simple implementation
- Maintain existing MCP function signatures

## Implementation

### Phase 1: Metadata Enhancement (15 minutes)
```dart
// lib/services/claude_service.dart - _loadRecentHistory()
_conversationHistory.add({
  'role': message.isUser ? 'user' : 'assistant',
  'content': [{'type': 'text', 'text': message.text}],
  'timestamp': message.timestamp.toIso8601String(), // ← Add metadata
});
```

### Phase 2: Temporal Awareness Instructions (15 minutes)
```json
// assets/config/mcp_base_config.json
"temporal_awareness": {
  "principle": "Be aware of the timeline on every user interaction",
  "workflow": [
    "1. Each message includes timestamp metadata",
    "2. Use get_current_time to get current moment", 
    "3. Calculate accurate time differences",
    "4. Make precise temporal references"
  ],
  "examples": [
    "5 minutes ago → 'a few minutes ago when you said...'",
    "2 hours ago → 'earlier when you mentioned...'",
    "Yesterday → 'yesterday when you told me...'"
  ]
}
```

## Expected Outcome

**Corrected Behavior:**
```
00:17 - User: "voltei do hemi sync"  
00:22 - User: "Como foi?"
Oracle: "Há alguns minutos você voltou do hemi sync! Como foi a experiência?" ✅
```

## Success Criteria

- ✅ Oracle makes accurate temporal references (5 min ≠ "last night")
- ✅ Clean message text without embedded timestamps  
- ✅ Leverages existing `get_current_time` MCP function
- ✅ Enhanced coaching continuity and natural conversation flow

## Testing Strategy

**Manual Testing:**
1. Send message, wait 5 minutes, reference previous topic
2. Verify Oracle uses accurate temporal language
3. Confirm no visible timestamps in conversation UI
4. Test various time gaps (minutes, hours, days)
