# FT-150-Simple: Basic Conversation History Loading for Oracle 4.2 Coaching

**Feature ID:** FT-150-Simple  
**Priority:** High  
**Category:** Memory Enhancement / Oracle 4.2 Optimization  
**Effort Estimate:** 15 minutes  
**Status:** Specification  
**Dependencies:** FT-156 (Activity Message Linking) - Already Implemented  

## Problem Statement

**Oracle 4.2 has no cross-session memory**: AI starts fresh each session, causing users to re-explain context and breaking coaching continuity. This severely impacts the coaching experience.

**Current State:**
```
Session 1: User: "Acabei de beber água"
          Oracle: "Ótimo! Continue assim!"

Session 2: User: "Como está minha hidratação?"  
          Oracle: "Vou verificar suas atividades..." (no memory of previous conversation)
```

**Desired State:**
```
Session 2: User: "Como está minha hidratação?"
          Oracle: "Lembro que ontem você disse 'Acabei de beber água' às 20h57. Como está hoje?"
```

## Business Value

### Immediate Oracle 4.2 Benefits
- **Coaching Continuity**: References previous conversations naturally
- **Reduced Context Re-explanation**: Users don't need to repeat information
- **Enhanced Coaching Experience**: Feels like talking to someone who remembers
- **FT-156 Synergy**: Combines with activity message linking for rich context

### Technical Benefits
- **Minimal Token Impact**: +500-1,000 tokens (vs Oracle 4.2's 15,000+ token issues)
- **Zero Breaking Changes**: Additive enhancement only
- **Immediate Value**: Works instantly with existing FT-156 data

## Functional Requirements

### FR-1: Basic History Loading
**As Oracle 4.2, I need access to recent conversation history to provide coaching continuity.**

#### Acceptance Criteria:
- ✅ Load 5 most recent messages from database on `ClaudeService.initialize()`
- ✅ Convert messages to Claude API conversation history format
- ✅ Include both user and assistant messages for full context
- ✅ Graceful degradation if storage service unavailable
- ✅ No impact on existing conversation flow

### FR-2: FT-156 Integration
**As Oracle 4.2, I need to cross-reference conversation history with activity data for rich coaching context.**

#### Acceptance Criteria:
- ✅ Conversation history provides recent user statements
- ✅ `get_activity_stats` provides activities with `sourceMessageText` (already implemented)
- ✅ Oracle 4.2 can cross-reference both data sources
- ✅ Enable responses like: "You said 'X' and I detected activity Y"

## Technical Implementation

### Core Changes

**File:** `lib/services/claude_service.dart`

#### 1. Add History Loading Method
```dart
Future<void> _loadRecentHistory({int limit = 5}) async {
  if (_storageService == null) return;
  
  final recentMessages = await _storageService!.getMessages(limit: limit);
  
  // Convert to conversation history format (newest first, so reverse)
  for (final message in recentMessages.reversed) {
    _conversationHistory.add({
      'role': message.isUser ? 'user' : 'assistant',
      'content': [{'type': 'text', 'text': message.text}],
    });
  }
}
```

#### 2. Update Initialization
```dart
Future<bool> initialize() async {
  if (!_isInitialized) {
    try {
      _systemPrompt = await _configLoader.loadSystemPrompt();
      
      // FT-150-Simple: Load recent conversation history for context
      await _loadRecentHistory(limit: 5);
      
      _isInitialized = true;
    } catch (e) {
      _logger.error('Error initializing Claude service: $e');
      return false;
    }
  }
  return _isInitialized;
}
```

### Configuration
- **History Limit**: 5 messages (2-3 conversation exchanges)
- **Token Impact**: ~500-1,000 tokens per request
- **Memory Usage**: Minimal (5 message objects)

## Expected Behavior

### Before Implementation
- Oracle 4.2 starts fresh each session
- No memory of previous conversations
- Users must re-explain context
- Coaching feels disconnected

### After Implementation
- Oracle 4.2 remembers last 5 messages across sessions
- Can reference previous conversations: "You mentioned X yesterday"
- Combined with FT-156: "You said 'Acabei de beber água' and I detected hydration activity"
- Coaching feels continuous and attentive

## Success Criteria

1. **Cross-Session Memory**: Oracle 4.2 references previous conversation facts
2. **FT-156 Synergy**: Cross-references conversation history with activity data
3. **Performance**: No noticeable impact on response time
4. **Rate Limits**: Minimal token increase (~500-1,000 vs 15,000+ Oracle issues)
5. **User Experience**: Coaching feels continuous and personalized

## Implementation Notes

- **Backward Compatible**: No breaking changes to existing functionality
- **Graceful Degradation**: Works even if storage service unavailable
- **FT-156 Leverage**: Automatically benefits from existing activity message linking
- **Oracle 4.2 Focused**: Specifically designed to enhance coaching experience

## Testing Strategy

```dart
testWidgets('loads recent conversation history on initialization', (tester) async {
  // Setup: Add messages to storage
  await storageService.saveMessage(text: 'Acabei de beber água', isUser: true, type: MessageType.text);
  await storageService.saveMessage(text: 'Ótimo! Continue assim!', isUser: false, type: MessageType.text);
  
  // Test: Initialize service
  final service = ClaudeService(storageService: storageService);
  await service.initialize();
  
  // Verify: History loaded
  expect(service.conversationHistory.length, equals(2));
  expect(service.conversationHistory[0]['role'], equals('user'));
  expect(service.conversationHistory[0]['content'][0]['text'], equals('Acabei de beber água'));
  expect(service.conversationHistory[1]['role'], equals('assistant'));
});
```

## Risk Assessment

- **Risk Level**: Minimal
- **Breaking Changes**: None
- **Performance Impact**: Negligible (+500-1,000 tokens)
- **Rollback**: Simple (remove method call from initialize)

## Oracle 4.2 Coaching Enhancement

This simple implementation transforms Oracle 4.2 from a session-based coach to a **continuous coaching companion** that:

1. **Remembers previous conversations**
2. **Cross-references with FT-156 activity data**
3. **Provides rich, contextual coaching responses**
4. **Creates natural coaching continuity**

**Example Enhanced Response:**
```
User: "Como está minha hidratação?"
Oracle 4.2: "Lembro que ontem você disse 'Acabei de beber água' às 20h57, e depois comentou que estava se sentindo melhor. Vejo que você tem um padrão consistente de hidratação. Como está hoje?"
```

This leverages both conversation history (FT-150-Simple) and activity data (FT-156) for maximum coaching impact.
