# FT-181: Minimal Goal-Aware Activity Detection

**Feature ID**: FT-181  
**Priority**: High  
**Category**: Goal Management Enhancement  
**Effort Estimate**: 2-3 hours  
**Depends On**: FT-174 (Goals Tab), Oracle Goals Mapping, Feature Flags

## Problem Statement

Activity detection works but doesn't connect activities to user goals, missing opportunities for goal-specific progress feedback and visual organization.

## Solution

Enhance activity detection with goal awareness while preserving existing functionality and precision.

## Requirements

### Oracle Framework Compliance
- Use existing `oracle_prompt_4.2_goals_mapping.json` for activity-goal mappings
- No hardcoded rules or activity codes

### Same Detection Detail  
- Maintain current activity detection precision
- Preserve quantitative metadata extraction (`FlatMetadataParser`)
- Add goal context without changing detection logic

### Goal Sections
- Group activities by goals in Stats screen activity board
- Show goal headers with icons and activity counts
- Separate "Other Activities" section for non-goal activities

### Goal Labels
- Add visual goal indicators on activity cards
- Small blue badges showing related goal names
- Only when `activityGoalLabels` feature flag enabled

## Technical Implementation

### Core Components

**GoalActivityLinker Service**:
```dart
static Future<void> initialize() // Load Oracle mapping
static List<String> getGoalsForActivity(String activityCode)
static Future<List<GoalModel>> getRelatedUserGoals(String activityCode)
```

**Enhanced Activity Detection**:
```dart
class EnhancedActivityDetection extends ActivityDetection {
  final List<GoalModel> relatedGoals;
  final bool isGoalRelated;
  // Preserves all original ActivityDetection fields + metadata
}
```

**Goal-Aware Stats Screen**:
- Group activities by user goals using Oracle mapping
- Render goal sections with headers and counts
- Preserve existing activity cards with optional goal labels

### Feature Flags
- `goalAwareActivityDetection`: Master flag for enhanced detection
- `goalActivityBoard`: Goal sections in activity board  
- `activityGoalLabels`: Visual goal badges on cards

## Expected Result

**Before**: Activities listed chronologically without goal context
**After**: Activities grouped by goals with visual indicators

```
┌─ 🏃 Correr X Km (1)
│  └─ [SF13] Corrida - 5km • 08:30 [🎯 Correr X Km]
├─ 😴 Dormir melhor (1)  
│  └─ [SF1] Sono - 8 horas • 23:00 [🎯 Dormir melhor]
└─ Other Activities
   └─ [SF2] Água - 500ml • 14:30
```

## Success Criteria
- Activities automatically grouped by user goals
- Goal sections show correct activity counts
- Metadata extraction unchanged
- Performance impact < 50ms per detection
- Feature flags control all enhancements
