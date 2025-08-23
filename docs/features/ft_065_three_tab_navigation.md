# FT-065 Three-Tab Navigation System

**Feature ID**: FT-065  
**Priority**: High  
**Category**: UI/Navigation  
**Effort Estimate**: 2-3 hours  
**Dependencies**: None  
**Status**: Specification  

## Overview

Transform the single-screen chat app into a three-tab application with Chat, Stats, and Profile tabs using Flutter's standard bottom navigation pattern. This provides the foundation for displaying activity data and user profile management.

## User Story

As a user of the chat app, I want to navigate between different sections (Chat, Stats, Profile) using standard mobile bottom tabs, so that I can access conversation, activity tracking, and profile management in a familiar and efficient way.

## Functional Requirements

### Core Navigation
- **FR-065-01**: App displays three bottom tabs: Chat, Stats, Profile
- **FR-065-02**: Tapping a tab switches to that screen immediately
- **FR-065-03**: Current tab is visually highlighted
- **FR-065-04**: Chat functionality remains unchanged when accessed via tab
- **FR-065-05**: Tab state is preserved when switching between tabs

### UI Structure Changes
- **FR-065-06**: Remove settings button from AppBar
- **FR-065-07**: Maintain existing AppBar with persona display
- **FR-065-08**: Stats and Profile tabs show placeholder content initially
- **FR-065-09**: Each tab has appropriate screen title

### Tab Content (Phase 1 - Placeholder Only)
- **FR-065-10**: Chat tab contains existing ChatScreen
- **FR-065-11**: Stats tab shows "Stats coming soon..." placeholder
- **FR-065-12**: Profile tab shows "Profile coming soon..." placeholder

## Non-Functional Requirements

### Performance
- **NFR-065-01**: Tab switching responds within 100ms
- **NFR-065-02**: Chat state preserved when switching tabs
- **NFR-065-03**: No memory leaks from tab controller

### Usability
- **NFR-065-04**: Standard iOS/Android bottom navigation UX
- **NFR-065-05**: Tab icons are recognizable and intuitive
- **NFR-065-06**: Thumb-friendly tap targets (44pt minimum)

## Technical Specifications

### Navigation Structure
```dart
HomeScreen (StatefulWidget with TabController)
├── AppBar (existing persona display)
├── TabBarView
│   ├── ChatScreen (existing, unchanged)
│   ├── StatsScreen (new, placeholder)
│   └── ProfileScreen (new, placeholder)
└── BottomNavigationBar (3 tabs)
```

### Tab Configuration
- **Tab 0**: Chat (💬 icon, "Chat" label)
- **Tab 1**: Stats (📊 icon, "Stats" label)  
- **Tab 2**: Profile (👤 icon, "Profile" label)
- **Default**: Start on Chat tab (index 0)

### State Management
- Use `TabController` with `SingleTickerProviderStateMixin`
- Track current tab index in `_currentIndex` variable
- Preserve individual screen states during tab switches

## Implementation Details

### File Changes
**Modified Files:**
- `lib/main.dart` - Add TabController and bottom navigation

**New Files:**
- `lib/screens/stats_screen.dart` - Placeholder stats screen
- `lib/screens/profile_screen.dart` - Placeholder profile screen

### Dependencies
- No new package dependencies required
- Uses Flutter's built-in `BottomNavigationBar` and `TabController`

## Testing Requirements

### Unit Tests
- Tab controller initialization
- Tab switching logic
- State preservation between tabs

### Widget Tests  
- Bottom navigation bar renders correctly
- All three tabs are tappable
- Correct tab highlighting
- Placeholder content displays

### Integration Tests
- Chat functionality unchanged in tab context
- Navigation between all tabs works
- AppBar updates appropriately per tab

## Acceptance Criteria

### Phase 1 Success Criteria
- [ ] Three bottom tabs visible and labeled correctly
- [ ] Tapping each tab switches screen content
- [ ] Chat tab contains full existing chat functionality
- [ ] Stats and Profile tabs show placeholder content
- [ ] No crashes or navigation errors
- [ ] Settings button removed from AppBar
- [ ] App maintains existing persona functionality

### Definition of Done
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] No performance regressions
- [ ] Documentation updated

## Future Considerations

### Phase 2 Integration
- Stats tab will connect to ActivityMemoryService
- Profile tab will add user data management
- Settings will migrate to Profile tab

### Extensibility
- Tab system supports adding more tabs if needed
- Individual tab screens can be enhanced independently
- Navigation state can be persisted if needed

## Notes

This feature provides the foundational navigation structure for the app's evolution from a simple chat interface to a comprehensive personal assistant with activity tracking and profile management. The implementation focuses purely on navigation mechanics without adding functional complexity.
