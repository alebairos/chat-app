# FT-200: Conversation History Database Queries

**Feature ID:** FT-200  
**Priority:** High  
**Category:** Architecture Enhancement  
**Effort:** 2 hours  
**Date:** October 18, 2025

## Overview

Replace conversation history context injection with database-driven MCP queries to eliminate persona contamination and enable reliable persona switching. This applies the proven Oracle preprocessing pattern to conversation management.

---

## **Problem Statement**

### **Current Issues**
- **Persona contamination**: AI continues responding as previous persona due to conversation history in context
- **Identity confusion**: Despite correct persona loading, AI ignores identity due to historical message patterns
- **Scalability limitations**: Loading 25 messages into every API call increases token usage and latency
- **No selective access**: Cannot filter conversation data by persona, time, or content type

### **Evidence from Logs**
```
✅ System loads correct persona config (Ryo Tzu)
✅ Database has correct persona metadata  
❌ AI ignores current persona and responds as previous persona (Aristios)
Root Cause: Conversation history contamination overrides persona identity
```

---

## **Solution: Database-Driven Conversation Queries**

### **Core Concept**
Apply the Oracle framework's successful database approach to conversation history:
- **Remove**: Conversation history from Claude API context
- **Add**: MCP commands for selective conversation queries
- **Enable**: Clean persona switching without contamination
- **Maintain**: Conversation continuity through structured queries

### **Architecture Pattern**
```
Current: Conversation History → Context Injection → Persona Contamination
Proposed: Conversation Database → MCP Queries → Clean Context Access
```

---

## **Feature Toggle Configuration**

### **Toggle Implementation**
Add feature toggle to enable safe rollout and easy rollback:

**File**: `assets/config/conversation_database_config.json`
```json
{
  "enabled": true,
  "description": "FT-200: Conversation History Database Queries",
  "fallback_to_history_injection": false,
  "mcp_commands": {
    "get_recent_user_messages": true,
    "get_current_persona_messages": true,
    "search_conversation_context": true
  },
  "performance": {
    "max_user_messages": 10,
    "max_persona_messages": 5,
    "query_timeout_ms": 200
  }
}
```

### **Toggle Logic**
**File**: `lib/services/claude_service.dart`
```dart
// In _sendMessageInternal() method
Future<bool> _isConversationDatabaseEnabled() async {
  try {
    final configString = await rootBundle.loadString(
      'assets/config/conversation_database_config.json'
    );
    final config = json.decode(configString);
    return config['enabled'] == true;
  } catch (e) {
    // Default to legacy behavior if config not found
    return false;
  }
}

// Modified conversation loading logic
if (await _isConversationDatabaseEnabled()) {
  // FT-200: Use database queries (no history injection)
  _logger.info('FT-200: Using conversation database queries');
} else {
  // Legacy: Load conversation history into context
  await _loadRecentHistory(limit: 25);
  messages.addAll(_conversationHistory);
  _logger.info('Legacy: Using conversation history injection');
}
```

### **MCP Command Toggle**
**File**: `lib/services/system_mcp_service.dart`
```dart
Future<bool> _isConversationCommandEnabled(String command) async {
  try {
    final configString = await rootBundle.loadString(
      'assets/config/conversation_database_config.json'
    );
    final config = json.decode(configString);
    return config['mcp_commands']?[command] == true;
  } catch (e) {
    return false;
  }
}

// In processCommand() method
case 'get_recent_user_messages':
  if (await _isConversationCommandEnabled('get_recent_user_messages')) {
    return await _getRecentUserMessages(parsedCommand['limit'] ?? 5);
  } else {
    return _errorResponse('Conversation database queries disabled');
  }
```

### **Toggle States**

#### **Enabled (Production Ready)**
```json
{
  "enabled": true,
  "fallback_to_history_injection": false,
  "mcp_commands": {
    "get_recent_user_messages": true,
    "get_current_persona_messages": true,
    "search_conversation_context": true
  }
}
```

#### **Disabled (Legacy Mode)**
```json
{
  "enabled": false,
  "fallback_to_history_injection": true,
  "mcp_commands": {
    "get_recent_user_messages": false,
    "get_current_persona_messages": false,
    "search_conversation_context": false
  }
}
```

#### **Gradual Rollout (Hybrid Mode)**
```json
{
  "enabled": true,
  "fallback_to_history_injection": true,
  "mcp_commands": {
    "get_recent_user_messages": true,
    "get_current_persona_messages": false,
    "search_conversation_context": false
  }
}
```

---

## **Technical Implementation**

### **Phase 1: Add Feature Toggle Logic (15 minutes)**

**File**: `lib/services/claude_service.dart`
```dart
// In _sendMessageInternal() method
// REPLACE history injection with toggle logic:
if (await _isConversationDatabaseEnabled()) {
  // FT-200: Use database queries (no history injection)
  _logger.info('FT-200: Using conversation database queries');
} else {
  // Legacy: Load conversation history into context
  await _loadRecentHistory(limit: 25);
  messages.addAll(_conversationHistory);
  _logger.info('Legacy: Using conversation history injection');
}
```

### **Phase 2: Add Conversation MCP Commands (1 hour)**

**File**: `lib/services/system_mcp_service.dart`
```dart
// Add to processCommand() method
case 'get_recent_user_messages':
  final limit = parsedCommand['limit'] ?? 5;
  return await _getRecentUserMessages(limit);

case 'get_current_persona_messages':
  final personaKey = parsedCommand['persona_key'] ?? _getCurrentPersonaKey();
  final limit = parsedCommand['limit'] ?? 3;
  return await _getCurrentPersonaMessages(personaKey, limit);

case 'search_conversation_context':
  final query = parsedCommand['query'] as String?;
  final hours = parsedCommand['hours'] ?? 24;
  return await _searchConversationContext(query, hours);
```

### **Phase 3: Database Query Implementation (45 minutes)**

**File**: `lib/services/system_mcp_service.dart`
```dart
Future<String> _getRecentUserMessages(int limit) async {
  final storageService = ChatStorageService();
  final messages = await storageService.getMessages(limit: limit * 2);
  
  // Filter to ONLY user messages (no AI persona contamination)
  final userMessages = messages
      .where((msg) => msg.isUser)
      .take(limit)
      .map((msg) => {
        'timestamp': msg.timestamp.toIso8601String(),
        'text': msg.text,
        'time_ago': _formatTimeAgo(DateTime.now().difference(msg.timestamp))
      })
      .toList();

  return json.encode({
    'status': 'success',
    'data': {
      'user_messages': userMessages,
      'context': 'Recent user messages for conversation continuity'
    }
  });
}

Future<String> _getCurrentPersonaMessages(String personaKey, int limit) async {
  final storageService = ChatStorageService();
  final messages = await storageService.getMessages(limit: 50);
  
  // Filter to ONLY current persona's messages
  final personaMessages = messages
      .where((msg) => !msg.isUser && msg.personaKey == personaKey)
      .take(limit)
      .map((msg) => {
        'timestamp': msg.timestamp.toIso8601String(),
        'text': msg.text,
        'time_ago': _formatTimeAgo(DateTime.now().difference(msg.timestamp))
      })
      .toList();

  return json.encode({
    'status': 'success',
    'data': {
      'persona_messages': personaMessages,
      'persona_key': personaKey,
      'context': 'Previous responses from current persona for consistency'
    }
  });
}
```

### **Phase 4: Create Configuration File (15 minutes)**

**File**: `assets/config/conversation_database_config.json`
```json
{
  "enabled": false,
  "description": "FT-200: Conversation History Database Queries - Start disabled for safe rollout",
  "fallback_to_history_injection": true,
  "mcp_commands": {
    "get_recent_user_messages": true,
    "get_current_persona_messages": true,
    "search_conversation_context": true
  },
  "performance": {
    "max_user_messages": 10,
    "max_persona_messages": 5,
    "query_timeout_ms": 200
  }
}
```

**File**: `assets/config/mcp_base_config.json` (Add conversation instructions)
```json
{
  "conversation_access": {
    "enabled": true,
    "instructions": "## CONVERSATION ACCESS\nWhen you need conversation context, use these commands:\n- get_recent_user_messages: Get recent user messages only\n- get_current_persona_messages: Get your previous responses for consistency\n- search_conversation_context: Find specific topics discussed\n\nCRITICAL: NEVER assume conversation context - always query when needed."
  }
}
```

---

## **Benefits Analysis**

### **1. Eliminates Persona Contamination**
- **Clean API calls**: No conflicting persona messages in context
- **Pure identity**: Each conversation turn starts with clean persona state
- **Reliable switching**: Persona changes work immediately without interference

### **2. Selective Context Access**
- **User messages only**: Get conversation flow without AI persona responses
- **Current persona history**: Maintain consistency with previous responses from same persona
- **Filtered queries**: Access specific conversation segments without contamination

### **3. Performance Optimization**
- **Reduced token usage**: No automatic 25-message injection into every API call
- **Faster responses**: Smaller API payloads reduce latency
- **Efficient queries**: Load only needed conversation data on demand

### **4. Scalable Architecture**
- **Unlimited history**: Database can store years of conversations
- **Efficient access**: Index-based queries instead of loading everything
- **Future-proof**: Foundation for advanced conversation AI features

---

## **Success Metrics**

### **Immediate (Toggle Enabled)**
- **Persona switching works**: AI responds with correct persona identity immediately after switch
- **No contamination**: AI doesn't reference previous persona's responses or style
- **Clean responses**: AI starts each conversation turn with authentic persona voice
- **Safe rollback**: Can instantly disable feature if issues arise

### **Short-term (Phases 2-4)**
- **Conversation continuity**: AI can access relevant user messages when needed
- **Persona consistency**: AI maintains voice while referencing its own previous responses
- **Query efficiency**: MCP commands return relevant conversation data in <100ms

### **Long-term**
- **Scalable conversations**: System handles unlimited conversation history
- **Advanced features**: Foundation for conversation search, summarization, analytics
- **Reliable multi-persona**: Seamless switching between any personas without issues

---

## **Testing Strategy**

### **Unit Tests**
```dart
// Test conversation MCP commands
test('get_recent_user_messages returns only user messages', () async {
  // Verify filtering logic
});

test('get_current_persona_messages filters by persona key', () async {
  // Verify persona-specific filtering
});
```

### **Integration Tests**
```dart
// Test persona switching without contamination
testWidgets('persona switching works immediately', (tester) async {
  // 1. Send message as Aristios
  // 2. Switch to Ryo Tzu
  // 3. Verify response is authentic Ryo Tzu
});
```

### **Manual Validation**
1. **Switch personas** multiple times in conversation
2. **Verify identity**: Each persona responds authentically
3. **Check continuity**: AI can reference relevant conversation when needed
4. **Confirm performance**: Responses are fast and accurate

---

## **Risk Mitigation**

### **Implementation Risks**
- **Breaking conversation flow**: Gradual rollout with fallback to current system
- **Performance impact**: Monitor query times and optimize as needed
- **Data consistency**: Validate conversation filtering logic thoroughly

### **Rollback Plan**
- **Instant rollback**: Set `"enabled": false` in `conversation_database_config.json`
- **Gradual rollback**: Disable individual MCP commands while keeping legacy system
- **Emergency fallback**: Config file missing defaults to legacy behavior
- **Data integrity**: No database changes, only query logic modifications

### **Feature Toggle Benefits**
- **Safe deployment**: Test in production with instant rollback capability
- **Gradual rollout**: Enable features incrementally for validation
- **A/B testing**: Compare performance between old and new systems
- **Zero downtime**: Toggle without app restart or deployment
- **Risk mitigation**: Immediate fallback if issues detected

---

## **Dependencies**

- Existing `ChatStorageService` and `ChatMessageModel` (persona metadata)
- `SystemMCPService` singleton pattern (FT-195)
- Isar database with conversation history
- MCP command processing infrastructure

## **Related Features**

- FT-189: Multi-Persona Awareness Fix
- FT-194: Fix Activity Detection Bypass for Philosopher  
- FT-195: Fix SystemMCP Singleton Pattern
- FT-196: Fix Persona Prefix in Responses

---

## **Implementation Notes**

### **Oracle Pattern Similarity**
This feature applies the exact same architectural pattern used successfully in Oracle activity detection:
- **Oracle**: `oracle_prompt_4.2.md` → `oracle_prompt_4.2.json` → MCP queries
- **Conversation**: Conversation history → Database queries → MCP responses

### **Backward Compatibility**
- No changes to `ChatMessageModel` structure
- No changes to conversation storage logic
- Only changes to conversation access patterns

### **Future Enhancements**
- Conversation search and semantic queries
- Conversation summarization and insights
- Advanced persona interaction analytics
- Real-time conversation coaching features

---

## **Conclusion**

FT-200 transforms conversation history from a contamination source into a queryable resource, solving the persona switching issue while providing a scalable foundation for advanced conversation features. By applying the proven Oracle preprocessing pattern, this feature ensures reliable persona identity while maintaining conversation continuity through intelligent database queries.

**This architectural change eliminates the root cause of persona contamination while enabling more sophisticated conversation management capabilities.**
