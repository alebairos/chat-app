# FT-195: Fix SystemMCP Singleton Pattern for Oracle State Consistency

**Feature ID:** FT-195  
**Priority:** Critical  
**Category:** Bug Fix - Architecture  
**Effort:** 2-3 hours  

## Problem Statement

### Current Issue
Multiple SystemMCP instances are being created throughout the application lifecycle, causing Oracle state inconsistency. ClaudeService receives a different SystemMCP instance than the one configured with Oracle disabled state, leading to incorrect activity detection behavior for non-Oracle personas.

### Evidence from Diagnostic Logs
```
Line 83:  🔍 [FT-194] SystemMCP instance created: MCP_1760756717106_191284012 (Oracle: true)
Line 122: 🔍 [FT-194] SystemMCP instance created: MCP_1760756864567_929373453 (Oracle: true)
Line 123: 🔍 [FT-194] Oracle set to false on instance: MCP_1760756864567_929373453  ← CORRECT CONFIG
Line 223: 🔍 [FT-194] SystemMCP instance created: MCP_1760756868250_972164925 (Oracle: true)
Line 224: 🔍 [FT-194] ClaudeService received SystemMCP instance: 972164925  ← WRONG INSTANCE
Line 305: 🔍 [FT-194] ClaudeService checking Oracle on instance: 972164925
Line 306: 🔍 [FT-194] Oracle check on instance: MCP_1760756868250_972164925, enabled: true  ← WRONG STATE
```

**Problem**: 5 different SystemMCP instances created during single message processing, with ClaudeService using a different instance than the one configured with Oracle disabled.

## Root Cause Analysis

### 1. No Singleton Pattern
SystemMCP is instantiated multiple times throughout the application:
- App initialization
- Persona switching 
- Message processing
- MCP command execution
- Time context generation

### 2. Dependency Injection Issues
Services receive different SystemMCP instances:
- **CharacterConfigManager** configures instance A (Oracle disabled)
- **ClaudeService** receives instance B (Oracle enabled by default)
- **TimeContextService** creates instance C for time queries

### 3. Instance Lifecycle Problems
```
1. Instance 929373453: Gets Oracle disabled ✅ CORRECT
2. Instance 972164925: Created fresh with default Oracle enabled ❌ PROBLEM
3. ClaudeService: References wrong instance 972164925 ❌ WRONG REFERENCE
4. Oracle Check: Returns enabled from wrong instance ❌ WRONG RESULT
```

## Solution Design

### A) Implement Singleton Pattern for SystemMCP

Create a proper singleton implementation that ensures only one SystemMCP instance exists throughout the application lifecycle.

```dart
class SystemMCPService {
  static SystemMCPService? _instance;
  static final Object _lock = Object();
  
  // Private constructor
  SystemMCPService._internal() {
    _instanceId = 'MCP_SINGLETON_${DateTime.now().millisecondsSinceEpoch}';
    print('🔍 [FT-195] SystemMCP SINGLETON instance created: $_instanceId');
  }
  
  // Singleton factory
  factory SystemMCPService() {
    if (_instance == null) {
      synchronized(_lock, () {
        _instance ??= SystemMCPService._internal();
      });
    }
    return _instance!;
  }
  
  // Singleton getter
  static SystemMCPService get instance {
    return SystemMCPService();
  }
}
```

### B) Update All SystemMCP Usage Points

Ensure all services use the singleton instance:

#### 1. CharacterConfigManager
```dart
// OLD: Creates new instance
final mcpService = SystemMCPService();

// NEW: Uses singleton
final mcpService = SystemMCPService.instance;
```

#### 2. ClaudeService Constructor
```dart
// OLD: Accepts injected instance (could be different)
ClaudeService({SystemMCPService? systemMCP})

// NEW: Always uses singleton
ClaudeService({SystemMCPService? systemMCP}) 
  : _systemMCP = systemMCP ?? SystemMCPService.instance
```

#### 3. TimeContextService
```dart
// OLD: Creates new instance for time queries
final mcpService = SystemMCPService();

// NEW: Uses singleton
final mcpService = SystemMCPService.instance;
```

### C) Oracle State Persistence

Ensure Oracle state persists across all operations:

```dart
class SystemMCPService {
  // Oracle state persists in singleton
  bool _oracleEnabled = true;
  
  void setOracleEnabled(bool enabled) {
    _oracleEnabled = enabled;
    print('🔍 [FT-195] Oracle set to $enabled on SINGLETON instance: $_instanceId');
  }
  
  bool get isOracleEnabled {
    print('🔍 [FT-195] Oracle check on SINGLETON instance: $_instanceId, enabled: $_oracleEnabled');
    return _oracleEnabled;
  }
}
```

## Implementation Plan

### Phase 1: Implement Singleton Pattern (45 minutes)
1. **Convert SystemMCPService to singleton**
   - Add private constructor
   - Add singleton factory method
   - Add thread-safe instance creation
   - Update instance tracking logs

### Phase 2: Update Service Dependencies (60 minutes)
1. **Update CharacterConfigManager**
   - Use SystemMCPService.instance instead of new instance
   - Ensure Oracle configuration affects singleton

2. **Update ClaudeService**
   - Default to singleton instance if no injection provided
   - Remove dependency on external SystemMCP creation

3. **Update TimeContextService**
   - Use singleton for time queries
   - Remove new SystemMCP instantiation

### Phase 3: Update Dependency Injection (30 minutes)
1. **Update service initialization**
   - Ensure all services reference the same singleton
   - Remove multiple SystemMCP instantiations
   - Update service factories and providers

### Phase 4: Testing and Validation (45 minutes)
1. **Test Oracle state consistency**
   - Verify single instance creation log
   - Confirm Oracle disabled state persists
   - Validate no activity detection for Philosopher persona

## Expected Log Output After Fix

### Single Instance Creation
```
🔍 [FT-195] SystemMCP SINGLETON instance created: MCP_SINGLETON_xxx
🔍 [FT-195] Oracle set to false on SINGLETON instance: MCP_SINGLETON_xxx
🔍 [FT-195] ClaudeService using SINGLETON instance: MCP_SINGLETON_xxx
🔍 [FT-195] Oracle check on SINGLETON instance: MCP_SINGLETON_xxx, enabled: false
Activity analysis: Skipped - Oracle disabled for current persona
```

### No Multiple Instances
```
// BEFORE (WRONG): 5 different instances
🔍 [FT-194] SystemMCP instance created: MCP_xxx_111
🔍 [FT-194] SystemMCP instance created: MCP_xxx_222
🔍 [FT-194] SystemMCP instance created: MCP_xxx_333
🔍 [FT-194] SystemMCP instance created: MCP_xxx_444
🔍 [FT-194] SystemMCP instance created: MCP_xxx_555

// AFTER (CORRECT): 1 singleton instance
🔍 [FT-195] SystemMCP SINGLETON instance created: MCP_SINGLETON_xxx
```

## Success Metrics

### Immediate Validation
- ✅ **Single SystemMCP instance** created per app session
- ✅ **Oracle state consistency** across all services
- ✅ **No activity detection** for Philosopher persona
- ✅ **Normal activity detection** for Oracle-enabled personas

### Long-term Benefits
- ✅ **Reduced memory usage** - no duplicate SystemMCP instances
- ✅ **State consistency** - all services use same Oracle configuration
- ✅ **Simplified debugging** - single instance to track
- ✅ **Better performance** - no redundant instance creation

## Technical Implementation Details

### File Changes Required
1. `lib/services/system_mcp_service.dart` - Implement singleton pattern
2. `lib/config/character_config_manager.dart` - Use singleton instance
3. `lib/services/claude_service.dart` - Default to singleton instance
4. `lib/services/time_context_service.dart` - Use singleton for time queries
5. Any other services creating SystemMCP instances

### Backward Compatibility
- ✅ Existing API remains the same - `SystemMCPService()` still works
- ✅ Dependency injection still supported - falls back to singleton if null
- ✅ No breaking changes to service interfaces
- ✅ Oracle configuration methods unchanged

## Risk Mitigation

### Potential Issues
1. **Thread safety** - Mitigated by synchronized singleton creation
2. **Memory leaks** - Mitigated by proper singleton lifecycle management
3. **Testing complexity** - Mitigated by singleton reset methods for tests
4. **State pollution** - Mitigated by clear Oracle state management

### Rollback Plan
- Revert singleton pattern implementation
- Restore original SystemMCP constructor behavior
- All changes are code-based, no configuration impact
- Existing Oracle toggle mechanism remains intact

## Root Cause Summary

The issue occurs because **multiple SystemMCP instances** are created throughout the application lifecycle, with different instances receiving different Oracle configurations. The **singleton pattern** ensures all services use the **same instance** with **consistent Oracle state**.

**Before**: Multiple instances → Oracle state inconsistency → Wrong activity detection behavior
**After**: Single instance → Oracle state consistency → Correct activity detection behavior

This fix provides both **correct functionality** (proper Oracle toggling) and **architectural benefits** (reduced memory usage, simplified state management).
