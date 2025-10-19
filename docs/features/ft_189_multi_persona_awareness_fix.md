# FT-189: Multi-Persona Awareness Fix

**Feature ID:** FT-189  
**Priority:** High  
**Category:** Bug Fix  
**Effort:** 25 minutes  
**Date:** October 17, 2025

## Problem

AI personas are confused about their identity in multi-persona conversations. When users ask "com quem eu falo?" (who am I talking to?), the AI responds with the wrong persona name or shows uncertainty about its identity.

**Root Cause:** Claude API receives conversation history without persona metadata, causing identity confusion when processing messages from multiple personas.

**Evidence from logs:**
```
User: "Tem certeza de que vc e Aristios?"
AI: "não! 🪞 vou ser 100% honesto - sou o I-there sim."
```
Despite `personaKey: "ariWithOracle42"`, the AI identified as I-There due to conversation history confusion.

## Solution

### Core Fix: Add Persona Context to Message History

Modify `ClaudeService._loadRecentHistory()` to include persona metadata in conversation context sent to Claude API:

```dart
// Current (problematic)
_conversationHistory.add({
  'role': 'assistant',
  'content': [{'type': 'text', 'text': message.text}]
});

// Fixed (with persona context)
String content = message.text;
if (!message.isUser && message.personaDisplayName != null) {
  content = '[Persona: ${message.personaDisplayName}]\n${message.text}';
}
_conversationHistory.add({
  'role': 'assistant', 
  'content': [{'type': 'text', 'text': content}]
});
```

### Identity Context in System Prompt

Add persona identity context to `CharacterConfigManager.loadSystemPrompt()`:

```dart
final identityContext = '''

## YOUR IDENTITY
You are ${await getDisplayName()} (${activePersonaKey}).
When asked "com quem eu falo?" or about your identity, respond: "${await getDisplayName()}"

## CONVERSATION CONTEXT
The message history may contain responses from other personas marked as [Persona: Name].
Maintain YOUR unique voice and personality regardless of previous responses.

''';
```

### External Configuration (Optional)

Create `assets/config/multi_persona_config.json`:

```json
{
  "enabled": true,
  "includePersonaInHistory": true,
  "personaPrefix": "[Persona: {{displayName}}]"
}
```

## Implementation

### Files to Modify:
1. `lib/services/claude_service.dart` - Add persona context to conversation history
2. `lib/config/character_config_manager.dart` - Add identity context to system prompt  
3. `assets/config/multi_persona_config.json` - New configuration file (optional)

### Code Changes:

**1. ClaudeService._loadRecentHistory() modification:**
```dart
for (final message in recentMessages.reversed) {
  String content = message.text;
  
  // Add persona context for assistant messages (invisible to user)
  if (!message.isUser && message.personaDisplayName != null) {
    content = '[Persona: ${message.personaDisplayName}]\n${message.text}';
  }
  
  _conversationHistory.add({
    'role': message.isUser ? 'user' : 'assistant',
    'content': [{'type': 'text', 'text': content}],
  });
}
```

**2. CharacterConfigManager.loadSystemPrompt() addition:**
```dart
// Insert after core rules, before persona-specific prompt
final identityContext = '''

## YOUR IDENTITY
You are ${await getDisplayName()} (${activePersonaKey}).
When asked "com quem eu falo?" or about your identity, respond: "${await getDisplayName()}"

## CONVERSATION CONTEXT
The message history may contain responses from other personas marked as [Persona: Name].
Maintain YOUR unique voice and personality regardless of previous responses.

''';

buffer.writeln(coreRules);
buffer.writeln(identityContext);  // ← NEW
buffer.writeln(oraclePrompt);
```

## User Experience Impact

### What User Sees (Unchanged):
- Messages with persona icons
- Selected persona in title bar
- Clean message text (no visible metadata)

### What Claude Sees (Enhanced):
```
[Persona: I-There 4.2]
opa! que bom te ver por aqui! sou seu reflexo no reino dos espelhos 🪞

[Persona: Aristios 4.5]
oi! 🪞 sou o Aristos, seu coach de transformação pessoal.
```

## Testing

### Test Cases:
1. **Identity Verification**: Ask "com quem eu falo?" - should return correct persona name
2. **Multi-Persona History**: Switch personas mid-conversation - new persona should maintain distinct identity
3. **Conversation Continuity**: Ensure persona-specific responses remain consistent with their established personality
4. **UI Consistency**: Verify persona icons and titles display correctly

### Success Criteria:
- ✅ AI correctly identifies itself when asked
- ✅ Each persona maintains distinct communication style
- ✅ No visible metadata in user interface
- ✅ Conversation history provides proper context to AI

## Risk Assessment

**Risk Level:** Low
- **Non-breaking change**: Only adds context, doesn't modify existing functionality
- **User-invisible**: No UI changes required
- **Reversible**: Can be disabled via configuration
- **Isolated impact**: Only affects conversation context processing

## Future Enhancements

This fix establishes foundation for:
- Advanced multi-persona conversation features
- Persona-to-persona communication
- Enhanced conversation analytics
- Dynamic persona switching mid-conversation

## Dependencies

- No database schema changes required
- No external API modifications needed
- Leverages existing persona metadata in `ChatMessageModel`
