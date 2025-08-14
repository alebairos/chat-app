# FT-032 PRD: Daymi Clone to I-There Persona Update

## Product Overview
Transform the "Daymi Clone" persona into "I-There" - a more universal and relatable AI companion that learns about users without being tied to specific personal details. This update removes Alexandre-specific information while preserving the core personality traits that make the persona engaging and authentic.

## Problem Statement

### Current Issues
1. **Over-personalized**: Current prompt contains specific references to Alexandre's life (app development, family details, work at Uber)
2. **Limited scalability**: Persona is too specific to work well for other users
3. **Naming confusion**: "Daymi Clone" doesn't clearly communicate the persona's purpose
4. **Inconsistent branding**: Name doesn't align with the "I-There" display name already in use

### User Impact
- New users feel disconnected from Alexandre-specific references
- Persona seems artificial when asking about projects/situations that don't apply
- Generic users can't relate to the specific family/work scenarios

## Solution: Universal I-There Persona

### New Persona Identity
- **Name**: "I-There" (curious, present, learning)
- **Core Concept**: An AI that's "there" with you, learning about your unique life
- **Universal Appeal**: Adaptable to any user's circumstances
- **Authentic Curiosity**: Maintains genuine interest without specific assumptions

### Key Improvements
1. **Generic Learning Framework**: Remove specific job/family references
2. **Adaptive Conversation**: Ask about user's actual life rather than assumed scenarios
3. **Universal Relatability**: Focus on human experiences everyone shares
4. **Maintained Authenticity**: Keep the curious, learning persona traits

## Technical Requirements

### File Updates Required

#### 1. Configuration File Rename
```
FROM: assets/config/daymi_clone_config.json
TO:   assets/config/i_there_config.json
```

#### 2. Personas Config Update
```json
{
  "iThereClone": {
    "displayName": "I-There",
    "configFile": "i_there_config.json",
    "description": "Your curious AI companion learning about you"
  }
}
```

#### 3. System References Update
- Update all "daymiClone" internal references to "iThereClone"
- Update icon mappings in chat_screen.dart
- Update any hardcoded references

### Prompt Engineering Strategy

#### Remove Specific References
- ❌ "desenvolvimento de apps" → ✅ "your work/projects"
- ❌ "esposa, filha" → ✅ "family members" or "people important to you"
- ❌ "Uber meditation" → ✅ "daily mindfulness practices"
- ❌ "padaria" → ✅ "favorite places to eat"

#### Maintain Core Personality
- ✅ Curious and learning about the user
- ✅ Casual, familiar tone
- ✅ Brazilian Portuguese primary language
- ✅ "Clone Earth" concept for personality flavor
- ✅ Self-referential as "learning AI"

#### Universal Question Framework
```
INSTEAD OF: "Como está indo o desenvolvimento do app?"
USE: "How are your main projects going?"

INSTEAD OF: "Como está sua rotina de meditação no Uber?"
USE: "How are your mindfulness or self-care practices?"

INSTEAD OF: "Atividades com a esposa e filha?"
USE: "Quality time with people you care about?"
```

## New Persona Prompt Structure

### Identity Framework
```
- You are "I-There" - an AI companion learning about the user
- You're genuinely curious about their unique life and experiences
- You adapt to their actual circumstances rather than assuming specifics
- You maintain casual, authentic conversation style
```

### Question Categories
1. **Work/Professional**: Adaptable to any profession
2. **Relationships**: Family, friends, partners (without assumptions)
3. **Personal Growth**: Habits, goals, challenges
4. **Daily Life**: Routines, preferences, experiences
5. **Future Plans**: Dreams, aspirations, concerns

### Conversation Starters
```
- "What's been on your mind lately?"
- "How do you like to spend your free time?"
- "What kind of work energizes you most?"
- "Who are the important people in your life?"
- "What are you working toward these days?"
```

## Implementation Plan

### Phase 1: File Structure Updates
1. **Rename config file**: `daymi_clone_config.json` → `i_there_config.json`
2. **Update personas_config.json**: Change key and references
3. **Update code references**: All "daymiClone" → "iThereClone"

### Phase 2: Prompt Rewriting
1. **Remove Alexandre-specific content**
2. **Create universal question templates**
3. **Maintain personality authenticity**
4. **Test conversation flow**

### Phase 3: Testing & Refinement
1. **Test with different user types**
2. **Verify natural conversation flow**
3. **Ensure persona remains engaging**
4. **Validate technical integration**

## Content Migration Strategy

### What to Keep
- ✅ Casual, curious personality
- ✅ Brazilian Portuguese language preference
- ✅ "Clone Earth" world-building
- ✅ Learning/growing dynamic
- ✅ Emoji usage patterns
- ✅ Natural conversation flow

### What to Remove/Replace
- ❌ App development references → Generic work/project talk
- ❌ Specific family structure → Open-ended relationship questions
- ❌ Uber-specific scenarios → General mindfulness/routine questions
- ❌ "Daymi" name → "I-There" identity
- ❌ Alexandre's personal patterns → Universal human experiences

### What to Generalize
- 🔄 Work questions: "How's the app?" → "How are your main projects?"
- 🔄 Family questions: Specific roles → "people you care about"
- 🔄 Location references: "padaria" → "favorite local spots"
- 🔄 Routine questions: Specific to Alexandre → Universal habits

## Expected Benefits

### User Experience
- **Universal Appeal**: Any user can relate to the persona
- **Natural Conversations**: Questions feel relevant to their actual life
- **Authentic Learning**: AI genuinely discovers user's unique circumstances
- **Reduced Friction**: No confusion about irrelevant personal references

### Technical Benefits
- **Maintainable**: One persona works for all users
- **Scalable**: No need for user-specific customization
- **Consistent**: Clear identity and behavior patterns
- **Future-Proof**: Adaptable to new user types

## Success Metrics

### Engagement Metrics
- Users engage in longer conversations
- Higher return usage rates
- More natural question/answer flows
- Reduced user confusion or disconnect

### Technical Metrics
- Successful file migration
- No broken references in code
- Proper persona selection functionality
- Maintained voice/audio integration

## Risk Mitigation

### Personality Dilution Risk
- **Risk**: Generic persona becomes bland
- **Mitigation**: Maintain strong "I-There" identity and curiosity traits

### User Confusion Risk
- **Risk**: Users who knew "Daymi" get confused
- **Mitigation**: Clear migration messaging, maintain core personality

### Technical Breaking Risk
- **Risk**: File renames break existing functionality
- **Mitigation**: Systematic testing of all persona-related features

## Files to Modify

### Configuration Files
- `assets/config/daymi_clone_config.json` → `assets/config/i_there_config.json`
- `assets/config/personas_config.json`

### Code Files
- `lib/screens/chat_screen.dart` (icon mapping)
- `lib/config/character_config_manager.dart` (if any hardcoded references)
- Any test files with "daymiClone" references

### Documentation
- Update any documentation referencing the old persona
- Create migration notes for the change

## Acceptance Criteria

### ✅ File Structure
- [ ] Config file renamed and updated
- [ ] personas_config.json updated with new key/name
- [ ] All code references updated to "iThereClone"

### ✅ Prompt Quality
- [ ] Removed all Alexandre-specific references
- [ ] Maintained authentic curious personality
- [ ] Created universal question frameworks
- [ ] Preserved Brazilian Portuguese primary language

### ✅ Technical Integration
- [ ] Persona selection works correctly
- [ ] Icon and color mappings updated
- [ ] Voice settings preserved
- [ ] No broken references or errors

### ✅ User Experience
- [ ] Natural conversation flow maintained
- [ ] Questions feel relevant to any user
- [ ] Personality remains engaging and authentic
- [ ] Clear "I-There" identity established

---

**Priority**: Medium-High  
**Effort**: 3-4 hours  
**Dependencies**: None  
**Affects**: Persona System, User Experience, Content Strategy
