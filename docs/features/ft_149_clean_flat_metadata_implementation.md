# FT-149: Clean Flat Metadata Implementation

## Overview

**Goal**: Add quantitative metadata extraction to activity detection using a clean, flat key-value architecture.

**Principle**: Flat structure eliminates parsing complexity and ensures 100% reliability.

## Architecture

### **Flat Key-Value Structure**
```json
{
  "activities": [{
    "code": "SF15",
    "catalog_name": "Caminhar 7000 passos",
    "confidence": "high",
    "quantitative_steps_value": 7000,
    "quantitative_steps_unit": "steps",
    "quantitative_distance_value": 200,
    "quantitative_distance_unit": "meters",
    "behavioral_mood": "positive"
  }]
}
```

**Key Benefits**:
- **Zero ambiguity**: No nested structures to parse incorrectly
- **LLM-proof**: Impossible to generate wrong format
- **Trivial parsing**: Filter keys by prefix (`quantitative_*_value`)
- **Future-proof**: New measurements work automatically

## Implementation Components

### **1. LLM Instructions (`MetadataPromptEnhancement`)**

**Purpose**: Instruct LLM to generate flat structure with quantitative data.

**Key Rules**:
- Every activity MUST have quantitative data
- Use flat keys: `quantitative_{type}_value` and `quantitative_{type}_unit`
- Extract exact values from user input
- NO nested objects allowed

**Example Instructions**:
```
MANDATORY: Use flat structure only
✅ CORRECT: "quantitative_steps_value": 7000, "quantitative_steps_unit": "steps"
❌ FORBIDDEN: "metadata": {"steps": {"value": 7000}}
```

### **2. Flat Parser (`FlatMetadataParser`)**

**Purpose**: Extract quantitative measurements from flat key-value structure.

**Core Logic**:
```dart
// Filter quantitative keys
final valueKeys = metadata.keys
    .where((key) => key.startsWith('quantitative_') && key.endsWith('_value'))
    .toList();

// Extract value + unit pairs
for (final valueKey in valueKeys) {
  final type = valueKey.replaceAll('quantitative_', '').replaceAll('_value', '');
  final value = metadata[valueKey];
  final unit = metadata['quantitative_${type}_unit'];
  // Display: "👣 7000 steps"
}
```

**Supported Measurements**: steps, distance, volume, weight, duration, reps, sets, calories

### **3. System Integration (`system_mcp_service.dart`)**

**Purpose**: Integrate flat metadata into Oracle detection without conflicts.

**Integration Points**:
1. **Prompt Enhancement**: Add flat structure instructions to LLM prompt
2. **Response Parsing**: Extract flat keys from activity-level JSON
3. **Validation**: Ensure flat structure compliance

**Key Changes**:
```dart
// Add flat instructions to prompt
final metadataInstructions = MetadataPromptEnhancement.getInstructions();

// Parse flat metadata from activity level (not nested)
final flatMetadata = <String, dynamic>{};
for (final entry in activityData.entries) {
  if (entry.key.startsWith('quantitative_')) {
    flatMetadata[entry.key] = entry.value;
  }
}
```

### **4. UI Display (`ActivityCard`)**

**Purpose**: Show quantitative insights in activity cards.

**Display Logic**:
```dart
// Use flat parser
if (FlatMetadataParser.hasQuantitativeData(metadata)) {
  final measurements = FlatMetadataParser.extractQuantitative(metadata);
  final insights = measurements.map((m) => '${m["icon"]} ${m["display"]}').toList();
  // Show: "👣 7000 steps • 📏 200 meters"
}
```

### **5. Feature Configuration (`MetadataConfig`)**

**Purpose**: Enable/disable metadata functionality via feature flag.

**Configuration**:
```json
{
  "enabled": true,
  "ai_extraction": true
}
```

## Implementation Plan

### **Phase 1: Core Components (2 hours)**
1. Create `MetadataPromptEnhancement` with flat instructions
2. Create `FlatMetadataParser` with key filtering logic
3. Create `MetadataConfig` for feature flag control

### **Phase 2: System Integration (1 hour)**
1. Integrate flat instructions into `system_mcp_service.dart`
2. Add flat metadata parsing to activity detection
3. Ensure no conflicting instructions

### **Phase 3: UI Integration (1 hour)**
1. Update `ActivityCard` to use flat parser
2. Display quantitative insights with icons
3. Handle empty metadata gracefully

### **Phase 4: Validation (30 minutes)**
1. Test flat structure generation
2. Verify parsing accuracy
3. Confirm UI display

## Expected Results

### **LLM Response (After Implementation)**
```json
{
  "activities": [{
    "code": "SF15",
    "catalog_name": "Caminhar 7000 passos",
    "confidence": "high",
    "quantitative_steps_value": 7000,
    "quantitative_steps_unit": "steps",
    "quantitative_distance_value": 200,
    "quantitative_distance_unit": "meters"
  }]
}
```

### **UI Display**
```
💡 👣 7000 steps • 📏 200 meters
```

### **System Benefits**
- **100% parsing reliability** (no nested structure failures)
- **Consistent LLM output** (no conflicting instructions)
- **Zero maintenance overhead** (new measurements work automatically)
- **Fast performance** (O(n) key filtering vs O(n²) nested scanning)

## Testing Strategy

### **Unit Tests**
```dart
testWidgets('flat parser extracts quantitative measurements', (tester) async {
  final metadata = {
    'quantitative_steps_value': 7000,
    'quantitative_steps_unit': 'steps',
    'behavioral_mood': 'positive' // ignored
  };
  
  final results = FlatMetadataParser.extractQuantitative(metadata);
  expect(results.length, equals(1));
  expect(results[0]['display'], equals('7000 steps'));
});
```

### **Integration Tests**
1. **LLM Compliance**: Verify flat structure generation
2. **Parsing Accuracy**: Test various measurement types
3. **UI Display**: Confirm proper icon + value formatting
4. **Feature Flag**: Test enable/disable functionality

## Success Criteria

1. **✅ LLM generates flat structure** (no nested objects)
2. **✅ Parser extracts all quantitative measurements** (100% accuracy)
3. **✅ UI displays insights correctly** (icon + value + unit)
4. **✅ System performance maintained** (no degradation)
5. **✅ Zero conflicts** (single metadata approach only)

## Risk Mitigation

### **Low Risk Implementation**
- **Feature flag controlled**: Can be disabled instantly
- **Additive only**: No changes to core Oracle detection
- **Backward compatible**: Works with existing activities
- **Single approach**: No conflicting systems

### **Rollback Plan**
```bash
# Disable via feature flag
{"enabled": false, "ai_extraction": false}

# Or remove branch entirely
git checkout main
```

---

**Priority**: High  
**Effort**: 4.5 hours  
**Risk**: Low  
**Dependencies**: None  
**Feature Flag**: `metadata_config.json`
