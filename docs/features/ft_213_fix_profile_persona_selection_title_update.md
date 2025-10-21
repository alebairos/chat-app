# FT-213: Fix Profile Persona Selection Title Update

**Feature ID:** FT-213  
**Priority:** Medium  
**Category:** Bug Fix  
**Effort:** 30 minutes  
**Date:** October 20, 2025

## Overview

Fix bug where selecting a persona via the profile menu updates the persona but doesn't refresh the app title, leaving users confused about which persona is active.

---

## **Problem Statement**

### **Issue: Broken Callback Chain for Profile Persona Selection**
- **Problem**: When selecting persona via Profile → Persona Selection, the persona changes but app title remains outdated
- **User Impact**: Users see incorrect persona name in title bar, causing confusion about active persona
- **Root Cause**: ProfileScreen lacks callback to notify HomeScreen of persona changes
- **Scope**: Only affects profile menu selection; @mention persona switching works correctly

### **Current Behavior**
- ✅ @mention persona switch: Updates persona AND title
- ❌ Profile menu persona switch: Updates persona but NOT title

### **Expected Behavior**
- ✅ Both methods should update persona AND title consistently

---

## **Technical Analysis**

### **Root Cause**
Missing callback chain between ProfileScreen and HomeScreen:

**Working Flow (@mention)**:
```
ChatInput → ChatScreen → HomeScreen._refreshPersonaName() ✅
```

**Broken Flow (Profile)**:
```
ProfileScreen → ❌ NO CONNECTION ❌ → HomeScreen
```

### **Current Code Issue**
In `ProfileScreen.onTap()` (line ~179):
```dart
onCharacterSelected: () {
  setState(() {}); // Only refreshes ProfileScreen, NOT HomeScreen
}
```

---

## **Solution**

### **Approach: Add Callback Parameter (Consistent with ChatScreen)**

**Step 1: Modify ProfileScreen**
- Add optional `onPersonaChanged` callback parameter
- Call callback when persona selection completes

**Step 2: Update HomeScreen**
- Pass `_refreshPersonaName` callback to ProfileScreen in TabBarView

### **Implementation**

**File**: `lib/screens/profile_screen.dart`
```dart
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onPersonaChanged; // ADD
  
  const ProfileScreen({
    super.key,
    this.onPersonaChanged, // ADD
  });
}

// In onTap method:
onCharacterSelected: () {
  setState(() {});
  widget.onPersonaChanged?.call(); // ADD - notify parent
}
```

**File**: `lib/main.dart`
```dart
body: TabBarView(
  controller: _tabController,
  children: [
    ChatScreen(onPersonaChanged: _refreshPersonaName),
    const StatsScreen(),
    const JournalScreen(),
    ProfileScreen(onPersonaChanged: _refreshPersonaName), // ADD
  ],
),
```

---

## **Risk Assessment**

**Risk Level**: **MINIMAL**

**Why Low Risk**:
- Optional parameter - no breaking changes
- Follows existing ChatScreen pattern exactly
- Only 2 files, 3 lines added
- Trivial rollback (remove 3 lines)

---

## **Testing Strategy**

**Pre-Implementation**:
```bash
flutter test  # Ensure baseline passes
```

**Test Cases**:
1. ✅ Profile persona selection → title updates
2. ✅ @mention persona selection → still works  
3. ✅ Tab navigation → maintains correct title
4. ✅ Existing tests → no regressions

---

## **Acceptance Criteria**

- [ ] Profile persona selection updates app title immediately
- [ ] @mention persona selection continues to work
- [ ] No breaking changes to existing functionality
- [ ] All existing tests pass
- [ ] Consistent behavior between both persona selection methods

---

## **Implementation Notes**

**Files Modified**: 2  
**Lines Added**: 3  
**Pattern**: Follows FT-208 callback architecture  
**Dependencies**: None  
**Migration**: None required
