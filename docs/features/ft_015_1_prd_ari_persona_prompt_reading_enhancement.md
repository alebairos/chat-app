# Feature ft_015: Ari Persona Prompt Reading Enhancement

## Product Requirements Document (PRD)

### Executive Summary

This PRD outlines enhancements to Ari's Text-to-Speech (TTS) processing to improve audio experience quality by addressing language inconsistencies and unwanted acronym reading. The feature ensures that Ari's sophisticated coaching content is delivered with proper Portuguese pronunciation and clean audio output.

### Background & Context

Following the successful implementation of Ari as the default persona (ft_012), TARS-inspired brevity system (ft_013), and configuration consistency (ft_014), users are experiencing high-quality coaching conversations. However, the TTS audio experience has two critical issues that diminish the professional coaching experience:

1. **Language Mixing**: Numbers and some content are read in English while conversations are in Portuguese (pt_BR)
2. **Technical Noise**: Habit catalog acronyms (SF, R, SM, TG, E) and IDs are being read aloud, cluttering the audio experience

### Problem Statement

The current TTS implementation creates inconsistent and unprofessional audio experiences:

**Language Inconsistency Issues:**
- Numbers spoken in English: "twenty-one" instead of "vinte e um"
- Mixed language content disrupts conversation flow
- Breaks immersion for Portuguese-speaking users
- Reduces perceived professionalism of coaching

**Acronym Reading Issues:**
- Technical identifiers read aloud: "SF1233", "SM13", "R1"
- Habit catalog codes clutter coaching advice
- Reduces clarity of core coaching messages
- Creates cognitive load for users

### Product Vision

**"Deliver seamless, professional Portuguese audio coaching experiences through intelligent TTS processing that respects conversation language and filters technical noise."**

### Target Users

**Primary Users:**
- Portuguese-speaking users receiving audio coaching from Ari
- Users who prefer audio interaction over text reading
- Users in hands-free scenarios (driving, exercising, multitasking)

**Secondary Users:**
- All Ari persona users who may encounter TTS in the future
- Users switching between text and audio modes

### Core Features & Requirements

#### 1. Language-Aware TTS Processing

**Portuguese Number Reading:**
- All numbers should be pronounced in Portuguese when conversation is in pt_BR
- Examples:
  - "21 dias" → "vinte e um dias" (not "twenty-one dias")
  - "10 minutos" → "dez minutos" (not "ten minutos")
  - "3 vezes" → "três vezes" (not "three vezes")

**Language Detection & Consistency:**
- Detect conversation language from user messages
- Maintain language consistency throughout TTS processing
- Support explicit language preference override

**Content Localization:**
- Ensure all coaching content follows detected language
- Proper pronunciation of Portuguese coaching terms
- Consistent accent and intonation patterns

#### 2. Smart Acronym Filtering

**Habit Catalog Acronym Removal:**
- Filter out technical identifiers in parentheses
- Target patterns: `(SF\d+)`, `(SM\d+)`, `(R\d+)`, `(TG\d+)`, `(E\d+)`
- Examples:
  - "Exercício de força intenso 40min+ (SF1233)" → "Exercício de força intenso 40min+"
  - "Meditar 10min (SM13)" → "Meditar 10min"
  - "Praticar escuta ativa (R1)" → "Praticar escuta ativa"

**Dimension Code Filtering:**
- Remove standalone dimension codes
- Filter patterns: `SF`, `SM`, `R`, `TG`, `E` when used as technical identifiers
- Preserve when used in natural language context

**Flexible Pattern Matching:**
- Support various parenthetical patterns
- Handle different spacing and formatting
- Maintain text readability while removing audio noise

#### 3. Enhanced TTS Preprocessing

**Pre-processing Pipeline:**
1. **Language Detection**: Identify conversation language
2. **Acronym Filtering**: Remove technical identifiers
3. **Number Localization**: Convert numbers to target language
4. **Content Optimization**: Prepare for natural speech

**ElevenLabs Integration:**
- Configure voice settings for Portuguese pronunciation
- Optimize speech patterns for coaching content
- Ensure natural pauses and intonation

### Technical Implementation

#### Required Code Changes

**1. TTS Preprocessing Service Enhancement:**

```dart
// lib/services/tts_preprocessing_service.dart
class TTSPreprocessingService {
  static String preprocessForTTS(String text, String language) {
    String processed = text;
    
    // Remove habit catalog acronyms
    processed = _removeHabitAcronyms(processed);
    
    // Localize numbers based on language
    processed = _localizeNumbers(processed, language);
    
    // Clean up extra spaces
    processed = _cleanupSpacing(processed);
    
    return processed;
  }
  
  static String _removeHabitAcronyms(String text) {
    // Remove patterns like (SF1233), (SM13), (R1), etc.
    return text.replaceAll(RegExp(r'\s*\([A-Z]{1,2}\d+\)'), '');
  }
  
  static String _localizeNumbers(String text, String language) {
    if (language == 'pt_BR') {
      return _convertNumbersToPortuguese(text);
    }
    return text;
  }
  
  static String _convertNumbersToPortuguese(String text) {
    // Convert common numbers to Portuguese words
    final numberMap = {
      '1': 'um',
      '2': 'dois',
      '3': 'três',
      '4': 'quatro',
      '5': 'cinco',
      '6': 'seis',
      '7': 'sete',
      '8': 'oito',
      '9': 'nove',
      '10': 'dez',
      '11': 'onze',
      '12': 'doze',
      '13': 'treze',
      '14': 'quatorze',
      '15': 'quinze',
      '16': 'dezesseis',
      '17': 'dezessete',
      '18': 'dezoito',
      '19': 'dezenove',
      '20': 'vinte',
      '21': 'vinte e um',
      '30': 'trinta',
      '40': 'quarenta',
      '50': 'cinquenta',
      '60': 'sessenta',
    };
    
    String result = text;
    numberMap.forEach((number, word) {
      result = result.replaceAll(RegExp('\\b$number\\b'), word);
    });
    
    return result;
  }
}
```

**2. Language Detection Service:**

```dart
// lib/services/language_detection_service.dart
class LanguageDetectionService {
  static String detectLanguage(List<String> recentMessages) {
    // Analyze recent user messages for language patterns
    final portugueseKeywords = ['que', 'como', 'para', 'com', 'uma', 'seu', 'meu'];
    final englishKeywords = ['what', 'how', 'with', 'your', 'my', 'the'];
    
    int portugueseScore = 0;
    int englishScore = 0;
    
    for (String message in recentMessages) {
      String lowerMessage = message.toLowerCase();
      
      for (String keyword in portugueseKeywords) {
        if (lowerMessage.contains(keyword)) portugueseScore++;
      }
      
      for (String keyword in englishKeywords) {
        if (lowerMessage.contains(keyword)) englishScore++;
      }
    }
    
    return portugueseScore > englishScore ? 'pt_BR' : 'en_US';
  }
}
```

**3. TTS Service Integration:**

```dart
// lib/features/audio_assistant/tts_service.dart
class TTSService {
  Future<void> speak(String text, {String? language}) async {
    // Detect language if not provided
    final detectedLanguage = language ?? 
        LanguageDetectionService.detectLanguage(_recentMessages);
    
    // Preprocess text for TTS
    final processedText = TTSPreprocessingService.preprocessForTTS(
      text, 
      detectedLanguage
    );
    
    // Configure ElevenLabs voice settings
    await _configureVoiceForLanguage(detectedLanguage);
    
    // Generate and play audio
    await _generateAndPlayAudio(processedText);
  }
  
  Future<void> _configureVoiceForLanguage(String language) async {
    if (language == 'pt_BR') {
      // Configure for Portuguese pronunciation
      await _setVoiceSettings(
        stability: 0.75,
        similarityBoost: 0.85,
        style: 0.20,
        useSpeakerBoost: true,
      );
    }
  }
}
```

#### Files to Modify

**Core Services:**
- `lib/features/audio_assistant/tts_service.dart` - Main TTS processing
- `lib/services/claude_service.dart` - Integration with TTS preprocessing

**New Services:**
- `lib/services/tts_preprocessing_service.dart` - Text preprocessing logic
- `lib/services/language_detection_service.dart` - Language detection

**Configuration Updates:**
- `assets/config/ari_life_coach_config.json` - TTS-specific instructions

### Implementation Strategy

#### Phase 1: Core Preprocessing (2 days)
1. **Create TTS Preprocessing Service**
   - Implement acronym filtering
   - Add number localization
   - Create text cleanup utilities

2. **Language Detection Service**
   - Implement conversation language detection
   - Add language preference storage
   - Create fallback mechanisms

#### Phase 2: TTS Integration (2 days)
1. **Update TTS Service**
   - Integrate preprocessing pipeline
   - Add language-aware voice configuration
   - Implement ElevenLabs optimization

2. **Claude Service Integration**
   - Add TTS preprocessing to response flow
   - Ensure consistent language handling
   - Test with Ari persona responses

#### Phase 3: Testing & Optimization (1 day)
1. **Comprehensive Testing**
   - Test Portuguese number pronunciation
   - Verify acronym filtering
   - Validate language consistency

2. **Audio Quality Optimization**
   - Fine-tune voice settings
   - Optimize speech patterns
   - Ensure natural conversation flow

**Total Implementation Time: 5 days**

### Success Metrics

**Primary Success Criteria:**
- ✅ Numbers pronounced in Portuguese when conversation is in pt_BR
- ✅ Habit catalog acronyms filtered from TTS output
- ✅ Consistent language throughout audio experience
- ✅ Natural Portuguese pronunciation and intonation

**Secondary Success Criteria:**
- ✅ Improved user satisfaction with audio coaching
- ✅ Reduced cognitive load during audio sessions
- ✅ Professional coaching experience maintained
- ✅ Seamless language detection and switching

**Quality Metrics:**
- **Language Consistency**: 95%+ Portuguese pronunciation accuracy
- **Acronym Filtering**: 100% technical identifier removal
- **Audio Quality**: Maintained natural speech patterns
- **User Experience**: Improved audio coaching satisfaction

### Testing Strategy

**Unit Tests:**
```dart
// test/services/tts_preprocessing_service_test.dart
group('TTS Preprocessing Service', () {
  test('should remove habit catalog acronyms', () {
    final input = 'Exercício de força intenso 40min+ (SF1233)';
    final output = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');
    expect(output, 'Exercício de força intenso 40min+');
  });
  
  test('should convert numbers to Portuguese', () {
    final input = 'Meditar por 10 minutos';
    final output = TTSPreprocessingService.preprocessForTTS(input, 'pt_BR');
    expect(output, 'Meditar por dez minutos');
  });
});
```

**Integration Tests:**
```dart
// test/features/audio_assistant/tts_integration_test.dart
group('TTS Integration', () {
  test('should detect Portuguese and preprocess correctly', () async {
    final messages = ['Como posso melhorar meu sono?'];
    final ttsService = TTSService();
    
    // Should detect Portuguese and preprocess accordingly
    await ttsService.speak('Tente dormir 8 horas (SF15)');
    
    // Verify preprocessing occurred
    expect(lastProcessedText, 'Tente dormir oito horas');
  });
});
```

### Risk Assessment

**Technical Risks:**
- **Low**: Number conversion may miss edge cases
  - *Mitigation*: Comprehensive number mapping and testing
- **Low**: Language detection may be inaccurate
  - *Mitigation*: Fallback to user preference and manual override

**User Experience Risks:**
- **Low**: Over-filtering may remove important content
  - *Mitigation*: Careful pattern matching and testing
- **Low**: Portuguese pronunciation may not be perfect
  - *Mitigation*: Voice setting optimization and user feedback

### Future Enhancements

**Potential Improvements:**
- **Advanced Language Detection**: ML-based language identification
- **User Preference Learning**: Adaptive language selection
- **Voice Customization**: User-selectable voice characteristics
- **Multi-language Support**: Extend to other languages

### Implementation Checklist

#### Pre-Implementation:
- [ ] Analyze current TTS processing pipeline
- [ ] Identify all acronym patterns in Ari's responses
- [ ] Map Portuguese number conversion requirements
- [ ] Review ElevenLabs API language settings

#### Implementation Steps:
- [ ] Create `TTSPreprocessingService` with acronym filtering
- [ ] Implement `LanguageDetectionService` for conversation analysis
- [ ] Add number localization for Portuguese
- [ ] Update `TTSService` to integrate preprocessing
- [ ] Configure ElevenLabs settings for Portuguese
- [ ] Add language detection to Claude service integration
- [ ] Create comprehensive unit tests
- [ ] Implement integration tests
- [ ] Test with real Ari persona conversations

#### Post-Implementation:
- [ ] Monitor TTS quality metrics
- [ ] Collect user feedback on audio experience
- [ ] Fine-tune preprocessing patterns
- [ ] Document TTS enhancement guidelines

### Conclusion

ft_015 addresses critical TTS quality issues that impact the professional coaching experience with Ari. By implementing intelligent preprocessing for language consistency and acronym filtering, users will receive seamless Portuguese audio coaching that maintains Ari's sophisticated expertise while delivering clean, professional audio output.

The implementation leverages existing TTS infrastructure while adding targeted enhancements that significantly improve audio quality without disrupting current functionality.

**Final Recommendation:** Implement ft_015 as a high-priority enhancement to complete the Ari persona audio experience. The 5-day implementation provides substantial improvements in user experience and maintains the professional coaching quality that Ari represents.

---

**Document Version:** 1.0  
**Created:** January 16, 2025  
**Author:** AI Assistant  
**Status:** Ready for Implementation 