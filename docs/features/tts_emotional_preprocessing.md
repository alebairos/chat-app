# TTS Emotional Preprocessing Feature

## Overview

The TTS Emotional Preprocessing system enhances text-to-speech synthesis by intelligently processing character messages to remove formatting artifacts while preserving and utilizing emotional context for dynamic voice modulation.

## Problem Solved

**Before**: ElevenLabs TTS was reading formatting elements literally:
- `*adjusts helmet thoughtfully*` → "asterisk adjusts helmet thoughtfully asterisk"
- `**emphasis text**` → "asterisk asterisk emphasis text asterisk asterisk"
- `_special phrases_` → "underscore special phrases underscore"

**After**: Clean, natural speech with emotionally-aware voice modulation:
- Actions removed, emotions extracted for voice adjustment
- Emphasis preserved without formatting symbols
- Dynamic voice parameters based on emotional context

## Architecture

### Core Components

```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│ Original Text   │───▶│ TTSTextProcessor     │───▶│ Cleaned Text        │
│ with formatting │    │ - Remove actions     │    │ for TTS synthesis   │
└─────────────────┘    │ - Clean emphasis     │    └─────────────────────┘
                       │ - Normalize spaces   │                          
                       └──────────────────────┘                          
                                │                                         
                                ▼                                         
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│ Voice Settings  │◀───│ EmotionalToneMapper  │◀───│ Emotional Context   │
│ Adjustments     │    │ - Detect emotions    │    │ from actions        │
└─────────────────┘    │ - Map to parameters  │    └─────────────────────┘
                       └──────────────────────┘                          
```

### 1. **TTSTextProcessor** (`lib/features/audio_assistant/services/tts_text_processor.dart`)

**Purpose**: Cleans text for TTS synthesis while preserving important content.

**Key Methods**:
- `processForTTS(String text)` - Main processing pipeline
- `containsFormattingElements(String text)` - Detection utility

**Processing Steps**:
1. **Double Asterisk Handling**: Preserve `**emphasis**` → `emphasis`
2. **Action Removal**: Remove `*action descriptions*` 
3. **Single Asterisk Cleanup**: Clean remaining `*emphasis*` → `emphasis`
4. **Underscore Cleanup**: Clean `_special text_` → `special text`
5. **Whitespace Normalization**: Clean extra spaces

**Action Detection Logic**:
```dart
// Smart content analysis
bool _isActionDescription(String content) {
  // Portuguese actions
  final portugueseActions = [
    'ajusta', 'pensativamente', 'sorri', 'acena', 'suspira',
    'cruza', 'braços', 'inclina', 'cabeça', 'esperando'
  ];
  
  // English actions  
  final englishActions = [
    'strokes', 'chin', 'thoughtfully', 'chuckles', 'warmly',
    'leans', 'smirk', 'pats', 'shoulder', 'grins'
  ];
}
```

### 2. **EmotionalToneMapper** (`lib/features/audio_assistant/services/emotional_tone_mapper.dart`)

**Purpose**: Extracts emotional context and maps to voice parameters.

**Emotional Categories**:

| Emotion | Indicators | Voice Adjustments |
|---------|------------|-------------------|
| **Thoughtful** | `pensativamente`, `thoughtfully`, `strokes chin` | stability ↓20%, style +0.1 |
| **Warm** | `warmly`, `sorri`, `chuckles`, `pats shoulder` | similarity_boost +0.1, style +0.2 |
| **Playful** | `smirk`, `leans in`, `winks`, `grins` | stability ↓30%, style +0.3 |
| **Serious** | `seriously`, `sternly`, `firmly` | stability +0.2, style -0.1 |
| **Confident** | `confidently`, `boldly`, `proudly` | similarity_boost +0.15 |

**Voice Parameter Mapping**:
```dart
// Base parameters
{
  'stability': 0.5,        // How consistent the voice is
  'similarity_boost': 0.75, // How much like the character voice
  'style': 0.0,            // How expressive/dynamic
  'speaker_boost': true     // Clarity enhancement
}

// Emotional adjustments applied dynamically
// Parameters clamped to valid range [0.0, 1.0]
```

### 3. **ElevenLabsProvider Integration** (`lib/features/audio_assistant/services/eleven_labs_provider.dart`)

**Integration Flow**:
1. Extract emotional context before text processing
2. Process text to remove formatting
3. Apply emotional voice adjustments
4. Send to ElevenLabs with dynamic parameters

```dart
// Extract emotions first (before text cleaning)
final emotionalTone = EmotionalToneMapper.extractEmotionalTone(text);

// Clean text for TTS
final processedText = TTSTextProcessor.processForTTS(text);

// Apply emotional adjustments to voice settings
final voiceSettings = {
  'stability': emotionalTone['stability'] ?? defaultStability,
  'similarity_boost': emotionalTone['similarity_boost'] ?? defaultSimilarity,
  'style': emotionalTone['style'] ?? defaultStyle,
  'speaker_boost': emotionalTone['speaker_boost'] ?? defaultSpeaker,
};
```

## Language Support

### Portuguese (pt_BR)
- Action words: `ajusta`, `pensativamente`, `sorri`, `acena`, `suspira`, `cruza`, `braços`, `inclina`, `cabeça`
- Emotional mapping: `pensativamente` → thoughtful, `sorri` → warm

### English (en)
- Action words: `strokes`, `thoughtfully`, `chuckles`, `warmly`, `leans`, `smirk`, `pats`, `shoulder`
- Emotional mapping: `thoughtfully` → thoughtful, `chuckles` → warm, `smirk` → playful

## Testing Strategy

### Test Coverage
- **21 text processing tests** covering edge cases and language variations
- **11 emotional mapping tests** verifying emotion detection and parameter adjustments
- **Integration tests** ensuring proper workflow

### Key Test Scenarios
```dart
// Portuguese action removal
'*cruza os braços pensativamente*' → '' (removed, thoughtful emotion detected)

// English action removal  
'*leans in with a smirk*' → '' (removed, playful emotion detected)

// Emphasis preservation
'**important text**' → 'important text' (preserved)

// Mixed formatting
'*action* content **emphasis**' → 'content emphasis'
```

## Usage Examples

### Oracle Character Messages

**Input**:
```
🤔 *cruza os braços e inclina a cabeça, esperando sua pergunta* 
Como um verdadeiro legionário romano, **O conhecimento não tem fronteiras!** 
_sapientia_ é poder! 😊
```

**Processing**:
1. **Emotional Detection**: `thoughtful` (from "inclina a cabeça"), `warm` (from emoji context)
2. **Text Cleaning**: `Como um verdadeiro legionário romano, O conhecimento não tem fronteiras! sapientia é poder!`
3. **Voice Adjustment**: More contemplative + warmer tone

**Output**: Natural speech with thoughtful, warm delivery

## Performance Considerations

- **Regex Optimization**: Efficient pattern matching with minimal overhead
- **Parameter Caching**: Voice settings cached per emotion combination
- **Lazy Processing**: Only processes text containing formatting elements

## Debug Logging

```dart
// Text processing logs
'TTS Text Processing - Original length: 150, Processed length: 95'
'TTS Text Processing - Removed formatting elements from text'

// Emotional tone logs
'TTS Emotional Tone - detected emotions: thoughtful, warm'
'TTS Emotional Tone - Voice adjustments: {stability: 0.4, style: 0.3, ...}'
```

## Future Enhancements

1. **Emoji-Based Emotions**: Analyze emojis for additional emotional context
2. **Context Memory**: Remember character emotional state across messages
3. **Custom Voice Profiles**: Character-specific emotional parameter sets
4. **Real-time Adjustment**: Dynamic parameter tweaking based on conversation flow

## Configuration

### Adding New Languages
1. Add language-specific action words to detection arrays
2. Update emotional mapping indicators
3. Add corresponding test cases

### Adding New Emotions
1. Define emotion detection logic in `EmotionalToneMapper`
2. Add voice parameter mapping in `_mapEmotionsToVoiceParams`
3. Create comprehensive test coverage

### Voice Parameter Tuning
Adjust base parameters and emotional multipliers in `EmotionalToneMapper` based on character voice requirements and user feedback.

---

*Last Updated: January 2025*  
*Version: 1.0*  
*Contributors: AI Assistant* 