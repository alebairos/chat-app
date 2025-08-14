# FT-030 PRD: Dynamic Chat Header with Persona Names

## Product Overview
Update the chat screen header to display "AI Personas" as the main title and dynamically show the active persona's display name as a subtitle, creating clearer context for users about which AI personality they're currently interacting with.

## Problem Statement
Currently, the chat screen header shows the persona name as the main title (e.g., "Sergeant Oracle"), which can be confusing for users who may not immediately understand they're interacting with different AI personalities. Users need better context about:
- The nature of the interaction (AI Personas)
- Which specific persona is currently active
- Visual hierarchy that emphasizes the persona system

## Solution: Dynamic Header with Clear Persona Context

### Current State (Image Analysis)
- **Main title**: Shows persona name directly ("Sergeant Oracle")
- **Subtitle**: None
- **Context**: Limited clarity about the AI persona system

### Proposed New Design
- **Main title**: "AI Personas" (static, consistent across all personas)
- **Subtitle**: Dynamic persona display name from `personas_config.json`
- **Visual hierarchy**: Clear distinction between system context and active persona

## User Experience Goals

### Improved Context Awareness
- **System understanding**: Users immediately know they're in an AI persona interaction
- **Active persona clarity**: Clear indication of which persona is currently selected
- **Consistency**: Uniform header structure across all personas

### Visual Hierarchy
- **Primary information**: "AI Personas" establishes system context
- **Secondary information**: Persona name provides specific context
- **Scalability**: Design works with any number of future personas

## Technical Specifications

### Header Structure
```
┌─────────────────────────────────┐
│  AI Personas                ⚙️  │  ← Main title (static)
│  [Dynamic Persona Name]         │  ← Subtitle (from config)
└─────────────────────────────────┘
```

### Data Source Integration
- **Main title**: Hardcoded "AI Personas"
- **Subtitle source**: `personas_config.json` → `displayName` field
- **Dynamic loading**: Updates when persona changes via settings

### Current Persona Display Names (from config)
- `ariLifeCoach` → "Ari - Life Coach"
- `sergeantOracle` → "Sergeant Oracle"  
- `daymiClone` → "Daymi Clone"

## Implementation Requirements

### UI Component Updates
1. **Chat screen header modification**:
   - Update main title from dynamic persona name to static "AI Personas"
   - Add subtitle displaying current persona's `displayName`
   - Maintain existing settings gear icon functionality

2. **Typography hierarchy**:
   - **Main title**: Larger, bold "AI Personas"
   - **Subtitle**: Smaller, regular weight persona name
   - **Color scheme**: Consistent with existing design system

### Data Integration
- **Configuration loading**: Use existing `CharacterConfigManager.personaDisplayName`
- **Real-time updates**: Header updates when user switches personas via settings
- **Fallback handling**: Display generic text if persona name unavailable

### Responsive Design
- **Text overflow**: Handle long persona names gracefully
- **Accessibility**: Maintain screen reader compatibility
- **Platform consistency**: Works on both iOS and Android

## Visual Design Specifications

### Typography
- **Main title "AI Personas"**:
  - Font size: 18pt (or existing header size)
  - Font weight: Bold/Semi-bold
  - Color: Primary text color

- **Subtitle (persona name)**:
  - Font size: 14pt (smaller than main title)
  - Font weight: Regular/Medium
  - Color: Secondary text color or slightly muted

### Layout
- **Alignment**: Left-aligned with existing header pattern
- **Spacing**: Appropriate line height between title and subtitle
- **Settings icon**: Maintains current position (top right)

### Examples with All Personas
```
AI Personas                    ⚙️
Ari - Life Coach

AI Personas                    ⚙️  
Sergeant Oracle

AI Personas                    ⚙️
Daymi Clone
```

## Implementation Benefits

### User Experience
- **Immediate context**: Users understand they're in AI persona mode
- **Clear persona identification**: No confusion about which AI is active
- **System branding**: Reinforces the "AI Personas" feature concept

### Technical Benefits
- **Scalable design**: Works with unlimited future personas
- **Consistent branding**: Unified header approach across all personas
- **Maintainable**: Uses existing configuration system

### Future-Proofing
- **Persona additions**: New personas automatically work with header design
- **Branding evolution**: Easy to update main title if needed
- **Feature expansion**: Header design accommodates additional persona metadata

## Edge Cases & Considerations

### Long Persona Names
- **Text truncation**: Ellipsis for extremely long names
- **Multi-line**: Consider wrapping if needed
- **Responsive**: Adjust font size for smaller screens

### Persona Loading States
- **Loading**: Show "Loading..." as subtitle during persona switch
- **Error**: Fallback to generic "AI Assistant" if persona name unavailable
- **Default**: Handle initial app launch gracefully

### Accessibility
- **Screen readers**: Announce both title and subtitle clearly
- **Voice control**: Maintain existing navigation functionality
- **Contrast**: Ensure subtitle text meets accessibility standards

## Success Metrics

### User Understanding
- **Context clarity**: Users immediately understand AI persona system
- **Persona recognition**: Clear identification of active persona
- **Navigation confidence**: Users comfortable with persona switching

### Technical Quality
- **Performance**: No impact on header rendering speed
- **Reliability**: Consistent display across persona switches
- **Compatibility**: Works across all supported devices and screen sizes

## Development Phases

### Phase 1: Core Implementation
- Update chat screen header component structure
- Integrate with existing `CharacterConfigManager.personaDisplayName`
- Implement typography and layout changes
- Test with all existing personas (Ari, Sergeant Oracle, Daymi Clone)

### Phase 2: Polish & Edge Cases
- Handle long persona names and edge cases
- Optimize for different screen sizes
- Enhance accessibility features
- Add smooth transition animations for persona switches

### Phase 3: Future Enhancements
- Consider additional persona metadata in header (e.g., status indicators)
- Explore header customization options
- Integration with any future persona-specific branding

## Testing Requirements

### Functional Testing
- **Persona switching**: Header updates correctly when changing personas
- **Initial load**: Correct display on app startup
- **Error handling**: Graceful degradation if persona data unavailable

### Visual Testing
- **Typography**: Proper hierarchy and readability
- **Layout**: Correct spacing and alignment
- **Responsive**: Works on different screen sizes
- **Dark mode**: Proper contrast in both light and dark themes

### Accessibility Testing
- **Screen reader**: Both title and subtitle announced correctly
- **High contrast**: Readable in accessibility modes
- **Font scaling**: Works with user-adjusted font sizes

## Implementation Files

### Primary Changes
- `lib/screens/chat_screen.dart`: Header component updates
- Typography and styling adjustments
- Integration with existing persona display name logic

### Testing
- Update existing chat screen tests
- Add tests for header display with different personas
- Verify persona switching updates header correctly

## Conclusion
The dynamic chat header enhancement provides immediate context about the AI persona system while clearly identifying the active persona. This improves user understanding and creates a more cohesive experience across all AI personalities, setting the foundation for future persona system expansion.
