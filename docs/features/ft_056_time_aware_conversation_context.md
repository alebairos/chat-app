# Feature FT-056: Time-Aware Conversation Context

## Feature Overview

**Feature ID**: FT-056  
**Priority**: Medium  
**Category**: AI Enhancement  
**Effort Estimate**: 2-3 days  

## Executive Summary

Implement time-aware conversation context to create the perception of memory and temporal continuity across chat sessions. When users return to conversations after time gaps, the AI will have awareness of the elapsed time and can naturally reference temporal context like "yesterday," "last week," or "earlier today."

## Problem Statement

### Current State
- AI has no awareness of time gaps between conversations
- Conversations feel disconnected when resuming after breaks
- Users lose the sense of continuity in longer-term relationships with AI personas
- No differentiation between conversations happening minutes apart vs. days apart

### User Pain Points
- "The AI doesn't remember we talked yesterday"
- "It feels like starting from scratch every time I come back"
- "I want the AI to acknowledge time passing naturally"
- "Conversations don't feel like ongoing relationships"

## Product Vision

**"Enable AI personas to naturally acknowledge the passage of time, creating more human-like conversation continuity and the perception of persistent memory across sessions."**

## User Stories

### Primary User Stories

**As a user resuming a conversation after a break, I want the AI to acknowledge the time gap so that conversations feel naturally continuous.**

**Acceptance Criteria:**
- AI mentions temporal context when appropriate ("earlier today," "yesterday," etc.)
- Time awareness feels natural, not robotic
- Works consistently across all personas
- No impact on conversation quality or response time

**As a user having daily conversations with an AI persona, I want the AI to reference day-of-week and time-of-day so that interactions feel contextually aware.**

**Acceptance Criteria:**
- AI can reference current day of week ("Happy Monday," "How was your weekend?")
- AI acknowledges time of day when relevant ("Good morning," "Hope you're winding down for the evening")
- Time references feel natural and persona-appropriate

## Technical Requirements

### Functional Requirements

#### FR-1: Time Gap Detection
- **Requirement**: System must detect time gaps between last conversation and current session
- **Implementation**: Calculate duration between last message timestamp and current time
- **Acceptance**: Time gaps categorized accurately (same session, today, yesterday, this week, last week, long ago)

#### FR-2: Context Generation
- **Requirement**: Generate appropriate temporal context based on time gap
- **Implementation**: Template-based context strings injected into system prompts
- **Acceptance**: Context feels natural and appropriate for the detected time gap

#### FR-3: Day/Time Awareness
- **Requirement**: Include current day of week and general time of day in context
- **Implementation**: Add current datetime context to system prompt
- **Acceptance**: AI can naturally reference current day and time period

#### FR-4: Persona Consistency
- **Requirement**: Time awareness works identically across all personas
- **Implementation**: Universal time context service used by all persona configurations
- **Acceptance**: Ari, Sergeant Oracle, and I-There all demonstrate same time awareness capabilities

### Non-Functional Requirements

#### NFR-1: Performance
- **Requirement**: Time context generation adds < 10ms to message processing
- **Implementation**: Lightweight computational approach with minimal database queries
- **Acceptance**: No noticeable impact on conversation response time

#### NFR-2: Compatibility
- **Requirement**: Works with existing message storage and persona system
- **Implementation**: No changes to ChatMessageModel or database schema
- **Acceptance**: Existing conversations and personas function unchanged

#### NFR-3: Reliability
- **Requirement**: System gracefully handles missing or invalid timestamps
- **Implementation**: Fallback behavior when time calculation fails
- **Acceptance**: Conversations continue normally if time context fails

## Implementation Design

### Architecture Overview

```
Current Flow:
User Message → Claude Service → System Prompt + History → API

Enhanced Flow:
User Message → Time Context Service → Enhanced System Prompt + History → API
```

### Core Components

#### 1. TimeContextService
**Purpose**: Calculate time gaps and generate contextual prompts

**Key Methods:**
```dart
class TimeContextService {
  static TimeGap calculateTimeGap(DateTime lastMessage);
  static String generateTimeContext(DateTime? lastMessage);
  static String getCurrentTimeContext();
}
```

#### 2. TimeGap Enum
**Purpose**: Categorize conversation gaps

```dart
enum TimeGap {
  sameSession,     // < 30 minutes
  recentBreak,     // 30min - 4 hours  
  today,           // 4-24 hours
  yesterday,       // 1-2 days
  thisWeek,        // 2-7 days
  lastWeek,        // 1-2 weeks
  longAgo          // > 2 weeks
}
```

#### 3. Context Templates
**Purpose**: Natural language time references

```dart
Map<TimeGap, String> contextTemplates = {
  TimeGap.sameSession: '',
  TimeGap.recentBreak: 'Note: Conversation resuming after a short break.',
  TimeGap.today: 'Note: Conversation resuming later today.',
  TimeGap.yesterday: 'Note: Conversation resuming from yesterday.',
  TimeGap.thisWeek: 'Note: Conversation resuming from earlier this week.',
  TimeGap.lastWeek: 'Note: Conversation resuming from last week.',
  TimeGap.longAgo: 'Note: Conversation resuming after a significant time gap.',
};
```

### Integration Points

#### ClaudeService Enhancement
- Inject time context into system prompt before API calls
- Maintain existing conversation history logic
- Add current day/time context to each session

#### ChatStorageService Integration
- Use existing `getMessages()` to fetch last message timestamp
- No schema changes required
- Leverage existing timestamp indexing

## Implementation Phases

### Phase 1: Basic Time Awareness (This Feature)
**Scope**: Core time gap detection and context injection

**Deliverables:**
- TimeContextService implementation
- Integration with ClaudeService
- Time gap detection (same session → long ago)
- Day-of-week and time-of-day awareness
- Universal persona support

**Timeline**: 2-3 days

### Phase 2: Enhanced Context (Future)
**Scope**: Richer temporal context

**Potential Features:**
- Last conversation summary for longer gaps
- Conversation frequency awareness
- Seasonal/holiday awareness
- Time-based greeting variations

### Phase 3: Intelligent Memory (Future)
**Scope**: Content-aware temporal context

**Potential Features:**
- Topic continuity across time gaps
- Important event memory
- Progressive relationship building

## Technical Specifications

### Time Gap Calculation
```dart
TimeGap _calculateTimeGap(DateTime messageTime) {
  final now = DateTime.now();
  final difference = now.difference(messageTime);
  
  if (difference.inMinutes < 30) return TimeGap.sameSession;
  if (difference.inHours < 4) return TimeGap.recentBreak;
  if (difference.inDays == 0) return TimeGap.today;
  if (difference.inDays == 1) return TimeGap.yesterday;
  if (difference.inDays <= 7) return TimeGap.thisWeek;
  if (difference.inDays <= 14) return TimeGap.lastWeek;
  return TimeGap.longAgo;
}
```

### Current Time Context
```dart
String _getCurrentTimeContext() {
  final now = DateTime.now();
  final dayOfWeek = _getDayOfWeekName(now.weekday);
  final timeOfDay = _getTimeOfDay(now.hour);
  
  return 'Current context: It is $dayOfWeek $timeOfDay.';
}
```

### System Prompt Enhancement
```dart
String _buildEnhancedSystemPrompt() {
  String basePrompt = _systemPrompt ?? '';
  
  // Add time context
  final timeContext = TimeContextService.generateTimeContext(_lastMessageTime);
  final currentContext = TimeContextService.getCurrentTimeContext();
  
  if (timeContext.isNotEmpty || currentContext.isNotEmpty) {
    basePrompt = '$timeContext\n$currentContext\n\n$basePrompt';
  }
  
  return basePrompt;
}
```

## Testing Strategy

### Unit Tests
- TimeContextService time gap calculations
- Context template generation
- Edge cases (null timestamps, future dates)
- Day-of-week and time-of-day logic

### Integration Tests
- ClaudeService integration
- System prompt enhancement
- Cross-persona consistency
- Performance impact measurement

### User Experience Tests
- Natural conversation flow with time gaps
- Persona-specific time awareness validation
- Error handling and graceful degradation

## Success Metrics

### Quantitative Metrics
- Time context generation performance < 10ms
- Zero impact on existing conversation functionality
- 100% persona compatibility

### Qualitative Metrics
- Users report improved conversation continuity
- Natural time references in AI responses
- Enhanced perception of AI memory and awareness

## Dependencies

### Internal Dependencies
- Existing ChatMessageModel with timestamp field
- ClaudeService system prompt injection
- ConfigLoader persona system

### External Dependencies
- None (uses standard Dart DateTime functionality)

## Risk Assessment

### Technical Risks
- **Low Risk**: Minimal code changes, leveraging existing infrastructure
- **Mitigation**: Comprehensive testing and graceful fallback behavior

### User Experience Risks
- **Low Risk**: Additive feature that enhances without disrupting
- **Mitigation**: Conservative time reference templates, optional context injection

## Future Enhancements

### Natural Extensions
1. **Conversation Summaries**: Brief summaries for longer time gaps
2. **Frequency Awareness**: "We've been chatting daily this week"
3. **Contextual Greetings**: Time-appropriate conversation starters
4. **Memory Persistence**: Key topic retention across sessions

### Integration Opportunities
1. **Calendar Integration**: Awareness of user's actual schedule
2. **Location Services**: Time zone and location-aware context
3. **Usage Analytics**: Pattern-based conversation insights

## Conclusion

This feature provides immediate improvement to conversation continuity with minimal implementation complexity. By leveraging existing infrastructure and focusing on simple, natural time awareness, we create a foundation for more sophisticated memory and context features while delivering immediate user value.

The computational approach ensures accuracy, maintainability, and performance while avoiding the complexity of persistent memory storage. This aligns perfectly with the "simplest thing that could possibly work" philosophy while opening pathways for future enhancements.
