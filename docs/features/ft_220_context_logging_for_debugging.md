# FT-220: Complete Context Logging for Debugging & Optimization

**Feature ID**: FT-220  
**Priority**: High  
**Category**: Developer Tools / Debugging  
**Effort Estimate**: 6-7 hours (MVP)  
**Status**: Specification  
**Created**: 2025-10-24  
**Branch**: `feature/ft-220-context-logging`  
**Approach**: MVP (Minimum Viable Product) - Core functionality first, advanced features deferred

---

## 📋 Overview

Implement **MVP context logging** that captures the **EXACT** context sent to the Claude API for every request, enabling immediate debugging of repetition bugs (FT-206), token usage analysis, and system prompt optimization.

**MVP Focus**: Core logging functionality with zero overhead when disabled. Advanced features (export, auto-cleanup, analysis) deferred to future iterations.

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

**What Gets Logged (MVP)**:
- ✅ Complete system prompt (every character)
- ✅ Complete messages array (all messages)
- ✅ Complete API request (raw JSON)
- ✅ Complete API response (raw JSON)
- ✅ Basic metadata (persona, session, timestamp)
- ✅ Token usage (from API response)
- ❌ API key (redacted for security)
- ⏸️ **Deferred**: Automated analysis, detailed timing metrics (can be added later)

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

### **FR-6: Manual File Access** (MVP)

**Description**: Users can manually access log files via device file manager.

**File Location**:
- iOS: App Documents directory
- Android: App-specific storage
- Path: `<app_documents>/logs/context/session_<timestamp>/`

**Acceptance Criteria**:
- [ ] Log files are accessible via Files app (iOS) or file manager (Android)
- [ ] Files are readable JSON format
- [ ] Directory structure is clear and organized

**Note**: Export and auto-cleanup features deferred to Phase 4 (future iteration)

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

### **Context Log File (MVP - Simplified)**

```json
{
  "metadata": {
    "context_id": "ctx_001_1729795845123",
    "timestamp": "2025-10-24T18:30:45.123Z",
    "persona_key": "iThereWithOracle42",
    "persona_display_name": "I-There 4.2",
    "oracle_enabled": true,
    "session_id": "session_1729795000000",
    "message_number": 1
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
      "system": "<COMPLETE SYSTEM PROMPT - EVERY CHARACTER>",
      "messages": [
        {"role": "user", "content": "previous message"},
        {"role": "assistant", "content": "previous response"},
        {"role": "user", "content": "current message"}
      ]
    },
    "raw_json": "<COMPLETE REQUEST JSON STRING>"
  },
  "api_response": {
    "status_code": 200,
    "body": {
      "id": "msg_123",
      "content": [
        {"type": "text", "text": "<COMPLETE RESPONSE TEXT>"}
      ],
      "usage": {
        "input_tokens": 3850,
        "output_tokens": 150
      }
    },
    "raw_json": "<COMPLETE RESPONSE JSON STRING>"
  }
}
```

**Note**: Advanced analysis (timing, layer detection, flags) deferred to Phase 5

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

### **Phase 1: Configuration & Core Service** (3 hours)

**Files to Create**:
- [ ] `assets/config/context_logging_config.json` - Feature configuration
- [ ] `lib/services/context_logger_service.dart` - Core logging service

**Implementation**:
```dart
class ContextLoggerService {
  bool _enabled = false;
  String? _sessionId;
  int _contextCounter = 0;
  
  // Initialize and load config
  Future<void> initialize() async {
    final config = await _loadConfig();
    _enabled = config['enabled'] ?? false;
    if (!_enabled) return;  // ⚠️ Early return - zero overhead
    
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    await _ensureLogDirectory();
  }
  
  // Log context (NO-OP if disabled)
  Future<String?> logContext({
    required Map<String, dynamic> apiRequest,
    required Map<String, dynamic> metadata,
  }) async {
    if (!_enabled) return null;  // ⚠️ Guard pattern - zero overhead
    
    // ... logging implementation ...
  }
}
```

**Key Requirements (MVP)**:
- [ ] Guard pattern: `if (!_enabled) return null;` at start of every method
- [ ] Configuration loading with `enabled: false` default
- [ ] Session directory creation: `logs/context/session_<timestamp>/`
- [ ] Sequential file naming: `ctx_001_<timestamp>.json`
- [ ] Complete data logging (API request, response, basic metadata)
- [ ] API key redaction in headers
- [ ] Simple JSON structure (no complex analysis)

---

### **Phase 2: Integration with ClaudeService** (2 hours)

**File to Modify**:
- [ ] `lib/services/claude_service.dart`

**Integration Points**:

```dart
// 1. Add service instance
final _contextLogger = ContextLoggerService();

// 2. Initialize in constructor
ClaudeService() {
  // ... existing initialization ...
  _contextLogger.initialize();
}

// 3. Log before API call in _sendMessageInternal()
Future<String> _sendMessageInternal(...) async {
  // ... build context ...
  
  // ✅ Log context (zero overhead if disabled)
  String? contextLogPath;
  if (_contextLogger.isEnabled) {
    contextLogPath = await _contextLogger.logContext(
      apiRequest: {
        'endpoint': 'https://api.anthropic.com/v1/messages',
        'method': 'POST',
        'body': {
          'model': 'claude-sonnet-4-20250514',
          'system': systemPrompt,  // ⚠️ Complete system prompt
          'messages': messages,     // ⚠️ Complete messages array
        },
      },
      metadata: {
        'persona_key': _configManager.activePersonaKey,
        'oracle_enabled': await _configManager.isOracleEnabled(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  // Make API call
  final response = await _makeApiCall(...);
  
  // ✅ Update with response (zero overhead if disabled)
  if (contextLogPath != null) {
    await _contextLogger.updateWithResponse(
      contextLogPath: contextLogPath,
      response: response,
    );
  }
  
  return response.text;
}
```

**Key Requirements**:
- [ ] Log EXACT system prompt (no truncation)
- [ ] Log EXACT messages array (no filtering)
- [ ] Log raw JSON strings for reproduction
- [ ] Include timing metrics
- [ ] Include token usage from response

---

### **Phase 3: Settings UI** (1-2 hours)

**File to Modify**:
- [ ] `lib/screens/settings_screen.dart`

**UI Components**:

```dart
// 1. Add state variable
bool _contextLoggingEnabled = false;

// 2. Add settings card
Card(
  color: _contextLoggingEnabled ? Colors.orange[100] : null,
  child: Column(
    children: [
      SwitchListTile(
        title: Text('Context Logging (Debug)'),
        subtitle: Text(
          _contextLoggingEnabled 
            ? '⚠️ ENABLED - Logging complete conversation'
            : 'Disabled'
        ),
        value: _contextLoggingEnabled,
        onChanged: (value) {
          if (value) {
            _showContextLoggingWarning(value);
          } else {
            setState(() => _contextLoggingEnabled = false);
            ContextLoggerService().setEnabled(false);
          }
        },
      ),
      if (_contextLoggingEnabled) ...[
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ WARNING: Logs contain COMPLETE conversation history.',
                style: TextStyle(color: Colors.orange[900], fontSize: 12),
              ),
              SizedBox(height: 8),
              Text(
                'Access logs via Files app:\nlogs/context/session_<timestamp>/',
                style: TextStyle(color: Colors.grey[700], fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ],
  ),
)

// 3. Add warning dialog
Future<void> _showContextLoggingWarning(bool enable) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('⚠️ Enable Context Logging?'),
      content: Text(
        'Context logging will record:\n\n'
        '• Complete conversation history\n'
        '• All user messages (exact text)\n'
        '• All AI responses (exact text)\n'
        '• Complete system prompts\n\n'
        'Enable only if you understand the privacy implications.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Enable'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    setState(() => _contextLoggingEnabled = true);
    await ContextLoggerService().setEnabled(true);
  }
}
```

**Key Requirements (MVP)**:
- [ ] Toggle switch with visual warning (orange background)
- [ ] Confirmation dialog with clear privacy warning
- [ ] File path display for manual access
- ⏸️ **Deferred**: Export and clear buttons (manual file access for MVP)

---

### **Phase 4: Testing & Documentation** (1 hour)

**Unit Tests** (`test/services/context_logger_service_test.dart`):
- [ ] Test initialization with enabled/disabled
- [ ] Test guard pattern (no-op when disabled)
- [ ] Test file creation and writing
- [ ] Test API key redaction

**Integration Tests**:
- [ ] Test end-to-end logging flow
- [ ] Test settings UI integration

**Manual Testing (MVP)**:
- [ ] Enable logging and send messages
- [ ] Verify log files contain complete data
- [ ] Verify API key is redacted
- [ ] Access logs via Files app (iOS) or file manager (Android)
- [ ] Disable logging and verify no overhead

**Documentation**:
- [ ] Document file location for manual access
- [ ] Document privacy considerations
- [ ] Create implementation summary

---

## 📦 Dependencies

**Packages to Add** (if not already present):
```yaml
dependencies:
  path_provider: ^2.1.0  # For app documents directory
```

**Note**: `archive` package for ZIP export deferred to Phase 5 (future iteration)

---

## ⚡ Quick Start Guide

**1. Create Configuration**:
```bash
# Create config file with enabled: false
touch assets/config/context_logging_config.json
```

**2. Implement Core Service**:
```bash
# Create service file
touch lib/services/context_logger_service.dart
```

**3. Integrate with ClaudeService**:
```bash
# Modify claude_service.dart
# Add logging before/after API calls
```

**4. Add Settings UI**:
```bash
# Modify settings_screen.dart
# Add toggle, warning, export, clear
```

**5. Test**:
```bash
# Run tests
flutter test test/services/context_logger_service_test.dart

# Manual test (MVP)
# 1. Enable logging in settings
# 2. Send messages
# 3. Access logs via Files app: logs/context/session_<timestamp>/
# 4. Verify JSON files contain complete context
```

---

**Total Effort**: 6-7 hours (MVP)

**Priority**: Implement Phase 1-3 (core functionality + UI), then Phase 4 (testing & docs)

---

## 🔮 Phase 5: Future Enhancements (Deferred)

**Export Functionality** (2 hours):
- ZIP export of all context files
- Share via system share dialog
- Export button in settings

**Auto Cleanup** (1 hour):
- Auto-delete logs older than N days
- Configurable cleanup interval
- Cleanup on app startup

**Clear Logs Button** (30 min):
- Manual clear all logs
- Confirmation dialog

**Advanced Analysis** (2 hours):
- Automated layer detection
- Token breakdown by layer
- Pattern detection flags

**Total Future Enhancements**: 5-6 hours

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

