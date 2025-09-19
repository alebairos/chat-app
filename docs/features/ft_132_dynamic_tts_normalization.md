# Feature Specification: Enhanced Language-Aware TTS Optimization

## Overview

Implement comprehensive language-aware TTS optimization combining ElevenLabs API language parameter with dynamic normalization instructions, optimizing audio output quality while maintaining cost efficiency.

## Feature Summary

**Feature ID:** FT-132  
**Priority:** Medium  
**Category:** Audio Assistant > TTS Quality  
**Estimated Effort:** 0.5 days  

### Feature Description (FDD Format)
> Enable comprehensive language-aware TTS optimization through ElevenLabs API language parameter and dynamic normalization rules

## Problem Statement

**Current Issues:**
- ElevenLabs API not receiving `language_code` parameter for optimal TTS processing
- Portuguese time formats ("20:30") read incorrectly as "vinte três trinta" instead of "vinte e trinta"
- Fixed formatting rules limit multilingual persona support
- Suboptimal audio quality due to missing language context in API calls

**User Impact:**
- Portuguese users get incorrect time pronunciation ("vinte três trinta" vs "vinte e trinta")
- ElevenLabs cannot apply language-specific optimizations without language_code
- Inconsistent audio quality across different language contexts
- Missing benefits of ElevenLabs' built-in language normalization

## Solution Approach

### Two-Layer Language Optimization

Implement both API-level and prompt-level language optimization:

**Layer 1: ElevenLabs API Integration (Primary)**
- Add `language_code` parameter to ElevenLabs API calls
- Leverage ElevenLabs' built-in language-specific TTS optimization
- Zero token cost, immediate pronunciation improvements

**Layer 2: Dynamic Prompt Normalization (Secondary)**
- Language-aware formatting instructions for edge cases
- Hybrid approach: explicit rules for PT/EN + ElevenLabs fallback
- Minimal token increase for complex scenarios

## Functional Requirements

### FR-1: ElevenLabs Language Parameter Integration
- **Requirement:** Add `language_code` parameter to ElevenLabs API calls
- **Implementation:** Map detected language (`pt_BR` → `pt`, `en_US` → `en`) 
- **Success Criteria:** All TTS requests include correct language_code

### FR-2: Language Detection Enhancement
- **Requirement:** Reliable language detection for API parameter mapping
- **Implementation:** Use existing language detection in TTS service
- **Success Criteria:** 95% accuracy for PT/EN detection

### FR-3: Portuguese TTS Optimization
- **Requirement:** Optimal Portuguese pronunciation through API + formatting
- **Primary:** ElevenLabs `language_code: "pt"` for built-in optimization
- **Secondary:** Brazilian time format instructions ("20h30") if needed
- **Success Criteria:** "20h30" reads as "vinte e trinta" (not "vinte três trinta")

### FR-4: English TTS Optimization  
- **Requirement:** Natural English pronunciation through API + formatting
- **Primary:** ElevenLabs `language_code: "en"` for built-in optimization
- **Secondary:** Standard format instructions if needed
- **Success Criteria:** Natural English time pronunciation

### FR-5: Multilingual Model Compatibility
- **Requirement:** Ensure language_code works with eleven_multilingual_v1
- **Implementation:** Validate compatibility and fallback handling
- **Success Criteria:** No API errors, graceful degradation if unsupported

## Non-Functional Requirements

### NFR-1: Zero Token Cost (Primary Solution)
- **Requirement:** ElevenLabs API integration adds no token cost
- **Implementation:** Language parameter is API-level, not prompt-level
- **Measurement:** No increase in system prompt tokens

### NFR-2: Minimal Token Impact (Secondary Solution)
- **Requirement:** If prompt changes needed, limit increase to ≤30%
- **Current Baseline:** ~200 tokens  
- **Target:** ≤260 tokens (only if API solution insufficient)
- **Measurement:** Token count in system prompt

### NFR-3: Response Reliability
- **Requirement:** 95% correct pronunciation improvement
- **Measurement:** Manual testing across language scenarios
- **Fallback:** Graceful degradation to current behavior

### NFR-4: Performance Impact
- **Requirement:** No measurable increase in response latency
- **Implementation:** Language parameter adds minimal API overhead
- **Measurement:** Response time comparison before/after implementation

## Technical Implementation

### Phase 1: ElevenLabs API Integration (Primary)

#### Language Code Mapping
```dart
String _getLanguageCode(String detectedLanguage) {
  switch (detectedLanguage) {
    case 'pt_BR':
    case 'pt':
      return 'pt';
    case 'en_US':
    case 'en':
      return 'en';
    default:
      return 'en'; // Safe fallback
  }
}
```

#### API Request Enhancement
```dart
final requestBody = {
  'text': processedText,
  'model_id': modelId,
  'voice_settings': voiceSettings,
  'apply_text_normalization': _getTextNormalizationMode(),
  'language_code': _getLanguageCode(targetLanguage), // NEW
};
```

### Phase 2: Prompt Enhancement (If Needed)

#### Configuration Structure (Optional)
```json
{
  "enhanced_tts_optimization": {
    "api_integration": {
      "language_code_enabled": true,
      "fallback_language": "en"
    },
    "prompt_normalization": {
      "enabled": false,
      "rules": {
        "portuguese": {"time_format": "20h30"},
        "english": {"time_format": "8:30 PM"}
      }
    }
  }
}
```

## Success Metrics

### Primary Success Criteria
- ✅ **Portuguese TTS Quality:** Correct pronunciation through language_code parameter
- ✅ **English TTS Quality:** Natural pronunciation through language_code parameter  
- ✅ **Zero Token Cost:** API-level solution with no prompt changes
- ✅ **Language Parameter Integration:** All TTS requests include correct language_code

### Quality Metrics
- **Audio Quality Score:** Subjective evaluation (1-5 scale) before/after
- **API Integration Success:** % of requests with correct language_code
- **Cross-Language Consistency:** Uniform quality across PT/EN
- **Error Rate:** API compatibility issues with language parameter

## Testing Strategy

### Test Cases
1. **Portuguese Language Code Integration**
   - Input: Portuguese text with times ("20:30")
   - API Call: Includes `language_code: "pt"`
   - Validation: Improved pronunciation vs. no language_code

2. **English Language Code Integration**
   - Input: English text with times ("8:30 PM")
   - API Call: Includes `language_code: "en"`
   - Validation: Natural English pronunciation

3. **Language Detection Accuracy**
   - Input: Mixed Portuguese/English content
   - Expected: Correct language_code per detected language
   - Validation: API logs show correct language parameters

4. **API Compatibility Testing**
   - Input: Various text formats with language_code
   - Expected: No API errors with eleven_multilingual_v1
   - Validation: Successful API responses, graceful fallback

### Performance Testing
- **API Response Time:** Latency impact of language_code parameter
- **Error Rate Monitoring:** API compatibility issues
- **Token Count Verification:** Confirm zero token increase (Phase 1)

## Dependencies

### Internal Dependencies
- Existing language detection in TTS service
- ElevenLabs provider implementation
- Audio formatting configuration system (FT-131)

### External Dependencies
- ElevenLabs API language_code parameter support
- eleven_multilingual_v1 model compatibility
- ElevenLabs Turbo v2.5 model (optimal support)

## Risks and Mitigations

### Risk 1: API Compatibility Issues
- **Impact:** ElevenLabs API errors with language_code parameter
- **Probability:** Low (documented feature)
- **Mitigation:** Graceful fallback, error handling, model compatibility check

### Risk 2: Language Detection Accuracy
- **Impact:** Wrong language_code sent to API
- **Probability:** Low (existing system works well)
- **Mitigation:** Conservative fallback to English, logging for debugging

### Risk 3: Model Limitations
- **Impact:** language_code not supported by current model
- **Probability:** Medium (feature may be model-specific)
- **Mitigation:** Feature flag, fallback to current behavior, model upgrade path

## Implementation Plan

### Phase 1: ElevenLabs API Integration (2 hours)
- Add language_code parameter to ElevenLabsProvider
- Implement language code mapping function
- Add error handling and fallback logic

### Phase 2: Testing & Validation (2 hours)
- Test Portuguese pronunciation improvements
- Validate API compatibility with current model
- Monitor for API errors and performance impact

### Phase 3: Optional Prompt Enhancement (2 hours)
- Evaluate if API solution is sufficient
- Implement prompt-level normalization if needed
- A/B test API vs. prompt vs. combined approaches

### Phase 4: Documentation & Monitoring (1 hour)
- Update implementation summary
- Add monitoring and debugging guides
- Document fallback procedures

**Total Effort:** 0.5 days (7 hours)

## Future Enhancements

### Potential Extensions
- **Model Optimization:** Upgrade to ElevenLabs Turbo v2.5 for better language_code support
- **Additional Languages:** Spanish, French, Italian language_code support
- **Dynamic Model Selection:** Choose optimal model based on language
- **User Language Preferences:** Manual language override in persona settings

### Scalability Considerations
- API-first approach reduces maintenance overhead
- Language code mapping easily extensible
- Performance monitoring for API parameter impact
- Graceful degradation ensures reliability
