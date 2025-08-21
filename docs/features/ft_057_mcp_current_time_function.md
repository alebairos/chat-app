# Feature FT-057: MCP Current Time Function

## Feature Overview

**Feature ID**: FT-057  
**Priority**: Low  
**Category**: AI Enhancement  
**Effort Estimate**: 30 minutes  

## Executive Summary

Add a simple MCP function that allows AI personas to request the exact current time during conversations. This enables precise time awareness, calculations, and scheduling capabilities that complement the existing time-aware conversation context system.

## Problem Statement

### Current State
- AI has basic time awareness through system prompts ("quinta-feira à tarde")
- No ability to get precise current time during conversation
- Cannot perform time calculations or scheduling
- Time context is computed only at message start, not on-demand

### User Pain Points
- AI says "I don't know what time it is exactly" when asked
- Cannot help with scheduling or time-based planning
- No ability to calculate durations or time differences
- Limited usefulness for time-sensitive conversations

## Solution Approach

### The Simplest Thing That Could Possibly Work

Add a single MCP function `get_current_time` that returns basic time information when the AI requests it.

**Core Principle**: Minimal implementation, maximum utility.

## Functional Requirements

### Primary Function
- **get_current_time**: Returns current timestamp and readable time

### Data Returned
```json
{
  "status": "success",
  "data": {
    "timestamp": "2024-01-18T15:30:45.123Z",
    "hour": 15,
    "minute": 30,
    "dayOfWeek": "Thursday",
    "timeOfDay": "afternoon",
    "readableTime": "Thursday, January 18, 2024 at 3:30 PM"
  }
}
```

### AI Capabilities Enabled
- Answer "What time is it?" precisely
- Calculate time differences
- Help with scheduling
- Provide time-aware responses

## Technical Implementation

### Architecture

```
ChatScreen → ClaudeService → LifePlanMCPService.get_current_time()
                ↓
          Add to system prompt: "You can call get_current_time function"
```

### Implementation Steps

1. **Add to MCP Service** (`lib/services/life_plan_mcp_service.dart`)
   ```dart
   case 'get_current_time':
     final now = DateTime.now();
     return json.encode({
       'status': 'success',
       'data': {
         'timestamp': now.toIso8601String(),
         'hour': now.hour,
         'minute': now.minute,
         'dayOfWeek': _getDayOfWeek(now.weekday),
         'timeOfDay': _getTimeOfDay(now.hour),
         'readableTime': DateFormat('EEEE, MMMM d, yyyy \'at\' h:mm a').format(now),
       }
     });
   ```

2. **Update System Prompt**
   - Add function documentation to persona prompts
   - Simple instruction: "Use get_current_time when you need exact time"

3. **Helper Methods**
   ```dart
   String _getDayOfWeek(int weekday) { /* ... */ }
   String _getTimeOfDay(int hour) { /* ... */ }
   ```

## Non-Functional Requirements

### Performance
- **Target**: < 1ms execution time
- **Impact**: Negligible (0.003% of total response time)
- **Local execution**: No network calls required

### Reliability
- **Fallback**: If function fails, continue without time data
- **Error handling**: Return error status in JSON response
- **No dependencies**: Uses only built-in DateTime

### Maintainability
- **Code size**: ~20 lines total
- **Complexity**: Minimal (simple JSON response)
- **Testing**: Unit tests for time formatting

## Success Metrics

### Immediate Success
- [ ] AI can answer "What time is it?" with exact time
- [ ] Function executes in < 1ms
- [ ] No impact on message response times

### User Value
- [ ] AI provides helpful time-based responses
- [ ] Users can ask scheduling questions
- [ ] Improved perception of AI competence

## Testing Strategy

### Unit Tests
```dart
testWidgets('get_current_time returns valid response', (tester) async {
  final service = LifePlanMCPService(mockLifePlanService);
  final response = service.processCommand('{"action": "get_current_time"}');
  final decoded = json.decode(response);
  
  expect(decoded['status'], 'success');
  expect(decoded['data']['hour'], isA<int>());
  expect(decoded['data']['dayOfWeek'], isA<String>());
});
```

### Integration Tests
- Test AI can call function via system prompt
- Verify time data appears in conversations
- Test error handling

### Manual Testing
1. Ask AI: "What time is it exactly?"
2. Ask AI: "What time should I schedule lunch?"
3. Ask AI: "How many hours until 6 PM?"

## Implementation Notes

### Design Decisions
- **JSON response**: Consistent with existing MCP pattern
- **Multiple formats**: Both machine-readable and human-readable time
- **Localization**: Uses system locale for readable format
- **No timezone complexity**: Uses device local time

### Future Considerations (Not Implemented)
- Timezone conversion capabilities
- Calendar integration
- Alarm/reminder functionality
- Time zone awareness for different users

### Dependencies
- No new dependencies required
- Uses existing MCP infrastructure
- Leverages built-in DateTime and DateFormat

## Acceptance Criteria

### Definition of Done
- [ ] Function added to LifePlanMCPService
- [ ] AI can successfully call function
- [ ] Returns properly formatted time data
- [ ] Unit tests pass
- [ ] Manual testing confirms functionality
- [ ] Performance impact < 1ms
- [ ] Documentation updated

### User Acceptance
- [ ] AI responds to "What time is it?" with exact time
- [ ] AI can help with basic time calculations
- [ ] No degradation in message response speed
- [ ] Function works across all personas (Ari, Oracle, I-There)

## Risk Assessment

### Technical Risks
- **Risk**: Function call overhead
- **Mitigation**: Local execution, no network dependency
- **Probability**: Very Low

### User Experience Risks
- **Risk**: Over-reliance on time queries
- **Mitigation**: Simple implementation, natural conversation flow
- **Probability**: Low

## Conclusion

This feature provides significant utility with minimal implementation effort. The MCP infrastructure already exists, making this a perfect "quick win" that enhances AI capabilities with negligible risk or complexity.

**Key Benefit**: Transform AI from "I don't know what time it is" to precise time awareness and scheduling assistance with just 20 lines of code.
