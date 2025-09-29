# FT-162: Clear Messages and Activities

**Feature ID**: FT-162  
**Priority**: Medium  
**Category**: Data Management/UI  
**Effort Estimate**: 15 minutes  
**Dependencies**: FT-071 (Clear Chat History), FT-161 (Delete Activities)  
**Status**: Specification  

## Overview

Add "Clear Messages and Activities" shortcut button that combines FT-071 and FT-161 operations in sequence. This provides a convenient single-action method to achieve a completely clean database state without code duplication.

## Problem Statement

Users need a quick way to clear both chat history and activity data simultaneously for:
1. **Complete fresh start** - Clean slate for new user experience
2. **Testing preparation** - Empty database for comprehensive import/export testing
3. **Development workflows** - Quick database reset during feature development
4. **User convenience** - Single action instead of two separate operations

## Functional Requirements

### Core Functionality
- **FR-162-01**: Add "Clear Messages and Activities" button in Data Management section
- **FR-162-02**: Execute FT-071 clear chat history operation
- **FR-162-03**: Execute FT-161 clear activity data operation
- **FR-162-04**: Perform operations sequentially (no parallel execution)

### User Safety
- **FR-162-05**: Show comprehensive confirmation dialog explaining full scope
- **FR-162-06**: Single confirmation covers both operations (no double dialogs)
- **FR-162-07**: Allow user to cancel before any operations begin
- **FR-162-08**: Show unified success message after both operations complete

### Implementation Approach
- **FR-162-09**: **No code duplication** - Call existing FT-071 and FT-161 methods
- **FR-162-10**: **Error handling** - If first operation fails, don't proceed to second
- **FR-162-11**: **Atomic behavior** - Both succeed or both fail (rollback on partial failure)

## UI Integration

**Button Placement:** Below individual clear buttons in Data Management section  
**Button Style:** Distinct styling to indicate comprehensive action  
**Confirmation Dialog:**
- Title: "Clear Messages and Activities"
- Message: "This will remove ALL chat messages AND activity data. This action cannot be undone. Continue?"
- Actions: Cancel / Clear All

## Implementation Pattern

```dart
Future<void> _clearMessagesAndActivities() async {
  final confirmed = await _showClearAllConfirmation();
  if (!confirmed) return;
  
  try {
    await _clearChatHistory();  // Reuse FT-071
    await _clearActivityData(); // Reuse FT-161
    _showSuccessMessage("All data cleared successfully");
  } catch (e) {
    _showErrorMessage("Clear operation failed: $e");
  }
}
```

## Expected Results

✅ **Empty chat interface** - No messages displayed  
✅ **Zero activity stats** - All counters reset to 0  
✅ **Complete clean slate** - Ready for fresh start or testing  
✅ **No code duplication** - Leverages existing implementations
