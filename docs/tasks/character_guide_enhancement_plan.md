# Character Guide Enhancement Plan

## Overview

This document outlines a comprehensive plan to enhance the character guides in the chat app, focusing on personality refinement and voice optimization. This plan integrates with the existing audio assistant implementation while addressing specific issues related to character identity, consistency, and voice quality.

## Current Status Assessment

### Character Guides
1. **Sergeant Oracle**: Roman military time-traveler with ancient wisdom and futuristic insights
   - Recently updated from habit specialist to general-purpose assistant
   - Voice configuration exists but uses generic voice ID

2. **The Zen Master**: Enlightened guide inspired by Lao Tzu and Buddhist zen tradition
   - Recently updated from "The Zen Guide" habit specialist
   - Voice configuration exists but uses generic voice ID

3. **Personal Development Assistant**: Focused on helping users achieve goals
   - Still configured as a habit specialist with MCP database dependency
   - No specific voice configuration exists

### Identified Issues

1. **Voice Configuration Issues**:
   - All characters use the same generic voice ID (`pNInz6obpgDQGcFmaJgB`)
   - Voice parameters are configured but not fully optimized for character personalities
   - No distinct voice for Personal Development Assistant
   - Name mismatch in voice config (uses "Guide Sergeant Oracle" instead of "Sergeant Oracle")

2. **Personality Consistency Issues**:
   - Personal Development Assistant still restricted to habit specialist role
   - System prompts need review for consistent formatting and capabilities
   - Personality traits need stronger differentiation

3. **Integration Issues**:
   - Character selection UI needs refinement
   - Voice application during character switching needs validation
   - Documentation of character guide system is incomplete

## Enhancement Plan

### Phase 1: Voice Configuration Enhancements

#### Task 1.1: Research and Select Character-Specific Voice IDs
- Research ElevenLabs voice catalog for appropriate character voices
- Select specific voice IDs for each character:
  - Military authoritative voice for Sergeant Oracle
  - Calm, contemplative voice for The Zen Master
  - Friendly, supportive voice for Personal Development Assistant
- Test selected voices with sample character dialogue

#### Task 1.2: Update Character Voice Configuration
- Update `character_voice_config.dart` with new voice IDs
- Fix the name mismatch (change "Guide Sergeant Oracle" to "Sergeant Oracle")
- Add specific voice configuration for Personal Development Assistant
- Optimize voice parameters for each character's personality
- Create test cases to validate voice configuration changes

```dart
// Example configuration update
static const Map<String, Map<String, dynamic>> _characterVoices = {
  'Sergeant Oracle': {
    'voiceId': 'military_voice_id', // Replace with actual ID
    'modelId': 'eleven_multilingual_v1',
    'stability': 0.75,
    'similarityBoost': 0.85,
    'style': 0.3,
    'speakerBoost': true,
    'description': 'Authoritative military sergeant voice',
  },
  'The Zen Master': {
    'voiceId': 'contemplative_voice_id', // Replace with actual ID
    'modelId': 'eleven_multilingual_v1',
    'stability': 0.85,
    'similarityBoost': 0.75,
    'style': 0.0,
    'speakerBoost': true,
    'description': 'Serene zen master voice',
  },
  'Personal Development Assistant': {
    'voiceId': 'supportive_voice_id', // Replace with actual ID
    'modelId': 'eleven_multilingual_v1',
    'stability': 0.7,
    'similarityBoost': 0.8,
    'style': 0.1,
    'speakerBoost': true,
    'description': 'Supportive coaching voice',
  },
  'default': {
    'voiceId': 'pNInz6obpgDQGcFmaJgB',
    'modelId': 'eleven_multilingual_v1',
    'stability': 0.6,
    'similarityBoost': 0.8,
    'style': 0.0,
    'speakerBoost': true,
    'description': 'Standard assistant voice',
  },
};
```

### Phase 2: Character Personality Refinements

#### Task 2.1: Update Personal Development Assistant
- Revise `claude_config.json` to make Personal Development Assistant a general-purpose assistant
- Remove restrictions to MCP database dependency
- Maintain empathetic, supportive personality traits
- Add formatting guidelines consistent with other characters

#### Task 2.2: Review and Enhance All Character Prompts
- Ensure consistent formatting instructions across all characters
- Add standardized response structures for better user experience
- Enhance personality traits and speaking styles for clear differentiation
- Validate prompts with test conversations

#### Task 2.3: Character Response Style Guide
- Create a comprehensive style guide for each character
- Document voice, tone, language patterns, and formatting for each character
- Create examples of responses to common queries for each character
- Implement character-specific welcome messages and help responses

### Phase 3: Technical Integration

#### Task 3.1: Character Selection Flow Enhancement
- Update character selection UI to display distinctive character traits
- Add character preview functionality in the selection screen
- Implement proper voice application when switching characters
- Add transition effects when changing characters

#### Task 3.2: Voice Configuration Testing
- Create comprehensive tests for voice configuration application
- Test voice switching during character changes
- Verify error handling when voice application fails
- Document expected voice behavior for each character

#### Task 3.3: Character Persistence
- Ensure character selection is properly persisted between sessions
- Implement proper loading of character voice configuration on app start
- Add logging to track character voice application
- Create recovery paths for voice configuration failures

### Phase 4: Documentation and Quality Assurance

#### Task 4.1: Update Documentation
- Create comprehensive character guide documentation
- Document voice configurations and character personalities
- Update README with character guide information
- Add troubleshooting guides for voice issues

#### Task 4.2: Quality Assurance
- Create test matrix for all character configurations
- Test character responses across common scenarios
- Validate voice quality and appropriateness for each character
- Test edge cases and error recovery

## Integration with Existing Tasks

This character enhancement plan should be integrated with the existing audio assistant implementation tasks:

1. **Task 2: Claude Service TTS Implementation**
   - Ensure TTS implementation properly handles character-specific voice configurations
   - Add character voice testing to TTS test suite

2. **Task 4: Chat Screen Integration**
   - Update chat screen to display character-specific UI elements
   - Implement character switching with proper voice transition

3. **Task 5: End-to-End Testing**
   - Add character guide specific test scenarios
   - Test voice quality and appropriateness in real conversations

4. **Task 6: Error Handling**
   - Add specific error handling for character voice application failures
   - Implement graceful fallbacks for voice configuration issues

## Testing Strategy

### Unit Tests
- Test character voice configuration loading
- Test TTS service with different character configurations
- Test character switching with proper voice application

### Integration Tests
- Test end-to-end character selection flow
- Test voice application during character switching
- Test response formatting for each character

### Performance Tests
- Measure voice configuration application time
- Test voice generation performance for each character
- Evaluate memory usage during character switching

## Success Criteria

1. Each character has a unique, appropriate voice ID and optimized voice parameters
2. All three characters function as general-purpose assistants with distinct personalities
3. Character switching properly applies the correct voice configuration
4. All tests pass with the enhanced character system
5. Documentation is complete and accurate

## Next Steps

1. Begin with Phase 1: Voice Configuration Enhancements
2. Integrate with existing Task 2: Claude Service TTS Implementation
3. Proceed to Phase 2: Character Personality Refinements
4. Continue with remaining phases in parallel with existing tasks

## Estimated Timeline

- Phase 1: 2-3 days
- Phase 2: 3-4 days
- Phase 3: 2-3 days
- Phase 4: 1-2 days

Total estimated time: 8-12 days, with potential overlap between phases and existing tasks. 