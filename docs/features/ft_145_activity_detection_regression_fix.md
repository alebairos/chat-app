# FT-145: Activity Detection Regression Fix

**Feature ID**: FT-145  
**Priority**: Critical  
**Category**: Bug Fix  
**Effort**: 2 hours  

## Problem Statement

Activity detection broke at 12:52 PM today (commit 5dae82c) after FT-140 MCP integration:

1. **Completion vs Todo**: Both completed and planned activities being registered (should only register completed)
2. **Character Encoding**: Portuguese characters corrupted ("Não" → "NÃo", "d'água" → "d'Ã¡gua")  
3. **Custom Phrases**: Generating user descriptions instead of exact catalog names ("vai fazer um pomodoro" vs "T8")

**Before**: "Beber água", "Ativar modo foco trabalho" correctly registered  
**After**: Broken detection with encoding issues and wrong activity types

## Root Cause

FT-140's new MCP prompt in `SystemMCPService._oracleDetectActivities()` lacks:
- Completion detection rules (past tense vs future tense)
- Catalog mapping enforcement (exact names vs custom descriptions)
- UTF-8 character preservation

## Solution

**Surgical fix**: Update the MCP detection prompt with missing rules while preserving FT-140 architecture.

## Functional Requirements

### FR-1: Multilingual Completion Detection Rules
- **MUST** detect only completed activities (past tense indicators in any language)
- **MUST** ignore planned/future activities across languages
- **MUST** recognize completion indicators in:
  - **Portuguese**: "fiz", "completei", "bebi", "caminhei", "terminei", "acabei", "realizei"
  - **English**: "did", "completed", "finished", "drank", "walked", "exercised", "meditated"
  - **Spanish**: "hice", "completé", "bebí", "caminé", "terminé", "realicé", "medité"
  - **Past tense patterns**: "-ed", "-ou", "-í", "-é" endings and irregular verbs

### FR-2: Catalog Mapping Enforcement  
- **MUST** return exact catalog activity names only
- **MUST** map detected activities to precise Oracle codes (SF1, TT5, etc.)
- **MUST NOT** generate custom user descriptions

### FR-3: Character Encoding Preservation
- **MUST** preserve UTF-8 Portuguese characters throughout detection pipeline
- **MUST** maintain "Não", "água", and other accented characters correctly

## Technical Implementation

### Single File Change: `lib/services/system_mcp_service.dart`

Update `_oracleDetectActivities()` method prompt from:
```dart
final prompt = '''
User message: "$userMessage"
Oracle activities (ALL 265): $compactOracle

Analyze the user message semantically and identify completed activities.
...
''';
```

To:
```dart
final prompt = '''
User message: "$userMessage"
Oracle activities: $compactOracle

MULTILINGUAL DETECTION RULES:
1. ONLY COMPLETED activities (past tense in ANY language)
2. Completion indicators:
   - Portuguese: "fiz", "completei", "bebi", "caminhei", "terminei", "acabei", "realizei"
   - English: "did", "completed", "finished", "drank", "walked", "exercised", "meditated"  
   - Spanish: "hice", "completé", "bebí", "caminé", "terminé", "realicé", "medité"
   - Past tense patterns: "-ed", "-ou", "-í", "-é" endings
3. IGNORE future/planning in ALL languages:
   - Portuguese: "vou fazer", "preciso", "quero", "planejo", "vai fazer"
   - English: "will do", "going to", "need to", "want to", "plan to"
   - Spanish: "voy a hacer", "necesito", "quiero", "planeo"
4. Return EXACT Oracle catalog names, not custom descriptions
5. Semantic understanding: detect meaning beyond keywords

Required JSON format:
{"activities": [{"code": "SF1", "confidence": "high", "catalog_name": "Beber água"}]}

Return empty array if NO COMPLETED activities detected.
''';
```

### Response Processing Update

Update `_parseDetectionResults()` to use `catalog_name` instead of custom `description`.

## Acceptance Criteria

### AC-1: Multilingual Completion Detection ✅
- ✅ "Bebi água" (PT) → Detects SF1 "Beber água"  
- ✅ "I drank water" (EN) → Detects SF1 "Beber água"
- ✅ "Bebí agua" (ES) → Detects SF1 "Beber água"
- ✅ "Completei um pomodoro" (PT) → Detects T8
- ✅ "I finished a pomodoro session" (EN) → Detects T8
- ❌ "Vou beber água" (PT) → No detection
- ❌ "I will drink water" (EN) → No detection  
- ❌ "Voy a beber agua" (ES) → No detection

### AC-2: Character Encoding ✅  
- ✅ "Não usar rede social" → Preserves "Não" correctly
- ✅ "bebeu água" → Preserves "água" correctly

### AC-3: Catalog Mapping ✅
- ✅ Pomodoro activity → Returns "T8" with exact catalog name
- ✅ Water activity → Returns "SF1: Beber água" (not custom description)

## Testing Strategy

### Test Cases
1. **Multilingual Completion Detection**: Test past tense vs future tense in PT/EN/ES
2. **Cross-Language Semantic Understanding**: Same activity expressed in different languages
3. **Character Encoding**: Test Portuguese characters preservation across languages
4. **Catalog Mapping**: Verify exact Oracle activity names returned regardless of input language

### Validation Commands
```bash
# Test the specific regression cases
flutter test test/activity_detection_regression_test.dart
```

## Implementation Notes

- **Minimal Change**: Only update the prompt and response parsing
- **Preserve FT-140**: Keep MCP architecture and token optimization  
- **UTF-8 Handling**: Ensure proper encoding in HTTP requests/responses
- **Backward Compatible**: No breaking changes to existing functionality

## Success Metrics

- ✅ Only completed activities registered (0% false positives for planned activities)
- ✅ Portuguese characters preserved (100% encoding accuracy)  
- ✅ Exact catalog names returned (0% custom descriptions)
- ✅ Regression test cases pass

## Dependencies

- Existing FT-140 MCP infrastructure
- Oracle 4.2 static cache system
- Claude API integration

---

**Estimated Time**: 2 hours  
**Risk Level**: Low (surgical prompt fix)  
**Impact**: Critical (restores core functionality)
