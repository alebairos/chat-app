# FT-149.6: Integrated Metadata Architecture Fix

## Problem Statement

The current metadata extraction architecture has fundamental flaws:

1. **Context Isolation**: Metadata extraction occurs in a separate `LeanClaudeConnector` call, losing access to:
   - Persona context and behavioral rules
   - Conversation history and user patterns
   - MCP functions and real-time data
   - Proper UTF-8 encoding handling

2. **Rate Limit Vulnerability**: Separate API calls double the rate limit pressure, causing frequent 429 errors and fallback metadata

3. **Encoding Issues**: Portuguese characters corrupted (`respiração` → `respiraÃ§Ã£o`) due to isolated HTTP handling

4. **Cost Inefficiency**: Additional API calls increase costs despite "cost-neutral" design goal

## Root Cause Analysis

**Current Flow (Broken):**
```
User Message → Claude (Pass 1: Response) → Oracle Detection (Pass 2) → Separate Metadata Call → Rate Limits
                ↓                              ↓                           ↓
        Full Context                    Full Context                 Isolated Context
        Proper Encoding                Proper Encoding              Broken Encoding
        No Rate Pressure              Some Rate Pressure           High Rate Pressure
```

**Evidence from Logs:**
- `FT-149: Lean extraction successful (1793 chars)` - Rich metadata generated
- `"respiraÃ§Ã£o controlada"` - UTF-8 encoding corruption
- Multiple 429 rate limit errors in queue processing
- Fallback metadata for 75% of recent activities

## Solution: Integrated Two-Pass Architecture

### Architecture Overview

**New Flow (Integrated):**
```
User Message → Claude (Pass 1: Response) → Enhanced Oracle Detection (Pass 2 + Metadata) → Single Response
                ↓                              ↓
        Full Context                    Full Context + Metadata
        Proper Encoding                Proper Encoding
        No Rate Pressure              Minimal Rate Pressure
```

### Implementation Plan

#### Phase 1: Enhanced Oracle Prompt
**File**: `lib/services/system_mcp_service.dart`

Modify `_oracleDetectActivities()` to include metadata extraction:

```dart
String _buildEnhancedOraclePrompt(String userMessage) {
  return '''
$existingOraclePrompt

## METADATA ENHANCEMENT (FT-149.6)
For each detected activity, extract rich contextual metadata using the Universal Framework:

### Quantitative Dimensions
- Scale/Magnitude: measurements, quantities, distances, weights
- Time: duration, frequency, timing, intervals
- Performance: speed, intensity, efficiency, heart rate zones

### Qualitative Dimensions  
- Experience: difficulty, satisfaction, perceived effort
- Method: technique, approach, breathing patterns
- Conditions: environment, equipment, circumstances

### Behavioral Dimensions
- Motivation: internal/external drivers, goals
- State: physical/mental/emotional condition
- Patterns: habits, progressions, integrations

Return enhanced format:
{
  "activities": [
    {
      "code": "SF13",
      "description": "Fazer exercício cardio/aeróbico",
      "confidence": "high",
      "metadata": {
        "quantitative": {
          "distance": {"total": 1700, "running": 1500, "walking": 200},
          "duration": {"total": "~20min", "zone2": "5min"}
        },
        "qualitative": {
          "breathing": {"method": "nasal", "timing": "during_exercise"},
          "experience": {"difficulty": "moderate", "satisfaction": "high"}
        },
        "behavioral": {
          "integration": {"physical": true, "mental": true, "spiritual": true},
          "progression": {"structured": true, "interval_based": true}
        }
      }
    }
  ]
}
''';
}
```

#### Phase 2: Response Parser Enhancement
**File**: `lib/services/system_mcp_service.dart`

Update `_parseDetectionResults()` to extract metadata:

```dart
List<ActivityDetection> _parseDetectionResults(String response) {
  // Parse enhanced JSON response
  final parsed = json.decode(response);
  final activities = <ActivityDetection>[];
  
  for (final activity in parsed['activities']) {
    activities.add(ActivityDetection(
      activityCode: activity['code'],
      activityName: activity['description'],
      confidence: _parseConfidence(activity['confidence']),
      // FT-149.6: Extract metadata from same response
      metadata: activity['metadata'],
    ));
  }
  
  return activities;
}
```

#### Phase 3: Fallback Strategy
**File**: `lib/services/system_mcp_service.dart`

Add graceful degradation for rate limits:

```dart
Future<List<ActivityDetection>> _detectWithFallback(String userMessage) async {
  try {
    // Try enhanced detection with metadata
    return await _detectWithEnhancedPrompt(userMessage);
  } catch (e) {
    if (_isRateLimitError(e)) {
      _logger.warning('FT-149.6: Rate limit hit, using basic detection');
      return await _detectWithBasicPrompt(userMessage);
    }
    rethrow;
  }
}
```

#### Phase 4: Cleanup Legacy System
**Files to Remove/Modify:**
- `lib/services/lean_claude_connector.dart` - Remove entirely
- `lib/services/metadata_extraction_service.dart` - Remove entirely  
- `lib/services/metadata_extraction_queue.dart` - Remove entirely
- `lib/services/activity_memory_service.dart` - Remove metadata queue calls

## Expected Benefits

### 1. Context Preservation
- ✅ Full persona context and behavioral rules
- ✅ Access to conversation history and patterns
- ✅ MCP functions and real-time data integration
- ✅ Proper UTF-8 encoding from main Claude service

### 2. Rate Limit Resilience
- ✅ 50% reduction in API calls (no separate metadata calls)
- ✅ Single rate limit budget for detection + metadata
- ✅ Graceful fallback to basic detection during high traffic

### 3. Quality Improvements
- ✅ Contextually aware metadata (knows user's fitness level, preferences)
- ✅ Consistent encoding (Portuguese characters display correctly)
- ✅ Reduced fallback metadata (from 75% to <10%)

### 4. Cost Efficiency
- ✅ Eliminates separate API calls
- ✅ Slight token increase per call, but fewer total calls
- ✅ Maintains "cost-neutral" design goal

## Implementation Effort

**Complexity**: Medium
**Risk**: Low (fallback preserves existing functionality)
**Timeline**: 1-2 days

### Rollout Strategy
1. **Phase 1**: Implement enhanced prompt (1 day)
2. **Phase 2**: Update parsing and fallback logic (0.5 day)
3. **Phase 3**: Remove legacy components (0.5 day)
4. **Phase 4**: Testing and validation (ongoing)

## Success Metrics

- **Encoding Quality**: 0% Portuguese character corruption
- **Metadata Completeness**: >90% rich metadata (vs current 25%)
- **Rate Limit Errors**: <5% of requests (vs current 75%)
- **Context Relevance**: Metadata reflects user's actual patterns and preferences

## Migration Notes

- Existing metadata in database remains compatible
- UI components require no changes
- Feature flags (`MetadataConfig`) remain functional
- Backward compatibility maintained for all existing metadata formats
