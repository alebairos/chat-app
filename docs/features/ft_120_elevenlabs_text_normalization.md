# FT-120: ElevenLabs Text Normalization Integration

**Feature ID**: FT-120  
**Priority**: Medium  
**Category**: Audio Assistant > TTS Enhancement  
**Effort Estimate**: 1 week  
**Dependencies**: Existing ElevenLabsProvider (lib/features/audio_assistant/services/eleven_labs_provider.dart)  
**Status**: Specification  

## Overview

Integrate ElevenLabs' `apply_text_normalization` parameter to improve conversational pronunciation of numbers, dates, time, acronyms, and symbols in TTS audio generation. This minimal implementation focuses on enabling the API parameter with configurable settings per persona.

## User Story

As a user conversing with AI personas, I want numbers, dates, and times to be pronounced naturally (e.g., "123" as "one hundred twenty-three", "14:30" as "two thirty PM") rather than as individual digits, so that audio responses sound more conversational and professional.

## Problem Statement

**Current State:**
- ElevenLabs API calls do not include `apply_text_normalization` parameter
- Numbers, dates, and times are pronounced as literal digits/characters
- No configuration option for text normalization behavior

**User Impact:**
- Audio responses sound robotic when reading structured content
- Poor user experience with timestamps, dates, and numerical data
- Inconsistent audio quality compared to ElevenLabs web interface

## Solution: Minimal Text Normalization Integration

### Core Implementation
- Add `apply_text_normalization` parameter to ElevenLabs API requests
- Start with `"auto"` mode (recommended by ElevenLabs)
- Make normalization configurable per persona
- Maintain backward compatibility with existing voice settings

## Functional Requirements

### Text Normalization API Integration
- **FR-120-01**: Add `apply_text_normalization` parameter to ElevenLabs API requests
- **FR-120-02**: Support all three normalization modes: `"on"`, `"off"`, `"auto"`
- **FR-120-03**: Default to `"auto"` mode for optimal balance of quality and performance
- **FR-120-04**: Handle API responses when normalization is not supported by model

### Configuration Management
- **FR-120-05**: Add text normalization setting to voice configuration structure
- **FR-120-06**: Enable per-persona normalization preferences
- **FR-120-07**: Provide fallback to `"off"` for Flash v2.5 and Turbo v2.5 models
- **FR-120-08**: Maintain existing voice settings compatibility

### Error Handling
- **FR-120-09**: Gracefully handle models that don't support normalization
- **FR-120-10**: Log normalization parameter usage for debugging
- **FR-120-11**: Fallback to previous behavior if API errors occur

## Non-Functional Requirements

### Performance
- **NFR-120-01**: Accept additional latency from text normalization processing
- **NFR-120-02**: Monitor and log performance impact
- **NFR-120-03**: No impact on existing TTS generation workflow

### Compatibility
- **NFR-120-04**: Maintain compatibility with all existing voice configurations
- **NFR-120-05**: Support all current ElevenLabs models
- **NFR-120-06**: Preserve existing error handling behavior

## Technical Implementation

### 1. ElevenLabsProvider Enhancement

```dart
// lib/features/audio_assistant/services/eleven_labs_provider.dart

class ElevenLabsProvider implements TTSProvider {
  // ... existing code ...

  @override
  Future<bool> generateSpeech(String text, String outputPath) async {
    // ... existing initialization code ...

    final requestBody = {
      'text': processedText,
      'model_id': modelId,
      'voice_settings': voiceSettings,
      // NEW: Add text normalization parameter
      'apply_text_normalization': _getTextNormalizationMode(),
    };

    // ... rest of existing implementation ...
  }

  /// Get text normalization mode based on configuration and model compatibility
  String _getTextNormalizationMode() {
    final configuredMode = _configuration['apply_text_normalization'] ?? 'auto';
    final modelId = _configuration['modelId'] ?? '';
    
    // Flash v2.5 and Turbo v2.5 only support 'off' or 'auto'
    if (modelId.contains('flash_v2_5') || modelId.contains('turbo_v2_5')) {
      if (configuredMode == 'on') {
        _logger.debug('Text normalization: Fallback to "auto" for model $modelId');
        return 'auto';
      }
    }
    
    return configuredMode;
  }
}
```

### 2. Configuration Structure Enhancement

```dart
// Default configuration update
ElevenLabsProvider() {
  _configuration = {
    'voiceId': 'pNInz6obpgDQGcFmaJgB',
    'modelId': 'eleven_monolingual_v1',
    'stability': 0.5,
    'similarityBoost': 0.75,
    'style': 0.0,
    'speakerBoost': true,
    'useAuthFromEnv': true,
    // NEW: Text normalization setting
    'apply_text_normalization': 'auto', // Default to 'auto' mode
  };
}
```

### 3. Persona Configuration Integration

```dart
// assets/config/personas_config.json
{
  "personas": [
    {
      "id": "ari_life_coach",
      "voice_config": {
        "provider": "elevenlabs",
        "voiceId": "pNInz6obpgDQGcFmaJgB",
        "modelId": "eleven_monolingual_v1",
        "stability": 0.75,
        "similarityBoost": 0.85,
        "style": 0.15,
        "speakerBoost": true,
        "apply_text_normalization": "auto"  // NEW: Per-persona setting
      }
    }
  ]
}
```

## Implementation Strategy

### Phase 1: Core Integration (Days 1-3)
1. **API Parameter Addition**
   - Add `apply_text_normalization` to ElevenLabs API requests
   - Implement model compatibility checking
   - Add configuration parameter to default settings

2. **Configuration Enhancement**
   - Update persona configuration structure
   - Add validation for normalization modes
   - Implement fallback logic for unsupported models

### Phase 2: Testing & Validation (Days 4-5)
1. **Functionality Testing**
   - Test all three normalization modes
   - Verify model compatibility handling
   - Validate persona-specific settings

2. **Quality Assessment**
   - Compare audio quality with/without normalization
   - Test with various content types (numbers, dates, times)
   - Monitor performance impact

## Testing Strategy

### Unit Tests
```dart
group('Text Normalization', () {
  test('should include apply_text_normalization in API request', () {
    // Test that API request includes normalization parameter
  });
  
  test('should fallback to auto for flash/turbo models when set to on', () {
    // Test model compatibility logic
  });
  
  test('should use configured normalization mode', () {
    // Test configuration reading and application
  });
});
```

### Integration Tests
```dart
group('ElevenLabs Text Normalization Integration', () {
  testWidgets('should generate audio with text normalization', (tester) async {
    // Test complete workflow with normalization enabled
    final provider = ElevenLabsProvider();
    await provider.updateConfig({'apply_text_normalization': 'auto'});
    
    final result = await provider.generateSpeech(
      'Meeting at 2:30 PM on 2024-12-15',
      'test_output.mp3'
    );
    
    expect(result, isTrue);
  });
});
```

## Success Metrics

### Primary Success Criteria
- ✅ `apply_text_normalization` parameter included in all ElevenLabs API requests
- ✅ All three normalization modes (`on`, `off`, `auto`) functional
- ✅ Per-persona configuration working correctly
- ✅ Model compatibility handling implemented
- ✅ No breaking changes to existing functionality

### Quality Metrics
- **API Integration**: 100% of requests include normalization parameter
- **Configuration**: All personas support normalization settings
- **Compatibility**: Proper handling of model limitations
- **Performance**: Acceptable latency increase (monitored but not blocked)

## Risks & Mitigations

### Technical Risks
- **Risk**: Increased latency from text normalization processing
  - **Mitigation**: Use `"auto"` mode by default, monitor performance, allow per-persona tuning
- **Risk**: Model compatibility issues
  - **Mitigation**: Implement fallback logic for unsupported models
- **Risk**: API changes or deprecation
  - **Mitigation**: Use stable API endpoints, implement graceful degradation

### Implementation Risks
- **Risk**: Breaking existing voice configurations
  - **Mitigation**: Maintain backward compatibility, default to safe settings
- **Risk**: Inconsistent behavior across personas
  - **Mitigation**: Clear configuration documentation, consistent defaults

## Future Enhancements

### Immediate Follow-ups
- Monitor performance impact and optimize settings
- Gather user feedback on audio quality improvements
- Fine-tune normalization settings per persona based on usage

### Long-term Possibilities
- Advanced normalization rules for specific content types
- Dynamic normalization based on message content analysis
- Integration with custom text preprocessing (building on FT-077)

## Conclusion

This minimal implementation focuses on enabling ElevenLabs' built-in text normalization capabilities with proper configuration management. By starting with the `"auto"` mode and making it configurable per persona, we can immediately improve audio quality for numbers, dates, and times while maintaining system stability and performance.

The implementation leverages ElevenLabs' existing AI-powered normalization rather than building custom preprocessing, ensuring optimal results with minimal development effort and maintenance overhead.
