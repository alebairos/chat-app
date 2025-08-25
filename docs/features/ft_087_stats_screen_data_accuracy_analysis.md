# FT-087: Stats Screen Data Accuracy Analysis

## **Problem Analysis**

### **Database Evidence (from db_20250825_0102.json)**

#### **Today's Activities (Monday 25/8/2025)**
- **00:28**: SF1 - Beber água (ID: 142) 
- **00:29**: T8 - Pomodoro (ID: 143)
- **Total today**: 2 activities

#### **Yesterday's Activities (Sunday 24/8/2025)**  
- **23:04-23:56**: Multiple pomodoros and other activities
- **15:45**: Various activities logged
- **01:33-01:34**: Multiple activities
- **Total yesterday**: ~30+ activities

#### **Current Stats Screen Issues**

1. **Wrong Time Period Query**
   - Using `days: 1` (yesterday) instead of `days: 0` (today)
   - Shows Sunday's data when user expects Monday's data
   - "Today's Activities" section displays wrong day

2. **Time Calculation Bug**
   - `-1386 min ago` indicates parsing time without proper date context
   - Assumes activity time is "today" when it's actually from yesterday
   - Creates negative time differences

3. **Red 0% Visual Issue**
   - Confidence percentages showing as red when 0%
   - Creates negative psychological impact
   - Should use neutral colors for low confidence

4. **Data Refresh Problems**
   - Screen may not update after new activities logged
   - User sees stale data instead of recent activities
   - Missing latest 2 activities from today

### **Root Causes**

#### **Technical Issues**
- `StatsScreen._loadActivityStats()` uses wrong days parameter
- `_getLastActivityTime()` has flawed date calculation logic
- Activity confidence display uses negative color coding
- No real-time refresh mechanism for new activities

#### **User Experience Impact**
- **Confusion**: "Today's Activities" shows wrong day
- **Demotivation**: Red zeros feel like failure
- **Frustration**: Recent work not reflected immediately
- **Inaccuracy**: Wrong progress assessment

### **Expected vs Actual Behavior**

#### **Expected (User Perspective)**
- "Today's Activities" shows Monday 25/8 activities (2 items)
- Last activity: "Pomodoro completed 1 hour ago" (00:29 → 01:30)
- Progress indicators reflect actual today vs yesterday improvement
- Recent activities appear immediately after logging

#### **Actual (Current Behavior)**  
- "Today's Activities" shows Sunday 24/8 activities (~30 items)
- Last activity: "-1386 minutes ago" (impossible negative time)
- Progress comparisons are meaningless (wrong baseline)
- New activities don't appear until app restart

### **Impact Assessment**

#### **Data Integrity Issues**
- **Critical**: Wrong day's data completely misleads user
- **High**: Negative time calculations break trust
- **Medium**: Color psychology affects motivation

#### **User Trust Issues**
- Users can't rely on stats for daily progress tracking
- Undermines the core value proposition of activity monitoring
- Creates doubt about system accuracy

### **Solution Requirements**

1. **Immediate Fixes**
   - Fix days parameter (1 → 0) for today's data
   - Fix time calculation with proper date handling
   - Change red confidence colors to neutral
   - Add data refresh mechanism

2. **User Experience Improvements**
   - Clear "Today" vs "Yesterday" labeling
   - Positive progress indicators
   - Real-time activity updates
   - Accurate time calculations

3. **Data Quality Assurance**
   - Validate date ranges in queries
   - Add logging for data inconsistencies
   - Test edge cases (midnight transitions)
   - Monitor query performance

### **Next Steps**

1. **FT-088**: Fix stats screen days parameter calculation
2. **FT-089**: Remove negative color indicators for confidence scores  
3. **FT-090**: Implement real-time stats screen refresh mechanism

This analysis provides the foundation for targeted fixes to restore user trust and data accuracy in the stats screen.
