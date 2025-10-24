# FT-220: Complete Context Logging for Debugging & Optimization

**Feature ID**: FT-220  
**Priority**: High  
**Category**: Developer Tools / Debugging  
**Effort Estimate**: 9-12 hours  
**Status**: Specification  
**Created**: 2025-10-24  
**Branch**: `feature/ft-220-context-logging`

---

## 📋 Overview

Implement comprehensive context logging that captures the **EXACT** context sent to the Claude API for every request, enabling debugging, optimization, and analysis of system prompt complexity, token usage, and conversation patterns.

---

## 🎯 Problem Statement

### **Current Issues**

1. **No Visibility**: Cannot see what context is actually sent to the model
2. **Difficult Debugging**: Hard to diagnose issues like repetition bugs (FT-206)
3. **No Token Tracking**: Cannot measure actual token usage per request
4. **No Optimization Data**: Cannot identify redundant or inefficient prompt sections
5. **Manual Analysis**: Must manually inspect code to understand context building

### **Impact**

- Repetition bugs are hard to diagnose without seeing exact context
- Token optimization is guesswork without actual usage data
- Prompt engineering is trial-and-error without visibility
- System prompt complexity cannot be measured objectively

---

## 💡 Solution

### **Core Concept**

Log the **complete, unfiltered context** sent to the Claude API to local files, with:
- Zero performance overhead when disabled
- Complete transparency (log everything except API key)
- User control with clear privacy warnings
- Export capability for analysis

### **Three-Tier Architecture**

1. **Configuration Layer**: `context_logging_config.json` with `enabled: false` default
2. **Service Layer**: `ContextLoggerService` with guard pattern
3. **UI Layer**: Settings toggle with privacy warning

---

## 📐 Functional Requirements

### **FR-1: Complete Context Logging**

**Description**: Log the EXACT API request and response with zero filtering.

**What Gets Logged**:
- ✅ Complete system prompt (every character)
- ✅ Complete messages array (all messages)
- ✅ Complete API request (raw JSON)
- ✅ Complete API response (raw JSON)
- ✅ Timing metrics (latency, TTFB)
- ✅ Token usage (input, output, total)
- ✅ Metadata (persona, session, timestamp)
- ✅ Automated analysis (layer breakdown, flags)
- ❌ API key (redacted for security)

**Acceptance Criteria**:
- [ ] System prompt is logged character-for-character
- [ ] Messages array is logged without truncation
- [ ] Raw JSON strings are included for exact reproduction
- [ ] API key is redacted in headers
- [ ] All other data is unfiltered

---

### **FR-2: Zero Overhead When Disabled**

**Description**: When `enabled: false`, logging has ZERO performance impact.

**Implementation**:
- Guard pattern: `if (!_enabled) return null;`
- Early return before any computation
- No file I/O, no JSON serialization, no analysis

**Acceptance Criteria**:
- [ ] Single boolean check when disabled
- [ ] No file system operations when disabled
- [ ] No JSON serialization when disabled
- [ ] No performance degradation when disabled

---

### **FR-3: Configuration Control**

**Description**: Configuration file controls all logging behavior.

**File**: `assets/config/context_logging_config.json`

```json
{
  "enabled": false,
  "settings": {
    "log_api_request": true,
    "log_api_response": true,
    "log_raw_json": true,
    "log_timing": true,
    "include_analysis": true,
    "redact_api_key": true,
    "max_logs_per_session": 100,
    "auto_cleanup_days": 7
  },
  "storage": {
    "directory": "logs/context",
    "format": "json",
    "compression": "none",
    "max_file_size_mb": 10
  }
}
```

**Acceptance Criteria**:
- [ ] Config file exists with `enabled: false` default
- [ ] All settings are configurable
- [ ] Config is loaded at app startup
- [ ] Config changes require app restart

---

### **FR-4: File Organization**

**Description**: Logs are organized by session with sequential numbering.

**Structure**:
```
logs/
  context/
    session_<timestamp>/
      ctx_001_<timestamp>.json
      ctx_002_<timestamp>.json
      ctx_003_<timestamp>.json
      ...
```

**Acceptance Criteria**:
- [ ] Session directory created on app launch
- [ ] Context files numbered sequentially
- [ ] Timestamps in ISO 8601 format
- [ ] JSON files are valid and parseable

---

### **FR-5: Settings UI**

**Description**: User can enable/disable logging with clear privacy warning.

**UI Elements**:
- Toggle switch for enable/disable
- Warning message when enabled
- Confirmation dialog when enabling
- Export button (when enabled)
- Clear logs button (when enabled)

**Acceptance Criteria**:
- [ ] Toggle switch in Settings screen
- [ ] Warning dialog on enable
- [ ] Clear privacy notice displayed
- [ ] Export functionality works
- [ ] Clear logs functionality works

---

### **FR-6: Export Functionality**

**Description**: User can export context logs for analysis.

**Export Format**:
- ZIP archive of all context files
- Named: `session_<timestamp>_export.zip`
- Shared via system share dialog

**Acceptance Criteria**:
- [ ] Export creates ZIP archive
- [ ] ZIP contains all context files
- [ ] Share dialog opens correctly
- [ ] Files are readable after export

---

### **FR-7: Auto Cleanup**

**Description**: Old logs are automatically deleted after N days.

**Behavior**:
- Check on app startup
- Delete logs older than `auto_cleanup_days`
- Log cleanup actions

**Acceptance Criteria**:
- [ ] Cleanup runs on app startup
- [ ] Logs older than N days are deleted
- [ ] Cleanup is logged
- [ ] Cleanup can be disabled (set to 0)

---

## 🎨 Non-Functional Requirements

### **NFR-1: Performance**

- Zero overhead when disabled (single boolean check)
- Minimal overhead when enabled (<50ms per log)
- Async file I/O to avoid blocking UI
- No impact on API request latency

### **NFR-2: Privacy**

- Clear warning about data sensitivity
- Opt-in only (disabled by default)
- Local storage only (no cloud sync)
- User control over export and deletion

### **NFR-3: Security**

- API key redacted in all logs
- Logs excluded from app backup
- Logs stored in app documents directory
- No network transmission of logs

### **NFR-4: Reliability**

- Logging failures don't crash app
- Graceful degradation if disk full
- Error logging for debugging
- Validation of log file integrity

---

## 🏗️ Technical Architecture

### **Components**

1. **ContextLoggerService** (`lib/services/context_logger_service.dart`)
   - Singleton service
   - Manages logging lifecycle
   - Handles file I/O
   - Provides export/cleanup

2. **Configuration** (`assets/config/context_logging_config.json`)
   - Feature toggle
   - Settings
   - Storage configuration

3. **Settings UI** (`lib/screens/settings_screen.dart`)
   - Toggle switch
   - Warning dialog
   - Export/clear buttons

4. **Integration** (`lib/services/claude_service.dart`)
   - Log context before API call
   - Update with response after API call
   - Guard pattern for zero overhead

---

## 📊 Data Structure

### **Context Log File**

```json
{
  "metadata": {
    "context_id": "ctx_001_1729795845123",
    "timestamp": "2025-10-24T18:30:45.123Z",
    "persona_key": "iThereWithOracle42",
    "persona_display_name": "I-There 4.2",
    "oracle_enabled": true,
    "session_id": "session_1729795000000",
    "message_number": 1,
    "app_version": "2.0.1",
    "build_number": "25"
  },
  "api_request": {
    "endpoint": "https://api.anthropic.com/v1/messages",
    "method": "POST",
    "headers": {
      "anthropic-version": "2023-06-01",
      "x-api-key": "[REDACTED]"
    },
    "body": {
      "model": "claude-sonnet-4-20250514",
      "max_tokens": 4096,
      "system": "<COMPLETE SYSTEM PROMPT>",
      "messages": [...]
    },
    "raw_json": "<COMPLETE REQUEST JSON>"
  },
  "api_response": {
    "status_code": 200,
    "body": {
      "id": "msg_123",
      "content": [...],
      "usage": {
        "input_tokens": 3850,
        "output_tokens": 150
      }
    },
    "raw_json": "<COMPLETE RESPONSE JSON>"
  },
  "timing": {
    "request_sent_at": "2025-10-24T18:30:45.123Z",
    "response_received_at": "2025-10-24T18:30:47.456Z",
    "latency_ms": 2333
  },
  "analysis": {
    "system_prompt": {
      "total_chars": 45678,
      "total_lines": 1082,
      "total_tokens": 3850,
      "layers_detected": [...]
    },
    "flags": {
      "has_priority_header": true,
      "has_conversation_context": true,
      "oracle_enabled": true
    }
  }
}
```

---

## 🧪 Testing Strategy

### **Unit Tests**

- [ ] `ContextLoggerService` initialization
- [ ] `ContextLoggerService` enable/disable
- [ ] `ContextLoggerService` logging when enabled
- [ ] `ContextLoggerService` no-op when disabled
- [ ] Configuration loading
- [ ] File creation and writing
- [ ] Export functionality
- [ ] Cleanup functionality

### **Integration Tests**

- [ ] End-to-end logging flow
- [ ] Settings UI integration
- [ ] Export and share flow
- [ ] Cleanup on startup

### **Manual Testing**

- [ ] Enable logging and send messages
- [ ] Verify log files are created
- [ ] Verify log content is complete
- [ ] Export logs and verify ZIP
- [ ] Clear logs and verify deletion
- [ ] Disable logging and verify no files

---

## 📈 Success Metrics

1. **Functionality**: All context logs contain complete, unfiltered data
2. **Performance**: Zero overhead when disabled (<1ms boolean check)
3. **Usability**: Users can enable, export, and clear logs easily
4. **Privacy**: Clear warnings prevent accidental data exposure
5. **Debugging**: Logs enable diagnosis of repetition bugs and optimization

---

## 🚀 Implementation Plan

### **Phase 1: Core Service** (4 hours)

- [ ] Create `ContextLoggerService` class
- [ ] Implement configuration loading
- [ ] Implement file I/O
- [ ] Implement guard pattern
- [ ] Add unit tests

### **Phase 2: Integration** (2 hours)

- [ ] Integrate into `claude_service.dart`
- [ ] Add logging before API call
- [ ] Add response update after API call
- [ ] Test end-to-end flow

### **Phase 3: Settings UI** (2 hours)

- [ ] Add toggle switch
- [ ] Add warning dialog
- [ ] Add export button
- [ ] Add clear logs button
- [ ] Test UI flow

### **Phase 4: Export & Cleanup** (2 hours)

- [ ] Implement ZIP export
- [ ] Implement auto cleanup
- [ ] Test export functionality
- [ ] Test cleanup functionality

### **Phase 5: Documentation & Testing** (2 hours)

- [ ] Write user documentation
- [ ] Write developer documentation
- [ ] Manual testing
- [ ] Bug fixes

**Total Effort**: 12 hours

---

## 🔒 Privacy & Security

### **Privacy Considerations**

1. **Disabled by Default**: Feature is opt-in only
2. **Clear Warning**: Users see privacy warning before enabling
3. **Local Storage**: Logs stored locally, never transmitted
4. **User Control**: Users can export and delete logs at any time
5. **Auto Cleanup**: Old logs automatically deleted

### **Security Measures**

1. **API Key Redaction**: API key is always redacted
2. **No Cloud Sync**: Logs excluded from cloud backup
3. **App Sandbox**: Logs stored in app documents directory
4. **No Network**: Logs never transmitted over network

---

## 📚 Related Features

- **FT-206**: System prompt optimization (needs context logs for analysis)
- **FT-210**: Duplicate conversation history fix (diagnosed via context logs)
- **FT-211**: Coaching objective tracking (needs context logs for verification)

---

## 🎯 Definition of Done

- [ ] `ContextLoggerService` implemented and tested
- [ ] Configuration file created with `enabled: false`
- [ ] Integration into `claude_service.dart` complete
- [ ] Settings UI implemented with warning dialog
- [ ] Export functionality working
- [ ] Clear logs functionality working
- [ ] Auto cleanup working
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Manual testing complete
- [ ] Documentation complete
- [ ] Code reviewed and approved
- [ ] Merged to develop branch

---

## 📝 Notes

- This feature is critical for debugging and optimization
- Zero overhead when disabled ensures no production impact
- Complete transparency enables effective prompt engineering
- Privacy warnings prevent accidental data exposure
- Export capability enables external analysis tools

---

**Next Steps**: Implement Phase 1 (Core Service) on `feature/ft-220-context-logging` branch.

