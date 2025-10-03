# FT-175: Goal-Aware Activity Detection & Persona Guidance

**Feature ID**: FT-175  
**Priority**: High  
**Category**: Goal Management Enhancement  
**Effort Estimate**: 3-4 hours  
**Depends On**: FT-174 (Goals Tab), Activity Detection System, Oracle Framework

## Overview

Enhance the activity detection system and persona guidance to be goal-aware, enabling personas to provide targeted recommendations and connect detected activities to user goals while maintaining comprehensive general activity tracking.

## Problem Statement

**Current Gap**: 
- Personas can create goals but cannot see user's existing goals for guidance
- Activity detection works but doesn't connect activities to relevant goals
- No progress indication when goal-related activities are detected
- Users get generic guidance instead of goal-specific recommendations

**User Impact**:
- Goals feel disconnected from daily activities
- No progress feedback on goal achievement
- Missed opportunities for targeted motivation and guidance

## Solution Architecture

### Core Principle: Dual-Layer Activity Detection

**Layer 1: General Activity Detection** (unchanged)
- Continue detecting ALL Oracle activities (water, meditation, work, etc.)
- Maintain comprehensive life tracking regardless of goals

**Layer 2: Goal-Aware Enhancement** (new)
- Connect detected activities to relevant user goals
- Provide goal-specific progress feedback
- Enable targeted persona guidance

## Functional Requirements

### FR-1: Goal-Aware Persona System

**FR-1.1**: Goal Context Integration
- Personas can access user's active goals via MCP
- System prompt includes current goals for context-aware responses
- Personas provide goal-specific guidance and encouragement

**FR-1.2**: Targeted Recommendations
```
User has OCX1 (Correr 5k) goal:
→ Persona suggests cardio activities (SF13, SF1812, SF1813)
→ Encourages running-related habits
→ Celebrates cardio progress: "Great workout! This helps your 5k goal."
```

### FR-2: Enhanced Activity Detection

**FR-2.1**: Dual Detection System
- **General Detection**: Continue tracking all activities as before
- **Goal Mapping**: Identify when detected activities relate to user goals
- **Progress Attribution**: Mark goal-related activities for progress tracking

**FR-2.2**: Oracle Trilha Mapping
```dart
// Goal-Activity Mapping via Oracle Framework
OCX1 (trilha: "CX1") → SF13, SF1812, SF1813 (cardio activities)
OPP1 (trilha: "PP1") → SF10, SF11, SF12 (nutrition activities)
```

### FR-3: Goal Progress Integration

**FR-3.1**: Activity-Goal Connection
- When SF13 (cardio) detected + user has OCX1 goal → mark as goal progress
- Store both general activity record AND goal progress record
- Maintain activity history for comprehensive tracking

**FR-3.2**: Progress Feedback
- Goals Tab shows recent related activities
- Personas acknowledge goal progress in conversations
- No complex progress calculations (keep simple for Phase 1)

## Technical Requirements

### TR-1: Non-Invasive Enhancement Architecture

**TR-1.1**: Additive Pattern (Zero Risk to Existing System)
```dart
// PROTECTED: Existing flow remains unchanged
final detectedActivities = await SemanticActivityDetector.analyzeWithTimeContext(
  userMessage: userMessage,
  oracleContext: oracleContext, 
  timeContext: timeData,
); // ✅ NO MODIFICATIONS

// NEW: Goal enhancement layer (parallel processing)
if (detectedActivities.isNotEmpty) {
  await GoalAwareActivityEnhancer.enhanceWithGoalContext(detectedActivities);
}

// PROTECTED: Existing storage unchanged
await _logActivitiesWithPreciseTime(activities: detectedActivities, timeContext: timeData);
```

**TR-1.2**: Graceful Degradation
```dart
// FT-175: Goal enhancement with complete fallback protection
try {
  await GoalAwareActivityEnhancer.enhanceWithGoalContext(detectedActivities);
} catch (e) {
  Logger().debug('FT-175: Goal enhancement failed, continuing normal flow: $e');
  // Core functionality continues unaffected
}
```

### TR-2: New Goal-Aware Services (Safe Additions)

**TR-2.1**: GoalAwareActivityEnhancer (New Service)
```dart
class GoalAwareActivityEnhancer {
  /// Enhance detected activities with goal context (non-invasive)
  static Future<void> enhanceWithGoalContext(List<ActivityDetection> activities) async {
    final activeGoals = await GoalContextManager.getActiveGoals();
    if (activeGoals.isEmpty) return; // No goals = no enhancement
    
    for (final activity in activities) {
      final relatedGoals = await _findRelatedGoals(activity.oracleCode, activeGoals);
      if (relatedGoals.isNotEmpty) {
        await _storeGoalProgress(activity, relatedGoals);
      }
    }
  }
  
  /// Find goals related to detected activity via Oracle trilha mapping
  static Future<List<GoalModel>> _findRelatedGoals(String activityCode, List<GoalModel> goals) async {
    // Use Oracle framework trilha structure for accurate mapping
    // OCX1 (trilha: CX1) → SF13, SF1812, SF1813 (cardio activities)
  }
  
  /// Store goal progress separately from activity storage
  static Future<void> _storeGoalProgress(ActivityDetection activity, List<GoalModel> goals) async {
    // Store in separate goal_progress table, don't modify activity records
  }
}
```

**TR-2.2**: GoalContextManager (New Service)
```dart
class GoalContextManager {
  /// Get active user goals for enhancement (doesn't affect existing Oracle context)
  static Future<List<GoalModel>> getActiveGoals() async {
    // Use existing ChatStorageService, no new dependencies
  }
  
  /// Get Oracle trilha mapping for goal-activity connections
  static Map<String, List<String>> getGoalActivityMapping() async {
    // Parse Oracle framework trilha structure
    return {
      "OCX1": ["SF13", "SF1812", "SF1813"], // Running → Cardio activities
      "OPP1": ["SF10", "SF11", "SF12"],     // Weight loss → Nutrition activities
    };
  }
}
```

### TR-3: MCP Enhancement (Safe Extension)

**TR-3.1**: Goal Context Function (New MCP Function)
```dart
// Add to SystemMCPService without modifying existing functions
case 'get_user_goals_context':
  return await _getUserGoalsContext(); // New function, existing MCP unchanged

Future<String> _getUserGoalsContext() async {
  final goals = await GoalContextManager.getActiveGoals();
  return json.encode({
    'status': 'success',
    'data': {
      'goals': goals.map((g) => {
        'objective_code': g.objectiveCode,
        'objective_name': g.objectiveName,
        'trilha': _getTrilhaForObjective(g.objectiveCode),
        'related_activities': _getRelatedActivities(g.objectiveCode),
      }).toList(),
    }
  });
}
```

### TR-4: Persona System Integration (Safe Addition)

**TR-4.1**: Goal Context in System Prompt (Additive)
```dart
// Extend existing persona prompt building without modifying core logic
class GoalAwarePersonaEnhancer {
  static String enhanceSystemPrompt(String existingPrompt) {
    final goalContext = _buildGoalContext();
    return existingPrompt + "\n\n" + goalContext; // Append, don't replace
  }
  
  static String _buildGoalContext() {
    final userGoals = GoalContextManager.getActiveGoalsSync();
    if (userGoals.isEmpty) return ""; // No goals = no enhancement
    
    return """
## User's Active Goals
${userGoals.map((g) => "- ${g.objectiveCode}: ${g.objectiveName}").join("\n")}

Provide goal-specific guidance and celebrate progress when relevant activities are mentioned.
""";
  }
}
```

## Protection Guarantees

### PG-1: Existing System Integrity

**PG-1.1**: Zero Modifications to Core Components
- ✅ **SemanticActivityDetector**: No changes to detection logic
- ✅ **FlatMetadataParser**: No changes to metadata extraction  
- ✅ **ActivityMemoryService**: No changes to activity storage
- ✅ **IntegratedMCPProcessor**: No changes to coordination flow
- ✅ **OracleContextManager**: No changes to Oracle context loading

**PG-1.2**: Preserved Interfaces
```dart
// All existing method signatures remain unchanged
SemanticActivityDetector.analyzeWithTimeContext()     // ✅ Unchanged
FlatMetadataParser.extractRawQuantitative()           // ✅ Unchanged  
ActivityMemoryService.logActivity()                   // ✅ Unchanged
IntegratedMCPProcessor.processTimeAndActivity()       // ✅ Unchanged
```

**PG-1.3**: Backward Compatibility
- Users without goals: System works exactly as before
- Non-Oracle personas: No impact on existing functionality
- Rate limiting: Existing queue processing unchanged
- Metadata extraction: All quantitative data preserved

### PG-2: Graceful Enhancement Pattern

**PG-2.1**: Feature Toggle Protection
```dart
class FeatureFlags {
  static bool goalAwareActivityDetection = false; // Default: disabled
}

// Only enhance if explicitly enabled
if (FeatureFlags.goalAwareActivityDetection) {
  await GoalAwareActivityEnhancer.enhanceWithGoalContext(activities);
}
```

**PG-2.2**: Parallel Processing (No Interference)
```dart
// Layer 1: Existing detection (untouched)
final activities = await SemanticActivityDetector.analyzeWithTimeContext(...);

// Layer 2: Goal enhancement (parallel, isolated)
final goalConnections = await GoalAwareActivityEnhancer.findGoalConnections(activities);

// Both layers store independently, no conflicts
await _logActivitiesWithPreciseTime(activities, timeContext);           // Existing
await GoalProgressService.storeGoalProgress(goalConnections);           // New
```

## UI/UX Requirements

### UX-1: Goals Tab Enhancement

**UX-1.1**: Activity Connection Display
```
┌─────────────────────────────────┐
│ 🏃 Correr 5k                    │
│ Created: 2 days ago             │
│ Recent: Cardio today, 30min     │ ← New: show recent related activities
└─────────────────────────────────┘
```

**UX-1.2**: No Complex Progress UI (Phase 1)
- Keep Goals Tab simple with basic activity mentions
- Avoid progress bars or percentages in first implementation
- Focus on connection visibility, not detailed tracking

### UX-2: Chat Experience Enhancement

**UX-2.1**: Goal-Aware Responses
```
User: "Fiz 30 minutos de cardio"
Persona: "Excelente! Esse treino cardio contribui para sua meta de correr 5k. Como se sentiu durante o exercício?"
```

**UX-2.2**: Proactive Goal Guidance
```
User: "Bom dia"
Persona: "Bom dia! Vi que você tem a meta de correr 5k. Que tal incluir um pouco de cardio no seu dia hoje?"
```

## Implementation Strategy

### Phase 1: Safe Foundation (Zero Risk) - 2 hours

**Step 1: New Services Creation (45 minutes)**
- Create `GoalAwareActivityEnhancer` service (new file)
- Create `GoalContextManager` service (new file)  
- Create `GoalProgressService` for separate storage (new file)
- **PROTECTION**: No modifications to existing services

**Step 2: MCP Safe Extension (30 minutes)**
- Add `get_user_goals_context` case to SystemMCPService
- Add new `_getUserGoalsContext()` method only
- **PROTECTION**: Existing MCP functions unchanged

**Step 3: Oracle Trilha Mapping (45 minutes)**
- Create static mapping using Oracle framework trilha structure
- Parse existing `oracle_prompt_4.2_optimized.json` for connections
- **PROTECTION**: No changes to OracleContextManager

### Phase 2: Non-Invasive Integration (Low Risk) - 1.5 hours

**Step 4: Activity Enhancement Layer (60 minutes)**
- Add goal enhancement call AFTER existing detection
- Implement parallel processing pattern
- Add comprehensive error handling with graceful degradation
- **PROTECTION**: Existing detection flow completely unchanged

**Step 5: Persona Safe Enhancement (30 minutes)**
- Create `GoalAwarePersonaEnhancer` to append goal context
- Modify persona prompt building to add (not replace) content
- **PROTECTION**: Existing persona logic preserved

### Phase 3: Protected Rollout (Minimal Risk) - 30 minutes

**Step 6: Feature Toggle Implementation (15 minutes)**
- Add `FeatureFlags.goalAwareActivityDetection` (default: false)
- Wrap all enhancements in feature flag checks
- **PROTECTION**: Can disable instantly if issues arise

**Step 7: Testing & Validation (15 minutes)**
- Test with feature flag disabled (existing behavior)
- Test with feature flag enabled (enhanced behavior)
- Verify existing functionality unchanged
- **PROTECTION**: Regression testing before activation

## Risk Mitigation Strategy

### RM-1: Rollback Capability
```dart
// Instant rollback via feature flag
FeatureFlags.goalAwareActivityDetection = false; // Disable enhancement
// System immediately returns to pre-FT-175 behavior
```

### RM-2: Monitoring Points
- Existing activity detection rate (should remain unchanged)
- Metadata extraction success rate (should remain unchanged)
- Activity storage performance (should remain unchanged)
- Goal enhancement success rate (new metric, failures don't affect core)

### RM-3: Gradual Activation
1. **Phase A**: Feature disabled, test existing functionality
2. **Phase B**: Feature enabled for testing, monitor core metrics  
3. **Phase C**: Full activation after validation

## Success Metrics

### Functional Success
- Personas can see and reference user's active goals
- Detected activities correctly connect to relevant goals
- Goal-related activities appear in Goals Tab
- All general activities continue to be detected

### User Experience Success
- Users receive goal-specific guidance and encouragement
- Goals feel connected to daily activities
- No disruption to existing activity tracking
- Natural, contextual persona responses

## Benefits

### For Users
- **Targeted Guidance**: Goal-specific recommendations and encouragement
- **Progress Visibility**: See how daily activities contribute to goals
- **Motivation**: Immediate feedback when working toward goals
- **Comprehensive Tracking**: All activities still detected and logged

### For System
- **Goal Integration**: Seamless connection between goals and activities
- **Oracle Compliance**: Uses existing trilha structure for accuracy
- **Backward Compatible**: No disruption to existing functionality
- **Foundation**: Enables future progress tracking enhancements

## Future Enhancements

**Phase 2: Advanced Progress Tracking**
- Calculate goal completion percentages
- Progress visualizations and charts
- Goal milestone celebrations

**Phase 3: Intelligent Goal Recommendations**
- Suggest new goals based on activity patterns
- Adaptive goal difficulty based on progress
- Cross-goal activity optimization

---

## Comprehensive Testing Strategy

### TS-1: Regression Testing (Existing Functionality)

**TS-1.1**: Core Activity Detection Unchanged
```dart
group('FT-175: Existing Activity Detection Regression', () {
  test('semantic detection works exactly as before', () async {
    // Test with FT-175 disabled
    FeatureFlags.goalAwareActivityDetection = false;
    
    final activities = await SemanticActivityDetector.analyzeWithTimeContext(
      userMessage: "Bebi 250ml de água",
      oracleContext: mockOracleContext,
      timeContext: mockTimeContext,
    );
    
    expect(activities.length, equals(1));
    expect(activities.first.oracleCode, equals('SF1'));
    expect(activities.first.metadata['quantitative_volume_value'], equals(250));
  });
  
  test('metadata extraction unchanged', () async {
    final metadata = FlatMetadataParser.extractRawQuantitative(mockActivityData);
    expect(metadata['quantitative_volume_value'], equals(250));
    expect(metadata['quantitative_volume_unit'], equals('ml'));
  });
  
  test('activity storage unchanged', () async {
    final activity = await ActivityMemoryService.logActivity(
      activityCode: 'SF1',
      activityName: 'Beber água',
      dimension: 'SF',
      source: 'Test',
    );
    expect(activity.activityCode, equals('SF1'));
    expect(activity.dimension, equals('SF'));
  });
});
```

**TS-1.2**: Integration Flow Unchanged
```dart
test('integrated MCP processor works as before', () async {
  FeatureFlags.goalAwareActivityDetection = false;
  
  await IntegratedMCPProcessor.processTimeAndActivity(
    userMessage: "Fiz 30 minutos de cardio",
    claudeResponse: "",
  );
  
  // Verify existing behavior preserved
  final activities = await ActivityMemoryService.getRecentActivities(1);
  expect(activities.isNotEmpty, isTrue);
  expect(activities.first.activityCode, equals('SF13'));
});
```

### TS-2: Enhancement Testing (New Functionality)

**TS-2.1**: Goal-Aware Enhancement
```dart
group('FT-175: Goal-Aware Enhancement', () {
  test('goal enhancement works when enabled', () async {
    FeatureFlags.goalAwareActivityDetection = true;
    
    // Create test goal
    await createTestGoal(objectiveCode: 'OCX1', objectiveName: 'Correr 5k');
    
    // Detect cardio activity
    final activities = await SemanticActivityDetector.analyzeWithTimeContext(
      userMessage: "Fiz 30 minutos de cardio",
      oracleContext: mockOracleContext,
      timeContext: mockTimeContext,
    );
    
    // Verify activity detected normally
    expect(activities.length, equals(1));
    expect(activities.first.oracleCode, equals('SF13'));
    
    // Verify goal enhancement applied
    final goalProgress = await GoalProgressService.getProgressForGoal('OCX1');
    expect(goalProgress.isNotEmpty, isTrue);
  });
  
  test('enhancement fails gracefully', () async {
    FeatureFlags.goalAwareActivityDetection = true;
    
    // Simulate enhancement failure
    GoalContextManager.simulateFailure = true;
    
    final activities = await SemanticActivityDetector.analyzeWithTimeContext(
      userMessage: "Bebi água",
      oracleContext: mockOracleContext,
      timeContext: mockTimeContext,
    );
    
    // Core functionality should still work
    expect(activities.length, equals(1));
    expect(activities.first.oracleCode, equals('SF1'));
  });
});
```

### TS-3: Protection Validation

**TS-3.1**: Feature Toggle Protection
```dart
test('feature toggle provides instant rollback', () async {
  // Enable enhancement
  FeatureFlags.goalAwareActivityDetection = true;
  await processActivityWithGoals();
  
  // Disable enhancement (simulate rollback)
  FeatureFlags.goalAwareActivityDetection = false;
  await processActivityWithoutGoals();
  
  // Verify system returns to pre-FT-175 behavior
  expect(systemBehaviorMatchesBaseline(), isTrue);
});
```

**TS-3.2**: Parallel Processing Isolation
```dart
test('goal enhancement failure does not affect core detection', () async {
  FeatureFlags.goalAwareActivityDetection = true;
  
  // Simulate goal enhancement crash
  GoalAwareActivityEnhancer.simulateCrash = true;
  
  final activities = await SemanticActivityDetector.analyzeWithTimeContext(
    userMessage: "Bebi água e fiz exercício",
    oracleContext: mockOracleContext,
    timeContext: mockTimeContext,
  );
  
  // Core detection should work despite enhancement failure
  expect(activities.length, equals(2));
  expect(activities.map((a) => a.oracleCode), containsAll(['SF1', 'SF13']));
});
```

## Implementation Notes

### Oracle Framework Integration
- Use existing `trilha` field in objectives for activity mapping
- Leverage Oracle dimension structure (SF for physical activities)  
- Maintain compatibility with current Oracle activity detection
- **PROTECTION**: Parse Oracle data, don't modify Oracle services

### Backward Compatibility Guarantees
- All existing activity detection continues unchanged
- Goals Tab remains functional without activity connections
- Personas work normally for users without goals
- **PROTECTION**: Feature flag allows instant revert to pre-FT-175 behavior

### Performance Considerations
- Goal enhancement runs in parallel, doesn't block core detection
- Oracle trilha mapping cached for performance
- Graceful degradation prevents enhancement failures from affecting core
- **PROTECTION**: Core performance unchanged, enhancement is additive overhead only

### Security & Data Integrity
- Goal progress stored separately from activity records
- No modifications to existing activity or metadata schemas
- Feature flag prevents accidental activation in production
- **PROTECTION**: Existing data schemas and storage patterns unchanged

---

*This enhancement bridges the gap between goal setting and daily activity tracking while providing comprehensive protection for existing functionality. The additive, non-invasive approach ensures zero risk to current activity detection and metadata extraction systems.*
