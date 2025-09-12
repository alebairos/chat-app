# Text Normalization Manual Testing Guide

## Overview
This guide provides specific test phrases to manually validate the ElevenLabs text normalization feature (FT-120). The feature improves how numbers, dates, times, and other structured content are pronounced in TTS audio.

## Testing Method
1. Chat with any persona in the app
2. Send messages containing the test phrases below
3. Listen to the TTS audio response
4. Compare the pronunciation quality

## Portuguese (pt_BR) Test Phrases

### Numbers
| Test Phrase | Expected Improvement |
|-------------|---------------------|
| "Preciso de 123 reais" | "cento e vinte e três reais" (not "um dois três") |
| "Comprei 50 livros" | "cinquenta livros" (not "cinco zero") |
| "Tenho 1.500 seguidores" | "mil e quinhentos seguidores" |
| "Ganhei R$ 2.750" | "dois mil setecentos e cinquenta reais" |
| "Perdi 15%" | "quinze por cento" (not "um cinco por cento") |

### Time Formats
| Test Phrase | Expected Improvement |
|-------------|---------------------|
| "Reunião às 14:30" | "quatorze horas e trinta minutos" (not "um quatro dois pontos três zero") |
| "Acordo às 7:15" | "sete horas e quinze minutos" |
| "Jantar às 19:45" | "dezenove horas e quarenta e cinco minutos" |
| "Exercício às 6:00" | "seis horas" |
| "Meditação às 23:30" | "vinte e três horas e trinta minutos" |

### Dates
| Test Phrase | Expected Improvement |
|-------------|---------------------|
| "Nasceu em 15/03/1990" | "quinze de março de mil novecentos e noventa" |
| "Evento em 2024-12-25" | "vinte e cinco de dezembro de dois mil e vinte e quatro" |
| "Prazo até 01/06/2025" | "primeiro de junho de dois mil e vinte e cinco" |
| "Formatura em 10/12/2023" | "dez de dezembro de dois mil e vinte e três" |

### Mixed Content
| Test Phrase | Expected Improvement |
|-------------|---------------------|
| "Exercitei 45 minutos às 6:30" | "quarenta e cinco minutos às seis horas e trinta minutos" |
| "Gastei R$ 150 em 3 livros" | "cento e cinquenta reais em três livros" |
| "Reunião dia 15/03 às 14:00" | "quinze de março às quatorze horas" |
| "Meta: 10.000 passos até 18:00" | "dez mil passos até dezoito horas" |

## English Test Phrases

### Numbers
| Test Phrase | Expected Improvement |
|-------------|---------------------|
| "I need $123 dollars" | "one hundred twenty-three dollars" (not "one two three") |
| "Bought 50 books" | "fifty books" (not "five zero") |
| "Have 1,500 followers" | "one thousand five hundred followers" |
| "Earned $2,750" | "two thousand seven hundred fifty dollars" |
| "Lost 15%" | "fifteen percent" (not "one five percent") |

### Time Formats
| Test Phrase | Expected Improvement |
|-------------|---------------------|
| "Meeting at 2:30 PM" | "two thirty PM" (not "two colon three zero PM") |
| "Wake up at 7:15 AM" | "seven fifteen AM" |
| "Dinner at 7:45 PM" | "seven forty-five PM" |
| "Exercise at 6:00 AM" | "six AM" |
| "Meditation at 11:30 PM" | "eleven thirty PM" |

### Dates
| Test Phrase | Expected Improvement |
|-------------|---------------------|
| "Born on 03/15/1990" | "March fifteenth, nineteen ninety" |
| "Event on 2024-12-25" | "December twenty-fifth, twenty twenty-four" |
| "Deadline 06/01/2025" | "June first, twenty twenty-five" |
| "Graduation 12/10/2023" | "December tenth, twenty twenty-three" |

### Mixed Content
| Test Phrase | Expected Improvement |
|-------------|---------------------|
| "Exercised 45 minutes at 6:30 AM" | "forty-five minutes at six thirty AM" |
| "Spent $150 on 3 books" | "one hundred fifty dollars on three books" |
| "Meeting on 03/15 at 2:00 PM" | "March fifteenth at two PM" |
| "Goal: 10,000 steps by 6:00 PM" | "ten thousand steps by six PM" |

## Testing Scenarios

### Scenario 1: Life Coaching Session (Ari)
**Test Message**: "Quero acordar às 6:30, exercitar por 45 minutos, e estar no trabalho às 8:00. Meta: 10.000 passos até 18:00."

**Expected Audio**: Natural pronunciation of all times and numbers instead of digit-by-digit reading.

### Scenario 2: Activity Tracking (I-There)
**Test Message**: "Today I exercised for 30 minutes at 7:15 AM, had lunch at 12:30 PM, and finished work at 5:45 PM."

**Expected Audio**: Smooth, conversational pronunciation of all time references.

### Scenario 3: Goal Setting (Sergeant Oracle)
**Test Message**: "Soldado! Meta para 2025: economizar R$ 12.000, ler 24 livros, e correr 500km até 31/12/2025!"

**Expected Audio**: Energetic but natural pronunciation of numbers and dates.

## Comparison Testing

### Before Text Normalization
- Numbers read digit by digit: "um dois três" instead of "cento e vinte e três"
- Times read literally: "um quatro dois pontos três zero" 
- Dates read as separate numbers: "dois zero dois quatro traço um dois traço dois cinco"

### After Text Normalization (Current)
- Numbers read naturally: "cento e vinte e três"
- Times read conversationally: "quatorze horas e trinta minutos" or "two thirty PM"
- Dates read properly: "vinte e cinco de dezembro de dois mil e vinte e quatro"

## Configuration Testing

### Test Different Modes
You can test different normalization modes by updating the persona configuration:

1. **Auto Mode** (default): ElevenLabs AI decides when to normalize
2. **On Mode**: Always normalize text
3. **Off Mode**: Never normalize (back to old behavior)

### Model Compatibility Testing
- Test with different ElevenLabs models
- Flash v2.5 and Turbo v2.5 automatically fall back to "auto" mode
- Other models support all three modes

## Expected Results

### Quality Improvements
- ✅ More natural, conversational audio
- ✅ Professional-sounding pronunciation
- ✅ Better user experience for numerical content
- ✅ Consistent pronunciation across languages

### Performance Notes
- Slight increase in TTS generation time (acceptable trade-off)
- No additional API calls required
- Works with all existing voice configurations

## Troubleshooting

### If Numbers Still Sound Robotic
1. Check that the persona is using ElevenLabs provider
2. Verify text normalization is set to "auto" or "on"
3. Ensure you're using a supported model (not Flash/Turbo v2.5 with "on" mode)

### If Feature Seems Inactive
1. Restart the app to ensure new configuration is loaded
2. Check debug logs for text normalization mode selection
3. Test with simple phrases first (e.g., "Meeting at 2:30")

## Debug Information

The feature logs its activity for debugging:
- Text normalization mode selection
- Model compatibility fallbacks
- Configuration updates

Look for logs like:
```
Text normalization: Using mode "auto" for model eleven_multilingual_v1
Text normalization: Fallback to "auto" for model eleven_flash_v2_5
```
