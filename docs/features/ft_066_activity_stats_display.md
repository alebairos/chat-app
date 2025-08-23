# FT-066 Activity Stats Display System

**Feature ID**: FT-066  
**Priority**: High  
**Category**: Analytics/UI  
**Effort Estimate**: 3-4 hours  
**Dependencies**: FT-065 (Three-Tab Navigation), FT-064 (Activity Detection)  
**Status**: Specification  

## Overview

Populate the Stats tab with real activity tracking data from FT-064, displaying detected activities, patterns, and insights in a simple, readable format. This feature makes the activity detection system visible and valuable to users.

## User Story

As a user who has activities automatically detected by the app, I want to see my tracked activities, patterns, and progress in the Stats tab, so that I can understand my habits, celebrate achievements, and identify areas for improvement.

## Functional Requirements

### Activity Display
- **FR-066-01**: Show today's detected activities with timestamps
- **FR-066-02**: Display recent activities from the last 7 days
- **FR-066-03**: Show activity names, Oracle codes, and confidence scores
- **FR-066-04**: Group activities by dimension (Physical Health, Mental, etc.)
- **FR-066-05**: Display activity source (semantic detection, manual, etc.)

### Basic Statistics
- **FR-066-06**: Show total activity count (all time)
- **FR-066-07**: Display today's activity count
- **FR-066-08**: Show most frequent activities this week
- **FR-066-09**: Calculate and display simple activity streaks
- **FR-066-10**: Show time patterns (morning, afternoon, evening activities)

### Oracle Integration
- **FR-066-11**: Display Oracle activity codes with full descriptions
- **FR-066-12**: Show dimension mapping (SF = Physical Health, T = Mental, etc.)
- **FR-066-13**: Indicate Oracle vs. custom activities
- **FR-066-14**: Show available Oracle activities not yet tried

### Data Presentation
- **FR-066-15**: Activities sorted by most recent first
- **FR-066-16**: Show relative timestamps (2 hours ago, yesterday, etc.)
- **FR-066-17**: Display confidence scores as visual indicators
- **FR-066-18**: Use color coding for different dimensions

## Non-Functional Requirements

### Performance
- **NFR-066-01**: Stats screen loads within 500ms
- **NFR-066-02**: Handles up to 1000 stored activities efficiently
- **NFR-066-03**: Real-time updates when new activities detected

### Usability
- **NFR-066-04**: Information hierarchy prioritizes recent/relevant data
- **NFR-066-05**: Text is readable without requiring scrolling for key stats
- **NFR-066-06**: Visual design follows app's existing style patterns

## Technical Specifications

### Data Sources
```dart
// Primary data from ActivityMemoryService:
- getTodayActivities() → List<ActivityModel>
- getRecentActivities(7) → List<ActivityModel>
- getTotalActivityCount() → int
- getActivitiesByDimension(dimension) → List<ActivityModel>
- generateActivityContext() → String (for insights)
```

### Stats Screen Structure
```dart
StatsScreen
├── Today's Summary Card
│   ├── Activity count
│   ├── Last activity time
│   └── Active dimensions
├── Recent Activities List
│   ├── Activity cards (name, time, confidence)
│   ├── Oracle code mapping
│   └── Dimension indicators
├── Basic Patterns Section
│   ├── Most active time of day
│   ├── Most frequent activities
│   └── Simple streak counts
└── Oracle Progress Section
    ├── Activities tried by dimension
    ├── Total Oracle coverage
    └── Available activities preview
```

### UI Components
- **Activity Card**: Shows activity name, time, Oracle code, confidence
- **Dimension Badge**: Color-coded dimension indicators
- **Summary Stats**: Simple number + label pairs
- **Progress Indicators**: Basic text-based progress (X/Y format)

## Implementation Details

### File Structure
**New Files:**
- `lib/screens/stats_screen.dart` - Main stats display screen
- `lib/widgets/stats/activity_card.dart` - Individual activity display
- `lib/widgets/stats/stats_summary.dart` - Today's summary section

**Modified Files:**
- None (pure additive feature)

### Dependencies
- Existing `ActivityMemoryService` (FT-064)
- Existing `ActivityModel` data structure
- Standard Flutter widgets only

## Data Display Format

### Today's Activities
```
📅 Today (August 22, 2025)
┌─────────────────────────────────────┐
│ 🎯 2 activities detected            │
│ 🕐 Last: 14:25 (25 minutes ago)     │
│ 📊 Dimensions: Physical Health      │
└─────────────────────────────────────┘
```

### Activity List
```
🎯 Recent Activities
┌─────────────────────────────────────┐
│ T8 - Técnicas de foco/concentração  │
│ 🕐 Today 14:20 • 🎯 95% confidence  │
│ 📂 Mental Focus                     │
├─────────────────────────────────────┤
│ SF10 - Refeições nutritivas         │
│ 🕐 Today 14:25 • 🎯 95% confidence  │
│ 📂 Physical Health                  │
└─────────────────────────────────────┘
```

### Basic Statistics
```
📈 This Week's Patterns
• Total activities: 5
• Most active time: Afternoon (3 activities)
• Top dimension: Physical Health (60%)
• Longest streak: 3 days (water intake)
```

## Testing Requirements

### Unit Tests
- Activity data retrieval and formatting
- Statistics calculation accuracy
- Oracle code mapping correctness

### Widget Tests
- Stats screen renders with sample data
- Activity cards display correctly
- Summary statistics show proper values
- Empty state handling (no activities)

### Integration Tests
- Real activity data displays correctly
- Stats update when new activities detected
- Navigation from Chat to Stats preserves data

## Acceptance Criteria

### Core Functionality
- [ ] Stats tab shows real activity data from FT-064
- [ ] Today's activities displayed with timestamps
- [ ] Recent activities (7 days) visible in chronological order
- [ ] Activity confidence scores displayed
- [ ] Oracle codes mapped to readable descriptions

### Data Accuracy
- [ ] Activity counts match database queries
- [ ] Timestamps display in user-friendly format
- [ ] Dimension grouping works correctly
- [ ] Oracle vs. custom activities distinguished

### User Experience
- [ ] Stats load quickly (<500ms)
- [ ] Information is scannable and clear
- [ ] No crashes with empty or large datasets
- [ ] Visual hierarchy guides attention to important data

### Definition of Done
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] Real activity data displaying correctly
- [ ] Performance meets requirements
- [ ] Code reviewed and approved

## Future Considerations

### Phase 3 Enhancements
- Visual charts and graphs
- Weekly/monthly trend analysis
- Goal setting and progress tracking
- Export capabilities

### Oracle Framework Integration
- Activity suggestions based on gaps
- Dimension balance recommendations
- Progress toward Oracle framework completion

## Notes

This feature transforms the activity detection system (FT-064) from invisible background processing into a valuable user-facing feature. By focusing on simple data display first, we validate the usefulness of tracked data before investing in complex visualizations.

The implementation leverages existing ActivityMemoryService methods and requires no new data collection - purely presentation of already-captured information.
