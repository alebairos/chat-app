# Audio Format Enhancement Proposal

## Problem
Persona responses contain formatting that doesn't translate well to TTS audio:
- "22h" → pronounced as "vinte e dois ós" instead of "vinte e duas horas"
- Mixed language preprocessing issues
- Symbols and abbreviations that sound awkward when spoken

## Solution: Enhanced Persona Prompts

### Add Audio Formatting Section to Each Persona

```markdown
## AUDIO RESPONSE FORMATTING

### CRITICAL: TTS-OPTIMIZED FORMATS
Your responses will be converted to audio. Use these EXACT formats:

**Portuguese Times & Numbers:**
- ✅ "às 22:00" → "às vinte e duas horas"
- ❌ "às 22h" → "às vinte e dois ós" (wrong!)
- ✅ "entre 22:00 e 23:00" 
- ❌ "entre 22h e 23h"
- ✅ "R$ 1.500" → "mil e quinhentos reais"
- ✅ "15 de março de 2024"

**English Times & Numbers:**
- ✅ "at 10:00 PM" → "at ten PM"
- ❌ "at 10pm" → unclear pronunciation
- ✅ "$1,500" → "one thousand five hundred dollars"
- ✅ "March 15th, 2024"

**Audio-Friendly Writing:**
- Avoid markdown symbols: **, -, •, #
- Use full words: "and" not "&"
- Write numbers that sound natural when spoken
- Consider speech rhythm and natural pauses
```

### Implementation Files to Update

1. **ari_life_coach_config_2.0.json** - Add after "REGRA CRÍTICA: TRANSPARÊNCIA ZERO"
2. **i_there_config.json** - Add after "CRITICAL BALANCE" 
3. **sergeant_oracle_config.json** - Add after "PERSONALITY BALANCE"

### Example: Ari Enhancement

```json
{
  "system_prompt": {
    "role": "system", 
    "content": "PERSONA OVERLAY: Ari - Life Coach\n\n[...existing content...]\n\n## AUDIO RESPONSE FORMATTING\n\n### CRITICAL: TTS-OPTIMIZED FORMATS\nYour responses will be converted to audio. Use these EXACT formats:\n\n**Portuguese Times:**\n- ✅ \"às 22:00\" (not \"22h\")\n- ✅ \"entre 22:00 e 23:00\" (not \"22h e 23h\")\n- ✅ \"das 6:00 às 7:00\" (not \"6h-7h\")\n\n**Numbers & Dates:**\n- ✅ \"R$ 1.500\" → natural currency reading\n- ✅ \"15 de março de 2024\" → natural date reading\n- ✅ \"50 minutos\" → \"cinquenta minutos\"\n\n**Audio-Friendly Writing:**\n- Avoid markdown: **, -, •, # (sounds awkward)\n- Use full words: \"e\" not \"&\"\n- Write for speech, not text\n- Consider natural speaking rhythm\n\nMensagem de boas-vindas: 'O que precisa de ajuste primeiro?'"
  }
}
```

## Benefits

1. **Immediate Fix**: Solves "22h" → "22 ós" problem
2. **Consistent Quality**: All personas produce audio-friendly text
3. **Better UX**: More natural, professional-sounding TTS
4. **Future-Proof**: Works with ElevenLabs text normalization

## Implementation Priority

**High Priority Updates:**
1. Ari Life Coach (most used for time/schedule discussions)
2. I-There (general conversation)  
3. Sergeant Oracle (fitness schedules and goals)

**Test Cases After Implementation:**
- "horário ideal: entre 22:00 e 23:00" → should sound natural
- "economizar R$ 1.500 por mês" → proper currency pronunciation
- "reunião às 14:30 na segunda-feira" → natural time/date reading

This approach fixes the root cause by instructing Claude to generate audio-friendly text from the start, rather than trying to fix it in post-processing.
