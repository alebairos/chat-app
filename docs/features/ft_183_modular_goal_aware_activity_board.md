# FT-183: Modular Goal-Aware Activity Board

**Feature ID**: FT-183  
**Priority**: High  
**Category**: Goal Management Enhancement  
**Effort Estimate**: 3-4 hours  
**Depends On**: FT-174 (Goals Tab), FT-181 (Goal-Aware Activity Detection), Oracle Goals Mapping

## Problem Statement

Activities are displayed chronologically without goal context, missing opportunities for goal-specific progress feedback and coaching guidance.

## Solution

Enhance Stats screen to group detected activities by active goals while maintaining modular architecture and backward compatibility.

## Requirements

### Modular Architecture
- All goal functionality isolated under `lib/features/goals/`
- No modifications to existing `ActivityModel` or core stats logic
- External goal-activity association via mapping services
- Feature flag protection for safe rollout

### Activity Grouping
- Group today's and week's activities by active goals
- Show goal sections with headers and activity counts
- Display "Routine" section for non-goal activities
- Preserve existing activity card functionality

### Goal Context Display
- Goal section headers with icons and names
- Activity count per goal
- Optional goal labels on activity cards
- Progress indicators when enabled

## Technical Implementation

### Core Components

**Goal Activity Mapper**:
```dart
class GoalActivityMapper {
  static Future<Map<String, List<dynamic>>> groupActivitiesByGoals(
    List<dynamic> activities
  ) async {
    final activeGoals = await GoalStorageService.getActiveGoals();
    // Use oracle_prompt_4.2_goals_mapping.json for associations
    // Return grouped activities: {goalCode: [activities], 'routine': [activities]}
  }
}
```

**Stats Enhancer**:
```dart
class GoalAwareStatsEnhancer {
  static Future<Map<String, dynamic>> enhanceStatsWithGoals(
    Map<String, dynamic> originalStats
  ) async {
    if (!FeatureFlags.isGoalActivityBoardEnabled) return originalStats;
    
    final activities = originalStats['activities'];
    final grouped = await GoalActivityMapper.groupActivitiesByGoals(activities);
    
    return {...originalStats, 'goal_grouped_activities': grouped};
  }
}
```

**Enhanced Stats Screen**:
- Minimal changes to existing `StatsScreen`
- Add goal-aware section rendering when feature enabled
- Preserve all existing functionality when disabled

### Goal-Specific Widgets

**Goal Activity Section**:
```dart
class GoalActivitySection extends StatelessWidget {
  final String goalCode;
  final List<dynamic> activities;
  
  // Renders goal header + activity cards
}
```

**Goal Activity Card**:
```dart
class GoalActivityCard extends StatelessWidget {
  // Extends existing ActivityCard with optional goal labels
  // Only shows goal context when feature flags enabled
}
```

### Feature Flags
- `goalActivityBoard`: Enable goal sections in stats
- `activityGoalLabels`: Show goal badges on activity cards
- `goalAwareActivityDetection`: Master flag for goal awareness

## Expected Result

**Before**: Activities listed chronologically
```
Today's Activities
├─ [SF13] Corrida - 5km • 08:30
├─ [SF1] Água - 500ml • 09:00  
└─ [TG1] Trabalho - 2h • 14:00
```

**After**: Activities grouped by goals
```
Today's Activities
├─ 🎯 Correr X Km (2 activities)
│  ├─ [SF13] Corrida - 5km • 08:30 [🎯 OCX1]
│  └─ [SF1] Água - 500ml • 09:00 [🎯 OCX1]
└─ 📋 Routine (1 activity)
   └─ [TG1] Trabalho - 2h • 14:00
```

## Success Criteria
- Activities automatically grouped by active goals
- Goal sections show correct activity counts
- Existing functionality preserved when feature disabled
- No changes to `ActivityModel` or core activity logic
- Complete modularity under `lib/features/goals/`
- Easy to refactor/remove goals module if needed
