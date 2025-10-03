# FT-176: Goals Feature Modularization Refactor

**Feature ID**: FT-176  
**Priority**: Medium  
**Category**: Code Organization & Architecture  
**Effort Estimate**: 1-2 hours  
**Depends On**: FT-174 (Goals Tab)

## Overview

Refactor the existing goals implementation to follow the established `lib/features` modularization pattern, improving code organization, maintainability, and preparing for future goal-related enhancements like FT-175 (Goal-Aware Activity Detection).

## Problem Statement

**Current State**: 
- Goals functionality is scattered across multiple directories (`lib/models`, `lib/screens`, `lib/services`)
- Goal logic is mixed into `SystemMCPService` with other MCP functions
- No clear feature boundaries or isolated goal-specific services
- Inconsistent with established `lib/features/journal` and `lib/features/audio_assistant` patterns

**User Impact**:
- **Developers**: Harder to locate and maintain goal-related code
- **Architecture**: Inconsistent modularization affects code scalability
- **Future Features**: No clear place to add goal enhancements (FT-175)

## Solution Architecture

### Core Principle: Feature-Based Modularization

**Follow Established Pattern**: Mirror the structure of `lib/features/journal/` and `lib/features/audio_assistant/` for consistency and predictability.

**Feature Isolation**: All goal-related code should be self-contained within `lib/features/goals/` with clear service boundaries and minimal external dependencies.

## Functional Requirements

### FR-1: Code Organization

**FR-1.1**: Feature Directory Structure
```
lib/features/goals/
├── models/
│   ├── goal_model.dart           # Moved from lib/models/
│   └── goal_model.g.dart         # Generated file
├── services/
│   ├── goal_storage_service.dart # Database operations
│   ├── goal_mcp_service.dart     # MCP function handlers
│   └── goal_utils.dart           # Helper utilities
├── screens/
│   └── goals_screen.dart         # Moved from lib/screens/
├── widgets/
│   ├── goal_card.dart            # Individual goal display
│   ├── empty_goals_state.dart    # Empty state widget
│   └── goal_list_view.dart       # Goals list container
└── utils/
    └── goal_validation.dart      # Goal validation logic
```

**FR-1.2**: Service Separation
- Extract goal CRUD operations from `SystemMCPService` into dedicated `GoalStorageService`
- Create `GoalMCPService` to handle MCP commands (`create_goal`, `get_active_goals`)
- Maintain clean separation between storage logic and MCP interface

### FR-2: Preserved Functionality

**FR-2.1**: Exact Behavior Preservation
- All existing goal functionality must work identically after refactoring
- Goal creation via MCP commands unchanged
- Goals display in UI unchanged
- Database operations and storage unchanged

**FR-2.2**: API Compatibility
- `SystemMCPService` maintains same MCP command interface
- `ChatStorageService` continues to manage Isar schema registration
- Main app integration points unchanged

### FR-3: Future Enhancement Readiness

**FR-3.1**: FT-175 Preparation
- `lib/features/goals/services/` provides clear location for `GoalContextManager`
- `lib/features/goals/widgets/` ready for progress tracking components
- `lib/features/goals/utils/` available for Oracle trilha mapping utilities

**FR-3.2**: Scalability Foundation
- Service architecture supports additional goal-related features
- Widget structure allows for complex goal UI components
- Clear boundaries enable isolated testing and development

## Technical Requirements

### TR-1: File Migration Strategy

**TR-1.1**: Model Migration
```dart
// FROM: lib/models/goal_model.dart
// TO:   lib/features/goals/models/goal_model.dart

// Update part directive:
part 'goal_model.g.dart';

// Regenerate generated file in new location
flutter packages pub run build_runner build
```

**TR-1.2**: Service Extraction
```dart
// Create: lib/features/goals/services/goal_storage_service.dart
class GoalStorageService {
  static final Logger _logger = Logger();
  
  /// Create a new goal (extracted from SystemMCPService._createGoal)
  static Future<GoalModel> createGoal({
    required String objectiveCode,
    required String objectiveName,
  }) async {
    final goal = GoalModel.fromObjective(
      objectiveCode: objectiveCode,
      objectiveName: objectiveName,
    );
    
    final chatStorage = ChatStorageService();
    final isar = await chatStorage.db;
    
    await isar.writeTxn(() async {
      await isar.goalModels.put(goal);
    });
    
    return goal;
  }
  
  /// Get all active goals (extracted from SystemMCPService._getActiveGoals)
  static Future<List<GoalModel>> getActiveGoals() async {
    // Move existing goal retrieval logic here
  }
}

// Create: lib/features/goals/services/goal_mcp_service.dart
class GoalMCPService {
  static final Logger _logger = Logger();
  
  /// Handle create_goal MCP command
  static Future<String> handleCreateGoal(Map<String, dynamic> parsedCommand) async {
    // Move MCP command handling logic here
    // Delegate to GoalStorageService for actual operations
  }
  
  /// Handle get_active_goals MCP command  
  static Future<String> handleGetActiveGoals() async {
    // Move MCP command handling logic here
    // Delegate to GoalStorageService for actual operations
  }
}
```

**TR-1.3**: Screen Migration
```dart
// FROM: lib/screens/goals_screen.dart  
// TO:   lib/features/goals/screens/goals_screen.dart

// Update imports:
import '../services/goal_mcp_service.dart';
import '../models/goal_model.dart';
import '../widgets/goal_card.dart';
import '../widgets/empty_goals_state.dart';
```

### TR-2: Integration Updates

**TR-2.1**: SystemMCPService Delegation
```dart
// Update: lib/services/system_mcp_service.dart
class SystemMCPService {
  Future<String> processCommand(String command) async {
    // ... existing code ...
    
    switch (action) {
      // Delegate goal commands to GoalMCPService
      case 'create_goal':
        return await GoalMCPService.handleCreateGoal(parsedCommand);
      
      case 'get_active_goals':
        return await GoalMCPService.handleGetActiveGoals();
      
      // ... other commands unchanged ...
    }
  }
}
```

**TR-2.2**: Schema Registration
```dart
// Update: lib/services/chat_storage_service.dart
import '../features/goals/models/goal_model.dart';

// Schema registration unchanged:
schemas: [
  ChatMessageModelSchema,
  ActivityModelSchema,
  JournalEntryModelSchema,
  GoalModelSchema, // Import from new location
]
```

**TR-2.3**: Main App Integration
```dart
// Update: lib/main.dart
import 'features/goals/screens/goals_screen.dart';

// TabBarView unchanged:
children: [
  ChatScreen(),
  StatsScreen(),
  JournalScreen(),
  GoalsScreen(), // Import from new location
  ProfileScreen(),
]
```

### TR-3: Widget Extraction

**TR-3.1**: Goal Card Component
```dart
// Create: lib/features/goals/widgets/goal_card.dart
class GoalCard extends StatelessWidget {
  final GoalModel goal;
  
  const GoalCard({super.key, required this.goal});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _getGoalIcon(goal.objectiveCode),
        title: Text(goal.displayName),
        subtitle: Text('Created: ${goal.formattedCreatedDate}'),
      ),
    );
  }
  
  Widget _getGoalIcon(String objectiveCode) {
    // Extract icon logic from GoalsScreen
  }
}
```

**TR-3.2**: Empty State Component
```dart
// Create: lib/features/goals/widgets/empty_goals_state.dart
class EmptyGoalsState extends StatelessWidget {
  const EmptyGoalsState({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No goals yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Talk to your persona about your goals and aspirations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

## Implementation Strategy

### Phase 1: Preparation (15 minutes)

**Step 1: Create Directory Structure**
```bash
mkdir -p lib/features/goals/{models,services,screens,widgets,utils}
```

**Step 2: Backup Current Implementation**
```bash
# Ensure all changes are committed before refactoring
git add .
git commit -m "Pre-refactoring backup: FT-174 goals implementation"
```

### Phase 2: Model Migration (20 minutes)

**Step 3: Move Goal Model**
```bash
mv lib/models/goal_model.dart lib/features/goals/models/goal_model.dart
```

**Step 4: Update Generated Files**
```bash
# Update part directive in goal_model.dart
# Regenerate generated file
flutter packages pub run build_runner build
```

**Step 5: Fix Import References**
- Update `lib/services/chat_storage_service.dart`
- Update `lib/screens/goals_screen.dart` 
- Update `lib/services/system_mcp_service.dart`

### Phase 3: Service Extraction (30 minutes)

**Step 6: Create GoalStorageService**
- Extract goal CRUD operations from `SystemMCPService`
- Create clean, focused service for database operations
- Add comprehensive error handling and logging

**Step 7: Create GoalMCPService**
- Extract MCP command handlers from `SystemMCPService`
- Delegate business logic to `GoalStorageService`
- Maintain exact same MCP interface

**Step 8: Update SystemMCPService**
- Replace goal logic with delegation to `GoalMCPService`
- Remove goal-specific imports and methods
- Test MCP commands still work

### Phase 4: UI Migration (15 minutes)

**Step 9: Move Goals Screen**
```bash
mv lib/screens/goals_screen.dart lib/features/goals/screens/goals_screen.dart
```

**Step 10: Extract Goal Widgets**
- Create `GoalCard` widget for individual goals
- Create `EmptyGoalsState` widget for empty state
- Update `GoalsScreen` to use new widgets

**Step 11: Update Main App**
- Fix import in `lib/main.dart`
- Test goals tab navigation works

### Phase 5: Validation (15 minutes)

**Step 12: Comprehensive Testing**
- Test goal creation via chat
- Test goals display in UI
- Test MCP commands directly
- Run existing tests

**Step 13: Code Quality Check**
```bash
flutter analyze
dart format lib/features/goals/
```

## Success Metrics

### Functional Success
- All goal functionality works identically to before refactoring
- Goal creation via MCP commands unchanged
- Goals display in UI unchanged
- No regressions in existing functionality

### Architectural Success
- Goals code is isolated in `lib/features/goals/`
- Clear service boundaries between storage and MCP handling
- Consistent with `journal` and `audio_assistant` feature patterns
- Reduced coupling between goal logic and other services

### Maintainability Success
- Goal-related code is easier to locate and understand
- Clear place to add future goal enhancements (FT-175)
- Isolated testing capabilities for goal functionality
- Improved code organization and readability

## Benefits

### For Developers
- **Clear Organization**: All goal code in predictable location
- **Easier Maintenance**: Isolated services with single responsibilities
- **Better Testing**: Feature-isolated components easier to test
- **Consistent Patterns**: Follows established modularization approach

### For Architecture
- **Improved Scalability**: Clean foundation for future goal features
- **Reduced Coupling**: Clear boundaries between features
- **Enhanced Modularity**: Self-contained feature with minimal dependencies
- **Future-Ready**: Perfect foundation for FT-175 goal-aware enhancements

### For Future Development
- **FT-175 Integration**: Ready location for `GoalContextManager` and progress tracking
- **Goal Analytics**: Natural place for goal insights and statistics
- **Advanced UI**: Dedicated widgets directory for complex goal components
- **Goal Automation**: Clear service layer for automated goal recommendations

## Risk Mitigation

### RM-1: Import Path Management
- **Risk**: Multiple files need import path updates
- **Mitigation**: Systematic file-by-file updates with testing at each step
- **Rollback**: Git backup before starting allows instant revert

### RM-2: Generated File Dependencies  
- **Risk**: `goal_model.g.dart` needs regeneration in new location
- **Mitigation**: Clear build_runner execution after file moves
- **Validation**: Compile-time errors will catch any missing regeneration

### RM-3: Database Schema Registration
- **Risk**: Isar schema might break if imports fail
- **Mitigation**: Test database operations immediately after import updates
- **Verification**: Goal creation/retrieval tests validate schema integrity

### RM-4: MCP Command Interface
- **Risk**: MCP delegation might break command handling
- **Mitigation**: Preserve exact same command interface and response format
- **Testing**: Direct MCP command testing validates delegation logic

## Testing Strategy

### Phase 1: Regression Testing
```dart
group('FT-176: Goals Refactoring Regression', () {
  test('goal creation via MCP unchanged', () async {
    final response = await systemMCP.processCommand(
      '{"action": "create_goal", "objective_code": "OCX1", "objective_name": "Correr 5k"}'
    );
    final data = json.decode(response);
    expect(data['status'], equals('success'));
  });
  
  test('goals retrieval via MCP unchanged', () async {
    final response = await systemMCP.processCommand('{"action": "get_active_goals"}');
    final data = json.decode(response);
    expect(data['status'], equals('success'));
    expect(data['data']['goals'], isA<List>());
  });
});
```

### Phase 2: Architecture Validation
```dart
group('FT-176: Service Architecture', () {
  test('GoalStorageService creates goals correctly', () async {
    final goal = await GoalStorageService.createGoal(
      objectiveCode: 'OCX1',
      objectiveName: 'Correr 5k',
    );
    expect(goal.objectiveCode, equals('OCX1'));
    expect(goal.isActive, isTrue);
  });
  
  test('GoalMCPService delegates correctly', () async {
    final response = await GoalMCPService.handleCreateGoal({
      'objective_code': 'OCX1',
      'objective_name': 'Correr 5k',
    });
    final data = json.decode(response);
    expect(data['status'], equals('success'));
  });
});
```

### Phase 3: UI Validation
```dart
group('FT-176: UI Components', () {
  testWidgets('GoalCard displays goal information', (tester) async {
    final goal = GoalModel.fromObjective(
      objectiveCode: 'OCX1',
      objectiveName: 'Correr 5k',
    );
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GoalCard(goal: goal)),
    ));
    
    expect(find.text('Correr 5k'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
  
  testWidgets('EmptyGoalsState shows guidance', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EmptyGoalsState()),
    ));
    
    expect(find.text('No goals yet'), findsOneWidget);
    expect(find.text('Talk to your persona about your goals'), findsOneWidget);
  });
});
```

---

## Implementation Notes

### File Movement Checklist
- [ ] `lib/models/goal_model.dart` → `lib/features/goals/models/goal_model.dart`
- [ ] `lib/screens/goals_screen.dart` → `lib/features/goals/screens/goals_screen.dart`
- [ ] Update part directive in `goal_model.dart`
- [ ] Regenerate `goal_model.g.dart`
- [ ] Update imports in `chat_storage_service.dart`
- [ ] Update imports in `system_mcp_service.dart`
- [ ] Update imports in `main.dart`

### Service Creation Checklist
- [ ] Create `GoalStorageService` with CRUD operations
- [ ] Create `GoalMCPService` with command handlers
- [ ] Extract goal logic from `SystemMCPService`
- [ ] Update `SystemMCPService` to delegate goal commands
- [ ] Test MCP command delegation works correctly

### Widget Extraction Checklist
- [ ] Create `GoalCard` widget
- [ ] Create `EmptyGoalsState` widget
- [ ] Create `GoalListView` widget (if needed)
- [ ] Update `GoalsScreen` to use new widgets
- [ ] Test UI components render correctly

### Integration Testing Checklist
- [ ] Goal creation via chat works
- [ ] Goals display in UI correctly
- [ ] MCP commands respond correctly
- [ ] Database operations succeed
- [ ] No regressions in existing functionality

---

*This refactoring establishes a clean, maintainable architecture for goals that follows established patterns and provides a solid foundation for future goal-related enhancements while preserving all existing functionality.*
