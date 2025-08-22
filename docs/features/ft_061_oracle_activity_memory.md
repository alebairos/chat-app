# FT-061: Oracle Activity Memory

**Feature ID**: FT-061  
**Priority**: Medium  
**Category**: Activity Tracking  
**Effort Estimate**: 3-4 hours  
**Depends On**: FT-060 (Enhanced Time Awareness)

## Overview

Implement intelligent activity tracking that gives the AI long-term memory of user activities and habits. The system will dynamically parse Oracle framework activities from persona configs and use AI-powered natural language detection to track completed activities with precise timestamps.

## Problem Statement

Currently, the AI has no memory of user activities beyond the current conversation session. This limits its ability to:

- Track habit consistency over time
- Provide contextual recommendations based on past activities
- Celebrate progress and identify patterns
- Support the app's goal of helping users achieve "maximum human potential"

The solution must be persona-aware, reading Oracle activities directly from configs without hardcoding, and handle natural language detection of completed activities.

## Solution Architecture

### Core Components

1. **OracleActivityParser**: Dynamically parses activities from persona Oracle configs
2. **SystemMCP extract_activities**: AI-powered activity detection from natural language
3. **ActivityMemoryService**: Manages activity storage and retrieval using Isar
4. **Enhanced ClaudeService**: Injects activity context into conversations

### Key Features

- **Zero Hardcoding**: All activities parsed dynamically from Oracle prompts
- **Persona-Specific**: Each persona gets its actual Oracle framework
- **AI-Powered Detection**: Natural language understanding vs brittle keyword matching
- **Precise Timestamps**: Leverages FT-060 for exact time tracking
- **Smart Context**: Provides activity insights in conversations

## Functional Requirements

### FR-1: Dynamic Oracle Activity Parsing

The system shall dynamically parse Oracle activities from persona configurations:

- **FR-1.1**: Parse dimensions from Oracle prompt structure (e.g., "SAÚDE FÍSICA (SF)")
- **FR-1.2**: Parse activities from main library section with scores
- **FR-1.3**: Parse missing activities referenced in trilhas but not in library
- **FR-1.4**: Handle inconsistencies in Oracle prompt structure
- **FR-1.5**: Support personas without Oracle configs (custom activities only)

**Expected Oracle 2.1 Results:**
- Dimensions: 5 (R, SF, TG, E, SM)
- Library Activities: ~33 (SF1-SF13, T1-T18, SM1-SM10, E1-E7, R1-R6)
- Trilha Activities: ~2 (SF19, SF22) discovered from usage references
- Total: ~35 activities parsed dynamically

### FR-2: AI-Powered Activity Detection

The system shall use natural language understanding to detect completed activities:

- **FR-2.1**: Analyze user messages for activity completion (not planning)
- **FR-2.2**: Match against current persona's Oracle activities
- **FR-2.3**: Detect custom activities not in Oracle framework
- **FR-2.4**: Extract duration when mentioned
- **FR-2.5**: Assign confidence scores to detections
- **FR-2.6**: Handle multiple activities in one message

**Detection Examples:**
```
"Acabei de meditar 10 minutos" → SM1 (Meditar/Mindfulness) + 10min
"Fiz academia e bebi água" → Custom (gym) + SF1 (Beber água)
"Terminei sessão de foco de 25min" → T8 (Pomodoro) + 25min
"Vou meditar agora" → No detection (future intention)
```

### FR-3: Activity Memory Storage

The system shall store detected activities with rich metadata:

- **FR-3.1**: Store in Isar database for offline access
- **FR-3.2**: Include precise timestamps from FT-060
- **FR-3.3**: Track Oracle code, name, dimension, duration, notes
- **FR-3.4**: Support both Oracle and custom activities
- **FR-3.5**: Enable efficient querying by date ranges and dimensions

**Activity Model:**
```dart
@collection
class ActivityModel {
  Id id = Isar.autoIncrement;
  
  // Activity identification
  String? activityCode;  // "SF1", null for custom
  late String activityName;  // "Beber água", "Academia treino"
  late String dimension;  // "saude_fisica", "custom"
  late String source;  // "Oracle oracle_prompt_2.1.md", "Custom"
  
  // Completion details (FT-060 integration)
  late DateTime completedAt;
  late int hour;
  late int minute;
  late String dayOfWeek;
  late String timeOfDay;
  int? durationMinutes;
  String? notes;
  
  // Metadata
  late DateTime createdAt;
  double confidence = 1.0;
}
```

### FR-4: Smart Activity Context

The system shall provide intelligent activity context in conversations:

- **FR-4.1**: Generate activity summaries for recent periods (7 days, 30 days)
- **FR-4.2**: Group activities by Oracle dimensions
- **FR-4.3**: Identify activity patterns and streaks
- **FR-4.4**: Provide insights for conversation enhancement
- **FR-4.5**: Update context when persona changes

**Context Example:**
```
Oracle Framework (oracle_prompt_2.1.md):
• Saúde Física: 15 activities available
• Trabalho Gratificante: 10 activities available
• Saúde Mental: 10 activities available

Recent Activity Memory (7 days):
• Saúde Física: 12 activities (SF1 daily streak 4 days, T8 3x this week)
• Trabalho Gratificante: 5 activities (peak focus 23:00-24:00 pattern)
• Custom: 3 activities (Academia 2x, Reading 30min sessions)

Smart Insights:
- Meditation gap: Last SM1 session 2 days ago
- Hydration consistent: SF1 evening pattern established
- Focus sessions: Thursday-Friday pattern emerging
```

## Non-Functional Requirements

### NFR-1: Performance
- Oracle parsing cached until persona change
- Activity queries optimized with Isar indexes
- Context generation under 100ms for 7-day periods

### NFR-2: Reliability
- Graceful handling of malformed Oracle prompts
- Fallback to custom activities if Oracle parsing fails
- Confidence thresholds for activity detection

### NFR-3: Maintainability
- Zero hardcoded activity definitions
- Clean separation of parsing, detection, and storage
- Extensive logging for debugging activity detection

### NFR-4: Scalability
- Support for unlimited custom activities
- Efficient storage for long-term activity history
- Extensible to new Oracle prompt versions

## Technical Architecture

### File Structure
```
lib/services/
├── oracle_activity_parser.dart     # Dynamic Oracle parsing
├── activity_memory_service.dart    # Activity storage/retrieval
└── system_mcp_service.dart         # Enhanced with extract_activities

lib/models/
└── activity_model.dart             # Isar activity model

test/services/
├── oracle_activity_parser_test.dart
├── activity_memory_service_test.dart
└── ft061_activity_detection_test.dart
```

### Integration Points

1. **CharacterConfigManager**: Gets Oracle config paths
2. **SystemMCP**: Processes extract_activities commands
3. **ClaudeService**: Injects activity context and processes MCP responses
4. **TimeContextService**: Provides precise timestamps via FT-060
5. **Isar Database**: Stores ActivityModel records

### MCP Function Specification

```dart
// New SystemMCP function
case 'extract_activities':
  final message = jsonDecode(command)['message'] as String;
  return await _extractActivities(message);

Future<String> _extractActivities(String message) async {
  final oracleResult = await OracleActivityParser.parseFromPersona();
  
  // Build dynamic activity catalog for AI analysis
  final activityCatalog = oracleResult.activities.entries.map((entry) {
    return '${entry.key}: ${entry.value.name} [${entry.value.dimension.displayName}]';
  }).join('\n');
  
  final analysisPrompt = '''
Analyze this message for completed activities: "$message"

Oracle Activities (${oracleResult.totalCount} available):
$activityCatalog

Also detect custom activities. Return JSON with COMPLETED activities only:
{
  "activities": [
    {
      "code": "SF1",
      "name": "Beber água", 
      "confidence": 0.95,
      "type": "oracle",
      "duration_minutes": 0
    },
    {
      "name": "Academia treino",
      "confidence": 0.8,
      "type": "custom", 
      "dimension": "physical",
      "duration_minutes": 45
    }
  ]
}
''';

  return await _analyzeWithAI(message, analysisPrompt);
}
```

## Implementation Plan

### Phase 1: Oracle Activity Parser (1 hour)
1. Create OracleActivityParser service
2. Implement dynamic dimension parsing
3. Parse library activities with scores
4. Parse trilha activities (missing from library)
5. Add comprehensive caching

### Phase 2: Activity Detection & Storage (1.5 hours)
1. Enhance SystemMCP with extract_activities
2. Create ActivityModel and ActivityMemoryService
3. Implement AI-powered activity analysis
4. Add activity logging with FT-060 timestamps

### Phase 3: Context Integration (1 hour)
1. Enhance ClaudeService with activity context generation
2. Implement MCP response processing
3. Add smart activity insights
4. Update system prompt with activity instructions

### Phase 4: Testing & Validation (0.5 hours)
1. Test Oracle 2.1 parsing completeness
2. Validate activity detection accuracy
3. Test persona switching
4. Verify context generation performance

## Testing Strategy

### Unit Tests
- `OracleActivityParser` with various Oracle prompt formats
- `ActivityMemoryService` CRUD operations
- Activity detection confidence scoring

### Integration Tests
- End-to-end activity flow: message → detection → storage → context
- Persona switching with different Oracle configs
- MCP command processing

### Manual Testing
- Test natural language variations
- Verify Oracle 2.1 activity completeness
- Test custom activity detection
- Validate activity context in conversations

## Success Criteria

1. ✅ **Zero Hardcoding**: All activities parsed from Oracle configs
2. ✅ **Oracle 2.1 Complete**: All ~35 activities discovered (library + trilhas)
3. ✅ **Natural Language**: Handles varied Portuguese/English phrasing
4. ✅ **Persona-Specific**: Each persona gets its Oracle framework
5. ✅ **Smart Context**: AI receives relevant activity memory
6. ✅ **Precise Timing**: Activities timestamped with FT-060 precision

## Future Enhancements

- **Activity Streaks**: Track consecutive days for habits
- **Pattern Recognition**: Identify optimal timing patterns
- **Goal Integration**: Connect activities to OKRs and trilhas
- **Remote Sync**: Sync activities with external systems
- **Activity Insights**: Weekly/monthly activity reports
- **Habit Recommendations**: AI suggests activities based on patterns

## Dependencies

- **FT-060**: Enhanced Time Awareness (precise timestamps)
- **Isar Database**: Activity storage
- **Persona Config System**: Oracle prompt access
- **SystemMCP**: MCP command infrastructure

## Risk Assessment

**Low Risk**: Builds on existing proven patterns (FT-060, SystemMCP, Isar storage)

**Mitigation Strategies:**
- Graceful degradation if Oracle parsing fails
- Confidence thresholds for activity detection
- Comprehensive logging for debugging
- Fallback to basic keyword detection if AI analysis fails

---

**This feature provides the foundation for long-term activity memory, enabling the AI to support users' journey toward maximum human potential with personalized, data-driven insights.**
