# FT-062: Oracle Preprocessing Architecture

## Feature Overview

Replace fragile runtime Oracle markdown parsing with robust build-time preprocessing that generates static JSON templates for reliable activity detection.

## Problem Statement

**Current Issue:**
- Oracle parsing fails completely (0 dimensions, 0 activities parsed)
- Regex-based parsing is fragile and breaks with text formatting changes
- Runtime parsing errors prevent activity memory functionality
- Debugging parsing failures is complex and time-consuming

**Root Cause:**
```
flutter: 🔍 [DEBUG] Found BIBLIOTECA section, length: 40
flutter: 🔍 [DEBUG] Found 0 dimension matches
flutter: ⚠️ [WARNING] Could not find dimension for activity code: SF1, T8, R1, etc.
```

## Solution: Build-Time Preprocessing

### Core Concept
**Oracle Markdown → Preprocessing Script → Static JSON → Runtime Loading**

Instead of parsing markdown at runtime, generate validated JSON templates during development/build time.

## Requirements

### Functional Requirements

**FR-1: Preprocessing Script**
- Parse Oracle markdown files and generate structured JSON
- Support multiple Oracle versions (2.0, 2.1, future versions)
- Extract dimensions (SF, TG, R, E, SM) with full names and descriptions
- Extract all activities with codes, names, dimension mappings, and scores
- Generate validation reports showing parsing success/failures

**FR-2: JSON Template Format**
- Structured format with dimensions and activities sections
- Include metadata (version, source file, generation timestamp)
- Human-readable for debugging and verification
- Backward compatible with existing parsing interface

**FR-3: Runtime JSON Loading**
- Replace `OracleActivityParser` with `OracleJSONLoader`
- Maintain same public API for existing code
- Graceful fallback when JSON files are missing
- Fast loading with minimal runtime overhead

**FR-4: Development Workflow**
- Manual preprocessing command for prompt updates
- Clear documentation for adding new Oracle versions
- Validation scripts to verify JSON correctness

### Non-Functional Requirements

**NFR-1: Reliability**
- 100% parsing accuracy for well-formed Oracle prompts
- Zero runtime parsing failures
- Comprehensive error reporting during preprocessing

**NFR-2: Performance**
- JSON loading < 10ms (vs current parsing time)
- No runtime regex processing
- Minimal memory footprint

**NFR-3: Maintainability**
- Clear separation between parsing logic and runtime code
- Easy to debug preprocessing failures
- Simple workflow for updating Oracle prompts

## Technical Design

### 1. File Structure
```
scripts/
├── preprocess_oracle.py           # Main preprocessing script
└── oracle_template.json           # JSON schema template

assets/config/oracle/
├── oracle_prompt_2.1.md          # Source markdown (existing)
├── oracle_prompt_2.1.json        # Generated JSON (new)
├── oracle_prompt_2.0.md          # Source markdown (existing)
└── oracle_prompt_2.0.json        # Generated JSON (new)
```

### 2. JSON Template Structure
```json
{
  "version": "2.1",
  "source_file": "oracle_prompt_2.1.md",
  "generated_at": "2025-01-22T10:30:00Z",
  "dimensions": {
    "SF": {
      "code": "SF",
      "name": "SAÚDE FÍSICA", 
      "description": "Physical health and wellness"
    },
    "TG": {
      "code": "TG",
      "name": "TRABALHO GRATIFICANTE",
      "description": "Meaningful work and productivity"
    }
  },
  "activities": {
    "SF1": {
      "code": "SF1",
      "name": "Beber água",
      "dimension": "SF",
      "scores": {"R": 0, "T": 0, "SF": 1, "E": 0, "SM": 0}
    },
    "T8": {
      "code": "T8", 
      "name": "Pomodoro",
      "dimension": "TG",
      "scores": {"R": 0, "T": 3, "SF": 0, "E": 0, "SM": 0}
    }
  },
  "metadata": {
    "total_activities": 125,
    "total_dimensions": 5,
    "parsing_status": "success"
  }
}
```

### 3. Preprocessing Script Interface
```bash
# Basic usage
python3 scripts/preprocess_oracle.py assets/config/oracle/oracle_prompt_2.1.md

# Output validation
python3 scripts/preprocess_oracle.py assets/config/oracle/oracle_prompt_2.1.md --validate

# Process all Oracle files
python3 scripts/preprocess_oracle.py --all
```

### 4. Runtime API (Maintains Compatibility)
```dart
// Existing interface preserved
final result = await OracleJSONLoader.parseFromPersona();
print('Loaded ${result.totalCount} activities'); // Now actually works!

// Implementation changes from regex parsing to JSON loading
class OracleJSONLoader {
  static Future<OracleParseResult> parseFromPersona() async {
    final configManager = CharacterConfigManager();
    final oracleConfigPath = await configManager.getOracleConfigPath();
    
    if (oracleConfigPath == null) return OracleParseResult.empty();
    
    // Load preprocessed JSON instead of parsing markdown
    final jsonPath = oracleConfigPath.replaceAll('.md', '.json');
    return await _loadFromJSON(jsonPath);
  }
}
```

## Implementation Plan

### Phase 0: Clean Current Approach (30 minutes)
1. **Remove fragile regex parsing logic** from `OracleActivityParser`
2. **Simplify error-prone dimension mapping** (T→TG workarounds)
3. **Clean up debug logging** that clutters output
4. **Revert complex MCP command patterns** to basic matching
5. **Remove unused imports and cached variables**

### Phase 1: Preprocessing Script (2-3 hours)
1. Create Python script with robust markdown parsing
2. Implement multiple parsing strategies for reliability
3. Generate JSON template for Oracle 2.1
4. Add validation and error reporting

### Phase 2: Runtime Integration (1-2 hours)
1. Create `OracleJSONLoader` class to replace `OracleActivityParser`
2. Update `SystemMCPService` to use JSON loader
3. Clean integration points and remove legacy parsing code
4. Add error handling for missing JSON files

### Phase 3: Validation & Testing (1 hour)
1. Verify JSON loading works correctly
2. Test activity detection with real JSON data
3. Confirm MCP command hiding works
4. Generate JSON for all existing Oracle versions

### Phase 4: Documentation (30 minutes)
1. Document new preprocessing workflow
2. Add instructions for updating Oracle prompts
3. Create troubleshooting guide

## Success Criteria

**Immediate Success:**
- Oracle parsing shows `Successfully parsed Oracle: 5 dimensions, 125+ total activities`
- Activity detection works: `extract_activities` MCP calls process correctly
- MCP commands are hidden from user responses
- Zero runtime parsing warnings

**Long-term Success:**
- New Oracle prompt versions can be added in < 5 minutes
- Parsing reliability is 100% for well-formed prompts
- Runtime activity loading is consistently fast (<10ms)
- Development team can easily maintain and extend Oracle support

## Acceptance Criteria

1. **Cleanup Phase Complete**
   - Current failing regex parsing code removed
   - Debug logging reduced to essential messages
   - Complex MCP patterns simplified
   - Code base is clean and ready for new architecture

2. **Preprocessing Script Works**
   - Successfully parses Oracle 2.1 markdown
   - Generates valid JSON with all dimensions and activities
   - Reports clear errors for parsing failures

3. **Runtime Loading Works**
   - `OracleJSONLoader.parseFromPersona()` returns valid data
   - Activity memory service can detect and log activities
   - No runtime regex parsing or warnings

4. **End-to-End Activity Detection Works**
   - User says "bebi água" → AI calls `extract_activities`
   - MCP command is processed and hidden from response
   - Activity is logged to Isar database with correct metadata

5. **Development Workflow Documented**
   - Clear instructions for adding new Oracle versions
   - Preprocessing command documented and tested
   - Migration path from current implementation

## Effort Estimation

**Total: 4.5-6.5 hours**
- **Cleanup current approach: 30 minutes**
- Preprocessing script: 2-3 hours
- Runtime integration: 1-2 hours  
- Testing & validation: 1 hour
- Documentation: 30 minutes

## Dependencies

- Python 3.x for preprocessing script
- Existing `CharacterConfigManager` for Oracle path resolution
- Current `SystemMCPService` and `ActivityMemoryService` interfaces

## Risk Mitigation

**Risk: Current code cleanup complexity**
- Mitigation: Focus on removing broken code, not fixing it - preprocessing will replace it entirely

**Risk: Preprocessing script complexity**
- Mitigation: Start with simple regex patterns, add robustness incrementally

**Risk: JSON file management**  
- Mitigation: Keep JSON files in version control alongside markdown

**Risk: Backward compatibility**
- Mitigation: Maintain same public API, add fallback to markdown parsing if JSON missing

**Risk: Breaking existing functionality during cleanup**
- Mitigation: Phase 0 removes only failing code, core MCP functionality preserved

---

*This feature represents a strategic architectural improvement that will eliminate the current parsing failures and provide a robust foundation for Oracle activity memory functionality.*
