# FT-192: Oracle Toggle Per Persona

**Feature ID**: FT-192  
**Priority**: Medium  
**Category**: Configuration Management  
**Effort**: 30 minutes  
**Status**: Specification  

## Problem Statement

Currently, all personas are forced to use Oracle framework commands (activity detection, metadata extraction) even when they are designed for pure conversational purposes. This creates:

- **Unnecessary complexity**: Conversational personas get Oracle instructions they don't need
- **Performance overhead**: Oracle processing for personas that don't use it
- **Architectural coupling**: Cannot create Oracle-free personas
- **Prompt pollution**: Oracle MCP commands appear in all persona prompts

## Current State Analysis

### What Works
- ✅ Oracle framework fully functional for coaching personas
- ✅ Activity detection and metadata extraction working
- ✅ MCP command processing established
- ✅ Multi-persona system operational

### What's Missing
- ❌ **No way to disable Oracle per persona**
- ❌ **All personas forced to load Oracle commands**
- ❌ **Cannot create pure conversational personas**
- ❌ **Hardcoded Oracle availability in SystemMCPService**

## Solution Design

### Approach: Configuration-Driven Oracle Toggle

Add a simple `oracleEnabled` boolean flag to persona configurations that controls Oracle command availability per persona.

### Dual Aristios Implementation

Create two complementary personas from the Aristios 4.5 foundation:

1. **Aristios 4.5, The Philosopher** (`aristiosPhilosopher45`)
   - Pure conversational wisdom and Socratic questioning
   - No activity tracking or Oracle framework
   - Focus on philosophical depth and life reflection
   - `oracleEnabled: false`

2. **Ari 4.5, The Oracle Coach** (`ariOracleCoach45`) 
   - Full Oracle 4.2 framework with activity detection
   - Behavioral change coaching with data-driven insights
   - Combines Aristios wisdom with Oracle methodology
   - `oracleEnabled: true`

### Technical Implementation

#### A) Persona Configuration Enhancement
```json
// In personas_config.json - Dual Aristios Implementation
"aristiosPhilosopher45": {
  "enabled": true,
  "displayName": "Aristios 4.5, The Philosopher",
  "description": "Pure philosophical wisdom and Socratic questioning without activity tracking",
  "configPath": "assets/config/aristios_philosopher_config_4.5.json",
  "oracleEnabled": false,  // ← NEW: Disable Oracle commands for pure conversation
  "mcpBaseConfig": "assets/config/mcp_base_config.json",
  "audioFormatting": {
    "enabled": true
  }
},
"ariOracleCoach45": {
  "enabled": true,
  "displayName": "Ari 4.5, The Oracle Coach", 
  "description": "Behavioral change coach combining Aristios wisdom with Oracle 4.2 framework",
  "configPath": "assets/config/ari_oracle_coach_config_4.5.json",
  "oracleEnabled": true,   // ← NEW: Enable Oracle commands for coaching
  "oracleConfigPath": "assets/config/oracle/oracle_prompt_4.2_optimized.md",
  "mcpBaseConfig": "assets/config/mcp_base_config.json",
  "mcpExtensions": ["assets/config/mcp_extensions/oracle_4.2_extension.json"],
  "audioFormatting": {
    "enabled": true
  }
}
```

#### B) SystemMCPService Enhancement
```dart
class SystemMCPService {
  bool _oracleEnabled = true;  // Default to enabled for backward compatibility
  
  /// Configure Oracle command availability for current persona
  void setOracleEnabled(bool enabled) {
    _oracleEnabled = enabled;
  }
  
  Future<String> processCommand(String command) async {
    // ... existing parsing logic ...
    
    switch (action) {
      // General commands (always available)
      case 'get_current_time':
      case 'get_device_info':
      case 'get_message_stats':
      case 'get_conversation_context':
        // Execute general commands normally
        break;
        
      // Oracle commands (conditional availability)
      case 'get_activity_stats':
      case 'oracle_detect_activities':
      case 'oracle_query_activities':
      case 'oracle_get_compact_context':
      case 'oracle_get_statistics':
        if (!_oracleEnabled) {
          return _errorResponse('Oracle commands not available for this persona');
        }
        // Execute Oracle commands when enabled
        break;
    }
  }
}
```

#### C) CharacterConfigManager Integration
```dart
class CharacterConfigManager {
  Future<void> switchPersona(String personaKey) async {
    // ... existing persona loading logic ...
    
    // Configure Oracle availability based on persona config
    final personaConfig = await _getPersonaConfig(personaKey);
    final oracleEnabled = personaConfig['oracleEnabled'] ?? true; // Default: enabled
    
    // Set Oracle availability in MCP service
    final mcpService = SystemMCPService();
    mcpService.setOracleEnabled(oracleEnabled);
    
    // ... rest of existing logic ...
  }
}
```

## Command Availability Matrix

| Command | Oracle Enabled | Oracle Disabled |
|---------|---------------|-----------------|
| `get_current_time` | ✅ Available | ✅ Available |
| `get_device_info` | ✅ Available | ✅ Available |
| `get_message_stats` | ✅ Available | ✅ Available |
| `get_conversation_context` | ✅ Available | ✅ Available |
| `get_activity_stats` | ✅ Available | ❌ Error Response |
| `oracle_detect_activities` | ✅ Available | ❌ Error Response |
| `oracle_query_activities` | ✅ Available | ❌ Error Response |
| `oracle_get_compact_context` | ✅ Available | ❌ Error Response |
| `oracle_get_statistics` | ✅ Available | ❌ Error Response |

## Functional Requirements

### Core Functionality
- [ ] Add `oracleEnabled` boolean field to persona configurations
- [ ] Implement Oracle toggle in `SystemMCPService.setOracleEnabled()`
- [ ] Add conditional Oracle command processing
- [ ] Integrate Oracle toggle in `CharacterConfigManager.switchPersona()`
- [ ] Maintain backward compatibility (default `oracleEnabled: true`)

### Oracle-Enabled Personas
- [ ] All existing Oracle personas continue working identically
- [ ] Activity detection and metadata extraction preserved
- [ ] Background processing unchanged
- [ ] Two-pass MCP system operational
- [ ] Complete Oracle 4.2 framework available

### Oracle-Disabled Personas
- [ ] General MCP commands available (time, device, conversation)
- [ ] Oracle commands return appropriate error messages
- [ ] No Oracle instructions in system prompt
- [ ] No activity detection or metadata extraction
- [ ] Clean conversational AI experience

### Error Handling
- [ ] Graceful error responses for disabled Oracle commands
- [ ] Clear error messages indicating command unavailability
- [ ] No system crashes or undefined behavior
- [ ] Proper fallback for missing `oracleEnabled` field

## Non-Functional Requirements

### Performance
- **Oracle-Enabled**: No performance impact (identical to current behavior)
- **Oracle-Disabled**: Reduced MCP processing overhead
- **Memory**: Lower memory usage for non-Oracle personas
- **Startup**: Faster persona loading without Oracle framework

### Compatibility
- **Backward Compatible**: Existing personas work unchanged
- **Default Behavior**: `oracleEnabled: true` when field missing
- **Migration**: No changes required for existing configurations
- **API Stability**: No breaking changes to existing interfaces

### Maintainability
- **Simple Logic**: Clear boolean flag with obvious behavior
- **Testable**: Easy to verify Oracle enable/disable functionality
- **Extensible**: Foundation for future feature toggles
- **Debuggable**: Clear separation of Oracle vs general functionality

## Implementation Plan

### Phase 1: Core Implementation (15 minutes)
1. Add `oracleEnabled` field to persona configurations
2. Implement `SystemMCPService.setOracleEnabled()`
3. Add conditional Oracle command processing
4. Update `CharacterConfigManager.switchPersona()`

### Phase 2: Testing (10 minutes)
1. Test existing Oracle personas (verify no regression)
2. Create test non-Oracle persona configuration
3. Verify Oracle commands properly disabled
4. Test general commands still available

### Phase 3: Documentation (5 minutes)
1. Update persona configuration documentation
2. Document Oracle toggle usage patterns
3. Add examples for Oracle-enabled and disabled personas

## Testing Strategy

### Regression Testing
- [ ] All existing Oracle personas function identically
- [ ] Activity detection works for Oracle personas
- [ ] Background processing preserved
- [ ] MCP commands execute normally for Oracle personas

### New Functionality Testing
- [ ] Create persona with `oracleEnabled: false`
- [ ] Verify Oracle commands return error responses
- [ ] Confirm general commands still available
- [ ] Test persona switching between Oracle/non-Oracle

### Edge Case Testing
- [ ] Missing `oracleEnabled` field (should default to `true`)
- [ ] Invalid `oracleEnabled` values (should handle gracefully)
- [ ] Persona switching preserves Oracle state correctly

## Acceptance Criteria

### Must Have
- [ ] Existing Oracle personas work identically (zero regression)
- [ ] New personas can disable Oracle with `oracleEnabled: false`
- [ ] Oracle commands return appropriate errors when disabled
- [ ] General MCP commands always available regardless of Oracle setting
- [ ] Backward compatible with existing persona configurations

### Should Have
- [ ] Clear error messages for disabled Oracle commands
- [ ] Performance improvement for non-Oracle personas
- [ ] Clean separation of Oracle vs general functionality
- [ ] Easy configuration management

### Could Have
- [ ] Logging of Oracle enable/disable state changes
- [ ] Metrics on Oracle vs non-Oracle persona usage
- [ ] Configuration validation for `oracleEnabled` field

## Risk Assessment

### Low Risk
- **Backward Compatibility**: Default `true` preserves existing behavior
- **Isolated Changes**: Small, focused modifications
- **Additive Only**: No existing functionality removed
- **Safe Defaults**: Conservative approach with proven patterns

### Mitigation Strategies
- **Thorough Testing**: Verify all existing personas unchanged
- **Gradual Rollout**: Test with single non-Oracle persona first
- **Rollback Plan**: Simple to revert if issues discovered
- **Monitoring**: Track persona switching and MCP command usage

## Success Metrics

### Technical Metrics
- Zero regression in existing Oracle persona functionality
- Successful creation of pure conversational personas
- Proper error handling for disabled Oracle commands
- Performance improvement for non-Oracle personas

### User Experience Metrics
- Cleaner conversational experience for non-Oracle personas
- Maintained coaching functionality for Oracle personas
- Seamless persona switching between Oracle/non-Oracle types

## Future Considerations

### Extensibility
- Foundation for additional feature toggles per persona
- Potential for more granular Oracle feature control
- Basis for full MCP package system in future

### Architecture Evolution
- Could evolve into full 2-package MCP system (General + Oracle)
- Potential for plugin-based MCP architecture
- Foundation for persona-specific capability management

## Conclusion

This feature provides a simple, safe way to create pure conversational personas while preserving all existing Oracle functionality. The implementation is minimal, backward compatible, and provides immediate value for creating diverse persona types within the same system architecture.
