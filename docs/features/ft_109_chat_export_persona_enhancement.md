# Feature Specification: Chat Export Persona Enhancement

## Overview

This specification addresses persona attribution issues in chat exports by implementing intelligent fallback logic for legacy messages and enhancing the export system's reliability.

## Feature Summary

**Feature ID:** FT-109  
**Priority:** High  
**Category:** Data Management  
**Estimated Effort:** 1-2 days  

### Problem Statement

After inspecting the actual database (`ChatMessageModel.json`), persona data **IS** being stored correctly in recent messages. However, exports include legacy messages without persona data, resulting in incomplete persona attribution in exported files.

**Database Evidence:**
- ✅ Recent messages: `"personaDisplayName":"Ari 2.1","personaKey":"ariWithOracle21"`
- ❌ Legacy messages: `"personaDisplayName":null,"personaKey":null`

### User Story

> As a user, I want my chat exports to always show correct persona names for all AI messages, with intelligent fallback for legacy messages that lack stored persona data.

## Functional Requirements

### FR-1: Intelligent Persona Attribution
- **Primary**: Use stored `personaDisplayName` when available
- **Fallback**: Derive persona from `currentPersonaKey` and configuration for legacy messages
- **Default**: Use "AI Assistant" only when no persona context exists

### FR-2: Export Statistics Enhancement
- Display accurate persona counts in export preview
- Show breakdown: "X messages with stored persona, Y with inferred persona"
- Indicate data quality in export metadata

### FR-3: Legacy Message Processing
- Identify messages created before persona tracking (null `personaDisplayName`)
- Apply current persona context based on conversation timing
- Document inference method in export metadata

### FR-4: Configuration-Based Persona Resolution
- Load persona display names from current configuration files
- Support fallback to persona key if display name unavailable
- Handle deprecated or renamed personas gracefully

## Technical Requirements

### TR-1: Export Service Enhancement
Modify `ChatExportService` to implement intelligent persona resolution:

```dart
class PersonaResolver {
  static String resolvePersonaName(ChatMessageModel message, String? contextPersonaKey) {
    // 1. Use stored persona data (preferred)
    if (message.personaDisplayName?.isNotEmpty == true) {
      return message.personaDisplayName!;
    }
    
    // 2. Fallback to context persona + configuration
    if (contextPersonaKey != null) {
      return _getDisplayNameFromConfig(contextPersonaKey) ?? contextPersonaKey;
    }
    
    // 3. Default fallback
    return "AI Assistant";
  }
}
```

### TR-2: Export Metadata Enhancement
Add export quality metrics:

```dart
class ExportMetadata {
  final int totalMessages;
  final int messagesWithStoredPersona;
  final int messagesWithInferredPersona;
  final int messagesWithoutPersona;
  final Map<String, int> personaCounts;
  final DateTime exportDate;
  final String dataQualityNote;
}
```

### TR-3: Configuration Integration
- Integrate with existing `CharacterConfigManager`
- Support real-time persona configuration loading
- Handle missing or invalid persona configurations

## Implementation Strategy

### Phase 1: Core Logic Enhancement (4-6 hours)
1. **Enhance PersonaResolver** with intelligent fallback logic
2. **Update export service** to use resolver for all AI messages
3. **Add configuration integration** for persona display names

### Phase 2: Export Quality Metrics (2-3 hours)
1. **Implement export metadata** collection and display
2. **Enhance export preview** with persona breakdown
3. **Add data quality indicators** to exported files

### Phase 3: Testing & Validation (2-3 hours)
1. **Test with mixed message types** (stored vs. legacy)
2. **Verify persona accuracy** across different conversation periods
3. **Validate export statistics** and metadata

## Acceptance Criteria

### AC-1: Persona Attribution Accuracy
- ✅ Recent messages show correct stored persona names
- ✅ Legacy messages show inferred persona from context
- ✅ No messages show "AI Assistant" unless truly unknown

### AC-2: Export Quality Transparency
- ✅ Export preview shows accurate persona statistics
- ✅ Export metadata indicates data quality level
- ✅ Users understand message attribution source

### AC-3: Configuration Integration
- ✅ Persona names match current configuration files
- ✅ Deprecated personas handle gracefully
- ✅ Configuration changes reflect in future exports

## Risk Assessment

**Low Risk**: This enhancement builds on existing functionality without breaking changes

**Mitigation Strategies:**
- Preserve existing export format compatibility
- Add comprehensive test coverage for edge cases
- Implement gradual rollout with fallback options

## Dependencies

- **FT-049**: Persona Metadata Storage (completed)
- **Existing**: CharacterConfigManager
- **Existing**: Chat export service architecture

## Definition of Done

- [ ] All AI messages in exports show appropriate persona attribution
- [ ] Export statistics accurately reflect persona distribution
- [ ] Legacy message handling works seamlessly
- [ ] Configuration integration prevents persona mismatches
- [ ] Comprehensive tests cover all attribution scenarios
- [ ] Export metadata provides transparency on data quality

## Testing Strategy

### Test Cases

1. **Mixed Message Export**
   - Export conversation with both legacy and recent messages
   - Verify persona attribution uses appropriate fallback logic
   - Confirm statistics match actual attribution

2. **Configuration Changes**
   - Export after persona display name changes
   - Verify legacy messages use updated configuration
   - Confirm stored persona data takes precedence

3. **Edge Cases**
   - Export with unknown persona keys
   - Handle missing configuration files
   - Process deprecated persona references

### Test Data Requirements

- Conversations spanning pre/post persona tracking periods
- Messages with various persona configurations
- Legacy data with missing persona information

## Implementation Notes

This enhancement focuses on **data quality improvement** rather than system redesign. The existing export infrastructure remains intact while adding intelligent persona resolution capabilities.

The solution leverages the **principle of graceful degradation**: 
1. Best case: Use stored persona data
2. Good case: Infer from context and configuration  
3. Fallback case: Use generic "AI Assistant"

This approach ensures **backwards compatibility** while maximizing **persona attribution accuracy** for users' exported conversations.