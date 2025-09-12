# FT-121: Audio-Optimized Persona Prompts

**Feature ID**: FT-121  
**Priority**: High  
**Category**: Audio Assistant > TTS Quality  
**Effort Estimate**: 2-3 days  
**Dependencies**: FT-120 (ElevenLabs Text Normalization), existing persona configurations  
**Status**: Specification  

## Overview

Enhance persona system prompts with audio-friendly formatting instructions to ensure Claude generates text that produces high-quality TTS output. This addresses issues where abbreviations and text-optimized formatting create poor audio pronunciation (e.g., "22h" → "vinte e dois ós" instead of "vinte e duas horas").

## Problem Statement

**Current Issues:**
- Persona prompts focus only on text communication style
- Claude generates responses with abbreviations that don't translate well to speech
- "22h" pronounced as "vinte e dois ós" instead of "vinte e duas horas"
- Markdown symbols and abbreviations create awkward TTS output
- Mixed language preprocessing conflicts with ElevenLabs text normalization

**User Impact:**
- Poor audio quality with robotic, unnatural pronunciation
- Confusion when times and numbers are mispronounced
- Inconsistent professional audio experience across personas

## Solution: Audio-Optimized Prompt Enhancement

### Core Approach
Add comprehensive audio formatting instructions to all persona system prompts, instructing Claude to generate TTS-friendly text from the source rather than fixing it in post-processing.

## Functional Requirements

### Audio Format Instructions
- **FR-121-01**: Add TTS formatting section to all persona system prompts
- **FR-121-02**: Specify exact time formats for Portuguese and English
- **FR-121-03**: Define number and currency formatting standards
- **FR-121-04**: Provide date formatting guidelines for natural speech
- **FR-121-05**: Eliminate markdown symbols that don't translate to audio

### Language-Specific Formatting
- **FR-121-06**: Portuguese time format: "às 22:00" (not "22h")
- **FR-121-07**: English time format: "at 10:00 PM" (not "10pm")
- **FR-121-08**: Currency format: "R$ 1.500" and "$1,500" for proper pronunciation
- **FR-121-09**: Date format: "15 de março" and "March 15th" for natural reading

### Persona Integration
- **FR-121-10**: Maintain existing persona personality and communication style
- **FR-121-11**: Integrate audio instructions without disrupting persona identity
- **FR-121-12**: Ensure instructions work across all supported languages
- **FR-121-13**: Preserve persona-specific tone and engagement patterns

## Non-Functional Requirements

### Audio Quality
- **NFR-121-01**: Eliminate mispronunciation of common time formats
- **NFR-121-02**: Improve naturalness of number and date reading
- **NFR-121-03**: Maintain consistent audio quality across all personas
- **NFR-121-04**: Ensure compatibility with ElevenLabs text normalization

### Maintainability
- **NFR-121-05**: Use consistent formatting instructions across personas
- **NFR-121-06**: Make instructions easy to update and extend
- **NFR-121-07**: Preserve existing persona configuration structure
- **NFR-121-08**: Document audio formatting standards for future personas

## Technical Implementation

### 1. Centralized Audio Formatting Configuration

**File**: `assets/config/audio_formatting_config.json`

```json
{
  "audio_formatting_instructions": {
    "version": "1.0",
    "description": "TTS-optimized formatting instructions automatically applied to all personas",
    "content": "\n\n## TECHNICAL: AUDIO OUTPUT FORMATTING\n\n### Format Requirements (TTS Compatibility):\n\n**Time Format Standards:**\n- Use \"22:00\" format (not \"22h\")\n- Use \"14:30\" format (not \"14h30\")\n- Use \"6:00 AM\" format (not \"6am\")\n- Examples: \"às 22:00\", \"at 2:30 PM\", \"entre 14:00 e 15:30\"\n\n**Number Format Standards:**\n- Currency: \"R$ 1.500\", \"$1,500\"\n- Time duration: \"45 minutos\", \"45 minutes\"\n- Dates: \"15 de março\", \"March 15th\"\n\n**Avoid These Formats:**\n- Time abbreviations: 22h, 14h30, 6am, 10pm\n- Text symbols: **, -, •, &, %\n- Short abbreviations: min, seg, hrs\n\n**Technical Note:** These formatting requirements ensure optimal text-to-speech conversion. Maintain your natural communication style while using these standard formats."
  },
  "application_rules": {
    "auto_apply": true,
    "position": "append_to_system_prompt"
  }
}
```

### 2. Personas Configuration Enhancement

**File**: `assets/config/personas_config.json`

```json
{
  "defaultPersona": "iThereWithOracle30",
  "audioFormattingConfig": "assets/config/audio_formatting_config.json",
  "personas": {
    "ariWithOracle30": {
      "enabled": true,
      "displayName": "Aristos 3.0",
      "description": "Advanced Life Management Coach...",
      "configPath": "assets/config/ari_life_coach_config_2.0.json",
      "oracleConfigPath": "assets/config/oracle/oracle_prompt_v3.md",
      "audioFormatting": {
        "enabled": true
      }
    },
    "iThereWithOracle30": {
      "enabled": true,
      "displayName": "I-There 3.0", 
      "description": "AI reflection enhanced with Aristos 3.0...",
      "configPath": "assets/config/i_there_config.json",
      "oracleConfigPath": "assets/config/oracle/oracle_prompt_v3.md",
      "audioFormatting": {
        "enabled": true
      }
    }
  }
}
```

### 3. ConfigLoader Enhancement

**File**: `lib/config/character_config_manager.dart`

```dart
/// Load the system prompt for the active persona with configurable audio formatting
Future<String> loadSystemPrompt() async {
  try {
    // 1) Load Oracle prompt (existing logic)
    // ... existing Oracle loading logic ...

    // 2) Load persona prompt (existing logic)
    // ... existing persona loading logic ...

    // 3) NEW: Check if audio formatting is enabled for this persona
    String audioInstructions = '';
    try {
      // Load personas config to check audio formatting settings
      final String personasConfigString = await rootBundle.loadString(
        'assets/config/personas_config.json'
      );
      final Map<String, dynamic> personasConfig = json.decode(personasConfigString);
      
      // Get current persona's audio formatting settings
      final Map<String, dynamic>? personaData = personasConfig['personas'][_activePersonaKey];
      final Map<String, dynamic>? audioSettings = personaData?['audioFormatting'];
      
      if (audioSettings?['enabled'] == true) {
        // Load audio formatting config
        final String audioConfigPath = personasConfig['audioFormattingConfig'] ?? 
                                     'assets/config/audio_formatting_config.json';
        final String audioConfigString = await rootBundle.loadString(audioConfigPath);
        final Map<String, dynamic> audioConfig = json.decode(audioConfigString);
        
        audioInstructions = audioConfig['audio_formatting_instructions']['content'] as String;
      }
    } catch (audioError) {
      print('Audio formatting config not found or disabled: $audioError');
    }

    // 4) Compose: Oracle + Persona + Audio Instructions (if enabled)
    String finalPrompt = '';
    
    if (oraclePrompt != null && oraclePrompt.trim().isNotEmpty) {
      finalPrompt = '${oraclePrompt.trim()}\n\n${personaPrompt.trim()}';
    } else {
      finalPrompt = personaPrompt.trim();
    }
    
    // Append audio instructions if enabled for this persona
    if (audioInstructions.isNotEmpty) {
      finalPrompt = '$finalPrompt$audioInstructions';
    }
    
    return finalPrompt;
  } catch (e) {
    print('Error loading system prompt: $e');
    final displayName = await personaDisplayName;
    throw Exception('Failed to load system prompt for $displayName');
  }
}
```

### 4. Configuration Benefits

**Per-Persona Control**: Each persona can control audio formatting:

- ✅ **Enabled**: All current personas have audio formatting enabled
- ✅ **Disabled**: Future personas can opt-out if needed  
- ✅ **Configurable Path**: Can use different audio formatting configs per use case

**Key Benefits**:
- ✅ **Simple Control**: Enable/disable per persona
- ✅ **Centralized Rules**: Single audio formatting file
- ✅ **No Code Changes**: Pure configuration-based
- ✅ **Future-Proof**: New personas inherit settings automatically

### 5. Implementation Files

**Files to Create/Update:**
1. ✅ `assets/config/audio_formatting_config.json` (Created)
2. ✅ `assets/config/personas_config.json` (Updated with audioFormatting settings)
2. `assets/config/i_there_config.json`  
3. `assets/config/sergeant_oracle_config.json`

**Backup Strategy:**
- Create backup copies before modification
- Test each persona individually after updates
- Validate audio quality with test phrases

## Implementation Strategy

### Phase 1: Core Persona Updates (Day 1)
1. **Ari Life Coach Enhancement**
   - Add audio formatting section to config
   - Test with problematic phrases like "22h e 23h"
   - Validate Portuguese time pronunciation

2. **I-There Enhancement**
   - Add bilingual audio formatting instructions
   - Test English and Portuguese time formats
   - Ensure casual tone is preserved

### Phase 2: Sergeant Oracle & Validation (Day 2)
1. **Sergeant Oracle Enhancement**
   - Add high-energy audio formatting instructions
   - Test workout-related time and number formats
   - Maintain energetic personality

2. **Cross-Persona Testing**
   - Test same phrases across all personas
   - Validate consistent audio quality improvements
   - Check for personality preservation

### Phase 3: Refinement & Documentation (Day 3)
1. **Quality Assurance**
   - Test edge cases and complex formatting
   - Validate with real user scenarios
   - Monitor for any regression in persona behavior

2. **Documentation Update**
   - Update persona documentation with audio guidelines
   - Create audio formatting standards document
   - Document testing procedures for future personas

## Testing Strategy

### Test Phrases for Validation

**Portuguese Time Formats:**
```
"horário ideal para dormir: entre 22:00 e 23:00"
"acordar às 6:30 e exercitar por 45 minutos"
"reunião das 14:00 às 15:30 na segunda-feira"
```

**English Time Formats:**
```
"meeting at 2:30 PM, workout from 6:00 AM to 7:00 AM"
"schedule: wake up at 6:30 AM, work from 9:00 AM to 5:00 PM"
```

**Mixed Content:**
```
"meta: economizar R$ 1.500, exercitar 150 minutos por semana"
"goal: save $2,500, exercise 150 minutes weekly"
```

### Expected Results
- **Before**: "22h" → "vinte e dois ós"
- **After**: "22:00" → "vinte e duas horas"

### Validation Process
1. **Send test messages** to each persona
2. **Listen to audio responses** for natural pronunciation
3. **Compare before/after** audio quality
4. **Verify personality preservation** in responses

## Success Metrics

### Primary Success Criteria
- ✅ Elimination of "22h" → "22 ós" mispronunciation
- ✅ Natural pronunciation of all time formats
- ✅ Improved currency and number reading
- ✅ Consistent audio quality across personas
- ✅ Preservation of existing persona personalities

### Quality Metrics
- **Time Format Accuracy**: 100% correct pronunciation of "HH:MM" formats
- **Number Pronunciation**: Natural reading of currency and quantities
- **Personality Preservation**: No degradation in persona character
- **User Experience**: Improved audio naturalness and professionalism

## Risks & Mitigations

### Technical Risks
- **Risk**: Audio instructions might affect persona personality
  - **Mitigation**: Integrate instructions seamlessly, test personality preservation
- **Risk**: Instructions might be too verbose for system prompts
  - **Mitigation**: Use concise, focused formatting rules
- **Risk**: Different languages might need different approaches
  - **Mitigation**: Test both Portuguese and English extensively

### User Experience Risks
- **Risk**: Over-optimization might make responses sound unnatural
  - **Mitigation**: Focus on common problematic formats, maintain conversational flow
- **Risk**: Personas might become too rigid in formatting
  - **Mitigation**: Provide guidelines, not strict rules, allow natural variation

## Future Enhancements

### Immediate Follow-ups
- Monitor real-world usage for additional formatting issues
- Gather user feedback on audio quality improvements
- Refine instructions based on edge cases discovered

### Long-term Possibilities
- Automated audio formatting validation
- Dynamic formatting based on detected language
- Integration with advanced TTS preprocessing
- Extension to additional personas and languages

## Conclusion

This feature addresses the root cause of TTS pronunciation issues by instructing Claude to generate audio-friendly text from the source. By enhancing persona prompts with specific formatting guidelines, we ensure consistent, high-quality audio output while preserving each persona's unique personality and communication style.

The solution is more reliable than post-processing fixes and more maintainable than complex text transformation rules, providing immediate improvement in user audio experience across all personas.
