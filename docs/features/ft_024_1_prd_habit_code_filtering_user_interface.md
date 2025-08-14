# FT-024: Habit Code Filtering for User Interface

**Feature Type**: User Experience Enhancement  
**Priority**: High  
**Status**: Planning  
**Estimated Effort**: 1-2 hours  

## Problem Statement

The AI assistant is exposing internal habit tracking codes (e.g., "SF2", "SF3", "TG45", "E7") to users in conversational responses, creating a poor user experience. These codes are meant for internal system reference and data organization, not for user-facing communication.

### Current Problematic Behavior
```
Assistant Response: "How about starting with SF2 (prepare bedroom) and SF3 (relaxation ritual)?"
TTS Output: "How about starting with SF2 prepare bedroom and SF3 relaxation ritual?"
```

### Expected Behavior
```
Assistant Response: "How about starting with preparing your bedroom and doing a relaxation ritual?"
TTS Output: "How about starting with preparing your bedroom and doing a relaxation ritual?"
```

## Root Cause Analysis

### 1. **System Prompt Integration**
- The Oracle knowledge base contains habit codes for internal reference
- Claude is using these codes in conversational responses
- No filtering mechanism exists between AI response and user presentation

### 2. **Content Processing Pipeline**
- Current TTS preprocessing removes acronyms in parentheses but not standalone codes
- No semantic understanding of what constitutes internal vs. user-facing content
- Habit codes are treated as regular text content

### 3. **User Experience Impact**
- **Confusing**: Users don't understand what "SF2" or "TG45" means
- **Unprofessional**: Exposes internal system architecture
- **Cognitive Load**: Users must mentally filter out irrelevant technical information

## Solution Overview

Implement a **Habit Code Content Filter** that:

1. **Detects habit code patterns** in AI responses
2. **Extracts meaningful descriptions** from code-description pairs
3. **Replaces codes with natural language** before user presentation
4. **Preserves codes for explicit requests** when users ask for technical details

## Technical Requirements

### 1. Habit Code Pattern Detection

#### Pattern Recognition
- **Primary Pattern**: `[CODE] ([description])` → `CODE (description)`
- **Secondary Pattern**: `[CODE]` (standalone) → Remove or replace with context
- **Code Formats**: 
  - Physical: `SF1`, `SF2`, `ME1`, `GM1`
  - Mental: `SM1`, `SM2`, `E1`, `E7`
  - Work: `TG1`, `TG2`, `R1`, `R2`

#### Examples to Handle
```
Input: "Try SF2 (prepare bedroom) and E7 (meditation)"
Output: "Try preparing your bedroom and meditation"

Input: "Start with habit TG45 for better focus"
Output: "Start with a focus-building habit"

Input: "Complete exercise (SF1233) today"
Output: "Complete your exercise today"
```

### 2. Content Filtering Service

#### Core Functionality
```dart
class HabitCodeContentFilter {
  /// Filter habit codes from user-facing content
  static String filterHabitCodes(String content, {bool preserveOnRequest = false});
  
  /// Detect if user is explicitly asking for technical details
  static bool isRequestingTechnicalDetails(String userMessage);
  
  /// Extract description from code-description pairs
  static String extractDescription(String codeDescriptionPair);
}
```

#### Processing Rules
1. **Code-Description Pairs**: Extract description, remove code
2. **Standalone Codes**: Replace with generic description or remove
3. **User Requests**: Preserve codes when user asks for "habit IDs", "codes", or "technical details"
4. **Context Preservation**: Maintain sentence flow and meaning

### 3. Integration Points

#### TTS Preprocessing Pipeline
```dart
static String preprocessForTTS(String text, String language) {
  // 1. Filter habit codes (NEW)
  processedText = HabitCodeContentFilter.filterHabitCodes(processedText);
  
  // 2. Localize time formats (existing)
  processedText = TimeFormatLocalizer.localizeTimeFormats(processedText, language);
  
  // 3. Remove acronyms in parentheses (existing)
  processedText = _removeAcronymsInParentheses(processedText);
  
  // 4. Fix author-book list patterns (existing)
  processedText = _fixAuthorBookLists(processedText);
}
```

#### Claude Service Response Processing
```dart
Future<String> sendMessage(String message) async {
  // ... existing logic ...
  
  var assistantMessage = data['content'][0]['text'];
  
  // Filter habit codes unless user requested technical details
  final requestingTechnical = HabitCodeContentFilter.isRequestingTechnicalDetails(message);
  if (!requestingTechnical) {
    assistantMessage = HabitCodeContentFilter.filterHabitCodes(assistantMessage);
  }
  
  // ... continue with existing logic ...
}
```

## Filtering Rules and Examples

### 1. Code-Description Pattern Filtering

#### Rule: Extract Description, Remove Code
```
"SF2 (prepare bedroom)" → "prepare bedroom"
"TG45 (deep work session)" → "deep work session"
"E7 (meditation practice)" → "meditation practice"
```

#### Rule: Handle Multiple Codes
```
"Try SF2 (prepare bedroom) and SF3 (relaxation ritual)"
→ "Try preparing your bedroom and doing a relaxation ritual"
```

### 2. Standalone Code Filtering

#### Rule: Replace with Generic Description
```
"Complete SF2 today" → "Complete your preparation routine today"
"Start with TG45" → "Start with your work habit"
"Try E7 for relaxation" → "Try meditation for relaxation"
```

#### Rule: Context-Aware Replacement
```
Physical codes (SF*, ME*, GM*) → "your physical routine"
Mental codes (SM*, E*) → "your mental practice"
Work codes (TG*, R*) → "your work habit"
```

### 3. User Request Detection

#### Preserve Codes When User Asks For:
- "What are the habit codes?"
- "Show me the IDs"
- "What's the technical reference?"
- "Give me the habit numbers"
- Messages containing: "code", "ID", "reference", "technical"

#### Example Scenarios
```
User: "What habits should I do?"
Response: "Try preparing your bedroom and meditation" (codes filtered)

User: "What are the habit codes for sleep?"
Response: "Try SF2 (prepare bedroom) and SF3 (relaxation ritual)" (codes preserved)
```

## Implementation Strategy

### Phase 1: Core Filtering Service
1. Create `HabitCodeContentFilter` service
2. Implement pattern detection regex
3. Add description extraction logic
4. Create comprehensive test suite

### Phase 2: Integration
1. Integrate with TTS preprocessing pipeline
2. Add to Claude service response processing
3. Implement user request detection
4. Add configuration options

### Phase 3: Enhancement
1. Context-aware replacements
2. Smart description generation
3. Category-based filtering rules
4. Performance optimization

## Configuration Options

### Filtering Behavior
```json
{
  "habitCodeFiltering": {
    "enabled": true,
    "preserveOnExplicitRequest": true,
    "replacementStrategy": "description", // "description" | "generic" | "remove"
    "contextAwareReplacement": true
  }
}
```

### Pattern Definitions
```json
{
  "habitCodePatterns": {
    "codeDescriptionPattern": "([A-Z]{1,3}\\d+)\\s*\\([^)]+\\)",
    "standaloneCodePattern": "\\b([A-Z]{1,3}\\d+)\\b",
    "categoryMappings": {
      "SF": "physical routine",
      "ME": "exercise routine", 
      "GM": "muscle building routine",
      "SM": "mental practice",
      "E": "mindfulness practice",
      "TG": "work habit",
      "R": "relationship practice"
    }
  }
}
```

## Success Criteria

### Functional Requirements
- ✅ Habit codes removed from user-facing responses
- ✅ Descriptions preserved and made natural
- ✅ Codes shown when explicitly requested
- ✅ Sentence flow and meaning maintained

### User Experience Requirements
- ✅ Responses sound natural and conversational
- ✅ No technical jargon unless requested
- ✅ Clear, actionable guidance without confusion
- ✅ Professional, polished communication

### Technical Requirements
- ✅ Processing time impact < 10ms per message
- ✅ Backward compatibility maintained
- ✅ Configurable filtering behavior
- ✅ Comprehensive test coverage

## Testing Strategy

### Unit Tests
- Pattern detection accuracy
- Description extraction correctness
- User request detection
- Edge cases (malformed codes, mixed content)

### Integration Tests
- TTS pipeline integration
- Claude service integration
- End-to-end filtering behavior
- Performance impact measurement

### User Experience Tests
- Natural language flow validation
- Technical request handling
- Cross-language compatibility
- Audio quality verification

## Risk Assessment

### Technical Risks
- **Over-filtering**: Removing legitimate content that happens to match patterns
  - *Mitigation*: Precise regex patterns, extensive testing
- **Context Loss**: Losing important meaning when removing codes
  - *Mitigation*: Smart description extraction, context preservation

### User Experience Risks
- **Information Loss**: Users missing important technical details
  - *Mitigation*: Explicit request detection, configuration options
- **Inconsistent Behavior**: Different filtering in different contexts
  - *Mitigation*: Centralized filtering service, consistent rules

## Future Enhancements

### Advanced Features
- **AI-Powered Description Generation**: Use LLM to generate natural descriptions
- **Personalized Filtering**: User preferences for technical detail level
- **Context-Aware Intelligence**: Smarter detection of when codes are appropriate

### Internationalization
- **Multi-language Support**: Filtering rules for different languages
- **Cultural Adaptation**: Region-specific communication styles
- **Localized Descriptions**: Translated habit descriptions

## Dependencies

### Internal
- `TTSPreprocessingService` (integration point)
- `ClaudeService` (integration point)
- `Logger` utility (existing)

### External
- No new external dependencies required
- Uses existing Dart regex capabilities

## Acceptance Criteria

1. **Content Filtering**
   - [ ] Code-description pairs converted to natural language
   - [ ] Standalone codes replaced appropriately
   - [ ] Sentence flow preserved

2. **User Request Handling**
   - [ ] Technical requests detected accurately
   - [ ] Codes preserved when explicitly requested
   - [ ] Natural responses for general queries

3. **Integration Quality**
   - [ ] Seamless TTS pipeline integration
   - [ ] Claude service response processing
   - [ ] No performance degradation

4. **User Experience**
   - [ ] Professional, natural communication
   - [ ] No confusing technical jargon
   - [ ] Clear, actionable guidance

---

**Next Steps**: Implement Phase 1 - Core Filtering Service with pattern detection and description extraction capabilities.
