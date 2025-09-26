# FT-149.11: Critical Metadata Extraction Fixes

**Feature ID**: FT-149.11  
**Priority**: Critical  
**Category**: Bug Fix / Data Quality  
**Effort**: 90 minutes  

## Problem Statement

Current metadata system has **4 critical failures** preventing production readiness:

### 1. Missing Metadata Detection ❌
- **"Seguir plano estruturado de corrida"**: NO metadata generated at all
- **Root Cause**: LLM fails to extract quantitative data from structured activities

### 2. Duplicate Display Issues 🔄
- **"Caminhar 7000 passos"**: Shows "Distance: 100m" twice + "Steps: 100"
- **Root Cause**: Semantic matching too broad - `distance` field matches both distance AND steps

### 3. Missing Units in Display 📏
- **Weight**: Shows "10" instead of "10kg" (unit data exists but lost)
- **Volume**: Shows "200" instead of "200ml" (unit data exists but lost)
- **Root Cause**: Parser extracts value but discards unit information

### 4. Incorrect Quantitative Values 📊
- **Walking 7000 steps**: Shows "100" instead of "7000"
- **Root Cause**: LLM generates wrong quantitative values

## Solution

**4-Phase Critical Fix Approach:**

### Phase 1: Semantic Precision (30min)
- Fix semantic matching to prevent distance/steps overlap
- Implement strict field-to-measurement mapping

### Phase 2: Unit Preservation (25min)  
- Extract and preserve unit information during parsing
- Display values with proper SI units (kg, ml, m, min)

### Phase 3: LLM Prompt Enhancement (20min)
- Improve quantitative extraction for structured activities
- Add explicit examples for running/structured plans

### Phase 4: Duplicate Elimination (15min)
- Prevent same value appearing multiple times
- Implement unique value tracking per activity

## Implementation

### 1. Fix Semantic Matching Precision (30min)
**File**: `lib/services/lean_metadata_parser.dart` & `lib/services/metadata_insight_generator.dart`

**Problem**: Current semantic matching allows `distance` field to match both distance AND steps requests.

```dart
/// Enhanced semantic matching with strict field separation
static bool _isSemanticMatch(String requestedKey, String fieldName) {
  // Steps-specific matching (STRICT - no distance overlap)
  if (requestedKey.contains('steps')) {
    return fieldName.contains('steps') && 
           !fieldName.contains('distance') && 
           !fieldName.contains('meter');
  }
  
  // Distance-specific matching (STRICT - no steps overlap)  
  if (requestedKey.contains('distance')) {
    return (fieldName.contains('distance') || fieldName.contains('meter')) &&
           !fieldName.contains('steps');
  }
  
  // Weight-related fields (STRICT)
  if (requestedKey.contains('weight')) {
    return fieldName.contains('weight') || 
           fieldName.contains('load') || 
           fieldName.contains('kg');
  }
  
  // Volume-related fields (STRICT)
  if (requestedKey.contains('volume') || requestedKey.contains('quantity')) {
    return fieldName.contains('volume') || 
           fieldName.contains('hydration') || 
           fieldName.contains('water') || 
           fieldName.contains('ml');
  }
  
  return false;
}
```

### 2. Implement Unit Preservation (25min)
**File**: `lib/services/lean_metadata_parser.dart` & `lib/services/metadata_insight_generator.dart`

**Problem**: Parser extracts values but discards unit information.

```dart
/// Enhanced value extraction with unit preservation
static Map<String, dynamic>? _extractValueWithUnit(Map<String, dynamic> fieldValue) {
  final value = fieldValue['value'] ?? fieldValue['amount'] ?? fieldValue['count'];
  final unit = fieldValue['unit'];
  
  if (value != null) {
    return {
      'value': value,
      'unit': unit ?? _inferUnit(value), // Infer unit if missing
      'raw_value': value
    };
  }
  return null;
}

/// Format value with unit for display
static String _formatValueWithUnit(dynamic value, String? unit, String key) {
  if (unit != null) {
    return '$value$unit'; // "10kg", "200ml", "7000steps"
  }
  
  // Fallback unit inference
  if (key.contains('weight')) return '${value}kg';
  if (key.contains('volume')) return '${value}ml';
  if (key.contains('distance')) return '${value}m';
  if (key.contains('steps')) return '${value}steps';
  if (key.contains('duration')) return '${value}min';
  
  return value.toString();
}
```

### 3. Enhanced LLM Prompt for Structured Activities (20min)
**File**: `lib/services/metadata_prompt_enhancement.dart`

**Problem**: LLM fails to extract quantitative data from structured activities like "Seguir plano estruturado de corrida".

```dart
static String _buildEnhancedQuantitativeInstructions() {
  return '''
## QUANTITATIVE METADATA EXTRACTION (FT-149.11)

### MANDATORY EXTRACTION RULES
1. **EVERY activity MUST have quantitative data**
2. **Extract actual values from user input** (e.g., "7000 passos" = 7000, not 100)
3. **Preserve units exactly** (kg, ml, steps, minutes, km)
4. **For structured activities**: Extract planned/target values

### STRUCTURED ACTIVITY EXAMPLES
- "Seguir plano estruturado de corrida" → Extract: duration=30min, distance=5km
- "Fazer treino de força" → Extract: duration=45min, exercises=8
- "Caminhar 7000 passos" → Extract: steps=7000 (EXACT VALUE)

### OUTPUT FORMAT (STRICT)
```json
{
  "quantitative": {
    "primary_measurement": {
      "value": 7000,
      "unit": "steps", 
      "confidence": "explicit"
    }
  }
}
```

### CRITICAL RULES
- **Use EXACT values**: "7000 passos" = value: 7000, NOT 100
- **Include units**: Always extract unit information
- **Default for unclear**: running=5km, strength=30min, walking=2000steps
''';
}
```

### 4. Duplicate Elimination (15min)
**File**: `lib/services/lean_metadata_parser.dart`

**Problem**: Same value appears multiple times due to multiple semantic matches.

```dart
/// Prevent duplicate extractions
static List<MetadataItem> _extractQuantitativeOnly(Map<String, dynamic> metadata) {
  final items = <MetadataItem>[];
  final seenValues = <String>{}; // Track unique value+unit combinations
  
  final targets = ['steps', 'distance', 'weight', 'volume', 'duration'];
  
  for (final key in targets) {
    final result = _getDirectValueWithUnit(metadata, key);
    if (result != null) {
      final valueUnit = '${result['value']}${result['unit'] ?? ''}';
      
      // Only add if not already seen
      if (!seenValues.contains(valueUnit)) {
        seenValues.add(valueUnit);
        items.add(MetadataItem(
          key: _formatKey(key), 
          value: _formatValueWithUnit(result['value'], result['unit'], key)
        ));
      }
    }
  }
  
  return items.take(3).toList();
}
```

### 2. Update Parser (20min)
**File**: `lib/services/lean_metadata_parser.dart`

Handle actual LLM-generated structure (`quantitative.volume.amount`) instead of expected structure:

```dart
static dynamic _getDirectValue(Map<String, dynamic> metadata, String key) {
  // Handle actual quantitative structure from LLM
  final quantitative = metadata['quantitative'];
  if (quantitative is Map<String, dynamic>) {
    
    // Volume (water, liquids)
    if (key.contains('volume') || key == 'quantity') {
      final volume = quantitative['volume'];
      if (volume is Map<String, dynamic>) {
        return volume['amount']; // 500 from "500 ml"
      }
    }
    
    // Distance (steps, walking, running)
    if (key.contains('distance') || key == 'steps') {
      final distance = quantitative['distance'];
      if (distance is Map<String, dynamic>) {
        return distance['amount'] ?? distance['count'];
      }
    }
    
    // Duration (time-based activities)
    if (key.contains('duration')) {
      final time = quantitative['time'];
      if (time is Map<String, dynamic>) {
        return time['amount'] ?? time['duration'];
      }
    }
  }
  
  // Fallback to existing logic
  return metadata[key] ?? _findInNestedStructure(metadata, key);
}
```

### 3. Add Validation (10min)
**File**: `lib/services/metadata_prompt_enhancement.dart`

```dart
static bool validateMetadataStructure(Map<String, dynamic> metadata) {
  final measurement = metadata['measurement'];
  return measurement != null && 
         measurement['count'] != null && 
         measurement['unit'] != null;
}
```

## Expected Results

### Before (Critical Failures)
- **"Seguir plano estruturado de corrida"**: NO metadata displayed
- **"Caminhar 7000 passos"**: Shows "Distance: 100m" (×2) + "Steps: 100" (wrong value)
- **"Fazer exercício de força"**: Shows "10" instead of "10kg" (missing unit)
- **"Beber água"**: Shows "200" instead of "200ml" (missing unit)

### After (Fixed)
- **"Seguir plano estruturado de corrida"**: `🏃 5km • ⏱️ 30min`
- **"Caminhar 7000 passos"**: `🚶 7000steps` (correct value, no duplicates)
- **"Fazer exercício de força"**: `🏋️ 10kg` (with proper unit)
- **"Beber água"**: `💧 200ml` (with proper unit)

### Quality Improvements
- **✅ 100% Extraction Success**: Every activity generates metadata
- **✅ Accurate Values**: Exact values from user input (7000, not 100)
- **✅ Proper Units**: All measurements display with SI units
- **✅ No Duplicates**: Each measurement appears once only
- **✅ Semantic Precision**: Weight stays weight, steps stay steps

## Testing

### Test Case 1: Structured Activity
1. **Input**: "Seguir plano estruturado de corrida"
2. **Expected Metadata**:
   ```json
   {
     "quantitative": {
       "distance": {"value": 5, "unit": "km", "confidence": "inferred"},
       "duration": {"value": 30, "unit": "min", "confidence": "inferred"}
     }
   }
   ```
3. **Expected Display**: `🏃 5km • ⏱️ 30min`

### Test Case 2: Exact Value Extraction
1. **Input**: "Caminhar 7000 passos"
2. **Expected Metadata**:
   ```json
   {
     "quantitative": {
       "steps": {"value": 7000, "unit": "steps", "confidence": "explicit"}
     }
   }
   ```
3. **Expected Display**: `🚶 7000steps`

### Test Case 3: Unit Preservation
1. **Input**: "Levantei 10kg no supino"
2. **Expected Metadata**:
   ```json
   {
     "quantitative": {
       "weight": {"value": 10, "unit": "kg", "confidence": "explicit"}
     }
   }
   ```
3. **Expected Display**: `🏋️ 10kg`

## Effort Breakdown
- Semantic matching precision: 30min
- Unit preservation implementation: 25min  
- LLM prompt enhancement: 20min
- Duplicate elimination: 15min
- **Total**: 90 minutes

**Result**: Production-ready metadata system with 100% extraction success, accurate values, proper units, and zero duplicates.
