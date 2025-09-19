# FT-139: Oracle Preprocessing Completeness Fix

**Feature ID:** FT-139  
**Priority:** Critical  
**Category:** Bug Fix / Data Processing  
**Effort Estimate:** 4-6 hours  
**Status:** Specification  

## Problem Statement

The Oracle preprocessing script (`scripts/preprocess_oracle.py`) has a critical bug that causes it to miss 73.2% of available activities when parsing Oracle 4.2 markdown files. This severely impacts the chat app's coaching capabilities by limiting activity detection to only 71 out of 265 available activities.

### Current Impact
- **Activity Detection**: Only 26.8% of Oracle activities are available for detection
- **Coaching Quality**: Severely compromised due to missing intervention options
- **Missing Categories**: Financial habits (F1-F23), Screen time control (TT1-TT16), Procrastination management (PR1-PR13), and most BIBLIOTECA activities
- **User Experience**: Limited coaching effectiveness and reduced activity variety

## Root Cause Analysis

### Primary Issue: Header Level Mismatch
The preprocessing script searches for:
```python
r'### BIBLIOTECA DE HÁBITOS POR DIMENSÃO(.*?)(?=\n### |\n## |\Z)'
```

But Oracle 4.2 markdown uses:
```markdown
## BIBLIOTECA DE HÁBITOS POR DIMENSÃO  # (2 hashes, not 3)
```

This causes the script to completely skip the main activity library section.

### Secondary Issues
1. **Limited Pattern Recognition**: Script only captures trilha-referenced activities
2. **Missing Activity Types**: No patterns for objective codes (OPP1, OGM1, etc.) or trilha level codes (VG1B, CX1A, etc.)
3. **Incomplete Category Coverage**: Financial, screen time, and procrastination activities not detected

## Functional Requirements

### FR-139.1: Fix BIBLIOTECA Section Detection
- **Requirement**: Update regex pattern to correctly identify BIBLIOTECA section with 2-hash headers
- **Acceptance Criteria**: 
  - Script successfully finds and parses BIBLIOTECA section in Oracle 4.2
  - All activities from BIBLIOTECA section are extracted
  - No regression in trilha activity detection

### FR-139.2: Enhance Activity Pattern Recognition
- **Requirement**: Add patterns to capture all activity types present in Oracle markdown
- **Patterns Needed**:
  - Objective codes: `- **OPP1**: Description → Trilha`
  - Trilha level codes: `- **VG1B** (Nível 1): Description`
  - Financial activities in SegF1 section
  - Screen time activities in TempoTela sections
  - Procrastination activities in Procrastinação sections
- **Acceptance Criteria**:
  - All 265 activities from Oracle 4.2 are captured
  - Activities are correctly categorized by dimension
  - Proper score parsing for BIBLIOTECA activities

### FR-139.3: Comprehensive Validation
- **Requirement**: Add validation checks to ensure completeness
- **Validation Checks**:
  - Total activity count matches expected range (260-270 for Oracle 4.2)
  - All major categories present (R, SF, TG, E, SM, TT, PR, F)
  - No duplicate activity codes
  - All activities have valid dimension assignments
- **Acceptance Criteria**:
  - Script reports validation results
  - Warnings for missing expected categories
  - Errors for critical parsing failures

## Non-Functional Requirements

### NFR-139.1: Backward Compatibility
- **Requirement**: Maintain compatibility with existing Oracle versions
- **Acceptance Criteria**: Script works with Oracle 2.1, 3.0, and 4.2 without regression

### NFR-139.2: Performance
- **Requirement**: Processing time should not increase significantly
- **Acceptance Criteria**: Processing completes within 10 seconds for Oracle 4.2

### NFR-139.3: Error Handling
- **Requirement**: Robust error handling and informative error messages
- **Acceptance Criteria**: Clear error messages for parsing failures with line numbers and context

## Technical Implementation

### Implementation Plan

#### Phase 1: Core Bug Fix (2 hours)
1. **Update BIBLIOTECA Pattern**:
   ```python
   # Line 91 in preprocess_oracle.py
   # FROM:
   biblioteca_match = re.search(r'### BIBLIOTECA DE HÁBITOS POR DIMENSÃO(.*?)(?=\n### |\n## |\Z)', 
                              content, re.DOTALL | re.IGNORECASE)
   # TO:
   biblioteca_match = re.search(r'## BIBLIOTECA DE HÁBITOS POR DIMENSÃO(.*?)(?=\n### |\n## |\Z)', 
                              content, re.DOTALL | re.IGNORECASE)
   ```

2. **Test Basic Fix**: Verify BIBLIOTECA activities are now captured

#### Phase 2: Enhanced Pattern Recognition (2 hours)
1. **Add Objective Code Pattern**:
   ```python
   objective_pattern = r'-\s*\*\*([A-Z]+\d+)\*\*:\s*([^→]+)→\s*Trilha\s*([A-Z0-9]+)'
   ```

2. **Add Trilha Level Pattern**:
   ```python
   trilha_level_pattern = r'-\s*\*\*([A-Z0-9]+)\*\*\s*\([^)]+\):\s*([^-\n]+)'
   ```

3. **Add Financial Section Pattern**:
   ```python
   financial_pattern = r'SegF1.*?CATÁLOGO DE HÁBITOS PARA SEGURANÇA FINANCEIRA:(.*?)(?=\n### |\n## |\Z)'
   ```

#### Phase 3: Validation and Testing (2 hours)
1. **Add Validation Function**:
   ```python
   def validate_parsing_completeness(self, expected_count_range):
       # Validate total count, category coverage, dimension mapping
   ```

2. **Comprehensive Testing**:
   - Test with Oracle 4.2 (should get ~265 activities)
   - Test with Oracle 2.1 and 3.0 (regression testing)
   - Validate all major categories present

### File Changes Required

#### Primary Changes
- `scripts/preprocess_oracle.py`: Core preprocessing logic updates
- `assets/config/oracle/oracle_prompt_4.2.json`: Regenerated with complete data

#### Testing Files
- Create test cases for validation
- Update documentation with new patterns

## Dependencies

### Internal Dependencies
- Oracle 4.2 markdown file structure
- Existing preprocessing script architecture
- JSON schema compatibility

### External Dependencies
- Python regex library
- JSON processing capabilities

## Testing Strategy

### Unit Tests
- Test each pattern recognition function individually
- Validate regex patterns with sample text
- Test error handling scenarios

### Integration Tests
- Full Oracle 4.2 processing test
- Regression tests with older Oracle versions
- JSON schema validation

### Acceptance Tests
- Verify 265 activities captured from Oracle 4.2
- Confirm all major categories present
- Validate chat app can detect previously missing activities

## Risks and Mitigation

### Risk 1: Regex Pattern Conflicts
- **Risk**: New patterns might conflict with existing ones
- **Mitigation**: Comprehensive testing with all Oracle versions
- **Contingency**: Rollback capability with version control

### Risk 2: Performance Impact
- **Risk**: Additional pattern matching might slow processing
- **Mitigation**: Optimize regex patterns and test performance
- **Contingency**: Implement caching if needed

### Risk 3: Breaking Changes
- **Risk**: Changes might break existing functionality
- **Mitigation**: Extensive regression testing
- **Contingency**: Feature flag to enable/disable new patterns

## Success Metrics

### Primary Metrics
- **Activity Completeness**: 95%+ of Oracle 4.2 activities captured (target: 265 activities)
- **Category Coverage**: 100% of major categories present (R, SF, TG, E, SM, TT, PR, F)
- **Processing Success**: 100% successful processing without errors

### Secondary Metrics
- **Processing Time**: <10 seconds for Oracle 4.2
- **Regression Prevention**: 100% backward compatibility with older versions
- **Error Rate**: 0% critical parsing failures

## Rollout Plan

### Phase 1: Development and Testing (2-3 days)
1. Implement core bug fix
2. Add enhanced pattern recognition
3. Comprehensive testing

### Phase 2: Validation (1 day)
1. Regenerate Oracle 4.2 JSON
2. Validate activity count and categories
3. Test chat app integration

### Phase 3: Deployment (1 day)
1. Update production preprocessing script
2. Regenerate all Oracle JSON files
3. Monitor for issues

## Monitoring and Maintenance

### Monitoring
- Track preprocessing success rates
- Monitor activity detection completeness
- Alert on parsing failures

### Maintenance
- Regular validation of new Oracle versions
- Update patterns as Oracle format evolves
- Performance optimization as needed

## Related Features

### Dependencies
- FT-062: Oracle Preprocessing Architecture (foundation)
- FT-064: Claude Semantic Activity Detection (consumer)

### Follow-up Features
- Enhanced activity recommendation engine with full activity set
- Improved coaching quality metrics
- Advanced activity pattern analysis

---

**Created:** 2025-09-19  
**Last Updated:** 2025-09-19  
**Author:** Development Agent  
**Reviewers:** TBD  
**Stakeholders:** Product Team, Engineering Team
