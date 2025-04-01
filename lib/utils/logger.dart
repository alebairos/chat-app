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

  /// Whether to show debug prints during startup
  bool _showDebugPrintsOnStartup = false;

  /// Whether the app is in startup mode
  bool _inStartupMode = true;

  /// Enable or disable all logging
  void setLogging(bool enabled) {
    _isEnabled = enabled;
  }

  /// Enable or disable logging of startup events specifically
  void setStartupLogging(bool enabled) {
    _logStartupEvents = enabled;
  }

  /// Enable or disable debug prints during startup
  void setDebugPrintsOnStartup(bool enabled) {
    _showDebugPrintsOnStartup = enabled;
  }

  /// Set whether the app is in startup mode
  void setStartupMode(bool inStartup) {
    _inStartupMode = inStartup;
  }

  /// Check if debug prints should be shown
  /// Returns true if either:
  /// - The app is not in startup mode
  /// - Debug prints are enabled during startup
  bool shouldShowDebugPrints() {
    return !_inStartupMode || _showDebugPrintsOnStartup;
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

/// A wrapper for debugPrint that respects the Logger settings
void logDebugPrint(String? message) {
  if (Logger()._isEnabled && (Logger().shouldShowDebugPrints() || kDebugMode)) {
    debugPrint(message);
  }
}
