# FT-149: Universal Metadata Intelligence Enhancement

**Feature ID**: FT-149.1  
**Priority**: Medium  
**Category**: Data Enhancement / User Experience  
**Effort**: 1-2 hours  
**Parent Feature**: FT-149 Activity Metadata Intelligence

## Problem Statement

Current FT-149 metadata extraction is **conservative and limited**, capturing only basic information like substance type. The system lacks the intelligence to extract rich behavioral context that could significantly enhance user engagement and self-awareness.

**Current State**: `{"activity_code": "SF1", "substance": "water"}`  
**Desired State**: Rich behavioral intelligence across all human activity dimensions

## Solution Overview

Enhance the existing FT-149 metadata extraction with a **Universal Metadata Intelligence Framework** that captures comprehensive behavioral context without habit-specific hardcoding.

### Core Innovation: Habit-Agnostic Intelligence

Instead of teaching the system specific vocabulary for each activity type, provide **universal principles** that apply to any human behavior, leveraging Claude's natural language understanding to extract meaningful patterns.

## 🎯 Universal Metadata Framework

### Four Universal Dimensions

#### 1. **Quantitative Dimensions**
- **Scale/Magnitude**: How much, how many, how big, how far, how heavy
- **Time**: Duration, frequency, timing, sequence, intervals  
- **Performance**: Speed, intensity, efficiency, accuracy, completion rate

#### 2. **Qualitative Dimensions**
- **Experience Quality**: How it felt, perceived difficulty, satisfaction level
- **Method/Approach**: Technique, style, tools, process used
- **Conditions**: Environment, circumstances, context, constraints

#### 3. **Relational Dimensions**
- **Comparison**: Better/worse than usual, first time, milestone, trend
- **Causation**: What triggered it, what influenced it, what resulted
- **Social**: Alone, with others, influenced by, competing with

#### 4. **Behavioral Dimensions**
- **Motivation**: Why this happened, internal/external drivers
- **State**: Physical/mental/emotional condition before/during/after
- **Intention**: Planned vs spontaneous, goal-oriented vs reactive

## Technical Implementation

### Enhanced Prompt Strategy

```dart
/// FT-149.1: Universal metadata extraction prompt
static String _buildUniversalMetadataPrompt({
  required String userMessage,
  required String activityCode,
  required String activityName,
}) {
  return '''
You are extracting metadata to enrich human activity tracking. Your goal is to capture information that reveals patterns, progress, and engagement across any type of human behavior.

**User said**: "$userMessage"
**Activity**: $activityName

## Universal Extraction Framework

Apply these high-level principles to extract meaningful metadata:

### Quantitative Dimensions
Extract any measurable aspects mentioned or reasonably inferable:
- **Scale/Magnitude**: How much, how many, how big, how far, how heavy
- **Time**: Duration, frequency, timing, sequence, intervals
- **Performance**: Speed, intensity, efficiency, accuracy, completion rate

### Qualitative Dimensions  
Capture descriptive and subjective information:
- **Experience Quality**: How it felt, perceived difficulty, satisfaction level
- **Method/Approach**: Technique, style, tools, process used
- **Conditions**: Environment, circumstances, context, constraints

### Relational Dimensions
Identify connections and patterns:
- **Comparison**: Better/worse than usual, first time, milestone, trend
- **Causation**: What triggered it, what influenced it, what resulted
- **Social**: Alone, with others, influenced by, competing with

### Behavioral Dimensions
Understand the human element:
- **Motivation**: Why this happened, internal/external drivers
- **State**: Physical/mental/emotional condition before/during/after  
- **Intention**: Planned vs spontaneous, goal-oriented vs reactive

## Extraction Guidelines

1. **Think Human Patterns**: What would help understand this person's relationship with this activity?
2. **Be Universally Relevant**: Focus on dimensions that apply to any human behavior
3. **Preserve User Voice**: Keep subjective language that shows personal perspective
4. **Infer Intelligently**: Use context and cultural understanding
5. **Structure Meaningfully**: Organize information to reveal insights

## Output Format
Return JSON with clear, descriptive keys. Group related information logically.
Use confidence indicators for inferences: "explicit", "inferred", "estimated"

JSON:''';
}
```

### Implementation Changes

**File**: `lib/services/metadata_extraction_service.dart`
**Method**: `_buildFocusedMetadataPrompt()`
**Change Type**: Prompt enhancement (no architectural changes)

```dart
// Replace existing prompt with universal framework
static String _buildFocusedMetadataPrompt({
  required String userMessage,
  required String activityCode,
  required String activityName,
}) {
  return _buildUniversalMetadataPrompt(
    userMessage: userMessage,
    activityCode: activityCode,
    activityName: activityName,
  );
}
```

## Expected Results

### Before Enhancement
**Input**: `"marca que bebi mais um copo d'água antes de dormir, tava com sede"`
**Output**: 
```json
{"activity_code": "SF1", "substance": "water"}
```

### After Enhancement
**Input**: `"marca que bebi mais um copo d'água antes de dormir, tava com sede"`
**Output**:
```json
{
  "quantitative": {
    "amount": "1",
    "unit": "copo",
    "estimated_volume": "200ml",
    "confidence": "inferred"
  },
  "qualitative": {
    "timing_context": "before_sleep",
    "physical_state": "thirsty",
    "substance": "water",
    "confidence": "explicit"
  },
  "relational": {
    "sequence": "additional_intake",
    "trigger": "physiological_need"
  },
  "behavioral": {
    "motivation": "thirst_response",
    "intention": "need_driven",
    "timing_pattern": "bedtime_routine"
  }
}
```

## Universal Application Examples

### Water Intake (SF1)
- **Quantitative**: Volume, frequency, timing
- **Qualitative**: Thirst level, taste, temperature preference
- **Relational**: More than usual, triggered by exercise
- **Behavioral**: Habit vs need, planned vs reactive

### Exercise (SF12)
- **Quantitative**: Duration, intensity, reps, distance
- **Qualitative**: Energy level, enjoyment, perceived effort
- **Relational**: Better than last time, social vs solo
- **Behavioral**: Motivation source, planned vs spontaneous

### Work Tasks (TG8)
- **Quantitative**: Time spent, output produced, interruptions
- **Qualitative**: Focus level, difficulty, satisfaction
- **Relational**: Compared to similar tasks, deadline pressure
- **Behavioral**: Procrastination patterns, motivation, energy state

### Reading/Learning
- **Quantitative**: Pages, time, comprehension rate
- **Qualitative**: Enjoyment, difficulty, engagement level
- **Relational**: Progress toward goal, compared to other materials
- **Behavioral**: Planned vs spontaneous, environment chosen

## Benefits

### User Engagement Enhancement
- **Pattern Recognition**: "You're most productive in the morning"
- **State Correlations**: "Better performance when well-rested"
- **Motivation Insights**: "Higher completion when intrinsically motivated"
- **Environmental Factors**: "More consistent in familiar environments"

### Cross-Activity Intelligence
- "Your focus improves after physical activities"
- "Planned activities have 60% higher satisfaction"
- "Social context increases effort by 25%"
- "Stress correlates with rushed completion patterns"

### Self-Awareness Development
- Reveals hidden behavioral patterns
- Identifies optimal conditions for success
- Tracks subjective experience trends
- Connects activities to emotional states

## Success Metrics

- **Metadata Richness**: Average 4-6 metadata fields per activity (vs current 2)
- **User Insight Generation**: 70% of activities provide actionable behavioral insights
- **Pattern Recognition**: System identifies 3+ behavioral patterns per user within 2 weeks
- **Engagement Impact**: 25% increase in user reflection and self-awareness
- **Universal Application**: Framework works across all activity types without modification

## Risk Assessment

**Low Risk Enhancement**:
- ✅ No architectural changes required
- ✅ Single prompt modification
- ✅ Backward compatible (existing metadata preserved)
- ✅ Graceful degradation (falls back to basic extraction)
- ✅ Cost-neutral (same single Claude call per activity)

## Implementation Timeline

- **Phase 1** (30 minutes): Update prompt in `MetadataExtractionService`
- **Phase 2** (30 minutes): Test with various activity types
- **Phase 3** (30 minutes): Validate output quality and adjust if needed
- **Phase 4** (30 minutes): Deploy and monitor extraction quality

## Dependencies

- **FT-149**: Core metadata extraction infrastructure (completed)
- **Claude API**: Natural language understanding capabilities
- **ActivityModel**: JSON metadata storage (existing)

## Future Enhancements

- **Confidence Scoring**: Track extraction confidence over time
- **Pattern Analytics**: Automated insight generation from metadata
- **User Feedback Loop**: Learn from user corrections to improve extraction
- **Cross-Activity Correlations**: Identify relationships between different activities

---

**Key Innovation**: This enhancement transforms FT-149 from a basic data extractor into a **universal behavioral intelligence engine** that captures the human story behind every activity, regardless of the specific habit type.

**Philosophy**: "Extract the human story behind every activity" through universal principles rather than habit-specific rules.
