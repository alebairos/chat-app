# FT-082: Persona-Aware MCP Response System

**Feature ID**: FT-082  
**Priority**: High  
**Category**: UX/Conversation Flow Enhancement  
**Effort Estimate**: 2-3 hours  
**Dependencies**: FT-078 (Persona-Aware MCP Data Integration), FT-081 (Language-Aware MCP Time Responses), LanguageDetectionService  
**Status**: Specification  

## Overview

Replace hardcoded MCP response templates with a dynamic, persona-aware system that generates contextually appropriate responses based on each persona's communication style, detected conversation language, and contextual relevance. Eliminate systematic, robotic responses while preserving authentic persona voices.

## Problem Description

### Current Behavior
```
User (Portuguese): "não madrugada neh? fim de noite ainda"
Ari Response: "Atualmente são sábado, agosto 23, 2025 às 22:52 (madrugada). Sim, são 22:52 de sábado à noite. Vamos começar um T8 (pomodoro) de 25 minutos?"

User (Portuguese): "deixa eu ver que horas são aí..."
I-There Response: "deixa eu ver que horas são aí... It is currently Saturday, August 23, 2025 at 11:59 PM (night). ah, quase meia noite de sábado!"
```

### Issue Analysis
1. **Hardcoded Templates**: `"It is currently $readableTime ($timeOfDay)."` overrides persona authenticity
2. **Language Mixing**: English templates in Portuguese conversations
3. **Systematic Responses**: Formal, robotic tone contradicts persona communication styles
4. **Redundancy**: AI mentions time naturally, then MCP injects formal time statement
5. **Persona Override**: Ari's TARS brevity (3-6 words) becomes verbose formal statements
6. **Universal Problem**: Affects all personas (Ari, I-There, Sergeant Oracle)

### Root Cause
**Multiple hardcoded English templates** in `ClaudeService._processMCPCommands()`:
- Line 389: `'It is currently $readableTime ($timeOfDay).'`
- Line 420: `'No activities found for the requested period.'`
- Line 416: `'[... and ${totalActivities - 10} more activities]'`

## User Story

As a user interacting with any persona, I want MCP data integration (time, activities, stats) to feel natural and authentic to each character's communication style and the conversation language, so that responses maintain persona consistency and conversational flow without systematic interruptions.

## Functional Requirements

### FR-082-01: Persona-Driven Response Generation
- **Extract communication style** from persona configuration files dynamically
- **Generate responses** that match persona's tone, length, and language patterns
- **Preserve authenticity** for all personas (Ari, I-There, Sergeant Oracle, future personas)
- **No hardcoded templates** - all responses generated from persona intelligence

### FR-082-02: Language-Aware Integration
- **Detect conversation language** using existing `LanguageDetectionService`
- **Generate localized responses** in detected language (Portuguese/English)
- **Maintain language consistency** throughout MCP data integration
- **Support persona language preferences** from configuration

### FR-082-03: Context-Sensitive Injection
- **Analyze AI response context** before injecting MCP data
- **Prevent redundancy** when AI already addresses information naturally
- **Inject only when needed** rather than automatic replacement
- **Maintain conversational flow** without systematic interruptions

### FR-082-04: Universal MCP Command Support
- **Apply to all MCP commands**: `get_current_time`, `get_activity_stats`, `get_message_stats`
- **Consistent persona voice** across all data types
- **Scalable architecture** for future MCP commands
- **Backward compatibility** with existing MCP functionality

## Technical Implementation

### Architecture Overview

```dart
// New persona-aware MCP processing system
class PersonaAwareMCPProcessor {
  static String generateResponse(
    String commandType,
    Map<String, dynamic> data,
    String currentPersona,
    String detectedLanguage,
    String aiResponseContext
  );
}
```

### Core Components

#### 1. Persona Style Analyzer
```dart
class PersonaStyleAnalyzer {
  static PersonaStyle extractFromConfig(Map<String, dynamic> personaConfig) {
    // Parse system prompt to extract:
    // - Response length rules (e.g., Ari: "3-6 palavras")
    // - Communication patterns (e.g., I-There: "lowercase", "casual")
    // - Language preferences (e.g., Portuguese primary)
    // - Tone indicators (e.g., Sergeant: "energetic", "💪")
    return PersonaStyle(
      maxWords: extractMaxWords(config),
      tone: extractTone(config),
      patterns: extractPatterns(config),
      languageStyle: extractLanguageStyle(config)
    );
  }
}
```

#### 2. Context-Sensitive Injection Logic
```dart
class MCPContextAnalyzer {
  static bool shouldInjectData(String aiResponse, String commandType) {
    // Analyze if AI response already handles information naturally
    if (commandType == 'get_current_time') {
      return !_containsTimeReference(aiResponse);
    }
    if (commandType == 'get_activity_stats') {
      return !_containsActivityReference(aiResponse);
    }
    return true; // Default to inject
  }
  
  static bool _containsTimeReference(String response) {
    // Check for natural time mentions: "22:52", "meia-noite", "tarde"
    final timePatterns = [
      r'\d{1,2}:\d{2}',  // 22:52
      r'meia-?noite',     // meia-noite
      r'(manhã|tarde|noite|madrugada)', // time periods
    ];
    return timePatterns.any((pattern) => RegExp(pattern).hasMatch(response));
  }
}
```

#### 3. Dynamic Response Generator
```dart
class PersonaResponseGenerator {
  static String generateTimeResponse(
    Map<String, dynamic> timeData,
    PersonaStyle style,
    String language
  ) {
    final time = timeData['readableTime'];
    final period = timeData['timeOfDay'];
    
    switch (style.personaType) {
      case 'ari':
        return _generateAriTimeResponse(time, period, language, style);
      case 'ithere':
        return _generateIThereTimeResponse(time, period, language, style);
      case 'sergeant':
        return _generateSergeantTimeResponse(time, period, language, style);
      default:
        return _generateGenericTimeResponse(time, period, language);
    }
  }
  
  static String _generateAriTimeResponse(
    String time, String period, String language, PersonaStyle style
  ) {
    if (language == 'pt_BR') {
      // Follow Ari's rules: 3-6 words max, question-focused
      final shortTime = _extractShortTime(time); // "22:52"
      return style.maxWords <= 6 
        ? "$shortTime. Próximo?" 
        : "$shortTime de $period. Quando?";
    } else {
      return "${_extractShortTime(time)}. Next?";
    }
  }
  
  static String _generateIThereTimeResponse(
    String time, String period, String language, PersonaStyle style
  ) {
    if (language == 'pt_BR') {
      // Follow I-There's casual, curious style
      return "são ${_extractShortTime(time)} de $period! tá tranquilo aí?";
    } else {
      return "it's ${_extractShortTime(time)} on $period! how's it going?";
    }
  }
  
  static String _generateSergeantTimeResponse(
    String time, String period, String language, PersonaStyle style
  ) {
    if (language == 'pt_BR') {
      // Follow Sergeant's energetic, Roman style
      return "${_extractShortTime(time)} de gladiador! 💪 Que conquista noturna, campeão?";
    } else {
      return "${_extractShortTime(time)} gladiator time! 💪 What's the night mission, champion?";
    }
  }
}
```

### Integration with Existing Systems

#### Modified ClaudeService._processMCPCommands()
```dart
Future<String> _processMCPCommands(String message) async {
  // ... existing code ...
  
  for (final match in allMatches) {
    final command = match.group(0)!;
    final action = match.group(1) ?? _extractActionFromCommand(command);
    
    try {
      final result = await _systemMCP!.processCommand(command);
      final data = jsonDecode(result);
      
      if (data['status'] == 'success') {
        // NEW: Use persona-aware response generation
        final replacement = await _generatePersonaAwareResponse(
          action, 
          data, 
          processedMessage
        );
        
        processedMessage = processedMessage.replaceFirst(command, replacement);
      }
    } catch (e) {
      // ... error handling ...
    }
  }
  
  return processedMessage;
}

Future<String> _generatePersonaAwareResponse(
  String action,
  Map<String, dynamic> data,
  String context
) async {
  // 1. Get current persona from CharacterConfigManager
  final currentPersona = await _configLoader.getCurrentPersona();
  
  // 2. Detect language from conversation history
  final recentMessages = _conversationHistory
      .where((msg) => msg['role'] == 'user')
      .map((msg) => msg['content'][0]['text'] as String)
      .take(5)
      .toList();
  final detectedLanguage = LanguageDetectionService.detectLanguage(recentMessages);
  
  // 3. Check if injection is needed
  if (!MCPContextAnalyzer.shouldInjectData(context, action)) {
    return ''; // Don't inject if AI already handles it naturally
  }
  
  // 4. Generate persona-aware response
  return PersonaAwareMCPProcessor.generateResponse(
    action,
    data['data'],
    currentPersona,
    detectedLanguage,
    context
  );
}
```

## Expected Results

### Before Fix (Current)
```
Ari: "Atualmente são sábado, agosto 23, 2025 às 22:52 (madrugada). Sim, são 22:52 de sábado à noite. Vamos começar um T8 (pomodoro) de 25 minutos?"
- Violates TARS brevity (3-6 words)
- Redundant time information
- Formal, systematic tone
```

### After Fix (Persona-Aware)
```
Ari: "22:52. T8 agora?" 
- Follows TARS brevity (4 words)
- No redundancy
- Natural, question-focused
```

### I-There Examples
**Before**: `"deixa eu ver que horas são aí... It is currently Saturday, August 23, 2025 at 11:59 PM (night). ah, quase meia noite de sábado!"`
**After**: `"deixa eu ver que horas são aí... quase meia-noite de sábado! tá tranquilo?"`

### Sergeant Oracle Examples
**Before**: Same formal template
**After**: `"Meia-noite de gladiador! 💪 Que conquista noturna, campeão?"`

## Success Metrics

- **✅ Persona Authenticity**: 100% of MCP responses maintain character voice and style
- **✅ Language Consistency**: 0% mixed-language responses in single conversations
- **✅ Redundancy Elimination**: 0% redundant time/data mentions in responses
- **✅ Context Sensitivity**: Only inject MCP data when contextually relevant
- **✅ Scalability**: New personas work automatically without code changes
- **✅ Performance**: No additional API calls, maintain response speed

## Testing Requirements

### Test Scenarios by Persona

#### Ari 2.1 Tests
1. **Time request in Portuguese**: Should return ≤6 words, question format
2. **Activity stats request**: Should use brief, action-focused language
3. **No activities found**: Should be concise, next-step oriented
4. **Context redundancy**: Should not inject if AI already mentions time

#### I-There 2.1 Tests  
1. **Time request in Portuguese**: Should be casual, lowercase, curious
2. **Time request in English**: Should maintain casual clone personality
3. **Mixed conversation**: Should follow dominant language
4. **Natural flow**: Should integrate seamlessly with clone curiosity

#### Sergeant Oracle Tests
1. **Time request**: Should include energy, Roman references, emojis
2. **Activity stats**: Should use gym bro language, motivational tone
3. **No activities**: Should be encouraging, action-oriented
4. **Language adaptation**: Should work in Portuguese and English

### Edge Case Testing
1. **Language detection failure**: Should gracefully fallback to Portuguese
2. **Unknown persona**: Should use generic but appropriate responses
3. **Malformed MCP data**: Should handle errors gracefully
4. **Empty conversation history**: Should use default language (Portuguese)

## Implementation Steps

1. **Create PersonaStyleAnalyzer** to parse communication rules from configs
2. **Build PersonaResponseGenerator** with persona-specific response logic
3. **Implement MCPContextAnalyzer** for context-sensitive injection
4. **Integrate LanguageDetectionService** into MCP processing pipeline
5. **Modify ClaudeService** to use new persona-aware system
6. **Add comprehensive testing** for all personas and scenarios
7. **Validate with real conversations** to ensure natural flow

## Integration Points

### Existing Systems Leveraged
- **LanguageDetectionService**: Reuse existing language detection logic
- **CharacterConfigManager**: Access current persona configuration
- **Persona Config Files**: Extract communication styles dynamically
- **SystemMCP**: Maintain existing MCP command functionality
- **TTS Pipeline**: Ensure consistent language for audio generation

### Future Extensibility
- **New Personas**: Automatically supported through config-driven approach
- **Additional Languages**: Easy to extend through persona language preferences
- **New MCP Commands**: Pattern applies to any future MCP functionality
- **A/B Testing**: Can test different response styles per persona

## Related Features

- **FT-078**: Provides foundation for persona-aware data handling
- **FT-081**: Establishes language-aware MCP processing (superseded by this feature)
- **FT-080**: Ensures clean TTS processing of generated responses
- **FT-060**: Enhanced time awareness provides precise time context

## Risk Assessment

### Low Risk Factors
- **Isolated change**: Only affects MCP response generation
- **Fallback mechanisms**: Graceful degradation if persona analysis fails
- **Existing infrastructure**: Leverages proven LanguageDetectionService
- **Backward compatibility**: Maintains all existing MCP functionality

### Mitigation Strategies
- **Comprehensive testing**: Cover all personas and edge cases
- **Gradual rollout**: Test with one persona before applying to all
- **Monitoring**: Log persona response generation for debugging
- **Fallback responses**: Generic templates if persona-specific generation fails

## Success Criteria

### User Experience
- **Natural conversations**: MCP data feels integrated, not injected
- **Persona consistency**: Each character maintains authentic voice
- **Language fluency**: No mixed-language responses
- **Conversational flow**: No systematic interruptions

### Technical Quality
- **Performance**: No degradation in response time
- **Reliability**: Graceful handling of edge cases
- **Maintainability**: Config-driven, no hardcoded responses
- **Scalability**: Easy to add new personas and languages

---

**Philosophy**: Replace systematic, hardcoded MCP responses with intelligent, persona-aware generation that respects each character's authentic communication style and conversation context.

**Status**: Ready for implementation  
**Impact**: High (significant UX improvement across all personas)  
**Risk**: Low (isolated change with comprehensive fallbacks)  
**Effort**: 2-3 hours (leverages existing infrastructure)
