import 'package:flutter/foundation.dart';

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
    }
  }

  /// Log a startup-related message if startup logging is enabled
  void logStartup(String message) {
    if (_isEnabled && _logStartupEvents) {
      print('🚀 [STARTUP] $message');
    }
  }

  /// Log an error message if logging is enabled
  void error(String message) {
    if (_isEnabled) {
      print('❌ [ERROR] $message');
    }
  }

  /// Log a warning message if logging is enabled
  void warning(String message) {
    if (_isEnabled) {
      print('⚠️ [WARNING] $message');
    }
  }

  /// Log an info message if logging is enabled
  void info(String message) {
    if (_isEnabled) {
      print('ℹ️ [INFO] $message');
    }
  }

  /// Log a debug message if logging is enabled and in debug mode
  void debug(String message) {
    if (_isEnabled && kDebugMode) {
      print('🔍 [DEBUG] $message');
    }
  }
}
