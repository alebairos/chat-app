import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// FT-220: Context logging service for debugging and optimization
///
/// Logs complete API request/response context to local files for analysis.
/// Zero overhead when disabled via guard pattern.
class ContextLoggerService {
  static final ContextLoggerService _instance =
      ContextLoggerService._internal();
  factory ContextLoggerService() => _instance;
  ContextLoggerService._internal();

  final _logger = Logger();

  bool _enabled = false;
  bool _initialized = false;
  String? _sessionId;
  int _contextCounter = 0;
  Map<String, dynamic>? _config;

  /// Check if logging is enabled
  bool get isEnabled => _enabled;

  /// Check if feature is available (from config)
  /// Returns false if config has enabled = false, preventing UI from showing the feature
  bool get isFeatureAvailable => _config?['enabled'] ?? false;

  /// Initialize service and load configuration
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _loadConfig();
      _enabled = _config?['enabled'] ?? false;

      if (!_enabled) {
        _logger.info('🚫 Context logging DISABLED');
        _initialized = true;
        return;
      }

      // Create session ID
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      _contextCounter = 0;

      // Ensure log directory exists
      await _ensureLogDirectory();

      _logger.info('✅ Context logging ENABLED - Session: $_sessionId');
      _initialized = true;
    } catch (e) {
      _logger.error('❌ Failed to initialize context logging: $e');
      _enabled = false;
      _initialized = true;
    }
  }

  /// Load configuration from assets
  Future<void> _loadConfig() async {
    try {
      final configString = await rootBundle.loadString(
        'assets/config/context_logging_config.json',
      );
      _config = json.decode(configString) as Map<String, dynamic>;
      _logger.info('✅ Loaded context logging config');
    } catch (e) {
      _logger.error('❌ Failed to load context logging config: $e');
      _config = {'enabled': false};
    }
  }

  /// Ensure log directory exists
  Future<void> _ensureLogDirectory() async {
    if (!_enabled) return;

    try {
      final directory = await _getContextDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        _logger.info('✅ Created context log directory: ${directory.path}');
      }
    } catch (e) {
      _logger.error('❌ Failed to create log directory: $e');
    }
  }

  /// Get context directory for current session
  Future<Directory> _getContextDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final storage = _config?['storage'] as Map<String, dynamic>? ?? {};
    final baseDir = storage['directory'] as String? ?? 'logs/context';
    return Directory('${appDir.path}/$baseDir/$_sessionId');
  }

  /// Log complete context
  ///
  /// Returns file path if successful, null otherwise.
  /// NO-OP if logging is disabled (guard pattern).
  Future<String?> logContext({
    required Map<String, dynamic> apiRequest,
    required Map<String, dynamic> metadata,
  }) async {
    // ⚠️ GUARD PATTERN: Zero overhead when disabled
    if (!_enabled) return null;

    try {
      _contextCounter++;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final contextId =
          'ctx_${_contextCounter.toString().padLeft(3, '0')}_$timestamp';

      // Build context data
      final contextData = {
        'metadata': {
          ...metadata,
          'context_id': contextId,
          'session_id': _sessionId,
          'message_number': _contextCounter,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'api_request': _sanitizeApiRequest(apiRequest),
      };

      // Write to file
      final filePath = await _writeContextFile(contextId, contextData);
      _logger.info('✅ Context logged: $contextId');

      return filePath;
    } catch (e) {
      _logger.error('❌ Failed to log context: $e');
      return null;
    }
  }

  /// Update context log with API response
  ///
  /// NO-OP if logging is disabled (guard pattern).
  Future<void> updateWithResponse({
    required String contextFilePath,
    required Map<String, dynamic> apiResponse,
  }) async {
    // ⚠️ GUARD PATTERN: Zero overhead when disabled
    if (!_enabled) return;

    try {
      final file = File(contextFilePath);
      if (!await file.exists()) {
        _logger.warning('⚠️ Context file not found: $contextFilePath');
        return;
      }

      // Read existing context
      final existingContent = await file.readAsString();
      final contextData = json.decode(existingContent) as Map<String, dynamic>;

      // Add response
      contextData['api_response'] = apiResponse;

      // Write back
      await file.writeAsString(
        JsonEncoder.withIndent('  ').convert(contextData),
      );

      _logger.info(
          '✅ Updated context with response: ${contextData['metadata']['context_id']}');
    } catch (e) {
      _logger.error('❌ Failed to update context with response: $e');
    }
  }

  /// Sanitize API request (redact API key)
  Map<String, dynamic> _sanitizeApiRequest(Map<String, dynamic> request) {
    final sanitized = Map<String, dynamic>.from(request);

    // Redact API key from headers
    if (sanitized.containsKey('headers')) {
      final headers = Map<String, dynamic>.from(
        sanitized['headers'] as Map<String, dynamic>,
      );
      if (headers.containsKey('x-api-key')) {
        headers['x-api-key'] = '[REDACTED]';
      }
      sanitized['headers'] = headers;
    }

    return sanitized;
  }

  /// Write context file
  Future<String> _writeContextFile(
    String contextId,
    Map<String, dynamic> contextData,
  ) async {
    final directory = await _getContextDirectory();
    final file = File('${directory.path}/$contextId.json');

    final jsonString = JsonEncoder.withIndent('  ').convert(contextData);
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Enable/disable logging at runtime
  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;

    _enabled = enabled;
    _logger.info('Context logging ${enabled ? 'ENABLED' : 'DISABLED'}');

    if (enabled && !_initialized) {
      await initialize();
    }
  }

  /// Get current session ID
  String? get sessionId => _sessionId;

  /// Get context counter
  int get contextCount => _contextCounter;

  /// Get log directory path (for display in UI)
  Future<String?> getLogDirectoryPath() async {
    if (!_enabled || _sessionId == null) return null;

    try {
      final directory = await _getContextDirectory();
      return directory.path;
    } catch (e) {
      _logger.error('❌ Failed to get log directory path: $e');
      return null;
    }
  }
}
