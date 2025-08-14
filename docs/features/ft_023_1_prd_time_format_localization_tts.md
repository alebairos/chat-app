# FT-023: Time Format Localization for TTS

**Feature Type**: Technical Task  
**Priority**: High  
**Status**: Planning  
**Estimated Effort**: 2-3 hours  

## Problem Statement

The TTS system is incorrectly reading time formats in English when the content is primarily Portuguese. For example:
- "10:30pm" is read as "ten thirty pee em" (English) instead of "dez e trinta da noite" (Portuguese)
- This creates a jarring user experience where Portuguese content contains English-pronounced time references

### Root Cause Analysis

1. **Language Detection Issue**: The current language detection service is being influenced by English patterns in time formats (e.g., "pm", "am")
2. **Time Format Processing**: The TTS preprocessing doesn't convert time formats to language-appropriate representations
3. **Mixed Content Challenge**: Messages containing primarily Portuguese text with English time formats confuse the language detection algorithm

### Current Behavior (from logs)
```
Language Detection - Detected language: en_US
Language Detection - Scores: {pt_BR: 0.19069767441860463, en_US: 0.8093023255813954}
```

## Solution Overview

Implement a **Time Format Localization System** that:

1. **Detects time patterns** in text before language detection
2. **Converts time formats** to localized representations based on context
3. **Improves language detection** by considering localized time patterns
4. **Maintains consistency** across different time format variations

## Technical Requirements

### 1. Time Pattern Detection
- Detect common time formats: `HH:MMam/pm`, `H:MMam/pm`, `HH:MM`, etc.
- Support various separators: `:`, `.`, `h`
- Handle both 12-hour and 24-hour formats

### 2. Time Localization Rules

#### Portuguese (pt_BR)
- `10:30pm` → `22:30` or `dez e trinta da noite`
- `10:40pm` → `22:40` or `dez e quarenta da noite`  
- `10:50pm` → `22:50` or `dez e cinquenta da noite`
- `11:00pm` → `23:00` or `onze da noite`

#### English (en_US)
- Keep original format: `10:30pm`, `10:40pm`, etc.

### 3. Language Detection Enhancement
- **Pre-process text** to convert time formats before language analysis
- **Boost Portuguese scores** when Portuguese time patterns are detected
- **Contextual analysis** to determine if surrounding text suggests Portuguese

### 4. Integration Points
- `TTSPreprocessingService`: Add time format conversion
- `LanguageDetectionService`: Enhance detection logic
- `TTS Service`: Apply preprocessing before language detection

## Implementation Plan

### Phase 1: Time Pattern Detection
1. Create `TimeFormatDetector` utility class
2. Implement regex patterns for various time formats
3. Add unit tests for pattern detection

### Phase 2: Time Localization
1. Create `TimeLocalizer` service
2. Implement Portuguese time conversion logic
3. Add configuration for different localization strategies

### Phase 3: Language Detection Enhancement
1. Update `LanguageDetectionService` to pre-process time formats
2. Add Portuguese time pattern indicators
3. Adjust scoring algorithm for mixed content

### Phase 4: TTS Integration
1. Integrate time localization into `TTSPreprocessingService`
2. Update TTS pipeline to apply time conversion
3. Add comprehensive testing

## Success Criteria

### Functional Requirements
- ✅ Time formats in Portuguese content are read in Portuguese
- ✅ Language detection correctly identifies Portuguese when time formats are present
- ✅ Various time format patterns are supported (12h/24h, different separators)
- ✅ English content with time formats remains unchanged

### Technical Requirements
- ✅ Processing time impact < 50ms per message
- ✅ Backward compatibility with existing TTS functionality
- ✅ Comprehensive test coverage (>90%)
- ✅ Configurable localization strategies

### User Experience
- ✅ Seamless audio experience without language switching mid-sentence
- ✅ Natural-sounding time pronunciation in Portuguese
- ✅ Consistent behavior across different time format variations

## Testing Strategy

### Unit Tests
- Time pattern detection accuracy
- Time conversion correctness
- Language detection improvements
- Edge cases (invalid times, mixed formats)

### Integration Tests
- End-to-end TTS processing with time formats
- Language detection with various content types
- Performance impact measurement

### User Acceptance Tests
- Audio quality verification
- Natural pronunciation validation
- Cross-language consistency

## Configuration Options

### Time Localization Strategy
```json
{
  "timeLocalization": {
    "strategy": "numeric", // "numeric" | "verbal" | "hybrid"
    "use24HourFormat": true,
    "preserveOriginalOnDetectionFailure": true
  }
}
```

### Language Detection Weights
```json
{
  "languageDetection": {
    "timePatternBoost": {
      "pt_BR": 2.0,
      "en_US": 1.0
    }
  }
}
```

## Risk Assessment

### Technical Risks
- **Performance Impact**: Time processing could slow down TTS pipeline
  - *Mitigation*: Optimize regex patterns, cache results
- **False Positives**: Incorrect time pattern detection
  - *Mitigation*: Comprehensive testing, fallback mechanisms

### User Experience Risks
- **Inconsistent Behavior**: Different time formats handled differently
  - *Mitigation*: Standardized conversion rules, extensive testing
- **Language Detection Regression**: Changes might affect other content types
  - *Mitigation*: Thorough regression testing, gradual rollout

## Future Enhancements

### Phase 2 Features
- Support for date formats (DD/MM/YYYY, etc.)
- Relative time expressions ("em 30 minutos", "daqui a 1 hora")
- Regional time format preferences

### Internationalization
- Support for additional languages (Spanish, French, etc.)
- Locale-specific time format conventions
- Cultural time expression patterns

## Dependencies

### Internal
- `TTSPreprocessingService` (existing)
- `LanguageDetectionService` (existing)
- `Logger` utility (existing)

### External
- No new external dependencies required
- Uses existing Dart regex capabilities

## Acceptance Criteria

1. **Time Format Detection**
   - [ ] Detects `HH:MMam/pm` patterns accurately
   - [ ] Handles various separators and formats
   - [ ] Identifies invalid time patterns

2. **Portuguese Localization**
   - [ ] Converts 12-hour to 24-hour format
   - [ ] Generates natural Portuguese time expressions
   - [ ] Maintains context appropriateness

3. **Language Detection**
   - [ ] Portuguese content with time formats detected as Portuguese
   - [ ] English content remains detected as English
   - [ ] Mixed content handled appropriately

4. **TTS Integration**
   - [ ] Seamless integration with existing TTS pipeline
   - [ ] No performance degradation
   - [ ] Backward compatibility maintained

5. **Quality Assurance**
   - [ ] Comprehensive test coverage
   - [ ] Audio quality validation
   - [ ] Edge case handling

---

**Next Steps**: Proceed with Phase 1 implementation - Time Pattern Detection utility class.
