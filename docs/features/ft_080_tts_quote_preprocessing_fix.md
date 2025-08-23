# FT-080: TTS Quote Preprocessing Fix

**Feature ID**: FT-080  
**Priority**: Low  
**Category**: Bug Fix / TTS Enhancement  
**Effort Estimate**: 30 minutes  
**Dependencies**: None  
**Status**: Specification  

## Overview

Fix TTS preprocessing that incorrectly handles quotes in AI responses, causing double quotes and escape characters to appear in speech generation. This is a minor cosmetic issue that affects speech quality but doesn't impact core functionality.

## Problem Description

### Current Behavior
```
AI Response: "Exatamente! Como planejar seu fim de semana para manter esse momentum?"
TTS Input: "\"Exatamente! Como planejar seu fim de semana para manter esse momentum? \""
```

### Issue Details
- **Double quotes**: AI naturally uses quotes for emphasis, but TTS adds escape characters
- **Extra formatting**: TTS preprocessing adds unnecessary quote wrapping
- **Speech quality**: Escape characters may be pronounced or cause audio artifacts

## Root Cause

The TTS preprocessing pipeline is **over-processing quotes** when preparing text for speech generation:

1. **AI generates natural response** with quotes
2. **TTS preprocessing** adds escape characters (`\"`)  
3. **Additional quote wrapping** creates nested quotes
4. **Result**: Malformed text sent to ElevenLabs API

## Functional Requirements

### FR-080-01: Clean Quote Handling
- **Remove unnecessary quote escaping** in TTS preprocessing
- **Preserve natural AI quotes** without adding extra formatting
- **Handle nested quotes** gracefully

### FR-080-02: TTS Text Normalization
- **Strip leading/trailing quotes** if they wrap entire response
- **Normalize internal quotes** to single quotes or remove entirely
- **Maintain text readability** for speech synthesis

### FR-080-03: Backward Compatibility
- **Preserve existing TTS functionality** for non-quote text
- **Maintain language detection** and preprocessing features
- **No impact on audio quality** for normal responses

## Technical Implementation

### Current TTS Preprocessing Location
```dart
// File: lib/features/audio_assistant/services/tts_service.dart
// Method: TTS preprocessing pipeline
```

### Proposed Fix
```dart
String _cleanQuotesForTTS(String text) {
  // Remove wrapping quotes if they encompass entire response
  String cleaned = text.trim();
  
  // Handle wrapped quotes: "entire response"
  if (cleaned.startsWith('"') && cleaned.endsWith('"') && 
      cleaned.indexOf('"', 1) == cleaned.length - 1) {
    cleaned = cleaned.substring(1, cleaned.length - 1);
  }
  
  // Remove escape characters for TTS
  cleaned = cleaned.replaceAll('\\"', '"');
  
  // Normalize quotes for better speech synthesis
  cleaned = cleaned.replaceAll('"', '');  // Remove internal quotes entirely
  // OR: cleaned = cleaned.replaceAll('"', "'");  // Convert to single quotes
  
  return cleaned.trim();
}
```

### Integration Point
```dart
// In TTS preprocessing pipeline, add quote cleaning step:
String preprocessedText = originalText;
preprocessedText = _cleanQuotesForTTS(preprocessedText);
// Continue with existing preprocessing...
```

## Expected Results

### Before Fix
```
AI: "Exatamente! Como planejar seu fim de semana para manter esse momentum?"
TTS: "\"Exatamente! Como planejar seu fim de semana para manter esse momentum? \""
Speech: Potentially includes escape characters or awkward pauses
```

### After Fix
```
AI: "Exatamente! Como planejar seu fim de semana para manter esse momentum?"
TTS: "Exatamente! Como planejar seu fim de semana para manter esse momentum?"
Speech: Natural, clean pronunciation
```

## Testing Requirements

### Test Cases
1. **Wrapped quotes**: `"Hello world"` → `Hello world`
2. **Internal quotes**: `He said "hello" to me` → `He said hello to me`
3. **Mixed quotes**: `"She replied 'yes' confidently"` → `She replied yes confidently`
4. **No quotes**: `Regular text` → `Regular text` (unchanged)
5. **Empty quotes**: `""` → `` (empty string)

### Validation
- **Audio quality**: Ensure no pronunciation artifacts
- **Language support**: Test with Portuguese and English
- **Edge cases**: Handle malformed or nested quotes gracefully

## Non-Functional Requirements

### Performance
- **Minimal overhead**: Quote cleaning should be fast (<1ms)
- **Memory efficient**: No significant memory allocation increase

### Reliability
- **Graceful degradation**: If quote cleaning fails, use original text
- **No breaking changes**: Existing TTS functionality preserved

## Success Metrics

- **✅ Clean TTS input**: No escape characters in speech generation
- **✅ Natural pronunciation**: Quotes don't cause audio artifacts  
- **✅ Preserved functionality**: All existing TTS features work normally
- **✅ User experience**: Improved speech quality and naturalness

## Implementation Steps

1. **Add quote cleaning function** to TTS service
2. **Integrate into preprocessing pipeline** before language detection
3. **Test with various quote patterns** and languages
4. **Validate audio output quality** with ElevenLabs
5. **Update TTS preprocessing documentation**

## Related Issues

- **FT-078**: This fix complements the natural AI responses enabled by persona-aware MCP integration
- **TTS Enhancement**: Part of ongoing TTS quality improvements

## Notes

- **Low priority**: Cosmetic issue that doesn't affect core functionality
- **Quick fix**: Simple text processing enhancement
- **Quality improvement**: Better user experience for audio responses
- **Foundation**: Sets up better TTS text normalization for future enhancements

---

**Status**: Ready for implementation  
**Impact**: Low (cosmetic improvement)  
**Effort**: Minimal (30 minutes)  
**Risk**: Very low (isolated change)
