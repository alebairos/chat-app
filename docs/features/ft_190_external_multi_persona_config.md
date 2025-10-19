# FT-190: External Multi-Persona Configuration System

**Feature ID**: FT-190  
**Priority**: Medium  
**Category**: Configuration Management  
**Effort**: 2-3 hours  
**Status**: Specification  

## Problem Statement

The current multi-persona awareness system (FT-189) has hardcoded instructions in `CharacterConfigManager._buildIdentityContext()`, creating:

- **Maintenance burden**: Changes require code updates
- **Scalability issues**: New personas need code modifications  
- **Configuration drift**: Persona behavior rules scattered across code
- **Non-developer barriers**: Content updates require developer intervention

## Current State Analysis

### What Works
- ✅ Basic identity context generation
- ✅ Persona switching functionality
- ✅ Multi-persona history prefixing

### What's Broken
- ❌ **Hardcoded instructions**: Identity rules embedded in Dart code
- ❌ **Incomplete external config**: `multi_persona_config.json` exists but is unused
- ❌ **No template processing**: Advanced config fields ignored
- ❌ **Maintenance complexity**: Behavior changes require code deployment

### Evidence
```dart
// Current hardcoded approach in _buildIdentityContext()
return '''
## CRITICAL: YOUR IDENTITY
You are $displayName ($_activePersonaKey).
// ... hardcoded instructions
''';
```

## Solution Design

### Core Principle
**Configuration-driven behavior**: Move all multi-persona instructions from code to external JSON configuration with template processing.

### Technical Approach

1. **Template System**: Use `{{placeholder}}` syntax for dynamic content
2. **Modular Instructions**: Separate identity, continuity, and symbol guidance
3. **Fallback Strategy**: Graceful degradation to hardcoded defaults
4. **Feature Toggles**: Enable/disable instruction components

### Configuration Structure
```json
{
  "identityContextTemplate": "## CRITICAL: YOUR IDENTITY\nYou are {{displayName}} ({{personaKey}})...",
  "continuityInstructions": {
    "enabled": true,
    "template": "## CONVERSATION CONTINUITY\nWhen user talked to other personas..."
  },
  "symbolGuidance": {
    "enabled": true, 
    "instruction": "Use your authentic symbols, not other personas' symbols"
  }
}
```

## Implementation Requirements

### 1. Template Processing Engine
- **Input**: Template string with `{{placeholder}}` syntax
- **Processing**: Replace `{{displayName}}` and `{{personaKey}}` with actual values
- **Output**: Fully resolved instruction text
- **Error Handling**: Graceful fallback if placeholders missing

### 2. Enhanced `_buildIdentityContext()` Method
```dart
Future<String> _buildIdentityContext() async {
  final config = await _loadMultiPersonaConfig();
  String context = '';
  
  // Process identity template
  if (config['identityContextTemplate'] != null) {
    context += _processTemplate(config['identityContextTemplate']);
  }
  
  // Add continuity instructions if enabled
  if (config['continuityInstructions']?['enabled'] == true) {
    context += _processTemplate(config['continuityInstructions']['template']);
  }
  
  // Add symbol guidance if enabled  
  if (config['symbolGuidance']?['enabled'] == true) {
    context += config['symbolGuidance']['instruction'];
  }
  
  return context;
}
```

### 3. Template Processing Helper
```dart
String _processTemplate(String template) {
  return template
    .replaceAll('{{displayName}}', displayName)
    .replaceAll('{{personaKey}}', _activePersonaKey);
}
```

### 4. Error Resilience
- **Malformed JSON**: Fall back to hardcoded defaults
- **Missing templates**: Use simplified identity context
- **Template errors**: Log warning, continue with available content

## Acceptance Criteria

### Functional Requirements
- [ ] All multi-persona instructions loaded from external JSON config
- [ ] Template placeholders (`{{displayName}}`, `{{personaKey}}`) properly replaced
- [ ] Modular instruction components (identity, continuity, symbols) work independently
- [ ] Feature toggles allow enabling/disabling instruction components
- [ ] Graceful fallback to hardcoded defaults if config fails

### Technical Requirements  
- [ ] No hardcoded instruction strings in `_buildIdentityContext()`
- [ ] Template processing handles missing placeholders gracefully
- [ ] Configuration loading errors don't break persona switching
- [ ] Performance impact minimal (< 10ms additional processing)

### Quality Requirements
- [ ] All existing multi-persona functionality preserved
- [ ] No regression in persona identity accuracy
- [ ] Configuration changes don't require app restart
- [ ] Error logging for configuration issues

## Testing Strategy

### Unit Tests
- Template processing with valid placeholders
- Template processing with missing placeholders  
- Configuration loading with malformed JSON
- Fallback behavior when config unavailable

### Integration Tests
- Full persona switching with external config
- Multi-persona conversation continuity
- Symbol guidance preventing cross-persona contamination

### Manual Testing
- Modify config file, verify behavior changes
- Test with various persona combinations
- Validate error handling with corrupted config

## Risks & Mitigations

### Risk: Configuration Corruption
**Impact**: Broken persona behavior  
**Mitigation**: Robust fallback to hardcoded defaults

### Risk: Template Processing Errors
**Impact**: Malformed instructions  
**Mitigation**: Validate templates, graceful error handling

### Risk: Performance Degradation
**Impact**: Slower persona switching  
**Mitigation**: Cache processed templates, optimize string operations

## Success Metrics

- **Maintainability**: Multi-persona instruction changes require only config updates
- **Scalability**: New personas automatically inherit proper multi-persona behavior
- **Reliability**: Zero persona switching failures due to configuration issues
- **Performance**: < 10ms additional processing time for template resolution

## Implementation Notes

### Current Config Status
The `assets/config/multi_persona_config.json` file exists with proper structure but is completely unused by the code. This feature implements the missing code to actually use the external configuration.

### Backward Compatibility
Maintain existing hardcoded defaults as fallback to ensure no regression if external config fails.

### Future Enhancements
- A/B testing different instruction approaches
- Persona-specific instruction overrides
- Dynamic config reloading without restart
