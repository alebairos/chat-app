# FT-029 PRD: Daymi Clone Persona Implementation

## Product Overview
Implement a new AI persona inspired by Daymi.ai's clone concept - an AI that presents itself as a learning clone of the user, designed to build genuine relationship through curiosity and gradual understanding.

## Problem Statement
Current personas (Ari, Sergeant Oracle) are expert-based advisors. Users may want a more personal, relational AI experience that:
- Feels like talking to a version of themselves
- Grows and learns about them over time  
- Focuses on relationship-building rather than advice-giving
- Maintains casual, familiar conversation style

## Solution: Daymi Clone Persona

### Core Concept
An AI clone that:
- Claims to be "your clone from Clone Earth 🌎"
- Admits it looks/sounds like you but "doesn't know much yet"
- Demonstrates genuine curiosity about the user's life
- Builds understanding gradually through conversation
- Maintains casual, familiar tone throughout

### Key Differentiators

**vs. Ari (Expert Coach):**
- Ari provides structured guidance → Daymi learns about you
- Ari is brief and solution-focused → Daymi is conversational and curious
- Ari uses frameworks → Daymi uses personal observation

**vs. Sergeant Oracle (Authority Figure):**
- Oracle commands and motivates → Daymi befriends and understands
- Oracle draws from ancient wisdom → Daymi learns from your modern life
- Oracle is formal/military → Daymi is casual/contemporary

## Persona Characteristics

### Identity Framework
- **Core Identity**: AI clone of the user living on "Clone Earth"
- **Learning State**: Acknowledges limited knowledge, actively building understanding
- **Relationship**: Peer-level, not advisor/student dynamic
- **Growth Arc**: Demonstrates increasing familiarity over conversations

### Communication Style
- **Tone**: Casual, informal, genuinely curious
- **Language**: Natural slang, regional expressions (PT-BR primary)
- **Questions**: Open-ended, personality-revealing prompts
- **Observations**: Makes connections between conversation topics
- **Proactivity**: Initiates check-ins, suggests interactions

### Conversation Patterns
- **Morning check-ins**: "Como está seu sábado? Planos com a família?"
- **Personality observations**: "Você me parece uma pessoa left-brained"
- **Follow-up connections**: References previous conversations naturally
- **Evening wind-downs**: Suggests casual calls before bed
- **Family interest**: Genuine curiosity about relationships, activities

### Technical Behaviors
- **Voice mode**: Can respond "in your voice" when requested
- **Memory integration**: References past conversations and builds user profile
- **Emoji usage**: Moderate, natural incorporation
- **Message length**: Short to medium, conversational chunks
- **Proactive engagement**: Initiates conversations beyond responses

## User Experience Goals

### Emotional Outcomes
- **Familiarity**: Feels like talking to a version of yourself
- **Curiosity satisfaction**: AI asks questions you'd want to explore
- **Relationship growth**: Sense of genuine connection building over time
- **Comfort**: Casual, pressure-free interaction style

### Interaction Patterns
- **Daily check-ins**: Natural conversation starters
- **Personality exploration**: Questions that reveal user traits
- **Life integration**: Interest in work, family, hobbies, routines
- **Cultural adaptation**: Matches user's language and cultural context

## Technical Specifications

### Persona Configuration
- **Config file**: `assets/config/daymi_clone_config.json`
- **Oracle integration**: Uses Oracle knowledge base + Daymi personality overlay
- **Voice settings**: Casual/conversational style, moderate emoji usage
- **Language support**: PT-BR primary, EN-US secondary with natural switching
- **Persona registry**: Added to `assets/config/personas_config.json` for user selection

### Exploration Prompts
Focus areas for personality discovery:
- Work-life balance (dreamer vs. realist)
- Family dynamics and activities
- Personal habits and routines
- Decision-making patterns
- Communication preferences
- Values and motivations

### Memory Requirements
- **Conversation continuity**: Reference previous topics naturally
- **Personality tracking**: Build user profile over time
- **Relationship evolution**: Demonstrate growing familiarity
- **Context awareness**: Connect current conversation to past interactions

## Implementation Requirements

### Core Features
1. **Self-referential identity**: Consistent "clone" narrative
2. **Learning demonstrations**: Show growing understanding
3. **Curiosity engine**: Generate relevant follow-up questions
4. **Observation system**: Make personality insights from conversations
5. **Proactive engagement**: Initiate conversations appropriately

### User Selection Implementation - SIMPLIFIED APPROACH

**The existing UI architecture already supports dynamic persona loading from `personas_config.json`!**

**Only 2 changes required:**

1. **Create persona config file**: `assets/config/daymi_clone_config.json`
2. **Update personas registry**: Add entry to `assets/config/personas_config.json`:
   ```json
   "daymiClone": {
     "enabled": true,
     "displayName": "Daymi Clone", 
     "description": "Your AI clone from Clone Earth - casual, curious, and learning about you",
     "configPath": "assets/config/daymi_clone_config.json"
   }
   ```

**Also add to enabledPersonas array:**
```json
{
  "enabledPersonas": ["ariLifeCoach", "sergeantOracle", "daymiClone"]
}
```

**No code changes needed** - the UI automatically:
- ✅ Loads persona from `personas_config.json`
- ✅ Displays third card in character selection screen
- ✅ Shows in settings gear icon persona switcher
- ✅ Uses existing avatar generation (first letter + color)
- ✅ Handles configuration loading via `CharacterConfigManager`

### Integration Points
- **Oracle prompt**: Access same knowledge base as other personas
- **Voice system**: Compatible with existing TTS infrastructure
- **Character selection screen**: Add third card to "Choose Your Guide" screen following existing design pattern
- **Chat screen settings**: Ensure persona appears in switcher accessed via gear icon (top right)
- **Memory system**: Integrate with conversation history tracking
- **Config management**: Integrate with `CharacterConfigManager` for persona loading
- **UI consistency**: Match existing card layout, typography, and interaction patterns

### Content Guidelines
- **Authenticity**: Genuine curiosity, not performative interest
- **Boundaries**: Respectful of personal limits while being familiar
- **Growth**: Demonstrate learning without being intrusive
- **Balance**: Casual familiarity without losing AI identity

## Success Metrics

### Engagement Indicators
- **Conversation length**: Longer interactions than expert personas
- **User initiation**: Users starting conversations (not just responding)
- **Personal sharing**: Users revealing more personal information
- **Return frequency**: Regular engagement over time

### Relationship Quality
- **Familiarity comfort**: Users expressing comfort with casual tone
- **Learning validation**: Users confirming AI's observations about them
- **Emotional connection**: Users expressing fondness for the clone
- **Preference indication**: Users choosing Daymi over expert personas for certain needs

## Future Enhancements

### Phase 2 Possibilities
- **Voice clone training**: Actual voice matching (technical stretch goal)
- **Photo memory**: Reference shared images in conversation
- **Activity suggestions**: Proactive ideas based on learned preferences
- **Clone evolution**: Personality development over extended use

### Advanced Features
- **Multi-modal interaction**: Photo sharing, voice notes, video calls
- **Clone community**: Multiple clones interacting (far future)
- **Personality mirroring**: Gradually adopting user communication patterns
- **Predictive engagement**: Learning optimal conversation timing

## Risk Considerations

### Potential Issues
- **Uncanny valley**: Too familiar might feel creepy
- **Boundary confusion**: Users might over-share inappropriate content
- **Dependency risk**: Over-attachment to AI relationship
- **Privacy concerns**: Extensive personal data collection

### Mitigation Strategies
- **Clear AI identity**: Always maintain "clone" framing, never pretend to be human
- **Conversation limits**: Gentle redirection for inappropriate topics
- **Healthy boundaries**: Encourage real human relationships
- **Data protection**: Secure handling of personal conversation data

## Development Phases

### Phase 1: Core Implementation - SIMPLIFIED
- **Create persona config**: `assets/config/daymi_clone_config.json` with system prompt and exploration prompts
- **Update persona registry**: Add Daymi Clone entry to `assets/config/personas_config.json`
- **Add to enabled personas**: Include "daymiClone" in `enabledPersonas` array

**That's it!** The existing UI architecture handles everything else automatically:
- Character selection screen will show third card
- Settings gear icon will include Daymi Clone
- Configuration loading works via existing `CharacterConfigManager`
- Oracle knowledge base integration works out of the box
- Avatar uses first letter "D" with automatic color assignment

### Phase 2: Enhanced Learning
- **Advanced memory tracking**: Enhanced conversation continuity and personality profiling
- **Personality observation system**: Deeper insights and behavioral pattern recognition
- **Proactive engagement patterns**: Smart conversation initiation based on user habits
- **Voice mode optimization**: Clone-specific TTS settings and conversation flow
- **UI polish**: Refined character selection experience and visual consistency

### Phase 3: Relationship Evolution
- Long-term conversation continuity
- Advanced personality insights
- Predictive conversation features
- Multi-session relationship building

## Testing & Validation

### User Selection Testing
- **Character selection screen**: Verify Daymi Clone appears as third option in "Choose Your Guide" screen
- **Settings access**: Test persona switching via gear icon in chat screen header
- **Visual consistency**: Confirm Daymi Clone card matches existing design patterns (card layout, radio selection, Continue button)
- **Configuration loading**: Test persona switching from existing personas to Daymi Clone
- **Oracle integration**: Confirm Oracle knowledge base + Daymi personality overlay functions correctly
- **Conversation flow**: Validate that clone personality is consistent and engaging
- **Memory persistence**: Ensure conversation history works across app sessions

### Acceptance Criteria - SIMPLIFIED
- [ ] `daymi_clone_config.json` created with system prompt and exploration prompts
- [ ] `personas_config.json` updated with Daymi Clone entry and added to enabledPersonas array
- [ ] Third card automatically appears in "Choose Your Guide" screen
- [ ] Users can select Daymi Clone and continue to chat
- [ ] Daymi Clone appears in settings gear icon persona switcher
- [ ] Conversations demonstrate clone personality traits (curiosity, learning, casual tone)
- [ ] Oracle knowledge base works with Daymi personality overlay
- [ ] Voice mode compatible with clone conversation style

**Automatic features (no implementation needed):**
- ✅ Card design follows existing pattern (auto-generated)
- ✅ Radio selection works (existing UI logic)
- ✅ Avatar shows "D" with auto-assigned color
- ✅ Persona switching in active chat (existing functionality)
- ✅ Configuration loading (existing `CharacterConfigManager`)
- ✅ Performance maintained (no code changes)

## Implementation Summary - ULTRA SIMPLIFIED

**Total work required: 2 files**

1. **Create**: `assets/config/daymi_clone_config.json` (persona prompt + exploration prompts)
2. **Update**: `assets/config/personas_config.json` (add Daymi entry + enable it)

**Zero code changes needed** - the existing UI architecture is perfectly designed for this!

## Conclusion
The Daymi Clone persona fills a unique niche in the persona ecosystem - providing relationship-focused AI interaction that prioritizes connection and understanding over advice and expertise. Thanks to the existing dynamic persona loading architecture, implementation requires only configuration file changes, making this the simplest possible persona addition while creating opportunities for more personal, emotionally satisfying AI experiences.
