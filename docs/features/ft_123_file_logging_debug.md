# FT-123: Simple File Logging Enhancement

**Feature ID:** FT-123  
**Priority:** High  
**Category:** Development Tools  
**Effort Estimate:** 30 minutes  
**Dependencies:** None  

## Overview

Extend the existing `Logger` utility class to also write log messages to a persistent file in the `logs/` directory. This simple enhancement will enable debugging of issues that persist across app sessions, particularly the FT-122 database connection problems.

## Problem Statement

Currently, debugging complex issues like the FT-122 database connection problems relies on console output, which:
- Disappears when the app restarts
- Cannot be easily shared or analyzed
- Is lost when debugging across app sessions

## Solution

Extend the existing `Logger` class (`lib/utils/logger.dart`) to also write all log messages to a file:
- Append to a single log file: `logs/debug.log`
- Add timestamps to file entries
- Maintain existing console output behavior
- No configuration needed - works automatically when logging is enabled

## Functional Requirements

### FR-123-01: File Output
- **Requirement:** Write all log messages to `logs/debug.log`
- **Details:**
  - Create `logs/` directory if it doesn't exist
  - Append messages with timestamps
  - Preserve existing console output behavior
  - Handle file creation errors gracefully

### FR-123-02: Timestamp Format
- **Requirement:** Add timestamps to file entries
- **Details:**
  - Format: `[2025-09-16 14:30:22] [ERROR] Database connection lost`
  - Use same log level indicators as console output
  - Maintain message formatting consistency

## Technical Implementation

### File Structure
```
logs/
└── debug.log    # Single persistent log file
```

### Log Entry Format
```
[2025-09-16 14:30:22] ❌ [ERROR] Database connection lost
[2025-09-16 14:30:23] 🔍 [DEBUG] Attempting reconnection...
[2025-09-16 14:30:24] ✅ [INFO] Connection restored
```

### Implementation Changes

Extend existing `Logger` class with:
```dart
// Add these fields
File? _logFile;

// Add this initialization method
Future<void> _initLogFile() async {
  // Create logs/debug.log
}

// Add this helper method
void _writeToFile(String message) {
  // Append timestamped message to file
}

// Modify existing methods to also write to file
void log(String message) {
  if (_isEnabled) {
    print(message);
    _writeToFile(message); // Add this line
  }
}
```

## Implementation Steps

### Single Implementation Phase (30 minutes)
1. **Add file initialization** - Create `logs/debug.log` on first use
2. **Add timestamp helper** - Format current time for file entries
3. **Add file writing method** - Append messages to log file
4. **Modify existing log methods** - Add file writing to all log methods (log, error, warning, info, debug, logStartup)
5. **Handle errors gracefully** - Don't crash if file operations fail

## Success Criteria

### Acceptance Criteria
- [ ] `logs/debug.log` file is created automatically
- [ ] All log messages appear in both console and file
- [ ] File entries include timestamps
- [ ] Existing console behavior is unchanged
- [ ] File operations don't crash the app if they fail
- [ ] No configuration required - works when logging is enabled

### Testing Approach
- **Manual Testing:** Enable logging, verify file is created and contains messages
- **Error Testing:** Verify app doesn't crash if file operations fail
- **FT-122 Integration:** Use for debugging database connection issues

## Dependencies

### Internal Dependencies
- Existing `Logger` utility class (`lib/utils/logger.dart`)

### External Dependencies
- `path_provider` package (already in use)
- Dart `io` library for file operations

## Future Enhancements

### Potential Extensions (Later)
- Log rotation when file gets too large
- Log level filtering
- Component tagging
- In-app log viewer

### Immediate Benefit
- **FT-122 Debug Support:** Persistent logging for database connection debugging
- **Cross-session Analysis:** Compare behavior across app restarts
- **Shareable Debug Info:** Easy to share log files for collaborative debugging

---

**Created:** 2025-09-16  
**Last Updated:** 2025-09-16  
**Status:** Draft  
**Assigned:** Development Agent
