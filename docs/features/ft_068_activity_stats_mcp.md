# FT-068 Activity Stats MCP Command

**Feature ID**: FT-068  
**Priority**: High  
**Category**: MCP/Data Access  
**Effort Estimate**: 1-2 hours  
**Dependencies**: FT-064 (Activity Detection), ActivityMemoryService  
**Status**: Specification  

## Overview

Add a `get_activity_stats` MCP command to SystemMCPService that provides Ari with precise, real-time access to stored activity data. This ensures accurate responses when users ask about their tracked activities, replacing approximate context injection with exact database queries.

## Problem Statement

Currently, when users ask Ari about tracked activities, the response is based on pre-generated activity context that may be:
- **Imprecise**: Summarized or approximated data
- **Stale**: Generated at conversation start, not real-time
- **Incomplete**: May not include all relevant details

**Example Issue:**
- Database has 5 activities from today
- Ari responds "2 activities" (summarized/deduplicated)
- User expects exact database information

## User Story

As a user tracking activities through FT-064, when I ask Ari "what was tracked today?" or "show me my stats," I want to receive precise, real-time information directly from the database, so that I can trust the accuracy of the reported data.

## Functional Requirements

### MCP Command Interface
- **FR-068-01**: Accept `get_activity_stats` action via JSON MCP format
- **FR-068-02**: Support optional `days` parameter (default: 1 for today)
- **FR-068-03**: Return structured JSON response with activity data
- **FR-068-04**: Handle timeframe queries (today, last 7 days, etc.)
- **FR-068-05**: Provide both detailed and summary information

### Data Retrieval
- **FR-068-06**: Query ActivityMemoryService for exact database data
- **FR-068-07**: Return all activities within specified timeframe
- **FR-068-08**: Include activity codes, names, timestamps, confidence
- **FR-068-09**: Provide dimension grouping and frequency analysis
- **FR-068-10**: Calculate time ranges and patterns

### Response Format
- **FR-068-11**: Structured JSON with status, data, and summary sections
- **FR-068-12**: Individual activity details with all stored fields
- **FR-068-13**: Summary statistics (counts by dimension, most frequent)
- **FR-068-14**: Human-readable time formatting (HH:MM)
- **FR-068-15**: Error handling with meaningful error messages

## Non-Functional Requirements

### Performance
- **NFR-068-01**: Query completes within 200ms for typical datasets
- **NFR-068-02**: Handles up to 1000 activities efficiently
- **NFR-068-03**: No impact on conversation response time

### Accuracy
- **NFR-068-04**: Returns exact database contents without approximation
- **NFR-068-05**: Real-time data (no caching delays)
- **NFR-068-06**: Consistent results across multiple queries

### Integration
- **NFR-068-07**: Seamless integration with existing MCP infrastructure
- **NFR-068-08**: Compatible with all persona types
- **NFR-068-09**: Graceful error handling maintains conversation flow

## Technical Specifications

### MCP Command Format
```json
// Today's activities (default)
{"action": "get_activity_stats"}

// Specific timeframe
{"action": "get_activity_stats", "days": 7}

// Extended period
{"action": "get_activity_stats", "days": 30}
```

### Response Structure
```json
{
  "status": "success",
  "data": {
    "period": "today|last_N_days",
    "total_activities": 5,
    "activities": [
      {
        "code": "T8",
        "name": "Realizar sessão de trabalho focado (pomodoro)",
        "time": "13:43",
        "full_timestamp": "2025-08-22T13:43:35.000Z",
        "confidence": 0.9,
        "dimension": "TG",
        "source": "Oracle FT-064 Semantic",
        "notes": "User explicitly mentioned completing pomodoro"
      }
    ],
    "summary": {
      "by_dimension": {"TG": 2, "SF": 3},
      "by_activity": {"T8": 2, "SF1": 2, "SF10": 1},
      "most_frequent": "SF1",
      "max_frequency": 2,
      "time_range": "13:35 - 13:43",
      "unique_activities": 3,
      "total_occurrences": 5
    }
  }
}
```

### Error Response
```json
{
  "status": "error",
  "message": "Error getting activity stats: [details]",
  "timestamp": "2025-08-22T13:45:00.000Z"
}
```

## Implementation Details

### File Changes
**Modified Files:**
- `lib/services/system_mcp_service.dart` - Add new MCP command
- `lib/services/claude_service.dart` - Update MCP function documentation

**Dependencies:**
- Existing `ActivityMemoryService` methods
- Existing `ActivityModel` data structure
- Standard Dart JSON encoding

### Core Implementation
```dart
// In SystemMCPService
case 'get_activity_stats':
  final days = parsedCommand['days'] as int? ?? 1;
  return await _getActivityStats(days);

Future<String> _getActivityStats(int days) async {
  // Query ActivityMemoryService
  // Format response data
  // Calculate summary statistics
  // Return structured JSON
}
```

### AI Integration
```dart
// Claude system prompt addition
'- get_activity_stats: Get precise activity tracking data
  Usage: {"action": "get_activity_stats", "days": 1}
  Returns: Exact database contents with statistics'
```

## Usage Examples

### User Query Scenarios
1. **"What did I track today?"**
   - Ari calls: `{"action": "get_activity_stats"}`
   - Gets exact 5 activities with timestamps

2. **"Show me this week's activities"**
   - Ari calls: `{"action": "get_activity_stats", "days": 7}`
   - Gets comprehensive weekly data

3. **"How many times did I drink water?"**
   - Ari calls: `{"action": "get_activity_stats", "days": 7}`
   - References `by_activity.SF1` count

### Expected AI Responses
**Before (approximate):**
> "Hoje já registrei: Beber água (SF1), Pomodoro/trabalho focado (T8)"

**After (precise):**
> "Consultando seus dados... Hoje você completou 5 atividades:
> - T8 (Pomodoro): 2x (13:35, 13:43)  
> - SF1 (Água): 2x (13:38, 13:40)
> - SF10 (Proteína): 1x (13:35)
> 
> Total: 3 TG (foco), 2 SF (saúde física)"

## Testing Requirements

### Unit Tests
- MCP command parsing and validation
- Activity data retrieval accuracy
- Summary statistics calculation
- Error handling for edge cases

### Integration Tests
- End-to-end MCP command flow
- Ari using the command in conversations
- Data consistency with ActivityMemoryService
- Performance with varying dataset sizes

### Test Cases
```dart
// Basic functionality
test('should return today activities with correct format')
test('should handle days parameter correctly')
test('should calculate summary statistics accurately')

// Edge cases  
test('should handle empty database gracefully')
test('should handle invalid days parameter')
test('should maintain performance with large datasets')
```

## Acceptance Criteria

### Core Functionality
- [ ] `get_activity_stats` MCP command implemented and functional
- [ ] Returns exact database contents without approximation
- [ ] Supports flexible timeframe queries (1, 7, 30 days)
- [ ] Provides both detailed and summary information
- [ ] Integrates seamlessly with existing MCP infrastructure

### Data Accuracy
- [ ] Activity counts match database exactly
- [ ] Timestamps preserved with precision
- [ ] All activity fields included (code, name, confidence, etc.)
- [ ] Summary statistics calculated correctly
- [ ] Dimension and frequency analysis accurate

### AI Integration
- [ ] Ari can call the command successfully
- [ ] Command documented in system prompt
- [ ] Responses use precise database information
- [ ] Error states handled gracefully
- [ ] No impact on conversation performance

### Definition of Done
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] Ari provides accurate activity responses
- [ ] Performance requirements met
- [ ] Code reviewed and approved

## Future Considerations

### Enhanced Queries
- **Filtering**: By dimension, activity code, confidence level
- **Aggregation**: Daily/weekly/monthly rollups
- **Trends**: Activity patterns and streaks
- **Insights**: Goal progress and recommendations

### Stats Tab Integration
- Same MCP command can power the Stats tab UI
- Consistent data source for both conversational and visual display
- Real-time updates when new activities detected

## Notes

This feature bridges the gap between background activity detection (FT-064) and user-facing data access. By providing Ari with precise database query capabilities, we ensure users receive accurate, trustworthy information about their tracked activities.

The MCP approach maintains the existing conversation flow while adding powerful data access capabilities that will also support the upcoming Stats tab implementation.
