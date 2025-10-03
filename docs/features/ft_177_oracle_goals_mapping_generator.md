# FT-177: Oracle Goals Mapping Generator

**Feature ID**: FT-177  
**Priority**: Medium  
**Category**: Goal Management Infrastructure  
**Effort Estimate**: 2-3 hours  
**Depends On**: Oracle Framework 4.2, FT-174 (Goals Tab), FT-176 (Goals Modularization)

## Overview

Extend the Oracle preprocessing pipeline to generate specialized goal-activity mapping JSON files that optimize FT-175 (Goal-Aware Activity Detection) performance. This creates a dedicated, optimized data structure for goal-activity relationships extracted from the Oracle framework.

## Problem Statement

**Current Gap**: 
- FT-175 needs efficient goal-activity mapping for real-time detection
- Oracle JSON contains all necessary data but requires runtime parsing
- No specialized format for goal-aware features
- Performance overhead from parsing full Oracle JSON repeatedly

**User Impact**:
- Slower goal-activity detection in FT-175
- Higher memory usage parsing large Oracle JSON
- More complex goal-aware service implementation

## Solution Architecture

### Core Approach: Extend `preprocess_oracle.py`

**Input**: Existing `oracle_prompt_4.2_optimized.json`  
**Output**: Specialized `oracle_goals_mapping_4.2.json`  
**Trigger**: `python3 scripts/preprocess_oracle.py --goals-mapping <oracle_json>`

## Functional Requirements

### FR-1: Goals Mapping Generation

**FR-1.1**: Extract Goal-Activity Relationships
```json
{
  "goal_trilha_mapping": {
    "OCX1": {
      "objective_code": "OCX1",
      "objective_name": "Correr X Km", 
      "trilha": "CX1",
      "dimension": "SF",
      "related_activities": ["SF13", "SF1812", "SF1813"],
      "trilha_levels": ["CX1B", "CX1I", "CX1A"]
    }
  }
}
```

**FR-1.2**: Bidirectional Activity-Goal Mapping
```json
{
  "activity_goal_mapping": {
    "SF13": ["OCX1"],           // Cardio → Running goals
    "SF10": ["OPP1"],           // Nutrition → Weight loss
    "SF11": ["OPP1", "OGM1"],   // Nutrition → Multiple goals
    "SM1": ["ORA1", "ODE1"]     // Meditation → Anxiety + Spirituality
  }
}
```

**FR-1.3**: Goal Categories Summary
```json
{
  "goal_categories": {
    "SF": {
      "name": "Saúde Física",
      "goals": ["OPP1", "OGM1", "ODM1", "OCX1", "OMMA1", "OLV1"],
      "primary_activities": ["SF13", "SF10", "SF11", "SF12"]
    },
    "TG": {
      "name": "Trabalho Gratificante", 
      "goals": ["OAE1", "OSPM1", "OSPM3", "OLM1"],
      "primary_activities": ["T8", "T14", "T15"]
    }
  }
}
```

### FR-2: Command Line Interface

**FR-2.1**: Goals Mapping Flag
```bash
# Generate goals mapping from existing Oracle JSON
python3 scripts/preprocess_oracle.py --goals-mapping assets/config/oracle/oracle_prompt_4.2_optimized.json

# Output: assets/config/oracle/oracle_goals_mapping_4.2.json
```

**FR-2.2**: Batch Processing Support
```bash
# Generate for all Oracle versions
python3 scripts/preprocess_oracle.py --all --goals-mapping
```

**FR-2.3**: Validation Support
```bash
# Validate generated goals mapping
python3 scripts/preprocess_oracle.py --validate assets/config/oracle/oracle_goals_mapping_4.2.json
```

### FR-3: Data Quality & Validation

**FR-3.1**: Completeness Validation
- All objectives (O*) mapped to trilhas
- All trilha codes have corresponding activities
- No orphaned activity codes

**FR-3.2**: Consistency Checks
- Trilha-activity relationships are bidirectional
- Dimension mappings are consistent
- No circular references

**FR-3.3**: Performance Optimization
- Optimized JSON structure for fast lookups
- Pre-computed reverse mappings
- Minimal memory footprint

## Technical Requirements

### TR-1: Code Extension Strategy

**TR-1.1**: New Functions in `preprocess_oracle.py`
```python
def generate_goals_mapping(oracle_json_path: str, output_path: str = None) -> bool:
    """Generate goals mapping JSON from Oracle JSON"""
    
def extract_goal_trilha_relationships(oracle_data: Dict) -> Dict:
    """Extract goal-trilha-activity relationships"""
    
def build_activity_goal_mapping(goal_trilha_data: Dict) -> Dict:
    """Build reverse mapping from activities to goals"""
    
def validate_goals_mapping(goals_mapping: Dict) -> List[str]:
    """Validate goals mapping completeness and consistency"""
```

**TR-1.2**: Data Processing Pipeline
```python
# 1. Parse Oracle JSON
oracle_data = load_oracle_json(input_path)

# 2. Extract objectives (O* codes) 
objectives = extract_objectives(oracle_data['activities'])

# 3. Map trilhas to activities
trilha_activities = map_trilhas_to_activities(oracle_data['activities'])

# 4. Build bidirectional mappings
goal_mapping = build_goal_trilha_mapping(objectives, trilha_activities)
activity_mapping = build_activity_goal_mapping(goal_mapping)

# 5. Generate categories summary
categories = build_goal_categories(goal_mapping, oracle_data['dimensions'])

# 6. Validate and output
validate_and_save(goal_mapping, activity_mapping, categories, output_path)
```

### TR-2: Output Format Specification

**TR-2.1**: Goals Mapping JSON Schema
```json
{
  "version": "4.2",
  "source_file": "oracle_prompt_4.2_optimized.json", 
  "generated_at": "2025-01-03T...",
  "metadata": {
    "total_goals": 28,
    "total_mapped_activities": 156,
    "coverage_percentage": 89.2,
    "generation_status": "success"
  },
  "goal_trilha_mapping": { /* Goal → Trilha → Activities */ },
  "activity_goal_mapping": { /* Activity → Goals */ },
  "goal_categories": { /* Dimension → Goals */ },
  "trilha_hierarchy": { /* Trilha → Levels (Basic/Intermediate/Advanced) */ },
  "validation_report": {
    "warnings": [],
    "errors": []
  }
}
```

**TR-2.2**: File Naming Convention
- Input: `oracle_prompt_4.2_optimized.json`
- Output: `oracle_goals_mapping_4.2.json`
- Pattern: `oracle_goals_mapping_<version>.json`

### TR-3: Integration Points

**TR-3.1**: FT-175 Integration Ready
```dart
// Future FT-175 usage
class GoalContextManager {
  static Future<Map<String, List<String>>> getActivityGoalMapping() async {
    final mapping = await rootBundle.loadString('assets/config/oracle/oracle_goals_mapping_4.2.json');
    return parseActivityGoalMapping(mapping);
  }
}
```

**TR-3.2**: Version Synchronization
- Goals mapping version matches Oracle version
- Automatic regeneration when Oracle updates
- Backward compatibility warnings

## CLI Usage Examples

### Basic Generation
```bash
# Generate goals mapping
python3 scripts/preprocess_oracle.py --goals-mapping assets/config/oracle/oracle_prompt_4.2_optimized.json

✅ Generated goals mapping: assets/config/oracle/oracle_goals_mapping_4.2.json
📊 Mapped 28 goals to 156 activities across 8 dimensions
🎯 Coverage: 89.2% of Oracle activities mapped to goals
⚡ Optimized for FT-175 goal-aware detection
```

### Validation
```bash
# Validate generated mapping
python3 scripts/preprocess_oracle.py --validate assets/config/oracle/oracle_goals_mapping_4.2.json

✓ Version: 4.2
✓ Goals: 28 objectives mapped
✓ Activities: 156 activities linked
✓ Bidirectional: All mappings consistent
✓ Coverage: 89.2% (excellent)
✅ Goals mapping validation passed
```

### Batch Processing
```bash
# Generate for all Oracle versions
python3 scripts/preprocess_oracle.py --all --goals-mapping

🔄 Processing Oracle files for goals mapping...
✅ oracle_prompt_4.2.json → oracle_goals_mapping_4.2.json
✅ oracle_prompt_2.1.json → oracle_goals_mapping_2.1.json
🎉 Generated 2 goals mapping files successfully
```

## Success Metrics

### Generation Quality
- **Goal Coverage**: >85% of Oracle objectives mapped
- **Activity Coverage**: >80% of relevant activities linked
- **Validation**: Zero errors, minimal warnings
- **Performance**: <2s generation time

### File Optimization
- **Size Reduction**: 60-80% smaller than full Oracle JSON
- **Lookup Speed**: O(1) activity→goals mapping
- **Memory Usage**: <500KB loaded size

### Developer Experience
- **Integration**: Drop-in replacement for FT-175 needs
- **Maintenance**: Auto-sync with Oracle updates
- **Documentation**: Clear usage examples

## Implementation Notes

### Oracle Framework Patterns
- **Objective Codes**: `O*` pattern (OCX1, OPP1, OGM1, etc.)
- **Trilha Codes**: Referenced in `trilha` field of objectives
- **Activity Codes**: Linked via dimension and trilha patterns
- **Trilha Levels**: `*B` (Basic), `*I` (Intermediate), `*A` (Advanced)

### Mapping Logic
```python
# Goal → Activities mapping
OCX1 (Running) → trilha: CX1 → activities: [SF13, SF1812, SF1813]
OPP1 (Weight Loss) → trilha: ME1 → activities: [SF10, SF11, SF12]

# Reverse mapping for fast lookup
SF13 (Cardio) → goals: [OCX1]  # FT-175 can instantly find related goals
SF10 (Nutrition) → goals: [OPP1, OGM1]  # Multiple goals benefit
```

### Error Handling
- **Missing Trilhas**: Warn but continue processing
- **Orphaned Activities**: Log for manual review
- **Invalid References**: Skip with detailed error messages
- **Validation Failures**: Clear actionable feedback

## Future Enhancements

**Phase 2: Advanced Mappings**
- Goal similarity scoring
- Activity recommendation weights
- Progress calculation formulas

**Phase 3: ML Integration**
- Activity pattern learning
- Goal success prediction
- Personalized recommendations

---

*This infrastructure feature enables efficient goal-aware activity detection in FT-175 while maintaining clean separation between Oracle framework and goal management systems.*
