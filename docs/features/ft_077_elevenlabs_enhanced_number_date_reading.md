# FT-077: ElevenLabs Enhanced Number & Date Reading

**Feature ID**: FT-077  
**Priority**: Medium  
**Category**: Audio Assistant > TTS Enhancement  
**Effort Estimate**: 2-3 weeks  
**Dependencies**: FT-015 (Ari Persona TTS Enhancement), existing TTS preprocessing infrastructure  
**Status**: Specification  

## Overview

Enhance the ElevenLabs TTS integration to provide intelligent, language-aware reading of numbers, dates, and time formats in both Portuguese (pt_BR) and English (en_US). This feature will improve the naturalness of audio responses by ensuring numbers and temporal information are pronounced correctly according to the detected conversation language, rather than being read as literal digits.

## User Story

As a user conversing with AI personas in Portuguese or English, I want numbers, dates, and times to be read naturally in the appropriate language (e.g., "23:13" pronounced as "vinte e três horas e treze minutos" in Portuguese, not "two three colon one three"), so that audio responses feel natural and culturally appropriate.

## Problem Statement

**Current Limitations:**
- **Literal Number Reading**: Numbers like "23:13" are read as individual digits instead of natural time expressions
- **Language Inconsistency**: Date formats and numbers may be pronounced in the wrong language context
- **Limited Number Range**: Current preprocessing only handles numbers 0-90, missing larger numbers and complex formats
- **No Date Recognition**: Dates like "2024-08-20" are read literally instead of as natural date expressions
- **Time Format Issues**: 12-hour formats aren't properly converted to natural language expressions

**User Pain Points:**
- Audio responses sound robotic when reading numbers and dates
- Inconsistent pronunciation between Portuguese and English conversations
- Poor user experience when listening to activity logs with timestamps
- Numbers and dates break the natural flow of audio coaching sessions

## Solution: Intelligent Number & Date Reading

### Core Concept
- **Language-Aware Processing**: Automatically detect conversation language and apply appropriate number/date reading rules
- **Natural Expression Conversion**: Transform numeric formats into natural language expressions (e.g., "23:13" → "vinte e três horas e treze minutos")
- **Comprehensive Coverage**: Handle all common number ranges, date formats, and time expressions
- **ElevenLabs Optimization**: Leverage ElevenLabs API features for better pronunciation control

### System Components
1. **Enhanced TTS Preprocessing**: Advanced number and date pattern recognition
2. **Language-Specific Rules**: Portuguese and English pronunciation patterns
3. **ElevenLabs Voice Optimization**: Language-specific voice settings and SSML integration
4. **Pattern Recognition Engine**: Intelligent detection of numbers, dates, and time formats

## Functional Requirements

### Enhanced Number Processing
- **FR-077-01**: Convert all numbers 0-9999 to natural language expressions
- **FR-077-02**: Handle decimal numbers with appropriate language formatting
- **FR-077-03**: Support ordinal numbers (1st, 2nd, 3rd → primeiro, segundo, terceiro)
- **FR-077-04**: Process percentages with natural language (25% → vinte e cinco por cento)
- **FR-077-05**: Handle currency amounts with proper formatting

### Advanced Time Format Processing
- **FR-077-06**: Convert 24-hour formats to natural language (23:13 → vinte e três horas e treze minutos)
- **FR-077-07**: Process 12-hour formats with AM/PM (11:30 PM → onze horas e trinta minutos da noite)
- **FR-077-08**: Handle time ranges and durations (30 min → trinta minutos)
- **FR-077-09**: Support relative time expressions (today, tomorrow, next week)

### Date Format Processing
- **FR-077-10**: Convert ISO dates to natural language (2024-08-20 → vinte de agosto de dois mil e vinte e quatro)
- **FR-077-11**: Handle various date formats (MM/DD/YYYY, DD/MM/YYYY)
- **FR-077-12**: Process month names in appropriate language
- **FR-077-13**: Support date ranges and intervals
- **FR-077-14**: Handle special dates (birthdays, holidays, anniversaries)

### Language-Specific Optimization
- **FR-077-15**: Apply Portuguese-specific pronunciation rules for pt_BR conversations
- **FR-077-16**: Apply English-specific pronunciation rules for en_US conversations
- **FR-077-17**: Maintain language consistency throughout audio responses
- **FR-077-18**: Support mixed-language content with appropriate pronunciation

### ElevenLabs Integration
- **FR-077-19**: Optimize voice settings for each language
- **FR-077-20**: Implement SSML tags for pronunciation control
- **FR-077-21**: Configure language-specific voice models
- **FR-077-22**: Support voice cloning for language consistency

## Non-Functional Requirements

### Performance
- **NFR-077-01**: Number/date processing completes within 100ms
- **NFR-077-02**: Support processing of text up to 10,000 characters
- **NFR-077-03**: Efficient pattern matching for complex formats
- **NFR-077-04**: Minimal impact on TTS generation time

### Accuracy
- **NFR-077-05**: 99%+ accuracy in number and date recognition
- **NFR-077-06**: Correct language detection and application
- **NFR-077-07**: Proper handling of edge cases and ambiguous formats
- **NFR-077-08**: Consistent pronunciation across different text contexts

### Usability
- **NFR-077-09**: Natural-sounding audio output
- **NFR-077-10**: Seamless integration with existing TTS workflow
- **NFR-077-11**: No degradation of existing TTS quality
- **NFR-077-12**: Maintainable and extensible preprocessing rules

## Technical Implementation

### Enhanced TTS Preprocessing Service

#### 1. Number Processing Engine
```dart
class EnhancedNumberProcessor {
  static String processNumbers(String text, String language) {
    // Handle time formats (HH:MM)
    text = _processTimeFormats(text, language);
    
    // Handle date formats (YYYY-MM-DD)
    text = _processDateFormats(text, language);
    
    // Handle general numbers (0-9999)
    text = _processGeneralNumbers(text, language);
    
    // Handle special formats (percentages, currency)
    text = _processSpecialFormats(text, language);
    
    return text;
  }
}
```

#### 2. Language-Specific Rules
```dart
class PortugueseNumberRules {
  static const Map<int, String> numbers = {
    0: 'zero', 1: 'um', 2: 'dois', 3: 'três',
    // ... complete mapping to 9999
  };
  
  static const Map<int, String> months = {
    1: 'janeiro', 2: 'fevereiro', 3: 'março',
    // ... complete month mapping
  };
  
  static String formatTime(int hour, int minute) {
    return '${_numberToPortuguese(hour)} horas e ${_numberToPortuguese(minute)} minutos';
  }
}
```

#### 3. Pattern Recognition
```dart
class PatternRecognitionEngine {
  static final List<RegExp> timePatterns = [
    RegExp(r'\b(\d{1,2}):(\d{2})\b'),           // HH:MM
    RegExp(r'\b(\d{1,2})\s*(am|pm)\b', caseSensitive: false), // H AM/PM
    RegExp(r'\b(\d{1,2}):(\d{2})\s*(am|pm)\b', caseSensitive: false), // HH:MM AM/PM
  ];
  
  static final List<RegExp> datePatterns = [
    RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b'), // YYYY-MM-DD
    RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b'), // MM/DD/YYYY
    RegExp(r'\b(\d{1,2})-(\d{1,2})-(\d{4})\b'), // DD-MM-YYYY
  ];
}
```

### ElevenLabs API Optimization

#### 1. Language-Specific Voice Configuration
```dart
class ElevenLabsLanguageOptimizer {
  static Map<String, dynamic> getLanguageConfig(String language) {
    switch (language) {
      case 'pt_BR':
        return {
          'modelId': 'eleven_multilingual_v1',
          'stability': 0.75,        // Higher for clearer pronunciation
          'similarityBoost': 0.85,  // Enhanced voice consistency
          'style': 0.15,           // More expressive for natural flow
          'speakerBoost': true,     // Better clarity for numbers
        };
      case 'en_US':
        return {
          'modelId': 'eleven_multilingual_v1',
          'stability': 0.70,        // Balanced for English
          'similarityBoost': 0.80,  // Good voice consistency
          'style': 0.10,           // Natural English flow
          'speakerBoost': true,     // Clear pronunciation
        };
      default:
        return _getDefaultConfig();
    }
  }
}
```

#### 2. SSML Integration
```dart
class SSMLProcessor {
  static String addPronunciationHints(String text, String language) {
    if (language.startsWith('pt')) {
      // Add Portuguese pronunciation hints
      text = text.replaceAllMapped(
        RegExp(r'\b(\d{1,2}):(\d{2})\b'),
        (match) => '<say-as interpret-as="time">${match.group(1)}:${match.group(2)}</say-as>'
      );
      
      text = text.replaceAllMapped(
        RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b'),
        (match) => '<say-as interpret-as="date">${match.group(1)}-${match.group(2)}-${match.group(3)}</say-as>'
      );
    }
    
    return text;
  }
}
```

### Integration Points

#### 1. TTS Service Enhancement
```dart
class AudioAssistantTTSService {
  Future<String?> generateAudio(String text, {String? language}) async {
    // ... existing initialization code ...
    
    // Enhanced preprocessing with number/date processing
    final processedText = EnhancedTTSPreprocessor.preprocessForTTS(
      text, 
      targetLanguage
    );
    
    // Configure ElevenLabs for optimal language performance
    await _configureProviderForLanguage(targetLanguage);
    
    // ... rest of existing code ...
  }
}
```

#### 2. Claude Service Integration
```dart
class ClaudeService {
  Future<void> _processAudioResponse(String text, String language) async {
    // Enhanced TTS preprocessing before audio generation
    final processedText = EnhancedTTSPreprocessor.preprocessForTTS(
      text, 
      language
    );
    
    // Generate audio with enhanced preprocessing
    await _ttsService?.generateAudio(processedText, language: language);
  }
}
```

## Implementation Strategy

### Phase 1: Core Number Processing (Week 1)
1. **Enhanced Number Processor**
   - Implement comprehensive number-to-word conversion (0-9999)
   - Add Portuguese and English number rules
   - Create pattern recognition for time formats

2. **Date Processing Engine**
   - Implement date format recognition and conversion
   - Add month name localization
   - Support various date formats

### Phase 2: ElevenLabs Integration (Week 2)
1. **Voice Configuration Optimization**
   - Implement language-specific voice settings
   - Add SSML processing capabilities
   - Test with different voice models

2. **Performance Optimization**
   - Optimize pattern matching algorithms
   - Implement caching for common conversions
   - Add performance monitoring

### Phase 3: Testing & Refinement (Week 3)
1. **Comprehensive Testing**
   - Test with various number and date formats
   - Validate language-specific pronunciation
   - Performance testing and optimization

2. **User Experience Validation**
   - Audio quality assessment
   - Naturalness evaluation
   - Language consistency verification

## Testing Strategy

### Unit Tests
```dart
group('Enhanced Number Processing', () {
  test('should convert time formats to Portuguese', () {
    final input = 'Exercício às 19:30 e meditação às 23:13';
    final expected = 'Exercício às dezenove horas e trinta minutos e meditação às vinte e três horas e treze minutos';
    
    final result = EnhancedTTSPreprocessor.preprocessForTTS(input, 'pt_BR');
    expect(result, equals(expected));
  });
  
  test('should convert dates to Portuguese', () {
    final input = 'Reunião em 2024-08-20';
    final expected = 'Reunião em vinte de agosto de dois mil e vinte e quatro';
    
    final result = EnhancedTTSPreprocessor.preprocessForTTS(input, 'pt_BR');
    expect(result, equals(expected));
  });
  
  test('should handle English time formats', () {
    final input = 'Meeting at 2:30 PM and call at 11:45 AM';
    final expected = 'Meeting at two thirty PM and call at eleven forty-five AM';
    
    final result = EnhancedTTSPreprocessor.preprocessForTTS(input, 'en_US');
    expect(result, equals(expected));
  });
});
```

### Integration Tests
```dart
group('ElevenLabs Integration', () {
  testWidgets('should generate audio with enhanced number processing', (tester) async {
    // Test complete TTS workflow with number processing
    final ttsService = AudioAssistantTTSService();
    await ttsService.initialize();
    
    final audioPath = await ttsService.generateAudio(
      'Exercício às 19:30 e meditação às 23:13',
      language: 'pt_BR'
    );
    
    expect(audioPath, isNotNull);
    // Verify audio file was generated
  });
});
```

### Performance Tests
```dart
group('Performance Testing', () {
  test('should process large text within performance limits', () {
    final largeText = 'Exercício às 19:30, meditação às 23:13, reunião em 2024-08-20, ' * 100;
    
    final stopwatch = Stopwatch()..start();
    final result = EnhancedTTSPreprocessor.preprocessForTTS(largeText, 'pt_BR');
    stopwatch.stop();
    
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
    expect(result, isNotEmpty);
  });
});
```

## Success Metrics

### Primary Success Criteria
- ✅ Numbers 0-9999 converted to natural language in both Portuguese and English
- ✅ Time formats (HH:MM) read as natural expressions
- ✅ Date formats converted to natural language expressions
- ✅ Language consistency maintained throughout audio responses
- ✅ No degradation in existing TTS quality

### Quality Metrics
- **Pronunciation Accuracy**: 99%+ correct number and date pronunciation
- **Language Consistency**: 100% language-appropriate pronunciation
- **Performance Impact**: <100ms processing time for typical text
- **Audio Naturalness**: Improved user satisfaction with audio responses

### User Experience Metrics
- **Audio Quality**: Enhanced naturalness of number and date reading
- **Language Appropriateness**: Culturally appropriate pronunciation
- **Consistency**: Uniform pronunciation across different contexts
- **Accessibility**: Better understanding of numerical information in audio

## Risks & Mitigations

### Technical Risks
- **Risk**: Complex pattern matching may impact performance
  - **Mitigation**: Implement efficient regex patterns and caching
- **Risk**: ElevenLabs API changes may affect integration
  - **Mitigation**: Use stable API endpoints and implement fallbacks
- **Risk**: Language detection errors may cause pronunciation issues
  - **Mitigation**: Robust fallback to default language rules

### User Experience Risks
- **Risk**: Over-processing may make text sound unnatural
  - **Mitigation**: Careful testing and user feedback validation
- **Risk**: Inconsistent pronunciation across different contexts
  - **Mitigation**: Comprehensive pattern coverage and testing

## Future Enhancements

### Phase 2 Features
- **Advanced Number Formats**: Support for scientific notation, fractions, and mathematical expressions
- **Cultural Adaptations**: Region-specific number and date formatting
- **Voice Training**: Custom voice models optimized for number pronunciation
- **Real-time Adaptation**: Dynamic pronunciation adjustment based on context

### Long-term Vision
- **Multilingual Expansion**: Support for additional languages beyond Portuguese and English
- **Context-Aware Processing**: Intelligent pronunciation based on semantic context
- **User Customization**: Allow users to customize pronunciation preferences
- **AI-Powered Optimization**: Machine learning-based pronunciation improvement

## Conclusion

This feature enhancement will significantly improve the audio experience for users conversing with AI personas in both Portuguese and English. By implementing intelligent number and date processing, combined with ElevenLabs API optimization, users will experience more natural and culturally appropriate audio responses.

The implementation leverages existing TTS preprocessing infrastructure while adding sophisticated pattern recognition and language-specific rules. The result will be a more professional and engaging audio coaching experience that maintains the high quality standards of the current system while adding significant value for users who rely on audio interaction.
