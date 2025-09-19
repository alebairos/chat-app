# Oracle 4.0 Analysis - Issues and LLM Input Parameters

**Feature ID**: FT-Oracle-4.0-Analysis  
**Date**: September 18, 2025  
**Status**: Investigation Complete  
**Priority**: High  

## Overview

Comprehensive analysis of Oracle 4.0 implementation issues and complete documentation of LLM input parameter flow for personas.

## 🔍 Oracle 4.0 Critical Issues Identified

### Issue 1: Rate Limit Exceeded (429 Errors) ❌

**Root Cause**: Oracle 4.0 has **75% more content** than 3.0:
- **Oracle 3.0**: 64 activities, ~1,210 lines
- **Oracle 4.0**: 112 activities, ~2,813 lines

**Impact**: 
- Larger system prompts consume more tokens per API call
- Two-pass processing (FT-084) makes **2 API calls per user message**
- Rate limit: **8 calls per minute** (claude_service.dart:21)
- **Math**: 4 user messages × 2 calls = 8 calls = rate limit hit

**Evidence from logs**:
```
flutter: ❌ [ERROR] FT-084: Error in two-pass processing: Exception: Claude API error: 429
```

### Issue 2: Internal Notes Exposed to Users ❌

**Root Cause**: Oracle 4.0's larger context is causing the AI to include **internal reasoning** in responses.

**Evidence from logs**:
```
[Nota: Aqui registraríamos: SF1 (água) e outros hábitos relevantes]
[Nota: Aguardando confirmação do sistema antes de prosseguir com feedback]
```

**Why this happens**: The larger Oracle 4.0 context may contain examples or patterns that include internal notes, causing the AI to mimic this behavior.

### Issue 3: Wrong Time Context ("Starting the Day" at 14:10 PM) ❌

**Root Cause**: Oracle 4.0's expanded content is **overriding** the system's time-awareness instructions.

**System has correct time awareness** (claude_service.dart:633-635):
```dart
'- Afternoon queries (12-18h): "Hoje pela manhã você fez... E à tarde?", "Como vai o restante do dia?"'
```

**But Oracle 4.0 context** is dominating the response, causing inappropriate "starting the day" language at 14:10 PM.

**Evidence from logs**:
```
flutter: ℹ️ [INFO]   🕐 Time: 14:10:25 (afternoon)  // ✅ Correct time detected
flutter: 🔍 [DEBUG] Original AI response: Como está se sentindo para começar o dia?  // ❌ Wrong context
```

### Comparison: Oracle 3.0 vs 4.0

| Aspect | Oracle 3.0 | Oracle 4.0 | Impact |
|--------|-------------|-------------|---------|
| **Size** | 64 activities, 1,210 lines | 112 activities, 2,813 lines | +75% larger context |
| **Rate Limits** | ✅ Rarely hits limits | ❌ Frequent 429 errors | API overload |
| **Time Awareness** | ✅ Respects system time context | ❌ Overrides with generic responses | Poor UX |
| **Internal Notes** | ✅ Clean responses | ❌ Exposes reasoning notes | Confusing to users |

## 📋 Complete LLM Input Parameters Flow for Personas

### 🔄 Persona Switching Flow

**User Actions to Switch Personas:**
1. **Profile Screen** → Tap current persona → `PersonaSelectionScreen`
2. **Character Selection Screen** → Choose persona → Continue button
3. **Settings** → Persona selection (alternative path)

**When Switch Occurs:**
```dart
// Line 158 in persona_selection_screen.dart
_configLoader.setActivePersona(_selectedPersonaKey);
```

### 🏗️ System Prompt Construction Pipeline

#### Step 1: Persona Configuration Loading
```dart
// Line 210 in claude_service.dart - EVERY message triggers reload
_systemPrompt = await _configLoader.loadSystemPrompt();
```

#### Step 2: Multi-Layer Prompt Assembly
**Location**: `character_config_manager.dart` lines 134-230

**Assembly Order:**
1. **Oracle Prompt** (if configured)
2. **Persona Base Prompt** 
3. **Audio Formatting Instructions** (if enabled)
4. **Time Context** (dynamic)
5. **MCP Function Documentation** (dynamic)

```dart
// Final composition (line 213)
if (oraclePrompt != null && oraclePrompt.trim().isNotEmpty) {
  finalPrompt = '${oraclePrompt.trim()}\n\n${personaPrompt.trim()}';
}
```

### 📊 Oracle Version Mapping

| Persona Key | Display Name | Oracle Version | Oracle Path |
|-------------|--------------|----------------|-------------|
| `ariWithOracle21` | "Ari 2.1" | Oracle 2.1 | `oracle_prompt_2.1.md` |
| `ariWithOracle30` | "Aristios 3.0" | Oracle 3.0 | `oracle_prompt_3.0.md` |
| `ariWithOracle40` | "Aristios 4.0" | Oracle 4.0 | `oracle_prompt_4.0.md` |
| `iThereWithOracle30` | "I-There 3.0" | Oracle 3.0 | `oracle_prompt_3.0.md` |
| `iThereWithOracle40` | "I-There 4.0" | Oracle 4.0 | `oracle_prompt_4.0.md` |
| `sergeantOracleWithOracle30` | "Sergeant Oracle 3.0" | Oracle 3.0 | `oracle_prompt_3.0.md` |
| `sergeantOracleWithOracle40` | "Sergeant Oracle 4.0" | Oracle 4.0 | `oracle_prompt_4.0.md` |

**Default Persona**: `iThereWithOracle40` (line 2 in personas_config.json)

### 🎯 Final LLM API Call Structure

**Location**: `claude_service.dart` lines 268-283

```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user", 
      "content": [{"type": "text", "text": "user message"}]
    }
  ],
  "system": "COMPLETE_SYSTEM_PROMPT"
}
```

### 📝 Complete System Prompt Structure

**For Aristios 3.0:**
```
[TIME CONTEXT - Dynamic]
Current time: Thursday at 2:10 PM (afternoon)
Time gap: same session

[ORACLE 3.0 PROMPT - 1,210 lines]
## SISTEMA DE COMANDO MCP - ACTIVITY TRACKING
[64 activities, 5 dimensions]
...

[PERSONA BASE PROMPT]
Você é um Life Management Coach...

[AUDIO FORMATTING - If enabled]
Audio response instructions...

[MCP FUNCTIONS - Dynamic]
System Functions Available:
- get_current_time
- get_activity_stats
...
```

**For Aristios 4.0:**
```
[TIME CONTEXT - Dynamic]
Current time: Thursday at 2:10 PM (afternoon)

[ORACLE 4.0 PROMPT - 2,813 lines]  ⚠️ 75% LARGER
## SISTEMA DE COMANDO MCP - ACTIVITY TRACKING
[112 activities, 5 dimensions]
...

[PERSONA BASE PROMPT]
Você é um Life Management Coach...

[AUDIO FORMATTING - If enabled]
Audio response instructions...

[MCP FUNCTIONS - Dynamic]
System Functions Available:
...
```

### ⚡ When Oracle Versions Are Called

**Oracle 3.0 Triggered When:**
- User selects: "Aristios 3.0", "I-There 3.0", or "Sergeant Oracle 3.0"
- System loads: `oracle_prompt_3.0.md` (1,210 lines, 64 activities)

**Oracle 4.0 Triggered When:**
- User selects: "Aristios 4.0", "I-There 4.0", or "Sergeant Oracle 4.0" 
- System loads: `oracle_prompt_4.0.md` (2,813 lines, 112 activities)
- **Default behavior** (since `iThereWithOracle40` is default)

### 🔄 Dynamic Context Addition

**Every Message Adds:**
1. **Time Context** (FT-060) - Current time, day, session gap
2. **MCP Functions** (FT-095) - Available system commands
3. **Conversation History** - Previous messages in thread

**Two-Pass Processing (FT-084):**
- **Pass 1**: Initial response with MCP commands
- **Pass 2**: Data-enriched response (causes rate limiting with Oracle 4.0)

### 📊 Token Impact Comparison

| Component | Oracle 3.0 | Oracle 4.0 | Impact |
|-----------|-------------|-------------|---------|
| **Oracle Content** | ~3,000 tokens | ~5,250 tokens | +75% |
| **Base Persona** | ~500 tokens | ~500 tokens | Same |
| **Dynamic Context** | ~800 tokens | ~800 tokens | Same |
| **Total System Prompt** | ~4,300 tokens | ~6,550 tokens | **+52%** |

This explains why Oracle 4.0 hits rate limits faster - each API call consumes significantly more tokens.

## 🛠️ Recommended Solutions

### Immediate Actions
1. **Rate Limiting**: Increase delay between API calls from 500ms to 1000ms
2. **Internal Notes**: Clean Oracle 4.0 prompt to remove internal reasoning examples  
3. **Time Context**: Strengthen time-awareness instructions to override Oracle context
4. **Consider**: Temporarily revert default persona to Oracle 3.0 until issues are resolved

### Long-term Solutions
1. **Oracle 4.0 Optimization**: Reduce content size while maintaining functionality
2. **Smart Context Loading**: Load only relevant Oracle sections based on user context
3. **Rate Limit Management**: Implement adaptive rate limiting based on prompt size
4. **Response Filtering**: Add post-processing to remove internal notes from responses

## Technical Implementation Details

### Key Files Involved
- `lib/config/character_config_manager.dart` - Prompt assembly
- `lib/services/claude_service.dart` - API calls and rate limiting
- `assets/config/personas_config.json` - Persona configuration
- `assets/config/oracle/oracle_prompt_4.0.md` - Oracle 4.0 content
- `lib/services/oracle_context_manager.dart` - Oracle loading

### Rate Limiting Configuration
- **Current Limit**: 8 calls per minute (`claude_service.dart:21`)
- **Current Delay**: 500ms between calls (`claude_service.dart:460`)
- **Two-Pass Processing**: Doubles API call frequency

### Database Connection Management
The analysis also revealed that activity detection **IS working** but there are database connection management issues that need to be addressed separately. Activities are being detected and stored successfully, but the `logActivity()` method logs show "null" descriptions due to missing field assignments.

## Conclusion

Oracle 4.0 introduces significant behavioral regressions that affect core user experience. The 75% increase in content size causes rate limiting issues, while the expanded context overrides system instructions for time awareness and exposes internal reasoning notes to users. Immediate mitigation is recommended while long-term optimization is planned.
