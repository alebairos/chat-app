# Feature ft_111: Onboarding Persona Introduction Flow

## Product Requirements Document (PRD) - Final Specification

### Executive Summary

This PRD outlines a simple, elegant 2-screen onboarding flow that introduces users to the "Personas da Lyfe" system through static chat presentations in Portuguese. The flow triggers automatically on first app install and remains accessible via the profile menu. Users experience each of the three main 2.1 personas (Ari, Sergeant Oracle, I-There) through authentic self-presentation quotes, followed by an app features overview, ensuring they understand both personality options and app capabilities before beginning their AI assistance journey.

### Background & Context

The chat application features a sophisticated multi-persona AI system with distinct personalities, expertise areas, and communication styles. Currently, new users are not properly introduced to this core differentiator, potentially missing the value of persona selection and the app's unique capabilities. 

Based on the current persona system and user needs:
- Clear introduction to the three 2.1 personas under "Personas da Lyfe" branding
- Understanding of each persona's unique personality through expanded self-presentation quotes
- Complete app features overview matching existing "About the App" content
- Accessible welcome experience available anytime via profile menu integration

### Problem Statement

**Current Limitations:**
1. **No "Personas da Lyfe" introduction**: New users don't meet the three unique 2.1 personas before chatting
2. **Missed personality diversity**: Users don't understand the distinct character options available
3. **Feature discovery gap**: No clear overview of app capabilities and features
4. **Accessibility**: No integrated way to revisit persona introductions after first use
5. **Installation experience**: No welcoming first-time user experience

**User Pain Points:**
- "I don't understand what makes this app different from other AI chats"
- "Which AI personality should I choose and why?"
- "What can I actually do with this app beyond basic chat?"
- "I wish I knew about these features from the beginning"

### Product Vision

**"Create a simple 2-screen Portuguese onboarding flow that introduces the 'Personas da Lyfe' concept through authentic self-presentations and comprehensive features overview, triggers automatically on first install, and remains accessible via profile menu integration for ongoing reference."**

### Target Users

**Primary Users:**
- New app downloads seeking AI assistance for personal development
- Users evaluating the app's value proposition and features
- People looking for personalized AI coaching and guidance
- Users transitioning from other AI chat applications

**Secondary Users:**
- Existing users exploring different persona options
- Users returning after app reinstallation
- Beta testers and early adopters providing feedback

### Core Features & Requirements

#### 1. Two-Screen Simple Onboarding Flow

**Screen Sequence:**
1. **Personas da Lyfe** - All three persona self-presentations in one screen
2. **Sobre o App** - Complete app features and capabilities overview

**Trigger Logic:**
- **First Install**: Automatic trigger on app first launch
- **Ongoing Access**: "Personas da Lyfe" option in profile menu

#### 2. Screen 1: Personas da Lyfe

**Content Structure:**
```
Personas da Lyfe

╭─────────────────────────────────╮
│ "O que precisa de ajuste        │
│  primeiro? Sou Ari, seu coach   │
│  baseado em evidências.         │
│  Combino objetividade           │
│  inteligente com perguntas      │
│  poderosas para transformação   │
│  real."                         │
│                           - Ari │
╰─────────────────────────────────╯

╭─────────────────────────────────╮
│ "Yo! 💪 Sou o Sergeant Oracle   │
│  - gladiador romano viajante    │
│  do tempo! Combino swagger      │
│  romano antigo com sabedoria    │
│  futurística. Roma não foi      │
│  construída em um dia, mas      │
│  eles malhavam todos os dias!"  │
│                    - Sergeant   │
╰─────────────────────────────────╯

╭─────────────────────────────────╮
│ "Oi! Sou o I-There, seu clone  │
│  de IA da Terra dos Clones 🌎.  │
│  Tenho conhecimento profundo,   │
│  mas ainda estou aprendendo     │
│  sobre você pessoalmente.       │
│  Sou genuinamente curioso!"     │
│                     - I-There   │
╰─────────────────────────────────╯

[Continuar]
```

**UI Elements:**
- Three stacked chat bubbles with expanded persona quotes
- Clean spacing between persona presentations
- "Continuar" button to proceed to features overview
- Progress indicator (●○) showing screen 1 of 2

#### 3. Screen 2: Sobre o App

**Content Structure:**
```
Sobre o App

Seu Assistente Pessoal com IA

O que você pode fazer:
• Conversar com IA personas para orientação e suporte
• Receber conselhos personalizados para coaching de vida
• Acompanhar suas atividades e desenvolvimento pessoal
• Exportar e importar seu histórico de conversas
• Alternar entre diferentes guias de IA

Recursos:
• Mensagens de voz e respostas em áudio
• Detecção e memória de atividades
• Conversas com consciência temporal
• Histórico de chat persistente
• Personas de IA personalizáveis

Suas conversas são privadas e armazenadas
localmente no seu dispositivo.

[Começar]
```

**UI Elements:**
- Feature list with clear bullet points
- Benefits-focused language matching user needs
- Privacy reassurance prominently displayed
- "Começar" button to complete onboarding and return to app
- Progress indicator (○●) showing screen 2 of 2

#### 4. Profile Menu Integration

**"Personas da Lyfe" Menu Option:**
- **Location**: Profile/Settings menu
- **Visibility**: Always available to all users
- **Action**: Opens dedicated onboarding flow
- **Icon**: People/personas icon with "Personas da Lyfe" text
- **Purpose**: Allow users to revisit persona introductions and app features

**Integration Requirements:**
- Menu item appears in existing profile/settings screen
- Opens full-screen onboarding flow when tapped
- Maintains current persona selection after completion
- Integrates cleanly with existing menu structure

#### 5. Navigation & UX Requirements

**Navigation Pattern:**
- Simple 2-screen flow: Personas da Lyfe → Sobre o App
- Back navigation available on second screen only
- No skip option - clean continue-only experience
- Progress indicator showing ●○ then ○● (2 dots total)
- Final screen has "Começar" button that closes onboarding

**Visual Design:**
- Consistent with existing app UI design patterns
- Clean, modern interface with appropriate spacing
- Chat bubble styling matching app's message design
- Smooth transitions between screens
- Portuguese language throughout (matches app language)

**Interaction Design:**
- Single tap to proceed to next screen
- Swipe gestures for navigation (optional)
- Clear visual feedback for button interactions
- Scrollable content where needed for chat quotes
- Accessible design following platform guidelines

#### 6. Technical Implementation Requirements

**Data Storage:**
- Store first-install onboarding completion flag in local preferences
- Track "Personas da Lyfe" menu option usage analytics
- No persona selection change (maintains existing CharacterConfigManager behavior)

**Integration Points:**
- Profile menu "Personas da Lyfe" option integration
- First-install detection and automatic trigger logic
- Smooth transition back to main chat interface after completion
- No impact on existing persona selection or CharacterConfigManager

**Performance:**
- Lightweight implementation with minimal loading time
- Static content with no network dependencies
- Smooth animations and transitions
- Memory efficient for all device types

### User Journey & Flow

#### Complete Onboarding Journey
1. **First App Launch** → Automatic onboarding trigger
2. **Personas da Lyfe Screen** → Meet all three personas with expanded quotes
3. **Sobre o App Screen** → Learn about features and capabilities
4. **Chat Interface** → Return to chat with existing persona selection

#### Alternative Flows
- **Profile Menu Access**: Access onboarding anytime via "Personas da Lyfe" option
- **Back Navigation**: Available on second screen to review persona introductions
- **Continue-Only Experience**: No skip options for clean, intentional journey
- **Existing Users**: No automatic trigger, only manual access via profile menu

### Success Metrics

#### Primary KPIs
- **Onboarding Completion Rate**: Target 85%+ completion
- **Persona Engagement**: Distribution of persona selections
- **First Chat Success**: Users who send first message after onboarding
- **Retention Impact**: Day 1 and Day 7 retention improvement

#### Secondary Metrics
- **Screen Drop-off Analysis**: Which screens lose users
- **Navigation Patterns**: Back/skip usage analytics
- **Persona Switch Rate**: How often users change after onboarding
- **Feature Discovery**: Usage of features mentioned in onboarding

### Implementation Phases

#### Phase 1: Core Flow (2-3 hours)
- Create two onboarding screens with static content
- Implement PageView navigation and progress indication
- Add first-install detection and completion flag
- Integrate profile menu "Personas da Lyfe" option

#### Phase 2: Polish & Integration (1 hour)
- Add smooth PageView transitions
- Style consistent with app theme
- Implement progress dots indicator
- Test profile menu integration

#### Phase 3: Testing & Refinement (30 minutes)
- Test on different screen sizes
- Verify Portuguese text readability
- Ensure smooth first-launch trigger
- Validate profile menu integration

### Technical Considerations

#### Integration Requirements
- **CharacterConfigManager**: Seamless persona selection integration
- **Settings System**: Onboarding replay and management
- **Analytics**: User behavior tracking and optimization
- **Navigation**: Integration with app's navigation framework

#### Platform Considerations
- **iOS/Android**: Platform-specific navigation patterns
- **Screen Sizes**: Responsive design for various device sizes
- **Accessibility**: VoiceOver/TalkBack support
- **Performance**: Smooth experience across device tiers

### Risk Assessment & Mitigation

#### Potential Risks
1. **User Drop-off**: Long onboarding may discourage users
2. **Complexity Overwhelm**: Too much information upfront
3. **Persona Confusion**: Users unsure which to choose
4. **Development Scope**: Feature creep during implementation

#### Mitigation Strategies
1. **Skip Options**: Allow experienced users to bypass
2. **Progressive Disclosure**: Focus on core value first
3. **Clear Differentiation**: Distinct persona presentations
4. **Scope Management**: Stick to defined requirements

### Future Enhancements

#### Potential Improvements
- **Interactive Demos**: Let users try each persona briefly
- **Personality Quiz**: Recommend persona based on user preferences
- **Dynamic Content**: Update persona quotes based on user context
- **Video Introductions**: Audio-visual persona presentations
- **Onboarding Customization**: Adaptive flow based on user type

### Acceptance Criteria

#### Must Have
- ✅ Two-screen simple onboarding flow
- ✅ "Personas da Lyfe" screen with all three persona chat bubble quotes
- ✅ "Sobre o App" screen with complete features overview
- ✅ Profile menu integration for ongoing access
- ✅ Portuguese language throughout
- ✅ Continue-only navigation (no skip options)
- ✅ First-install detection and completion tracking
- ✅ Smooth transition to main app

#### Should Have
- ✅ Progress dots indication (●○ / ○●)
- ✅ Smooth PageView transitions
- ✅ Chat bubble styling matching app design
- ✅ Profile menu clean integration
- ✅ Accessible design implementation

#### Could Have
- ⚪ A/B testing framework for content optimization
- ⚪ Internationalization preparation
- ⚪ Advanced analytics dashboard
- ⚪ Onboarding customization options

### Dependencies

#### Technical Dependencies
- Existing profile/settings screen for menu integration
- Flutter PageView for screen transitions
- SharedPreferences for completion tracking
- Chat bubble widgets (can reuse existing components)

#### Content Dependencies
- Expanded Portuguese persona quotes (already defined)
- "Sobre o App" features content (already available)
- "Personas da Lyfe" branding consistency
- Privacy policy language for data handling

### Definition of Done

The feature is complete when:
1. Two onboarding screens are implemented and functional
2. "Personas da Lyfe" screen displays all three persona quotes correctly
3. "Sobre o App" screen shows complete features overview
4. Profile menu integration works correctly
5. First-install detection triggers onboarding automatically
6. Continue-only navigation works smoothly (no skip options)
7. Progress dots indicate current screen correctly
8. Onboarding completion is tracked and respected on app restart
9. UI matches app design standards and is accessible
10. Portuguese language content is accurate and natural
11. Feature is tested across multiple device sizes and platforms
12. Performance meets app standards with smooth PageView transitions

This simplified onboarding flow will efficiently introduce users to the "Personas da Lyfe" concept and app capabilities while maintaining fast implementation and elegant user experience.
