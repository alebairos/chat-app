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

### **Phase 1: Configuration & Core Service** (3-4 hours)

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

**Key Requirements**:
- [ ] Guard pattern: `if (!_enabled) return null;` at start of every method
- [ ] Configuration loading with `enabled: false` default
- [ ] Session directory creation: `logs/context/session_<timestamp>/`
- [ ] Sequential file naming: `ctx_001_<timestamp>.json`
- [ ] Complete data logging (API request, response, timing, analysis)
- [ ] API key redaction in headers

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

### **Phase 3: Settings UI** (2 hours)

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
          child: Text(
            '⚠️ WARNING: Logs contain COMPLETE conversation history. Handle with care.',
            style: TextStyle(color: Colors.orange[900], fontSize: 12),
          ),
        ),
        ListTile(
          title: Text('Export Context Logs'),
          trailing: Icon(Icons.file_download),
          onTap: _exportContextLogs,
        ),
        ListTile(
          title: Text('Clear Context Logs'),
          trailing: Icon(Icons.delete),
          onTap: _clearContextLogs,
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

**Key Requirements**:
- [ ] Toggle switch with visual warning (orange background)
- [ ] Confirmation dialog with clear privacy warning
- [ ] Export functionality (ZIP archive)
- [ ] Clear logs functionality
- [ ] Only show export/clear when enabled

---

### **Phase 4: Export & Cleanup** (2 hours)

**Methods to Implement**:

```dart
// 1. Export session logs
Future<String> exportSessionLogs() async {
  final directory = await _getContextDirectory();
  final zipPath = '${directory.parent.path}/${_sessionId}_export.zip';
  
  // Create ZIP archive of all context files
  final encoder = ZipFileEncoder();
  encoder.create(zipPath);
  
  final files = directory.listSync();
  for (final file in files) {
    if (file is File) {
      encoder.addFile(file);
    }
  }
  
  encoder.close();
  return zipPath;
}

// 2. Auto cleanup old logs
Future<void> cleanupOldLogs() async {
  if (!_enabled) return;
  
  final config = await _loadConfig();
  final cleanupDays = config['settings']['auto_cleanup_days'] ?? 7;
  if (cleanupDays == 0) return;  // Cleanup disabled
  
  final logsDir = await _getLogsDirectory();
  final cutoffDate = DateTime.now().subtract(Duration(days: cleanupDays));
  
  final sessions = logsDir.listSync();
  for (final session in sessions) {
    if (session is Directory) {
      final stat = session.statSync();
      if (stat.modified.isBefore(cutoffDate)) {
        session.deleteSync(recursive: true);
        _logger.info('🗑️ Cleaned up old session: ${session.path}');
      }
    }
  }
}

// 3. Clear all logs
Future<void> clearAllLogs() async {
  final logsDir = await _getLogsDirectory();
  if (await logsDir.exists()) {
    await logsDir.delete(recursive: true);
    _logger.info('🗑️ Cleared all context logs');
  }
}
```

**Key Requirements**:
- [ ] ZIP export with all context files
- [ ] Share via system share dialog
- [ ] Auto cleanup on app startup
- [ ] Manual clear logs functionality
- [ ] Configurable cleanup days (0 = disabled)

---

### **Phase 5: Testing & Documentation** (2 hours)

**Unit Tests** (`test/services/context_logger_service_test.dart`):
- [ ] Test initialization with enabled/disabled
- [ ] Test guard pattern (no-op when disabled)
- [ ] Test file creation and writing
- [ ] Test API key redaction
- [ ] Test export functionality
- [ ] Test cleanup functionality

**Integration Tests**:
- [ ] Test end-to-end logging flow
- [ ] Test settings UI integration
- [ ] Test export and share flow

**Manual Testing**:
- [ ] Enable logging and send messages
- [ ] Verify log files contain complete data
- [ ] Verify API key is redacted
- [ ] Export logs and verify ZIP
- [ ] Clear logs and verify deletion
- [ ] Disable logging and verify no overhead

**Documentation**:
- [ ] Update README with context logging feature
- [ ] Document configuration options
- [ ] Document privacy considerations
- [ ] Create implementation summary

---

## 📦 Dependencies

**Packages to Add** (if not already present):
```yaml
dependencies:
  path_provider: ^2.1.0  # For app documents directory
  
dev_dependencies:
  archive: ^3.4.0  # For ZIP export
```

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

# Manual test
# 1. Enable logging in settings
# 2. Send messages
# 3. Verify logs in logs/context/
# 4. Export and verify ZIP
```

---

**Total Effort**: 11-12 hours

**Priority**: Implement Phase 1-2 first (core functionality), then Phase 3-4 (UI & features), finally Phase 5 (testing & docs)

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

