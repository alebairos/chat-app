import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A utility class for controlling logging throughout the app.
class Logger {
  /// Singleton instance
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  /// Whether logging is enabled
  bool _isEnabled = false;

  /// Whether to log startup events (data loading, initialization)
  bool _logStartupEvents = false;

  /// Log file for persistent logging
  File? _logFile;

  /// Enable or disable all logging
  void setLogging(bool enabled) {
    _isEnabled = enabled;
  }

  /// Enable or disable logging of startup events specifically
  void setStartupLogging(bool enabled) {
    _logStartupEvents = enabled;
  }

  /// Check if startup logging is enabled
  bool isStartupLoggingEnabled() {
    return _isEnabled && _logStartupEvents;
  }

  /// Log a message if logging is enabled
  void log(String message) {
    if (_isEnabled) {
      print(message);
      _writeToFile(message);
    }
  }

  /// Log a startup-related message if startup logging is enabled
  void logStartup(String message) {
    if (_isEnabled && _logStartupEvents) {
      print('🚀 [STARTUP] $message');
      _writeToFile('🚀 [STARTUP] $message');
    }
  }

  /// Log an error message if logging is enabled
  void error(String message) {
    if (_isEnabled) {
      print('❌ [ERROR] $message');
      _writeToFile('❌ [ERROR] $message');
    }
  }

  /// Log a warning message if logging is enabled
  void warning(String message) {
    if (_isEnabled) {
      print('⚠️ [WARNING] $message');
      _writeToFile('⚠️ [WARNING] $message');
    }
  }

  /// Log an info message if logging is enabled
  void info(String message) {
    if (_isEnabled) {
      print('ℹ️ [INFO] $message');
      _writeToFile('ℹ️ [INFO] $message');
    }
  }

  /// Log a debug message if logging is enabled and in debug mode
  void debug(String message) {
    if (_isEnabled && kDebugMode) {
      print('🔍 [DEBUG] $message');
      _writeToFile('🔍 [DEBUG] $message');
    }
  }

  /// Initialize the log file if not already done
  Future<void> _initLogFile() async {
    if (_logFile != null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');

      // Create logs directory if it doesn't exist
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _logFile = File('${logsDir.path}/debug.log');
    } catch (e) {
      // Silently fail - don't crash the app if file operations fail
      print('Failed to initialize log file: $e');
    }
  }

  /// Get formatted timestamp for log entries
  String _getTimestamp() {
    final now = DateTime.now();
    return '[${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}]';
  }

  /// Write message to log file with timestamp
  void _writeToFile(String message) {
    if (!_isEnabled) return;

    // Initialize file if needed (async, but don't wait)
    _initLogFile().then((_) {
      if (_logFile != null) {
        try {
          final timestampedMessage = '${_getTimestamp()} $message\n';
          _logFile!
              .writeAsStringSync(timestampedMessage, mode: FileMode.append);
        } catch (e) {
          // Silently fail - don't crash the app if file operations fail
        }
      }
    });
  }
}
