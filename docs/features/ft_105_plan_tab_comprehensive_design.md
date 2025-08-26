# FT-105: Plan Tab - Comprehensive Planning System

**Status**: 📝 SPECIFICATION  
**Priority**: High  
**Category**: Major Feature / UX Transformation  
**Effort**: Large (Multi-phase implementation)  

## **Overview**

Transform the activity tracking experience from reactive (stats-focused) to proactive (planning-focused) by creating a new Plan tab with calendar navigation, activity planning, and intelligent template replication.

## **Problem Statement**

### **Current Limitation: Reactive Activity Tracking**
- Users can only see what they **did** (past-focused stats)
- No forward planning or intentional activity scheduling
- Activity detection is reactive, not guided by user intentions
- Stats screen mixes retrospective analytics with activity browsing

### **User Need: Proactive Planning System**
- **"What will I do today?"** - Planning perspective
- **"What did I plan vs accomplish?"** - Execution tracking
- **"How can I replicate successful patterns?"** - Template intelligence
- **"How do I organize my activities meaningfully?"** - Personal categorization

## **Solution Strategy**

### **Core Concept: Planning-First Approach**

**Transform from:**
```
Activity happens → Gets detected → Appears in stats
```

**To:**
```
Plan activity → Activity happens → Mark completed OR auto-detect completion
```

### **Key Design Principles**

1. **Zero Impact on Detection System** - Preserve existing activity detection unchanged
2. **User Control with System Intelligence** - Manual planning with smart templates
3. **Flexible Organization** - Custom labels and drag-drop reordering
4. **Seamless Integration** - Planned activities sync with detected activities
5. **Progressive Enhancement** - Add features without breaking existing workflows

## **Feature Architecture**

### **1. Calendar Navigation System**

**Design**: Horizontal swipeable calendar with today as focus point

**Navigation Logic:**
- **Today (Center)**: Primary planning interface, fully editable
- **Left Swipe**: Previous days, read-only browsing of completed activities
- **Right Swipe**: Future days, editable planning with template replication
- **Focus Gravity**: Always returns to "today" as the primary action point

**User Experience:**
- **Quick navigation**: Swipe between days smoothly
- **Context awareness**: Visual indication of past vs future vs today
- **Data density**: Show activity count per day without overwhelming

### **2. Activity Planning System**

**Activity Structure** (Non-destructive to existing system):
```dart
class PlannedActivity {
  int? id;
  String activityCode;   // SF1, T8 (unchanged from detection system)
  String activityName;   // "Beber água" (unchanged from detection system)
  String? userNote;      // NEW: User's personal note ("With lemon", "30 minutes")
  String? detectionNote; // Display existing 'notes' field from detection
  int? labelId;          // Group under user-created label
  DateTime plannedDate;  // Which day this is planned for
  String status;         // "planned", "completed", "overdue"
  int sortOrder;         // Position within label for drag-drop
  DateTime? plannedTime; // Optional: specific time planning
}
```

**Activity Status Flow:**
- **Planned** (Blue "Do it!"): Future activities waiting execution
- **Completed** (Green "✓ Completed"): Successfully executed activities
- **Overdue** (Yellow): Yesterday's incomplete items (gentle nudge)

**User Interaction:**
- **Add Note**: Tap activity → add personal context
- **View Detection Note**: See system's automatic detection reasoning
- **Reorder**: Drag activities up/down within labels
- **Delete**: Remove from plan (like e-commerce cart item removal)

### **3. Label Organization System**

**Label Structure:**
```dart
class PlanLabel {
  int id;
  String name;           // "Morning Routine", "Work Block", "Self Care"
  int sortOrder;         // For drag-and-drop label reordering
  DateTime createdAt;
  Color? color;          // Optional: user-chosen label color
}
```

**Label Functionality:**
- **Create Labels**: Custom categorization ("Morning Routine", "Deep Work")
- **Rename Labels**: Editable at any time
- **Reorder Labels**: Drag to change priority/sequence
- **Move Activities**: Drag activities between labels
- **Collapse/Expand**: Manage visual complexity

**Default Label Suggestions:**
- **Time-based**: "Morning", "Afternoon", "Evening"
- **Category-based**: "Health", "Work", "Personal"
- **User choice**: Start empty or with defaults

### **4. Template Replication Intelligence**

**Replication Logic** (Simple and predictable):

```dart
DateTime getReplicationSourceDate(DateTime targetDate) {
  final isWeekend = targetDate.weekday >= 6; // Saturday/Sunday
  
  if (isWeekend) {
    // Find last weekend day that had planned activities
    return findLastWeekendWithActivities(targetDate);
  } else {
    // Find last weekday that had planned activities  
    return findLastWeekdayWithActivities(targetDate);
  }
}
```

**Replication Rules:**
- **Weekday planning**: Copy from most recent weekday with activities
- **Weekend planning**: Copy from most recent weekend with activities
- **User control**: Delete unwanted items (e-commerce cart behavior)
- **Preserve labels**: Maintain organization structure
- **Reset status**: All copied activities start as "planned"

**Edge Case Handling:**
- **First weekend**: No previous weekend → offer weekday template or start empty
- **Irregular schedules**: User manually adjusts after replication
- **Holiday handling**: Treat holidays as weekend days for replication

## **Integration Strategy**

### **Detection System Integration** (Zero Impact)

**Current Detection Flow** (Unchanged):
```
User message → Activity detected → Saved to database → Appears in stats
```

**Enhanced Integration Flow** (New):
```
User message → Activity detected → Check if planned today → Mark planned as completed OR create new completed activity
```

**Sync Logic:**
1. **Activity detected**: System checks today's plan for matching activity code
2. **Match found**: Mark planned activity as "completed", preserve user note
3. **No match**: Create new completed activity (existing behavior)
4. **Future plans**: Unaffected by today's detections

### **Stats Screen Separation**

**New Stats Screen Focus** (Pure Analytics):
- **Trend analysis**: Week/month patterns and insights
- **Achievement tracking**: Streaks, improvements, milestones
- **Dimension distribution**: SF, TG, SM activity balance
- **Time patterns**: When activities typically happen
- **Comparative analysis**: Plan vs actual execution rates

**Plan Tab Focus** (Action-Oriented):
- **Today's execution**: Main planning and tracking interface
- **Historical browsing**: Navigate past days to see what was accomplished
- **Future planning**: Template-based planning for upcoming days
- **Personal organization**: Labels, notes, custom arrangements

## **User Experience Flow**

### **Daily Planning Workflow**

1. **Morning**: Open Plan tab → Review today's plan → Adjust as needed
2. **Throughout day**: Activities get detected → Auto-mark planned items complete
3. **Evening**: Review completed vs planned → Plan tomorrow
4. **Weekly**: Use template replication → Customize for upcoming patterns

### **Activity Card Design** (Enhanced)

```dart
ActivityCard(
  code: "SF1",                    // Unchanged: system code
  name: "Beber água",             // Unchanged: system name
  time: "planned for 10:00",      // New: planned time or actual time
  dimension: "SF",                // Unchanged: system dimension
  status: ActivityStatus.planned, // New: planning status
  userNote: "With lemon",         // New: user's personal note
  detectionNote: "Auto-detected at 10:15", // Existing: system note
  onEdit: () => showNoteDialog(), // New: edit user note
  onDelete: () => removeFromPlan(), // New: remove from plan
  onMove: () => showLabelSelector(), // New: move between labels
)
```

**Visual Status Indicators:**
- **Planned**: Blue "Do it!" badge
- **Completed**: Green "✓ Completed" badge (from FT-089)
- **Overdue**: Yellow "Yesterday" badge

## **Implementation Phases**

### **Phase 1: Core Planning System (MVP)**

**Database Changes:**
```sql
-- New tables (additive, no impact on existing data)
CREATE TABLE plan_labels (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE TABLE planned_activities (
  id INTEGER PRIMARY KEY,
  activity_code TEXT NOT NULL,        -- SF1, T8, etc.
  activity_name TEXT NOT NULL,        -- "Beber água"
  user_note TEXT,                     -- User's personal note
  label_id INTEGER,                   -- FK to plan_labels
  planned_date TEXT NOT NULL,         -- "2025-08-26"
  status TEXT NOT NULL,               -- "planned", "completed", "overdue"
  sort_order INTEGER NOT NULL,       -- Position within label
  planned_time TEXT,                  -- Optional: "10:00"
  created_at INTEGER NOT NULL,
  completed_at INTEGER                -- When marked complete
);
```

**Core Features:**
- ✅ New Plan tab with calendar navigation
- ✅ Basic label system (create, rename, reorder)
- ✅ Activity replication (weekday/weekend logic)
- ✅ User notes (editable personal field)
- ✅ Detection notes (display existing notes field)
- ✅ Status management (planned/completed/overdue)
- ✅ Integration with detection system (auto-complete planned activities)

**Files to Create/Modify:**

**New Files:**
- `lib/screens/plan_screen.dart` - Main planning interface
- `lib/widgets/plan/plan_calendar.dart` - Swipeable calendar navigation
- `lib/widgets/plan/plan_activity_card.dart` - Enhanced activity card
- `lib/widgets/plan/plan_label_group.dart` - Label grouping widget
- `lib/services/plan_service.dart` - Planning business logic
- `lib/models/plan_label.dart` - Label data model
- `lib/models/planned_activity.dart` - Planned activity data model

**Modified Files:**
- `lib/services/activity_memory_service.dart` - Add plan integration methods
- `lib/screens/stats_screen.dart` - Remove activity lists, focus on analytics
- `lib/main.dart` - Add Plan tab to navigation

### **Phase 2: Enhanced UX & Intelligence**

**Advanced Features:**
- ✅ Drag & drop activity reordering
- ✅ Smart time suggestions based on historical patterns
- ✅ Plan vs actual analytics
- ✅ Quick actions (mark complete, add note, duplicate)
- ✅ Template customization (save custom templates)
- ✅ Notification integration (remind about planned activities)

### **Phase 3: Advanced Analytics & Optimization**

**Future Enhancements:**
- ✅ Predictive planning (suggest activities based on patterns)
- ✅ Goal setting and tracking within plans
- ✅ Social features (share plans, collaborative planning)
- ✅ Advanced template intelligence (frequency-based, seasonal)

## **Technical Considerations**

### **Performance Optimization**

**Database Queries:**
- **Today's plan**: Single query with label joins
- **Calendar navigation**: Lazy loading for visible date range
- **Template replication**: Batch operations for multiple activities

**Real-Time Updates:**
- **Integration with FT-090**: Plan tab needs real-time refresh when activities detected
- **Conflict resolution**: Handle simultaneous planning and detection gracefully
- **Offline support**: Plan activities work offline, sync when connected

### **Data Migration Strategy**

**Existing Users:**
- **No data loss**: All existing activity data preserved unchanged
- **Gradual adoption**: Plan tab starts empty, users begin planning organically
- **Optional migration**: Offer to create initial plan from recent activity patterns

**New Users:**
- **Onboarding flow**: Guide through creating first plan
- **Template gallery**: Offer common planning templates
- **Progressive disclosure**: Start simple, reveal advanced features over time

## **Testing Strategy**

### **User Experience Testing**

**Planning Workflow:**
- [ ] User can create plan for tomorrow using template
- [ ] User can add personal notes to planned activities
- [ ] User can organize activities with custom labels
- [ ] User can navigate smoothly between past/present/future days

**Integration Testing:**
- [ ] Detected activity auto-completes matching planned activity
- [ ] Multiple detections don't create duplicate completions
- [ ] Plan tab updates in real-time when activities detected
- [ ] Stats screen analytics exclude planned (non-completed) activities

**Edge Case Testing:**
- [ ] First-time user with no activity history
- [ ] User with irregular schedule (works weekends)
- [ ] Network interruption during planning
- [ ] Large number of activities and labels

### **Performance Testing**

**Load Testing:**
- [ ] Calendar navigation smooth with 100+ days of data
- [ ] Activity reordering responsive with 50+ activities per day
- [ ] Database queries performant with 1000+ planned activities

**Memory Testing:**
- [ ] No memory leaks during extended planning sessions
- [ ] Efficient widget recycling in scrollable activity lists

## **Expected Results**

### **User Behavior Transformation**

**Before (Reactive):**
- User logs activities → Reviews stats → Feels accomplished/disappointed
- Planning happens mentally or externally (other apps)
- No connection between intention and execution tracking

**After (Proactive):**
- User plans day → Executes activities → Tracks completion → Reviews success
- Planning and tracking unified in single interface
- Clear feedback loop between intention and outcome

### **Engagement Metrics**

**Predicted Improvements:**
- **Daily active usage**: +40% (planning becomes daily habit)
- **Activity completion rate**: +25% (planned activities more likely completed)
- **User retention**: +30% (planning creates system dependency)
- **Feature adoption**: Plan tab becomes primary interface within 2 weeks

### **Psychological Benefits**

**User Experience:**
- **Increased control**: Users feel ownership over their day
- **Reduced anxiety**: Clear plan reduces decision fatigue
- **Enhanced motivation**: Visual progress toward planned goals
- **Improved reflection**: Compare planned vs actual for insights

## **Risk Assessment**

### **Technical Risks**

**Low Risk:**
- **Database changes**: Additive only, no impact on existing data
- **UI integration**: New tab, existing functionality preserved
- **Performance impact**: New features isolated from existing system

**Medium Risk:**
- **Complex sync logic**: Planned vs detected activity matching
- **User adoption curve**: Learning new planning-focused workflow
- **Migration complexity**: Existing users adapting to new paradigm

### **Mitigation Strategies**

**Gradual Rollout:**
1. **Beta testing**: Power users test planning system
2. **Feature flags**: Gradually enable for user segments
3. **Fallback options**: Maintain stats screen activity browsing during transition
4. **User education**: In-app tutorials and planning best practices

## **Success Metrics**

### **Adoption Metrics**
- **Plan tab usage**: >60% of active users create plans within 1 week
- **Template replication**: >40% of users use template feature
- **Label usage**: >50% of users create custom labels
- **Note addition**: >30% of activities have user notes

### **Engagement Metrics**
- **Daily planning**: >70% of active users plan activities daily
- **Plan completion**: >75% completion rate for planned activities
- **Return usage**: Users return to plan vs just log activities

### **Satisfaction Metrics**
- **User feedback**: >4.5/5 rating for planning experience
- **Feature requests**: Primarily enhancements vs fixes
- **Support tickets**: <5% increase despite major feature addition

## **Dependencies**

**Must Complete First:**
- ✅ FT-089 (Remove confidence indicators) - Creates positive activity card foundation
- ✅ FT-090 (Real-time refresh) - Essential for plan/detection integration

**Should Complete First:**
- ✅ FT-088 (Days parameter fix) - Ensures accurate historical data for templates
- ✅ FT-104 (JSON command TTS fix) - Maintains system stability during development

**Parallel Development:**
- Can develop alongside other analytical features
- Independent of persona/TTS enhancements

## **Rollout Strategy**

### **Phase 1: Foundation (Week 1-2)**
- Implement core data models and Plan tab structure
- Basic calendar navigation and activity display
- Simple template replication (copy previous day)

### **Phase 2: Organization (Week 3-4)**
- Add label system and drag-drop functionality
- Implement user notes and detection note display
- Enhanced activity card with planning features

### **Phase 3: Intelligence (Week 5-6)**
- Smart weekday/weekend template replication
- Integration with detection system for auto-completion
- Plan vs actual tracking and basic analytics

### **Phase 4: Polish (Week 7-8)**
- Performance optimization and edge case handling
- User onboarding flow and tutorial system
- Advanced features (time planning, quick actions)

---

## **Priority**: **High**
Planning system addresses core user need for proactive life management.

## **Effort**: **Large** 
Major feature requiring new data models, UI components, and integration logic.

## **Category**: **UX Transformation**

## **Impact**: **Transformational**
Shifts entire app paradigm from reactive tracking to proactive planning.

---

*This specification represents a comprehensive evolution of the activity tracking system while maintaining full compatibility with existing functionality. The Plan tab will become the primary user interface for intentional life management, supported by enhanced analytics in a refined Stats screen.*
