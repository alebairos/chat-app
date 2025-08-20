# Feature Specification: Configurable Oracle Versions for Personas

**Feature ID:** FT-054  
**Priority:** Medium  
**Category:** Configuration Enhancement  
**Estimated Effort:** 2-3 hours  

## Executive Summary

This feature enables personas to use different versions of the Oracle knowledge base by adding an `oracleConfigPath` property to persona configurations. This allows creating multiple variants of existing personas (e.g., "Ari with Oracle 2.1", "I-There with Oracle 2.1") without duplicating persona logic.

## Problem Statement

Currently, all personas that use Oracle knowledge are limited to a single Oracle version determined by environment variable or default path. To test different Oracle versions or offer specialized variants, we need the ability to configure Oracle paths per persona.

## Solution Overview

Add `oracleConfigPath` as an optional property in `personas_config.json`. When specified, the persona uses that Oracle version; when omitted, it uses the current environment/default fallback behavior.

## Requirements

### Functional Requirements

#### FR-001: Oracle Configuration Property
- Add optional `oracleConfigPath` field to persona configurations
- Field specifies the path to Oracle markdown file (e.g., `assets/config/oracle/oracle_prompt_2.1.md`)
- When null/omitted, use current environment variable or default Oracle path

#### FR-002: Persona Variants
- Enable creation of new persona entries that combine existing persona configs with different Oracle versions
- Example: "Ari with Oracle 2.1" uses `ari_life_coach_config_2.0.json` + `oracle_prompt_2.1.md`

#### FR-003: Backward Compatibility
- Existing personas without `oracleConfigPath` continue working unchanged
- Environment variable `ORACLE_PROMPT_PATH` still works as fallback
- Default Oracle path `assets/config/oracle/oracle_prompt_1.0.md` remains as final fallback

### Non-Functional Requirements

#### NFR-001: Minimal Code Changes
- Leverage existing Oracle composition logic in `CharacterConfigManager.loadSystemPrompt()`
- Only change the source of Oracle path, not the composition mechanism

#### NFR-002: Configuration Driven
- New personas added by editing `personas_config.json` only
- No code changes required to add new Oracle variants

## Technical Implementation

### Configuration Schema Enhancement

#### Updated personas_config.json Structure
```json
{
  "defaultPersona": "ariLifeCoach",
  "personas": {
    "ariLifeCoach": {
      "enabled": true,
      "displayName": "Ari - Life Coach",
      "description": "TARS-inspired life coach with intelligent brevity",
      "configPath": "assets/config/ari_life_coach_config_2.0.json"
      // No oracleConfigPath = uses environment/default Oracle
    },
    "ariWithOracle21": {
      "enabled": true,
      "displayName": "Ari with Oracle 2.1",
      "description": "Life coach with Oracle 2.1 knowledge base",
      "configPath": "assets/config/ari_life_coach_config_2.0.json",
      "oracleConfigPath": "assets/config/oracle/oracle_prompt_2.1.md"
    },
    "iThereWithOracle21": {
      "enabled": true,
      "displayName": "I-There with Oracle 2.1", 
      "description": "AI clone with Oracle 2.1 knowledge base",
      "configPath": "assets/config/i_there_config.json",
      "oracleConfigPath": "assets/config/oracle/oracle_prompt_2.1.md"
    }
  }
}
```

### Code Changes Required

#### File: `lib/config/character_config_manager.dart`

**1. Add Oracle Config Path Method**
```dart
/// Get the Oracle configuration path for the active persona
Future<String?> getOracleConfigPath() async {
  try {
    final String jsonString =
        await rootBundle.loadString('assets/config/personas_config.json');
    final Map<String, dynamic> config = json.decode(jsonString);
    final Map<String, dynamic> personas = config['personas'] ?? {};

    if (personas.containsKey(_activePersonaKey)) {
      final persona = personas[_activePersonaKey] as Map<String, dynamic>?;
      if (persona != null && persona['oracleConfigPath'] != null) {
        return persona['oracleConfigPath'] as String;
      }
    }
  } catch (e) {
    print('Error loading Oracle config path: $e');
  }
  
  return null; // No Oracle config specified
}
```

**2. Update loadSystemPrompt() Method**

Replace lines 72-78 in existing `loadSystemPrompt()`:

```dart
// BEFORE:
final String defaultOraclePath = 'assets/config/oracle/oracle_prompt_1.0.md';
final String oraclePathEnv = (dotenv.env['ORACLE_PROMPT_PATH'] ?? '').trim();
final String oraclePath = oraclePathEnv.isNotEmpty ? oraclePathEnv : defaultOraclePath;

// AFTER:  
final String? oracleConfigPath = await getOracleConfigPath();
final String defaultOraclePath = 'assets/config/oracle/oracle_prompt_1.0.md';
final String oraclePathEnv = (dotenv.env['ORACLE_PROMPT_PATH'] ?? '').trim();
final String oraclePath = oracleConfigPath ?? 
    (oraclePathEnv.isNotEmpty ? oraclePathEnv : defaultOraclePath);
```

**Priority Logic:**
1. **Persona Oracle Config** (`oracleConfigPath` from persona config)
2. **Environment Variable** (`ORACLE_PROMPT_PATH`)
3. **Default Path** (`assets/config/oracle/oracle_prompt_1.0.md`)

### Configuration Files Required

#### New Persona Entries
Add to `assets/config/personas_config.json`:

```json
"ariWithOracle21": {
  "enabled": true,
  "displayName": "Ari with Oracle 2.1",
  "description": "Life coach with Oracle 2.1 knowledge base",
  "configPath": "assets/config/ari_life_coach_config_2.0.json",
  "oracleConfigPath": "assets/config/oracle/oracle_prompt_2.1.md"
},
"iThereWithOracle21": {
  "enabled": true,
  "displayName": "I-There with Oracle 2.1",
  "description": "AI clone with Oracle 2.1 knowledge base", 
  "configPath": "assets/config/i_there_config.json",
  "oracleConfigPath": "assets/config/oracle/oracle_prompt_2.1.md"
}
```

#### Oracle File
- **Target Oracle**: `assets/config/oracle/oracle_prompt_2.1.md`
- **Source**: `/Users/alebairos/Projects/mobile/chat_app/assets/config/oracle/oracle_prompt_2.1.md`

## Implementation Steps

### Phase 1: Core Implementation (1 hour)
1. Add `getOracleConfigPath()` method to `CharacterConfigManager`
2. Update Oracle path resolution in `loadSystemPrompt()`
3. Test with existing personas (should work unchanged)

### Phase 2: Configuration Setup (30 minutes)
1. Add new persona entries to `personas_config.json`
2. Verify Oracle 2.1 file is accessible at specified path
3. Test persona selection shows new variants

### Phase 3: Testing (30 minutes)
1. Test "Ari with Oracle 2.1" persona functionality
2. Test "I-There with Oracle 2.1" persona functionality
3. Verify existing personas still work with original Oracle
4. Test fallback behavior for missing Oracle files

## Testing Strategy

### Test Cases

#### TC-001: New Oracle Variants
- **Action**: Select "Ari with Oracle 2.1" persona
- **Expected**: Uses Ari personality + Oracle 2.1 knowledge
- **Verification**: Check system prompt contains Oracle 2.1 content

#### TC-002: Existing Personas Unchanged
- **Action**: Select original "Ari - Life Coach" persona  
- **Expected**: Uses environment/default Oracle (Oracle 1.0)
- **Verification**: Behavior identical to before implementation

#### TC-003: Missing Oracle File
- **Action**: Configure persona with non-existent Oracle path
- **Expected**: Falls back to environment/default Oracle
- **Verification**: No crashes, Oracle 1.0 content loaded

#### TC-004: Persona Selection UI
- **Action**: Open character selection screen
- **Expected**: Shows new Oracle variants as separate options
- **Verification**: "Ari with Oracle 2.1" and "I-There with Oracle 2.1" appear

### Integration Testing
- Verify persona metadata tracking still works (FT-049)
- Ensure persona icon display remains correct (FT-053) 
- Test chat export includes correct persona names (FT-048)

## Error Handling

### Scenarios
| Error Condition | Handling | User Impact |
|----------------|----------|-------------|
| Oracle file not found | Fall back to environment/default Oracle | Graceful degradation |
| Invalid Oracle path | Fall back to environment/default Oracle | Graceful degradation |
| Missing oracleConfigPath | Use environment/default Oracle | No change from current behavior |
| Malformed Oracle file | Log error, use persona-only prompt | Limited functionality, no crash |

## Success Criteria

### Core Functionality
- [ ] New persona variants appear in selection screen
- [ ] "Ari with Oracle 2.1" combines Ari personality + Oracle 2.1 knowledge
- [ ] "I-There with Oracle 2.1" combines I-There personality + Oracle 2.1 knowledge
- [ ] Existing personas continue working unchanged
- [ ] Oracle path priority: persona config > environment > default

### User Experience  
- [ ] Persona selection clearly distinguishes Oracle variants
- [ ] No performance impact on persona switching
- [ ] Error conditions fail gracefully without crashes
- [ ] Oracle 2.1 content appears in AI responses

### Technical Quality
- [ ] Minimal code changes (single method + small update)
- [ ] Backward compatibility maintained
- [ ] Configuration-driven extensibility achieved
- [ ] All existing tests continue passing

## Future Enhancements

### Immediate Extensions
- Add more Oracle variants (2.0, 2.2, etc.)
- Create Sergeant Oracle + Oracle 2.1 variant
- Add Oracle version indicators in chat UI

### Advanced Features  
- Dynamic Oracle version switching within conversations
- Oracle versioning and migration tools
- Custom user-provided Oracle configurations
- Oracle content validation and linting

## Dependencies

### Internal Dependencies
- **CharacterConfigManager**: Core implementation location
- **personas_config.json**: Configuration storage
- **Oracle Prompt 2.1**: Target Oracle version file

### External Dependencies
- No new package dependencies required
- No Flutter framework changes needed

## Risks and Mitigation

### Risk: Oracle File Size Impact
- **Concern**: Large Oracle files may impact app performance
- **Mitigation**: Oracle loading is already async; monitor performance
- **Fallback**: Implement Oracle caching if needed

### Risk: Configuration Complexity
- **Concern**: Users may create invalid Oracle configurations
- **Mitigation**: Comprehensive error handling and graceful fallbacks
- **Fallback**: Always fall back to working Oracle version

## Conclusion

This feature provides a simple, configuration-driven way to create Oracle variants of existing personas. The implementation leverages existing Oracle composition logic while adding minimal complexity. Users can experiment with different Oracle versions while maintaining the full personality characteristics of their preferred personas.

The solution enables immediate testing of Oracle 2.1 with both Ari and I-There personas while preserving all existing functionality and maintaining clean extensibility for future Oracle versions.

---

**Document Version:** 1.0  
**Last Updated:** January 20, 2025  
**Author:** AI Assistant  
**Implementation Ready:** Yes
