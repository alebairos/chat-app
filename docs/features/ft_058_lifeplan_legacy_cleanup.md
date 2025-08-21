# Feature FT-058: LifePlan Legacy Cleanup

## Feature Overview

**Feature ID**: FT-058  
**Priority**: Medium  
**Category**: Technical Debt  
**Effort Estimate**: 2-3 hours  

## Executive Summary

Remove legacy LifePlan domain logic and CSV data management while extracting and preserving the valuable MCP (Model Context Protocol) infrastructure patterns. This cleanup will eliminate unused complexity, reduce maintenance burden, and create a clean foundation for future system functions like time awareness.

## Problem Statement

### Current State
- LifePlan domain logic is legacy and unused by users
- Complex CSV data loading for goals, habits, and tracks nobody uses
- MCP infrastructure is built but buried in LifePlan-specific implementation
- Clean MCP patterns are obscured by domain complexity
- Tests and code coverage wasted on unused functionality

### Technical Debt Issues
- **Unused Code**: Entire life planning domain with no active users
- **Complex Dependencies**: CSV parsing, data models, business logic
- **Obscured Patterns**: Valuable MCP infrastructure hidden in legacy code
- **Maintenance Burden**: Tests, models, and services for unused features
- **Confusing Architecture**: Mix of useful patterns and legacy domain logic

## Solution Approach

### The Simplest Thing That Could Possibly Work

**Phase 1**: Extract reusable MCP patterns into clean generic service  
**Phase 2**: Remove all LifePlan-specific code, models, and data  
**Phase 3**: Update documentation and clean up tests  

**Core Principle**: Preserve what's useful, delete what's not.

## Functional Requirements

### What Gets Preserved (Extracted)
1. **Generic MCP Service Pattern**: JSON command processing infrastructure
2. **Claude Integration Pattern**: System prompt injection and command handling
3. **Error Handling**: Response formatting and validation patterns
4. **Logging Infrastructure**: Debug and monitoring capabilities

### What Gets Deleted
1. **Domain Models**: Goal, Habit, Track, Dimension classes
2. **CSV Data Management**: File loading, parsing, data initialization
3. **LifePlan Business Logic**: All domain-specific operations
4. **Legacy Tests**: Tests for removed functionality
5. **Data Files**: CSV files in `assets/data/`

## Technical Implementation

### Architecture Before
```
LifePlanService (CSV loading, business logic)
     ↓
LifePlanMCPService (domain-specific MCP wrapper)
     ↓
ClaudeService (complex integration with dimensions)
```

### Architecture After
```
SystemMCPService (clean, generic MCP functions)
     ↓
ClaudeService (simple JSON command integration)
```

### Implementation Steps

#### Phase 1: Extract Generic MCP Service (1 hour)

1. **Create SystemMCPService** (`lib/services/system_mcp_service.dart`)
   ```dart
   class SystemMCPService {
     final Logger _logger = Logger();
     
     String processCommand(String command) {
       try {
         final parsedCommand = json.decode(command);
         final action = parsedCommand['action'] as String?;
         
         switch (action) {
           case 'get_current_time':
             return _getCurrentTime();
           default:
             return _errorResponse('Unknown action: $action');
         }
       } catch (e) {
         return _errorResponse('Invalid command format: $e');
       }
     }
   }
   ```

2. **Update ClaudeService Integration**
   ```dart
   class ClaudeService {
     final SystemMCPService? _systemMCP;
     
     // Remove _fetchRelevantMCPData complexity
     // Keep simple JSON command pattern
   }
   ```

#### Phase 2: Remove LifePlan Legacy (1 hour)

3. **Delete Files**:
   - `lib/services/life_plan_service.dart`
   - `lib/services/life_plan_mcp_service.dart`
   - `lib/models/life_plan/` (entire directory)
   - `assets/data/` (CSV files)
   - Related test files

4. **Update ClaudeService**:
   - Remove LifePlan imports
   - Remove dimension detection logic
   - Remove complex MCP data fetching
   - Simplify to basic JSON command handling

5. **Update Main Application**:
   - Remove LifePlan service initialization
   - Update ClaudeService constructor calls

#### Phase 3: Clean Documentation (30 minutes)

6. **Update Tests**: Replace legacy tests with SystemMCPService tests
7. **Update Documentation**: Remove LifePlan references
8. **Clean Imports**: Remove unused dependencies

## File Impact Analysis

### Files to Delete
```
lib/services/life_plan_service.dart
lib/services/life_plan_mcp_service.dart
lib/models/life_plan/dimensions.dart
lib/models/life_plan/goal.dart
lib/models/life_plan/habit.dart
lib/models/life_plan/track.dart
lib/models/life_plan/index.dart
assets/data/habitos.csv
assets/data/Objetivos.csv
assets/data/habit-assistant-prompt-v13.json
test/services/life_plan_service_test.dart
test/services/life_plan_mcp_service_test.dart
test/models/life_plan/
test/life_plan/
```

### Files to Create
```
lib/services/system_mcp_service.dart
test/services/system_mcp_service_test.dart
```

### Files to Modify
```
lib/services/claude_service.dart (major cleanup)
lib/main.dart (remove LifePlan initialization)
lib/screens/chat_screen.dart (update service injection)
pubspec.yaml (remove csv dependency if unused elsewhere)
```

## Non-Functional Requirements

### Performance Impact
- **Positive**: Faster app startup (no CSV loading)
- **Positive**: Reduced memory usage (no data caching)
- **Positive**: Smaller bundle size (removed assets)

### Maintainability
- **Improved**: Cleaner codebase with less complexity
- **Improved**: Focused test suite on actual functionality
- **Improved**: Clear separation of system vs domain concerns

### Risk Mitigation
- **Backup**: Git ensures we can recover if needed
- **Incremental**: Phased approach allows rollback
- **Testing**: Each phase verified before proceeding

## Success Metrics

### Code Quality Metrics
- [ ] Remove ~2000+ lines of unused code
- [ ] Reduce test execution time by removing legacy tests
- [ ] Simplify ClaudeService from ~500 to ~200 lines
- [ ] Remove 6+ unused model classes

### Functional Verification
- [ ] Chat functionality unchanged
- [ ] MCP command pattern still works
- [ ] Time awareness can be added to clean foundation
- [ ] All existing tests pass (after cleanup)

## Testing Strategy

### Before Cleanup
1. **Verify Current Functionality**: Ensure chat works as expected
2. **Document Behavior**: Record what actually works vs what's tested

### During Each Phase
1. **Incremental Testing**: Verify app still works after each change
2. **Rollback Plan**: Git commits for easy reversion
3. **Smoke Testing**: Basic chat functionality verification

### After Cleanup
1. **Full Regression**: Complete app functionality testing
2. **Performance Verification**: Startup time and memory usage
3. **Clean Build**: Ensure no broken imports or dependencies

## Implementation Notes

### Design Decisions
- **Preserve Patterns**: Keep JSON command processing pattern
- **Generic Design**: SystemMCPService extensible for future functions
- **Clean Separation**: No business domain logic in system service
- **Simple Integration**: Minimal changes to ClaudeService core

### Future Extensibility
```dart
// Easy to add new system functions
case 'get_current_time': return _getCurrentTime();
case 'get_device_info': return _getDeviceInfo();
case 'get_app_settings': return _getAppSettings();
```

### Dependencies to Remove
- `csv` package (if only used for LifePlan)
- Any LifePlan-specific imports across the codebase

## Risk Assessment

### Technical Risks
- **Risk**: Breaking existing functionality during cleanup
- **Mitigation**: Incremental approach with testing at each step
- **Probability**: Low (code is unused)

### Business Risks
- **Risk**: Losing valuable patterns during cleanup
- **Mitigation**: Careful extraction of MCP infrastructure first
- **Probability**: Very Low (we're preserving useful patterns)

### Operational Risks
- **Risk**: Extended development time for cleanup
- **Mitigation**: Clear scope and time boxing
- **Probability**: Low (straightforward deletion)

## Acceptance Criteria

### Definition of Done
- [ ] SystemMCPService created with time function capability
- [ ] All LifePlan files and references removed
- [ ] ClaudeService simplified and cleaned
- [ ] Chat functionality fully preserved
- [ ] Test suite updated and passing
- [ ] No broken imports or dependencies
- [ ] App startup time improved
- [ ] Documentation updated

### User Acceptance
- [ ] Users see no change in chat functionality
- [ ] App feels faster (reduced startup time)
- [ ] Foundation ready for clean time function implementation
- [ ] No references to life planning in UI or conversations

## Conclusion

This cleanup will transform the codebase from a confused mix of useful patterns and legacy domain logic into a clean foundation for future system functions. The MCP infrastructure patterns are valuable and will be preserved, while the complex LifePlan domain logic that nobody uses will be removed.

**Key Benefits:**
- **Cleaner Architecture**: Focus on what actually works
- **Faster Development**: No more wading through legacy code
- **Better Foundation**: Clean base for time awareness and other system functions
- **Reduced Maintenance**: Remove tests and code for unused features

**Timeline**: 2-3 hours for complete cleanup with clean SystemMCPService ready for time function implementation.
