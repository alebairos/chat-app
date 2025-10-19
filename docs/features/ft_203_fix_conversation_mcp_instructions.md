# FT-203: Fix Missing Conversation MCP Instructions

## Problem Statement

FT-200 conversation database queries are implemented but the AI doesn't use them, causing "amnesia" behavior where the AI introduces itself in every message.

### Current Broken Behavior
- **FT-200 enabled**: Conversation history removed from context
- **MCP commands available**: `get_recent_user_messages`, `get_current_persona_messages`, `search_conversation_context`
- **AI behavior**: Doesn't use MCP commands, acts like every message is first interaction
- **Result**: "oi, sou o I-There..." in every response

### Evidence from Logs
**Line 917**: `FT-200: Using conversation database queries - no history injection`
**Line 951**: `Original AI response: oi, sou o I-There - seu reflexo que vive no Mirror Realm...`

**No MCP conversation queries found in logs** - only Oracle activity detection.

## Root Cause Analysis

The `assets/config/mcp_base_config.json` contains old `get_conversation_context` command but **missing the new FT-200 commands**:

### Missing Instructions
- `get_recent_user_messages`: Get recent user messages only
- `get_current_persona_messages`: Get current persona's previous responses  
- `search_conversation_context`: Search conversation by query/timeframe

### Current MCP Config Gap
The AI has no instructions on when/how to use the new conversation commands.

## Solution

### Add FT-200 Conversation Instructions to MCP Base Config

**File**: `assets/config/mcp_base_config.json`

**Add new section** after line 88:

```json
{
  "name": "get_recent_user_messages",
  "description": "Get recent user messages for conversation continuity",
  "usage": "{\"action\": \"get_recent_user_messages\", \"limit\": 5}",
  "when_to_use": [
    "When conversation history is not available in context",
    "To understand what user has been discussing recently",
    "For conversation continuity without persona contamination"
  ],
  "critical_rule": "Use when you need user context but want to avoid other personas' responses"
},
{
  "name": "get_current_persona_messages", 
  "description": "Get your own previous responses for consistency",
  "usage": "{\"action\": \"get_current_persona_messages\", \"limit\": 3}",
  "when_to_use": [
    "To maintain consistency with your previous responses",
    "When you need to reference what you said before",
    "For conversation continuity as the same persona"
  ],
  "critical_rule": "Use to avoid repeating introductions or contradicting yourself"
},
{
  "name": "search_conversation_context",
  "description": "Search conversation history by query and timeframe", 
  "usage": "{\"action\": \"search_conversation_context\", \"query\": \"topic\", \"hours\": 24}",
  "when_to_use": [
    "User references specific topics discussed before",
    "Need to find context about particular subjects",
    "User asks 'what did we discuss about X?'"
  ],
  "critical_rule": "Use for targeted context retrieval"
}
```

### Add Conversation Continuity Rules

**Add new section** after `temporal_intelligence`:

```json
"conversation_continuity": {
  "title": "## 💬 CONVERSATION CONTINUITY - FT-200",
  "description": "When conversation history is not in context, use MCP commands to maintain natural flow",
  "critical_rules": [
    "NEVER introduce yourself if you've already been talking to the user",
    "Use get_current_persona_messages to check if you've introduced yourself recently",
    "Use get_recent_user_messages to understand conversation flow",
    "Only introduce yourself on first interaction or after explicit persona switch"
  ],
  "amnesia_prevention": {
    "title": "### 🧠 PREVENT AMNESIA BEHAVIOR",
    "rule": "Before responding, check if this appears to be a continuing conversation",
    "auto_query": "If no conversation context available, automatically use get_recent_user_messages",
    "introduction_logic": "Only introduce yourself if get_current_persona_messages shows no recent responses"
  }
}
```

## Expected Outcome

### Before Fix (Amnesia)
- AI: "oi, sou o I-There - seu reflexo que vive no Mirror Realm..."
- Every response starts with introduction
- No conversation continuity

### After Fix (Natural Flow)  
- AI automatically queries conversation context
- Maintains natural conversation flow
- Only introduces when appropriate
- Consistent persona behavior

## Implementation Priority

**HIGH** - This breaks the core conversation experience and makes FT-200 unusable.

## Testing Strategy

1. **Enable FT-200** (already done)
2. **Apply MCP instruction fix**
3. **Test conversation flow**:
   - Send "opa" → Should not get introduction
   - Check logs for MCP conversation queries
   - Verify natural response continuation

## Dependencies

- FT-200: Conversation History Database Queries (implemented)
- MCP Base Config system (existing)
- SystemMCPService conversation commands (implemented)
