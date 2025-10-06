# FT-182: Automated Goal Checklist

**Feature ID**: FT-182  
**Priority**: Medium  
**Category**: Goal Management Enhancement  
**Effort Estimate**: 3-4 hours  
**Depends On**: FT-181 (Goal-Aware Activity Detection), Persona System

## Problem Statement

Goals lack actionable structure and automated progress tracking, requiring manual effort to track completion and missing opportunities for intelligent coaching.

## Solution

Add automated checklists to goals with persona-generated items and FT-181 auto-completion.

## Requirements

### Automated Checklist Structure
- **One-time Behaviors**: Persona-suggested setup tasks (buy equipment, plan routes)
- **Recurring Activities**: Oracle framework activities mapped to goal
- **Auto-completion**: FT-181 detections automatically check items

### Maximum Automation
- Zero manual checkbox clicking for detected activities
- Persona adds contextual checklist items based on goal type
- Real-time progress calculation and visual feedback
- Proactive coaching based on completion gaps

### Intelligent Persona Integration
- Personas suggest relevant one-time setup tasks
- Dynamic checklist item addition based on user progress
- Proactive reminders for incomplete recurring activities

## Technical Implementation

### Core Components

**AutomatedGoalChecklist Model**:
```dart
class GoalChecklistItem {
  final String title;
  final ChecklistItemType type; // oneTime, recurring
  final String? trackingCode; // Oracle activity code for auto-completion
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isPersonaSuggested;
}
```

**Checklist Auto-updater**:
```dart
class ChecklistAutoUpdater {
  void onActivityDetected(EnhancedActivityDetection detection) {
    // Auto-check matching checklist items
    // Update progress percentages
    // Trigger persona notifications if needed
  }
}
```

**Enhanced Goal Card UI**:
- Expandable checklist section in goal cards
- Progress bar showing completion percentage
- Visual distinction between auto-completed and manual items
- Persona suggestions highlighted differently

### Integration Points
- **FT-181**: Consumes enhanced activity detections for auto-completion
- **Persona System**: Generates contextual checklist items via MCP
- **Goals Tab**: Enhanced goal cards with integrated checklists

## Expected Result

**Goal Card with Automated Checklist**:
```
┌─────────────────────────────────────┐
│ 🏃 Correr X Km                     │
│ Progress: 67% this week ████████░░░ │
├─────────────────────────────────────┤
│ Setup (One-time):                  │
│ ✅ Buy running shoes (persona)      │
│ ✅ Plan 5k route (persona)          │
│                                     │
│ Weekly Activities:                  │
│ ✅ Run 3x per week (2/3) ← auto     │
│ ✅ Warm up before run ← auto        │
│ ☐ Cool down stretch                 │
│                                     │
│ 📊 This week: 2/3 runs completed   │
└─────────────────────────────────────┘
```

### Automation Flow
1. **User reports**: "Corri 5km hoje"
2. **FT-181 detects**: SF13 → OCX1 "Correr X Km" 
3. **Auto-completion**: ✅ "Run 3x per week" checked automatically
4. **Progress update**: 67% → 100% for today's activities
5. **Persona coaching**: "Great run! 1 more this week to hit your goal! 🏃‍♂️"

## Success Criteria
- Checklist items auto-complete from FT-181 detections
- Personas generate relevant setup tasks for new goals
- Progress tracking updates in real-time
- Proactive coaching triggers based on completion gaps
- Zero manual tracking required for detected activities
