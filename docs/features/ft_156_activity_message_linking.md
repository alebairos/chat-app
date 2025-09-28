# FT-156: Activity Message Linking for Simple Coaching Memory

**Feature ID:** FT-156  
**Priority:** High  
**Category:** Data Enhancement / Coaching Memory  
**Status:** Specification Complete - Ready for Implementation  
**Effort:** 4-6 hours  

## Problem Statement

**Missing coaching context**: Activities are detected and stored but lack connection to the original user messages, preventing personas from providing natural coaching-style responses that reference what users actually said.

**Current State**: Activities contain rich metadata but no link to source messages
```json
{
  "activityCode": "SF1",
  "activityName": "Beber água", 
  "metadata": "{\"volume\":100,\"unit\":\"ml\"}",
  "timestamp": 1759017452686749,
  // ❌ Missing: What did the user actually say?
  // ❌ Missing: Which message triggered this detection?
}
```

**Desired State**: Activities linked to source messages for coaching context
```json
{
  "activityCode": "SF1",
  "activityName": "Beber água",
  "sourceMessageId": "msg_1759017452686749_0001",     // ✅ NEW
  "sourceMessageText": "Acabei de beber um copo d'água", // ✅ NEW
  "metadata": "{\"volume\":100,\"unit\":\"ml\"}",
  "timestamp": 1759017452686749
}
```

## Business Value

### Coaching Memory Foundation
- **Natural References**: "Lembro que ontem você disse 'Acabei de beber um copo d'água'"
- **Contextual Follow-ups**: "Como está indo essa meta de beber mais água?"
- **Progress Tracking**: "Você mencionou água 3 vezes esta semana - ótimo progresso!"
- **Emotional Continuity**: "Você parecia animado quando disse isso ontem"

### Zero Breaking Changes
- **Backward Compatible**: Existing activities continue working
- **Optional Fields**: New fields are nullable, no migration required
- **Existing Queries**: All current MCP commands work unchanged
- **UI Compatibility**: Stats screens and exports work as before

## Functional Requirements

### FR-1: Message ID Generation
**As a system, I need unique message identifiers for every user message to enable activity linking.**

#### Acceptance Criteria:
- ✅ Generate unique message ID for each user message in `ClaudeService.sendMessage()`
- ✅ Message ID format: `msg_{timestamp}_{sequence}` (e.g., `msg_1759017452686749_0001`)
- ✅ Message IDs are sequential within conversation sessions
- ✅ Message IDs persist across app sessions (stored with conversation history)

### FR-2: Activity Model Enhancement
**As a developer, I need ActivityModel to store message linking information.**

#### Acceptance Criteria:
- ✅ Add `sourceMessageId` field (nullable String) to ActivityModel
- ✅ Add `sourceMessageText` field (nullable String) to ActivityModel  
- ✅ Update Isar schema generation (`flutter packages pub run build_runner build`)
- ✅ Maintain backward compatibility with existing activities (null values allowed)
- ✅ Update `ActivityModel.fromDetection()` constructor to accept new fields

### FR-3: Activity Detection Integration
**As a system, I need all activity detection methods to capture message context.**

#### Acceptance Criteria:
- ✅ **MCP Oracle Detection**: Pass message context to `_processDetectedActivitiesFromMCP()`
- ✅ **Semantic Detection**: Pass message context to `IntegratedMCPProcessor.processTimeAndActivity()`
- ✅ **Background Detection**: Pass message context to `_progressiveActivityDetection()`
- ✅ **Activity Queue**: Pass message context to queued activities (FT-154 integration)
- ✅ All `ActivityMemoryService.logActivity()` calls include message parameters

### FR-4: MCP Context Enhancement
**As a persona, I need access to message context through existing MCP commands.**

#### Acceptance Criteria:
- ✅ `get_activity_stats` returns activities with `sourceMessageText` when available
- ✅ Existing MCP response format maintained (backward compatible)
- ✅ New fields appear in activity objects within MCP responses
- ✅ Null message fields handled gracefully (pre-FT-156 activities)

## Technical Requirements

### TR-1: Message ID Management
```dart
class MessageIdGenerator {
  static int _sequenceCounter = 0;
  
  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _sequenceCounter++;
    return "msg_${timestamp}_${_sequenceCounter.toString().padLeft(4, '0')}";
  }
  
  static void resetSequence() {
    _sequenceCounter = 0;
  }
}
```

### TR-2: ActivityModel Schema Changes
```dart
@collection
class ActivityModel {
  // ... existing fields ...
  
  // FT-156: Message linking fields
  String? sourceMessageId;     // Links to triggering message
  String? sourceMessageText;   // What user actually said
  
  // Updated constructor
  ActivityModel.fromDetection({
    // ... existing parameters ...
    this.sourceMessageId,      // NEW
    this.sourceMessageText,    // NEW
  });
}
```

### TR-3: Integration Points
```dart
// 1. ClaudeService.sendMessage() - Generate message ID
final messageId = MessageIdGenerator.generate();

// 2. All activity detection methods - Pass message context
await ActivityMemoryService.logActivity(
  // ... existing parameters ...
  sourceMessageId: messageId,
  sourceMessageText: userMessage,
);

// 3. MCP responses - Include message context
{
  "activities": [
    {
      "code": "SF1",
      "name": "Beber água",
      "sourceMessageText": "Acabei de beber um copo d'água", // NEW
      "sourceMessageId": "msg_1759017452686749_0001"          // NEW
    }
  ]
}
```

## Implementation Plan

### Phase 1: Schema Enhancement (1 hour)
1. **Update ActivityModel**
   - Add `sourceMessageId` and `sourceMessageText` fields
   - Update constructors and factory methods
   - Regenerate Isar schema

2. **Create MessageIdGenerator**
   - Implement unique ID generation
   - Add sequence management
   - Add reset functionality for testing

### Phase 2: Integration Points (2-3 hours)
1. **ClaudeService Integration**
   - Generate message ID in `sendMessage()`
   - Pass to all activity detection methods
   - Update conversation history storage

2. **Activity Detection Updates**
   - Update `_processDetectedActivitiesFromMCP()`
   - Update `IntegratedMCPProcessor.processTimeAndActivity()`
   - Update `_progressiveActivityDetection()`
   - Update all `ActivityMemoryService.logActivity()` calls

3. **Activity Queue Integration (FT-154)**
   - Update `ActivityQueue.queueActivity()` to store message context
   - Update queue processing to preserve message links

### Phase 3: MCP Enhancement (1 hour)
1. **Update MCP Responses**
   - Modify `getActivityStats()` to include message fields
   - Update response formatting in `SystemMCPService`
   - Ensure backward compatibility

2. **Testing & Validation**
   - Test with existing activities (null fields)
   - Test with new activities (populated fields)
   - Verify MCP command responses

### Phase 4: Coaching Context Foundation (1 hour)
1. **Enhanced Context Generation**
   - Update `ActivityMemoryService.generateActivityContext()`
   - Add message-aware context building
   - Prepare for future coaching prompt integration

## Non-Functional Requirements

### NFR-1: Performance
- **Message ID Generation**: < 1ms per message
- **Database Impact**: Minimal (2 additional nullable text fields)
- **Query Performance**: No impact on existing queries
- **Memory Usage**: Negligible increase (text fields only when populated)

### NFR-2: Reliability
- **Backward Compatibility**: 100% compatibility with existing activities
- **Graceful Degradation**: System works when message fields are null
- **Error Handling**: Failed message linking doesn't break activity detection
- **Data Integrity**: Message IDs are unique and persistent

### NFR-3: Maintainability
- **Minimal Code Changes**: Leverage existing infrastructure
- **Clear Separation**: Message linking is additive, not disruptive
- **Testing Friendly**: Easy to test with and without message context
- **Documentation**: Clear integration points and examples

## Dependencies

### Internal Dependencies
- **FT-154**: Activity Queue system (for message context in queued activities)
- **FT-155**: Rate limiting system (ensure message context survives rate limits)
- **Existing MCP System**: SystemMCPService and activity detection flow
- **ActivityMemoryService**: Core activity storage infrastructure

### External Dependencies
- **Isar Database**: Schema regeneration required
- **Flutter Build Runner**: For Isar code generation
- **No Breaking Changes**: Must maintain compatibility with existing data

## Testing Strategy

### Unit Tests
```dart
// Message ID generation
test('MessageIdGenerator creates unique sequential IDs', () {
  final id1 = MessageIdGenerator.generate();
  final id2 = MessageIdGenerator.generate();
  expect(id1, isNot(equals(id2)));
  expect(id1, matches(RegExp(r'msg_\d+_\d{4}')));
});

// ActivityModel with message context
test('ActivityModel stores message context correctly', () {
  final activity = ActivityModel.fromDetection(
    activityCode: 'SF1',
    activityName: 'Beber água',
    sourceMessageId: 'msg_123_0001',
    sourceMessageText: 'Bebi água',
    // ... other required fields
  );
  
  expect(activity.sourceMessageId, equals('msg_123_0001'));
  expect(activity.sourceMessageText, equals('Bebi água'));
});
```

### Integration Tests
```dart
// End-to-end message linking
testWidgets('Activity detection preserves message context', (tester) async {
  // Send message that triggers activity detection
  final response = await claudeService.sendMessage('Acabei de beber água');
  
  // Verify activity was stored with message context
  final activities = await ActivityMemoryService.getRecentActivities(1);
  expect(activities.first.sourceMessageText, equals('Acabei de beber água'));
  expect(activities.first.sourceMessageId, isNotNull);
});

// MCP response includes message context
test('get_activity_stats includes message context', () async {
  // Create activity with message context
  await ActivityMemoryService.logActivity(
    activityCode: 'SF1',
    activityName: 'Beber água',
    sourceMessageId: 'msg_123_0001',
    sourceMessageText: 'Bebi água',
    // ... other fields
  );
  
  // Query via MCP
  final result = await systemMCP.processCommand('{"action": "get_activity_stats"}');
  final data = jsonDecode(result);
  
  expect(data['data']['activities'][0]['sourceMessageText'], equals('Bebi água'));
});
```

## Success Metrics

### Immediate Success (Post-Implementation)
- ✅ **100% Message Linking**: All new activities have message context
- ✅ **Zero Breaking Changes**: Existing functionality unchanged
- ✅ **MCP Enhancement**: Activity stats include message context
- ✅ **Backward Compatibility**: Pre-FT-156 activities work normally

### Foundation for Coaching Memory
- ✅ **Context Availability**: Message context accessible via MCP
- ✅ **Natural References**: Personas can reference user's actual words
- ✅ **Conversation Continuity**: Activities linked to conversation flow
- ✅ **Coaching Readiness**: Infrastructure ready for coaching prompts

## Future Enhancements

### Immediate Follow-ups
- **FT-157**: Simple Coaching Context Integration (use message links in prompts)
- **FT-158**: Conversation Threading (group related messages and activities)
- **FT-159**: Temporal Coaching Patterns (identify user habits over time)

### Advanced Coaching Features
- **Smart Follow-ups**: "How did that presentation go?" (based on past messages)
- **Progress Tracking**: "You've mentioned exercise 5 times this week!"
- **Emotional Continuity**: "You seemed excited about that project yesterday"
- **Goal Monitoring**: "Still working on that habit you mentioned?"

## Risk Assessment

### Low Risk Implementation
- **Additive Changes**: Only adding fields, not modifying existing logic
- **Proven Infrastructure**: Leverages existing activity detection flow
- **Graceful Degradation**: Works with or without message context
- **Minimal Dependencies**: Uses established patterns and services

### Mitigation Strategies
- **Incremental Rollout**: Test with single activity detection method first
- **Fallback Handling**: Null message fields handled gracefully
- **Performance Monitoring**: Track impact on activity detection performance
- **Rollback Plan**: New fields can be ignored if issues arise

---

## Conclusion

FT-156 provides the **minimal foundation** for coaching memory by linking activities to their source messages. This simple enhancement transforms the system from "activity tracking" to "conversation-aware coaching" while maintaining 100% backward compatibility.

The implementation leverages existing infrastructure, requires minimal code changes, and creates the foundation for natural, contextual coaching interactions that make personas feel genuinely attentive and caring.

**Next Step**: Implement Phase 1 (Schema Enhancement) to begin building the coaching memory foundation.
