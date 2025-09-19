# FT-138: Activity Metadata Registry

**Feature ID:** FT-138  
**Priority:** Medium  
**Category:** Data Enhancement / User Experience  
**Effort:** 2-3 hours  

## Problem Statement

Activities are tracked with basic information (name, time, duration) but lack rich metadata that users naturally provide:
- **Lost Context**: "bebi 500ml de água" → only stores "Beber água" (quantity lost)
- **Missing Details**: "corri 30 minutos" → duration stored but type, distance, intensity lost
- **Reduced Analytics**: Cannot analyze water consumption patterns, exercise progression, or productivity metrics
- **Poor User Value**: Stats show activity counts but not meaningful progress data

**Current Limitation:**
```
User: "fiz 3 séries de 12 flexões com 20kg"
→ Stored: "Exercício de força" (duration: null)
→ Lost: sets=3, reps=12, weight=20kg, exercise_type=push-ups
```

## Solution Overview

Extend the existing FT-119/FT-064 semantic detection system to automatically extract and store structured metadata as key-value pairs alongside activity detection.

## Core Principle

**Intelligent Context Preservation**: Capture the rich details users naturally provide about their activities without requiring additional input or changing the conversation flow.

## Technical Approach

### **Phase 1: ActivityModel Enhancement**

Extend `ActivityModel` with metadata storage:

```dart
// Add to ActivityModel
@JsonKey(includeIfNull: false)
Map<String, dynamic>? metadata;

// Usage examples:
// {"quantity": "500ml", "type": "water"}
// {"sets": 3, "reps": 12, "weight": "20kg", "exercise": "push-ups"}
// {"sessions": 2, "technique": "pomodoro", "task": "coding"}
```

### **Phase 2: Enhanced Semantic Detection**

Modify `SemanticActivityDetector._buildDetectionPrompt()` to include metadata extraction:

```dart
## Step 2: Activity Detection with Metadata Extraction
METADATA EXTRACTION RULES:
- **Hydration**: quantity (ml, cups, glasses, liters), beverage type
- **Exercise**: type, sets, reps, weight, distance, duration, intensity
- **Work/Focus**: sessions, technique, task type, tools used
- **Meals**: meal type, main ingredients, portion size
- **Sleep**: duration, quality rating, sleep/wake times

## Enhanced Output Format:
{
  "detected_activities": [
    {
      "oracle_code": "SF1",
      "activity_name": "Beber água",
      "user_description": "bebi 500ml de água",
      "duration_minutes": null,
      "confidence": "high",
      "reasoning": "User mentioned specific water quantity",
      "metadata": {
        "quantity": "500ml",
        "type": "water"
      }
    }
  ]
}
```

### **Phase 3: Processing Pipeline Integration**

Enhance `ActivityDetection` class and processing:

```dart
// Add to ActivityDetection
final Map<String, dynamic>? metadata;

// Modify _logActivitiesWithPreciseTime to store metadata
activity.metadata = detection.metadata;
```

## Functional Requirements

### **FR-138-1: Metadata Extraction**
- System extracts relevant key-value pairs from user descriptions
- Supports common activity types: hydration, exercise, work, meals, sleep
- Maintains backward compatibility with existing activities

### **FR-138-2: Flexible Storage**
- Metadata stored as JSON in ActivityModel.metadata field
- Schema-less design allows evolution without migrations
- Null metadata for activities without extractable details

### **FR-138-3: Reliable Processing**
- Metadata extraction integrated with FT-119 queue system
- Graceful degradation: activities stored even if metadata extraction fails
- No impact on conversation flow or existing functionality

## Non-Functional Requirements

### **NFR-138-1: Performance**
- Metadata extraction adds <50ms to activity processing
- JSON storage efficient for typical metadata sizes (<1KB)
- No impact on FT-119 queue processing performance

### **NFR-138-2: Reliability**
- Metadata extraction failures don't prevent activity storage
- Invalid metadata gracefully ignored with logging
- Maintains FT-119's 95% activity processing success rate

## Acceptance Criteria

### **AC-138-1: Metadata Extraction**
- [ ] Water activities extract quantity: "500ml", "2 cups", "1 liter"
- [ ] Exercise activities extract: sets, reps, weight, distance, type
- [ ] Work activities extract: sessions, duration, technique, task type
- [ ] Invalid/missing metadata doesn't break activity storage

### **AC-138-2: Data Storage**
- [ ] ActivityModel.metadata field stores JSON key-value pairs
- [ ] Database schema updated with metadata column
- [ ] Existing activities remain unaffected (null metadata)

### **AC-138-3: Processing Integration**
- [ ] Metadata extraction works with FT-119 queue system
- [ ] Rate limit scenarios preserve metadata in queued activities
- [ ] Processing logs include metadata extraction status

## Dependencies

- **FT-119**: Activity tracking graceful degradation (queue system)
- **FT-064**: Semantic activity detection (Claude integration)
- **ActivityModel**: Existing data model and storage

## Migration Considerations

- **Database Schema**: Add nullable `metadata` TEXT column to ActivityModel
- **Backward Compatibility**: Existing activities work unchanged with null metadata
- **Gradual Rollout**: New metadata extraction applies only to new activities

## Testing Strategy

### **Unit Tests**
- Metadata extraction from various user message formats
- JSON serialization/deserialization of metadata
- Graceful handling of invalid metadata

### **Integration Tests**
- End-to-end activity detection with metadata
- FT-119 queue processing with metadata preservation
- Database storage and retrieval of metadata

## Success Metrics

- **Metadata Capture Rate**: 80% of activities with user-provided details have extracted metadata
- **Processing Reliability**: Maintain FT-119's 95% success rate
- **Data Quality**: 90% of extracted metadata is accurate and useful
- **Performance Impact**: <5% increase in activity processing time

## Implementation Notes

This feature extends the proven FT-119/FT-064 infrastructure rather than replacing it. The implementation leverages Claude's semantic understanding to extract structured data from natural language, providing rich activity context without changing user interaction patterns.

**Key Benefits:**
- **Enhanced Analytics**: Track water consumption, exercise progression, productivity patterns
- **Better User Insights**: Meaningful progress data beyond simple activity counts
- **Preserved Simplicity**: No changes to user conversation flow
- **Future-Proof**: Flexible metadata schema supports new activity types
