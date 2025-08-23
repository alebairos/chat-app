# FT-081: Language-Aware MCP Time Responses

**Feature ID**: FT-081  
**Priority**: Medium  
**Category**: Bug Fix / Localization  
**Effort Estimate**: 1-2 hours  
**Dependencies**: FT-078 (Persona-Aware MCP Data Integration), FT-080 (TTS Quote Preprocessing Fix)  
**Status**: Specification  

## Overview

Fix MCP time responses that are hardcoded in English, causing language inconsistency when the conversation is in Portuguese or other languages. Leverage existing language detection infrastructure to provide localized time responses that match the conversation language.

## Problem Description

### Current Behavior
```
User (Portuguese): "Que horas são?"
AI Response: "It is currently Saturday, August 23, 2025 at 2:04 PM (afternoon). Às 14:04, tome cuidado..."
TTS Audio: Mixed English and Portuguese in same sentence
```

### Issue Details
- **Language mixing**: MCP time injection uses hardcoded English format
- **User confusion**: Inconsistent language within single response
- **Poor UX**: Audio switches between languages mid-sentence
- **Professional impact**: Reduces perceived AI quality

## Root Cause

The `ClaudeService._processMCPCommands()` method has hardcoded English time response:

```dart
// Current problematic code (line 389):
processedMessage = processedMessage.replaceFirst(
  command,
  'It is currently $readableTime ($timeOfDay).',
);
```

This ignores the conversation language and always injects English text, even when the AI is responding in Portuguese.

## Functional Requirements

### FR-081-01: Language-Aware Time Responses
- **Detect conversation language** using existing `LanguageDetectionService`
- **Generate localized time responses** based on detected language
- **Maintain natural flow** with appropriate phrasing for each language

### FR-081-02: Supported Languages
- **Portuguese (pt_BR)**: "Atualmente são [time] ([period])"
- **English (en_US)**: "It is currently [time] ([period])"
- **Fallback**: Default to Portuguese if detection fails

### FR-081-03: Integration with Existing Systems
- **Use existing language detection** from TTS service infrastructure
- **Preserve MCP functionality** for all other command types
- **Maintain performance** with minimal processing overhead

## Technical Implementation

### Current Architecture Analysis
```dart
// Existing infrastructure we can leverage:
- LanguageDetectionService.detectLanguage() ✅
- TTS service tracks recent messages ✅  
- Time data from SystemMCP ✅
- Message processing pipeline ✅
```

### Proposed Solution
```dart
// In ClaudeService._processMCPCommands()
if (action == 'get_current_time') {
  final timeData = data['data'];
  final readableTime = timeData['readableTime'];
  final timeOfDay = timeData['timeOfDay'];

  // Create language-aware time response
  final timeResponse = _createLocalizedTimeResponse(
    readableTime, 
    timeOfDay, 
    processedMessage
  );

  processedMessage = processedMessage.replaceFirst(command, timeResponse);
}
```

### Language Detection Integration
```dart
String _createLocalizedTimeResponse(
  String readableTime, 
  String timeOfDay, 
  String context
) {
  // Extract recent messages from context for language detection
  final language = _detectLanguageFromContext(context);
  
  switch (language) {
    case 'pt_BR':
      return _createPortugueseTimeResponse(readableTime, timeOfDay);
    case 'en_US':
      return _createEnglishTimeResponse(readableTime, timeOfDay);
    default:
      return _createPortugueseTimeResponse(readableTime, timeOfDay); // Default
  }
}
```

### Localized Response Templates
```dart
String _createPortugueseTimeResponse(String readableTime, String timeOfDay) {
  // Convert English time format to Portuguese
  final localizedTime = _localizeTimeFormat(readableTime, 'pt_BR');
  final localizedPeriod = _localizePeriod(timeOfDay, 'pt_BR');
  
  return 'Atualmente são $localizedTime ($localizedPeriod).';
}

String _createEnglishTimeResponse(String readableTime, String timeOfDay) {
  return 'It is currently $readableTime ($timeOfDay).';
}
```

### Time Format Localization
```dart
String _localizeTimeFormat(String englishTime, String language) {
  if (language == 'pt_BR') {
    // Convert "Saturday, August 23, 2025 at 2:04 PM" 
    // to "sábado, 23 de agosto de 2025 às 14:04"
    return TimeFormatLocalizer.localizeTimeFormats(englishTime, language);
  }
  return englishTime;
}

String _localizePeriod(String timeOfDay, String language) {
  if (language == 'pt_BR') {
    final periodMap = {
      'morning': 'manhã',
      'afternoon': 'tarde', 
      'evening': 'noite',
      'night': 'madrugada'
    };
    return periodMap[timeOfDay] ?? timeOfDay;
  }
  return timeOfDay;
}
```

## Expected Results

### Before Fix
```
AI: "It is currently Saturday, August 23, 2025 at 2:04 PM (afternoon). Às 14:04, tome cuidado..."
Language: Mixed English/Portuguese
User Experience: Confusing and unprofessional
```

### After Fix
```
AI: "Atualmente são sábado, 23 de agosto de 2025 às 14:04 (tarde). Às 14:04, tome cuidado..."
Language: Consistent Portuguese
User Experience: Natural and professional
```

## Testing Requirements

### Test Cases
1. **Portuguese conversation**: Time response should be in Portuguese
2. **English conversation**: Time response should be in English  
3. **Mixed conversation**: Should follow dominant language
4. **No conversation history**: Should default to Portuguese
5. **Language detection failure**: Should gracefully fallback

### Validation Scenarios
```dart
// Test case examples:
testPortugueseTimeResponse() {
  // Given: Portuguese conversation context
  // When: MCP time command processed
  // Then: Response should be "Atualmente são..."
}

testEnglishTimeResponse() {
  // Given: English conversation context  
  // When: MCP time command processed
  // Then: Response should be "It is currently..."
}
```

## Non-Functional Requirements

### Performance
- **Minimal overhead**: Language detection reuses existing infrastructure
- **Fast processing**: Simple string formatting operations
- **Memory efficient**: No additional data structures required

### Reliability  
- **Graceful degradation**: Fallback to Portuguese if detection fails
- **Error handling**: Preserve original functionality if localization fails
- **Backward compatibility**: No breaking changes to existing MCP commands

## Success Metrics

- **✅ Language consistency**: 100% of time responses match conversation language
- **✅ User experience**: No more mixed-language responses
- **✅ Performance**: No measurable impact on response time
- **✅ Reliability**: Graceful fallback for edge cases

## Integration Points

### Existing Systems
- **LanguageDetectionService**: Reuse existing language detection logic
- **TimeFormatLocalizer**: Leverage existing time localization utilities
- **TTS Pipeline**: Ensure consistent language for audio generation
- **MCP Framework**: Maintain compatibility with all MCP commands

### Future Extensibility
- **Additional languages**: Easy to add Spanish, French, etc.
- **Cultural formatting**: Can extend to locale-specific time formats
- **Other MCP commands**: Pattern can be applied to activity stats, etc.

## Implementation Steps

1. **Add language detection** to MCP time processing
2. **Create localized response templates** for Portuguese and English
3. **Integrate time format localization** using existing utilities
4. **Add comprehensive testing** for both languages
5. **Validate with real conversations** in iOS simulator

## Related Features

- **FT-078**: Natural persona responses now get consistent language support
- **FT-080**: Clean TTS processing works with properly localized text
- **FT-060**: Enhanced time awareness gets proper language formatting

## Notes

- **Leverages existing infrastructure**: No duplication of language detection
- **Minimal code changes**: Focused fix with clear scope
- **User-centric**: Addresses real usability issue observed in testing
- **Foundation for future**: Establishes pattern for localizing other MCP responses

---

**Status**: Ready for implementation  
**Impact**: Medium (significant UX improvement)  
**Risk**: Low (isolated change with fallback)  
**Effort**: 1-2 hours (reuses existing systems)
