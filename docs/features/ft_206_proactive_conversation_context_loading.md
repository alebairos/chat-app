# FT-206: Proactive Conversation Context Loading

**Feature ID:** FT-206  
**Priority:** High  
**Category:** Architecture Enhancement  
**Effort:** 1 hour  
**Date:** October 19, 2025

## Overview

Complete FT-200's architecture by adding proactive conversation context loading to ClaudeService, following the same system-driven pattern as time context loading. This provides conversation awareness without persona contamination.

---

## **Problem Statement**

### **Current Gap**
FT-200 successfully removed conversation history injection to prevent persona contamination, but created a conversation awareness gap:

- ✅ **Clean persona switching** (FT-200 working)
- ✅ **MCP conversation commands available** (SystemMCPService)
- ❌ **No conversation awareness** (AI has clean slate but no context)
- ❌ **AI not using conversation MCP commands** (relies on AI generation)

### **Evidence from Logs**
```
Line 638: 🔍 [DEBUG] FT-200: Conversation database queries enabled
Line 639: ℹ️ [INFO] FT-200: Using conversation database queries - no history injection
Line 673: 🔍 [DEBUG] Original AI response: [response without conversation context]
Line 674: 🔍 [DEBUG] Regular conversation - no data required
```

**Root Cause**: FT-200 removed automatic history but didn't add automatic conversation context loading.

---

## **Solution: System-Driven Conversation Context**

### **Core Concept**
Follow the exact same architectural pattern as time context loading:
- **System responsibility** (not AI decision-making)
- **Pre-execute** conversation MCP commands before AI processing
- **Inject** results into system prompt (not API messages)
- **Controlled** by FT-200 feature toggle

### **Architecture Pattern**
```
Current: User Message → Clean Context → AI Response (no conversation awareness)
Proposed: User Message → Load Time Context → Load Conversation Context → AI Response (full awareness)
```

---

## **Technical Implementation**

### **Phase 1: Add Conversation Context Loading (45 minutes)**

**File**: `lib/services/claude_service.dart`
```dart
// Add after time context loading in _sendMessageInternal()
Future<String> _loadConversationContext() async {
  if (!await _isConversationDatabaseEnabled()) {
    return ''; // FT-200 disabled, no context
  }
  
  try {
    // Execute conversation MCP commands directly (like time context)
    final recentMessages = await _systemMCP!.processCommand(
      '{"action":"get_recent_user_messages","limit":5}'
    );
    final personaMessages = await _systemMCP!.processCommand(
      '{"action":"get_current_persona_messages","limit":3}'
    );
    
    // Format for system prompt injection
    return _buildConversationContextPrompt(recentMessages, personaMessages);
  } catch (e) {
    _logger.warning('Failed to load conversation context: $e');
    return '';
  }
}

String _buildConversationContextPrompt(String recentMessages, String personaMessages) {
  final buffer = StringBuffer();
  
  // Parse and format recent user messages
  try {
    final recentData = json.decode(recentMessages);
    if (recentData['status'] == 'success' && recentData['data']['user_messages'].isNotEmpty) {
      buffer.writeln('## Recent User Messages:');
      for (final msg in recentData['data']['user_messages']) {
        buffer.writeln('- ${msg['time_ago']}: "${msg['text']}"');
      }
      buffer.writeln();
    }
  } catch (e) {
    _logger.warning('Failed to parse recent messages: $e');
  }
  
  // Parse and format persona messages
  try {
    final personaData = json.decode(personaMessages);
    if (personaData['status'] == 'success' && personaData['data']['persona_messages'].isNotEmpty) {
      buffer.writeln('## Your Previous Responses:');
      for (final msg in personaData['data']['persona_messages']) {
        buffer.writeln('- ${msg['time_ago']}: "${msg['text']}"');
      }
      buffer.writeln();
    }
  } catch (e) {
    _logger.warning('Failed to parse persona messages: $e');
  }
  
  return buffer.toString();
}
```

### **Phase 2: Integrate with System Prompt Assembly (15 minutes)**

**File**: `lib/services/claude_service.dart`
```dart
// In _sendMessageInternal() method, after time context loading:
final timeContext = await _timeContextService.getCurrentTimeData();

// NEW: Add conversation context loading
final conversationContext = await _loadConversationContext();

// Inject both into system prompt
final systemPrompt = await _characterManager.loadSystemPrompt(
  timeContext: timeContext,
  conversationContext: conversationContext,
);
```

**File**: `lib/config/character_config_manager.dart`
```dart
// Update loadSystemPrompt method signature:
Future<String> loadSystemPrompt({
  String? timeContext,
  String? conversationContext,
}) async {
  // ... existing code ...
  
  // Add conversation context after time context
  if (conversationContext != null && conversationContext.isNotEmpty) {
    finalPrompt += '\n\n$conversationContext';
  }
  
  // ... rest of existing code ...
}
```

---

## **Benefits Analysis**

### **1. Completes FT-200 Architecture**
- **Maintains** clean persona switching (no contamination)
- **Adds** conversation awareness (context when needed)
- **Follows** established system patterns (time context model)

### **2. System-Driven Reliability**
- **Guaranteed execution** (not dependent on AI decision-making)
- **Consistent behavior** across all personas and scenarios
- **Parallel processing** with time context loading

### **3. Performance Optimized**
- **Controlled by FT-200 toggle** (only when enabled)
- **Pre-executed** (no extra AI calls for command generation)
- **Minimal overhead** (same pattern as time context)

### **4. Architectural Consistency**
- **Same pattern** as time context loading
- **Same integration point** in ClaudeService
- **Same error handling** and logging approach

---

## **Success Metrics**

### **Immediate**
- **Conversation awareness**: AI references recent user messages naturally
- **Persona consistency**: AI avoids repeating introductions when continuing conversations
- **Clean switching**: Persona changes work without contamination (FT-200 preserved)

### **Validation**
- **Test conversation continuity**: "continue nossa conversa anterior"
- **Test persona consistency**: AI doesn't re-introduce itself unnecessarily
- **Test switching reliability**: Persona changes work immediately

---

## **Risk Mitigation**

### **Implementation Risks**
- **Performance impact**: Minimal (same pattern as time context)
- **Error handling**: Graceful degradation if MCP commands fail
- **Toggle dependency**: Controlled by existing FT-200 configuration

### **Rollback Plan**
- **Instant rollback**: Disable FT-200 toggle to remove conversation context loading
- **Code rollback**: Simple method removal if needed
- **No data changes**: Only affects context loading, not storage

---

## **Testing Strategy**

### **Unit Tests**
```dart
test('_loadConversationContext returns empty when FT-200 disabled', () async {
  // Verify toggle respect
});

test('_loadConversationContext formats MCP responses correctly', () async {
  // Verify prompt formatting
});
```

### **Integration Tests**
```dart
testWidgets('conversation context loaded in system prompt', (tester) async {
  // Verify context injection
});
```

### **Manual Validation**
1. **Enable FT-200** and send messages
2. **Verify logs** show conversation context loading
3. **Test continuity** with "continue nossa conversa"
4. **Test switching** between personas

---

## **Dependencies**

- FT-200: Conversation History Database Queries (active)
- FT-195: SystemMCP Singleton Pattern (implemented)
- Existing time context loading pattern
- CharacterConfigManager.loadSystemPrompt method

## **Related Features**

- FT-200: Conversation History Database Queries
- FT-205: System-Wide MCP Usage Enforcement
- FT-203: Fix Conversation MCP Instructions

---

## **Implementation Notes**

### **Pattern Consistency**
This feature follows the exact same pattern as:
- **Time Context**: System pre-executes `get_current_time` → injects into prompt
- **Oracle Context**: System pre-loads Oracle data → injects into prompt
- **Conversation Context**: System pre-executes conversation MCP → injects into prompt

### **FT-200 Integration**
- **Respects** FT-200 toggle (only loads when enabled)
- **Uses** FT-200's MCP commands (no new commands needed)
- **Maintains** FT-200's contamination prevention

### **Future Enhancements**
- Smart context selection based on message type
- Conversation summarization for long histories
- Semantic search integration

---

## **Conclusion**

FT-206 completes FT-200's architecture by adding the missing conversation awareness component. By following the proven time context loading pattern, this feature provides reliable conversation continuity without risking persona contamination.

**This implementation bridges the gap between clean persona switching (FT-200) and conversation awareness, creating a complete solution for multi-persona conversation management.**
