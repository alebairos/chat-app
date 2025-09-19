# Feature Fix: Audio Formatting Architecture Correction

## Overview

Fix the audio formatting system to follow proper source-level instruction approach instead of hardcoded post-processing rules, aligning with FT-121 principles and ElevenLabs best practices.

## Feature Summary

**Feature ID:** FT-131  
**Priority:** High  
**Category:** Audio Assistant > TTS Quality  
**Estimated Effort:** 1 day  

### Feature Description (FDD Format)
> Remove hardcoded parsing rules and enhance Claude instructions for proper audio formatting

## Problem Statement

**Current Issues:**
- Hardcoded Brazilian time parsing rules added today violate YAGNI/KISS principles
- Complex regex-based post-processing (~100+ lines of parsing code)
- Missing punctuation rules causing lack of natural pauses in TTS
- Missing symbol normalization (+ sign, parentheses) causing mispronunciation
- Architecture violates project's source-level formatting approach

**User Impact:**
- "+" read incorrectly instead of "mais" or "e"
- Missing sentence punctuation creates no pauses between phrases
- Maintenance burden from complex parsing rules
- Inconsistent with ElevenLabs normalization best practices

## Requirements

### Functional Requirements

#### FR-131-01: Remove Hardcoded Parsing Rules
- **Objective:** Eliminate `_convertBrazilianTimeFormats()` and related parsing functions
- **Scope:** Remove ~100+ lines of regex-based time conversion code
- **Rationale:** Violates YAGNI principle, creates maintenance burden

#### FR-131-02: Enhanced Audio Formatting Instructions
- **Objective:** Update audio formatting config with comprehensive ElevenLabs-compliant instructions
- **Data Fields:** Enhanced `audio_formatting_config.json` content
- **Scope:** Include punctuation, symbol normalization, and sentence structure rules

#### FR-131-03: Symbol Normalization Instructions
- **Objective:** Instruct Claude to normalize symbols for TTS
- **Examples:** 
  - "+" → "mais" (Portuguese) / "plus" (English)
  - "&" → "e" / "and"
  - "%" → "por cento" / "percent"
  - "()" → natural pauses or removal

#### FR-131-04: Punctuation for Natural Pauses
- **Objective:** Instruct Claude to add proper sentence punctuation
- **Examples:** "2 pomodoros focados (T8)" → "2 pomodoros focados T8."
- **Scope:** End sentences with periods, use commas for breath pauses

### Non-Functional Requirements

#### NFR-131-01: Architecture Compliance
- **YAGNI:** Simple instruction-based approach, no premature optimization
- **KISS:** Clear, straightforward configuration over complex parsing
- **DRY:** Single source of formatting rules in config file

#### NFR-131-02: ElevenLabs Compatibility
- **Standard:** Follow ElevenLabs normalization best practices
- **Template:** Use their proven prompt template structure
- **Coverage:** Handle time, symbols, punctuation, abbreviations

## Technical Implementation

### 1. Remove Hardcoded Parsing Rules

**Files to Modify:**
- `lib/services/tts_preprocessing_service.dart`

**Changes:**
- Remove `_convertBrazilianTimeFormats()` function call
- Remove `_convertBrazilianTimeFormats()` function implementation
- Remove `_convertHourToWords()` helper function
- Remove `_convertMinuteToWords()` helper function
- Remove related test cases

### 2. Enhanced Audio Formatting Configuration

**File:** `assets/config/audio_formatting_config.json`

**New Content Structure:**
```json
{
  "audio_formatting_instructions": {
    "version": "3.0",
    "description": "ElevenLabs-compliant TTS formatting instructions",
    "content": "
## TECHNICAL: AUDIO OUTPUT FORMATTING

Convert your response into a format suitable for text-to-speech. Ensure that numbers, symbols, and abbreviations are expanded for clarity when read aloud.

**Time Format Standards:**
- Use '18:10' format (not '18h10')
- Use '14:30' format (not '14h30') 
- Use '6:00 AM' format (not '6am')
- Examples: 'às 18:10', 'at 2:30 PM', 'entre 14:00 e 15:30'

**Symbol Normalization:**
- '+' → 'mais' (Portuguese) / 'plus' (English)
- '&' → 'e' (Portuguese) / 'and' (English)  
- '%' → 'por cento' / 'percent'
- '()' → remove or use natural pauses
- '×' → 'vezes' / 'times'

**Punctuation for Natural Speech:**
- End all sentences with periods for natural pauses
- Use commas for breath pauses in lists
- Structure responses as complete, well-punctuated sentences
- Example: '2 pomodoros focados T8.' (not '2 pomodoros focados (T8)')

**Number and Currency:**
- 'R$ 1.500' → 'mil e quinhentos reais'
- '$1,500' → 'fifteen hundred dollars'
- '100%' → 'cem por cento' / 'one hundred percent'

**Abbreviations:**
- Expand common abbreviations: 'Dr.' → 'Doctor', 'Ave.' → 'Avenue'
- Keep natural flow while ensuring clarity

**Technical Note:** These instructions ensure optimal text-to-speech conversion following ElevenLabs best practices. Generate properly formatted text from the source rather than relying on post-processing.
"
  }
}
```

### 3. Testing Strategy

**Validation Approach:**
- Send test messages with problematic formats
- Verify Claude generates properly formatted responses
- Confirm TTS produces natural audio without post-processing
- No complex mocks needed - direct instruction testing

**Test Cases:**
```
Input: "Roda comigo um roteiro de plano rápido pra esse fim de tarde"
Expected: Claude generates with proper punctuation and symbol handling
```

## Dependencies

- Existing FT-121 audio formatting infrastructure
- Current `CharacterConfigManager` audio instruction loading
- ElevenLabs TTS service integration

## Risks and Mitigation

### Technical Risks
- **Risk:** Instructions might be too verbose for system prompts
  - **Mitigation:** Use concise, focused rules based on ElevenLabs template
- **Risk:** Claude might not consistently follow formatting instructions  
  - **Mitigation:** Iterate on instruction clarity, test with real scenarios

### User Experience Risks
- **Risk:** Removing parsing might temporarily break some formatting
  - **Mitigation:** Enhanced instructions should provide better coverage
- **Risk:** Instructions might affect persona personality
  - **Mitigation:** Focus on technical formatting, preserve communication style

## Success Metrics

### Primary Success Criteria
- ✅ Elimination of hardcoded parsing rules (~100+ lines removed)
- ✅ Natural punctuation in Claude responses (periods, commas)
- ✅ Proper symbol normalization ("+" → "mais", "%" → "por cento")
- ✅ Maintained time format quality ("18h10" → "18:10")
- ✅ Architecture compliance with YAGNI/KISS principles

### Quality Metrics
- **Code Reduction:** Remove ~100+ lines of parsing code
- **Instruction Effectiveness:** Claude follows formatting rules consistently
- **TTS Quality:** Natural pauses and pronunciation without post-processing
- **Maintainability:** Single config file for all formatting rules

## Implementation Steps

1. **Update audio formatting config** with ElevenLabs-compliant instructions
2. **Remove hardcoded parsing functions** from TTS preprocessing service
3. **Update related tests** to focus on instruction-following rather than parsing
4. **Test with real messages** to verify Claude generates proper formats
5. **Iterate on instructions** based on results

## Conclusion

This fix aligns the audio formatting system with project principles (YAGNI, KISS, DRY) and ElevenLabs best practices by moving from complex post-processing to simple, effective source-level instructions. The approach is more maintainable, testable, and architecturally sound.
