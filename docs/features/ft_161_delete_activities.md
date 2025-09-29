# FT-161: Delete Activities

**Feature ID**: FT-161  
**Priority**: Medium  
**Category**: Data Management/UI  
**Effort Estimate**: 45 minutes  
**Dependencies**: ActivityMemoryService, FT-071 (Clear Chat History patterns)  
**Status**: Specification  

## Overview

Add "Clear Activity Data" functionality to complement the existing "Clear Chat History" (FT-071), enabling users to selectively delete activity tracking data while preserving chat messages. This provides granular control over data management and supports clean database scenarios for testing and fresh starts.

## Problem Statement

Users need the ability to clear activity tracking data independently of chat history for:
1. **Testing scenarios** - Clean activity slate for import/export testing
2. **Privacy management** - Remove activity history while keeping conversations
3. **Fresh tracking start** - Reset activity data without losing chat context
4. **Granular data control** - Complement existing chat clearing functionality

## Functional Requirements

### Core Functionality
- **FR-161-01**: Add "Clear Activity Data" button in Data Management section
- **FR-161-02**: Clear all ActivityModel entries from Isar database
- **FR-161-03**: Preserve all ChatMessageModel entries (inverse of FT-071)
- **FR-161-04**: Stats automatically update to reflect empty state (calculated dynamically)

### User Safety
- **FR-161-05**: Show confirmation dialog before clearing (follow FT-071 pattern)
- **FR-161-06**: Provide clear explanation of what will be cleared vs preserved
- **FR-161-07**: Allow user to cancel the operation
- **FR-161-08**: Show success confirmation after completion

### UI Integration
- **FR-161-09**: Place after "Clear Chat History" in Data Management section
- **FR-161-10**: Use consistent styling and confirmation patterns from FT-071

## Implementation Notes

**Service Method:**
```dart
Future<void> deleteAllActivities() async {
  await isar.writeTxn(() async {
    await isar.activityModels.clear();
  });
}
```

**Confirmation Dialog:**
- Title: "Clear Activity Data"
- Message: "This will remove all activity tracking data but keep your chat messages. Continue?"
- Actions: Cancel / Clear

## Expected Results

✅ **Empty activity stats** - All counters reset to 0  
✅ **Preserved chat history** - Messages remain intact  
✅ **Auto-updated UI** - Stats screen reflects empty state  
✅ **Clean testing environment** - Ready for activity import testing
