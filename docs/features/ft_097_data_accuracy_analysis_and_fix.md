# FT-097: Data Accuracy Analysis and Fix

**Status**: 🔄 IN PROGRESS  
**Priority**: High  
**Category**: Data Quality / Bug Fix  
**Effort**: 3-4 hours  

## Problem Statement

The two-pass processing system (FT-084) is technically working perfectly—temporal intelligence maps correctly, TTS contamination is eliminated, and database queries execute successfully. However, the AI responses contain significant data inaccuracies when reporting activity counts and statistics.

### Observed Issues

**Test Case**: "o que eu fiz no sábado?" (What did I do on Saturday?)

| **AI Response** | **Database Reality** | **Accuracy** |
|-----------------|---------------------|--------------|
| "dez pomodoros" | T8: 7 sessions | ❌ 143% overcount |
| "quatro refeições com família" | R5: 1 family meal | ❌ 400% overcount |
| "seis momentos de hidratação" | SF1: 5 water instances | ❌ 120% overcount |
| "Treinos: força e cardio" | SF12: 2, SF13: 2 | ✅ Correct categories |
| "Rotina da manhã" | T1: 2 morning routines | ✅ Correct category |
| "Exposição solar" | SF22: 3 sun exposures | ✅ Correct category |

**Overall Accuracy**: ~30-40% for counts, 100% for categories

## Root Cause Analysis

### Technical Infrastructure Assessment: ✅ PERFECT

1. **Phase 1 Temporal Intelligence**: "sábado" correctly maps to appropriate database query
2. **FT-096 TTS Fix**: No JSON contamination in audio responses
3. **FT-084 Two-Pass Processing**: Data retrieval and enrichment working correctly
4. **Database Queries**: SystemMCP successfully retrieves accurate data (72 activities found)
5. **Activity Categories**: AI correctly identifies all activity types

### Data Flow Analysis

```
1. User Query: "o que eu fiz no sábado?"
2. Temporal Mapping: ✅ Correctly generates MCP command
3. Database Query: ✅ Returns accurate structured data
4. Data Enrichment: ✅ JSON data provided to Claude
5. AI Interpretation: ❌ ISSUE: Numbers inflated/approximated
6. Response Generation: ❌ ISSUE: Inaccurate counts reported
```

### Suspected Causes

1. **Data Structure Confusion**: Claude may be misinterpreting JSON structure
2. **Prompt Interpretation**: AI ignoring existing accuracy guidance
3. **Summarization Bias**: AI tendency to round up or approximate instead of reporting exact counts
4. **Data Aggregation Error**: Possible confusion between different time periods or data sources

## Data Format Investigation

### Current Data Structure (ActivityMemoryService)

```json
{
  "status": "success",
  "data": {
    "period": "last_2_days",
    "total_activities": 72,
    "activities": [
      {
        "code": "T8",
        "name": "Realizar sessão de trabalho focado (pomodoro)",
        "time": "19:01",
        "full_timestamp": "2025-08-23T19:01:00.000Z",
        "confidence": 0.9,
        "dimension": "TG",
        "source": "Oracle FT-064 Semantic",
        "notes": "User indicates completing..."
      }
      // ... array of all activities
    ],
    "summary": {
      "by_activity": {
        "T8": 7,
        "SF1": 5,
        "SF22": 3,
        // ... exact counts per activity
      },
      "total_occurrences": 72,
      "unique_activities": 9
    }
  }
}
```

### Two-Pass Processing Flow

**First Pass**: Claude generates `{"action": "get_activity_stats", "days": 2}`  
**Data Collection**: SystemMCP executes command, returns structured JSON  
**Second Pass**: Enriched prompt sent to Claude:

```
o que eu fiz no sábado?

System Data Available: {above JSON structure}

Please provide a natural response using this information while maintaining your persona and language style.
```

## Current Mitigation Attempts

### Existing FT-095 Guidance

```dart
'### Data Utilization Rules\n'
'- ALWAYS use real data from MCP commands, never approximate\n'
'- Reference specific times and counts from returned data\n'
'- Use exact activity codes (SF1, T8, etc.) from results\n'
'- Include confidence scores and timestamps when relevant\n'
'- Present data in natural, conversational language while being accurate\n\n'
```

### Enhanced Guidance (Added)

```dart
'### Data Utilization Rules\n'
'- ALWAYS use real data from MCP commands, never approximate\n'
'- Use EXACT counts from "total_activities" and "by_activity" fields\n'
'- Reference specific times and counts from returned data\n'
'- Use exact activity codes (SF1, T8, etc.) from results\n'
'- Count activities from the activities array for precision\n'
'- Never inflate or summarize numbers - report actual database counts\n'
'- Include confidence scores and timestamps when relevant\n'
'- Present data in natural, conversational language while being accurate\n\n'
```

## Diagnostic Implementation

### Debug Logging Added

```dart
_logger.debug('🔍 [DATA DEBUG] Raw collected data length: ${collectedData.length} chars');
_logger.debug('🔍 [DATA DEBUG] Collected data preview: ${collectedData.length > 500 ? collectedData.substring(0, 500) + "..." : collectedData}');
```

**Purpose**: Verify exact data format sent to Claude in second pass

### Testing Strategy

**Phase A: Immediate Verification**
1. Run same query with debug logging
2. Examine raw data format sent to Claude
3. Verify if enhanced guidance improves accuracy

**Phase B: Root Cause Identification**
Based on debug logs, determine if issue is:
- Data format confusion (Claude misreading JSON)
- Prompt interpretation (ignoring accuracy rules)
- Data aggregation bugs (wrong data returned)
- Time period confusion (mixing date ranges)

**Phase C: Targeted Solution**
1. Data format optimization if structure issue
2. Prompt enhancement if interpretation issue  
3. SystemMCP correction if data retrieval issue
4. Time handling fix if temporal issue

## Expected Outcomes

### Success Metrics
- **Count Accuracy**: 95%+ match between AI response and database reality
- **Category Accuracy**: Maintained at 100%
- **Technical Performance**: No regression in temporal intelligence or TTS quality
- **User Experience**: Accurate, trustworthy activity reporting

### Implementation Phases

**Phase 1: Diagnosis** (Current)
- [ ] Debug logging implementation ✅
- [ ] Enhanced prompt guidance ✅  
- [ ] Test execution and log analysis
- [ ] Root cause identification

**Phase 2: Solution**
- [ ] Implement targeted fix based on diagnosis
- [ ] Comprehensive testing across multiple queries
- [ ] Verification of accuracy improvements

**Phase 3: Validation**
- [ ] Test edge cases (large datasets, multiple days)
- [ ] Verify no regression in existing functionality
- [ ] Performance impact assessment

## Technical Notes

### Files Modified
- `lib/services/claude_service.dart`: Debug logging + enhanced prompt guidance
- Lines 365-366: Debug logging for data inspection
- Lines 483-490: Strengthened data accuracy rules

### Dependencies
- Builds on FT-084 (Two-Pass Processing)
- Integrates with FT-095 (Temporal Intelligence)
- Maintains compatibility with FT-096 (TTS Fix)

### Risk Assessment
- **Low Risk**: Changes are additive (logging + prompt guidance)
- **No Breaking Changes**: Core functionality preserved
- **Easy Rollback**: Prompt modifications easily reversible

## Next Steps

1. **Execute test query** with debug logging enabled
2. **Analyze collected data format** and Claude's interpretation
3. **Identify specific disconnect** between data and response
4. **Implement targeted fix** based on findings
5. **Document solution** and update implementation summary

---

**Related Features**: FT-084, FT-095, FT-096  
**Testing Required**: Manual verification, accuracy testing  
**Documentation**: Implementation summary to follow completion
