import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../utils/logger.dart';

/// Generic MCP (Model Context Protocol) service for system functions
///
/// This service provides AI-callable functions for system operations like
/// getting current time, device info, and other non-domain-specific utilities.
/// It replaces the legacy LifePlan-specific MCP service with a clean,
/// extensible foundation for future system functions.
class SystemMCPService {
  final Logger _logger = Logger();

  /// Processes MCP commands in JSON format
  ///
  /// Expected format: {"action": "function_name", "param": "value"}
  /// Returns JSON response with status and data
  String processCommand(String command) {
    _logger.debug('SystemMCP: Processing command: $command');

    try {
      final parsedCommand = json.decode(command);
      _logger.debug('SystemMCP: Parsed command: $parsedCommand');

      final action = parsedCommand['action'] as String?;
      if (action == null) {
        _logger.warning('SystemMCP: Missing action parameter');
        return _errorResponse('Missing required parameter: action');
      }

      _logger.debug('SystemMCP: Action: $action');

      switch (action) {
        case 'get_current_time':
          return _getCurrentTime();

        case 'get_device_info':
          return _getDeviceInfo();

        default:
          _logger.warning('SystemMCP: Unknown action: $action');
          return _errorResponse('Unknown action: $action');
      }
    } catch (e) {
      _logger.error('SystemMCP: Error processing command: $e');
      return _errorResponse('Invalid command format: $e');
    }
  }

  /// Method to enable or disable logging
  void setLogging(bool enable) {
    _logger.setLogging(enable);
  }

  /// Gets current time in multiple formats
  String _getCurrentTime() {
    _logger.info('SystemMCP: Getting current time');

    try {
      final now = DateTime.now();

      final response = {
        'status': 'success',
        'data': {
          'timestamp': now.toIso8601String(),
          'timezone': now.timeZoneName,
          'hour': now.hour,
          'minute': now.minute,
          'second': now.second,
          'dayOfWeek': _getDayOfWeek(now.weekday),
          'timeOfDay': _getTimeOfDay(now.hour),
          'readableTime': _getReadableTime(now),
          'iso8601': now.toIso8601String(),
          'unixTimestamp': now.millisecondsSinceEpoch,
        }
      };

      _logger.info('SystemMCP: Current time retrieved successfully');
      return json.encode(response);
    } catch (e) {
      _logger.error('SystemMCP: Error getting current time: $e');
      return _errorResponse('Error getting current time: $e');
    }
  }

  /// Gets device information
  String _getDeviceInfo() {
    _logger.info('SystemMCP: Getting device info');

    try {
      final response = {
        'status': 'success',
        'data': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
          'locale': Platform.localeName,
          'hostname': Platform.localHostname,
          'numberOfProcessors': Platform.numberOfProcessors,
          'pathSeparator': Platform.pathSeparator,
          'executablePath': Platform.executable,
        }
      };

      _logger.info('SystemMCP: Device info retrieved successfully');
      return json.encode(response);
    } catch (e) {
      _logger.error('SystemMCP: Error getting device info: $e');
      return _errorResponse('Error getting device info: $e');
    }
  }

  /// Returns day of week as string
  String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  /// Returns time of day category
  String _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// Returns human-readable time string
  String _getReadableTime(DateTime dateTime) {
    try {
      // Use Portuguese format since the app is primarily used in Portuguese
      return DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy \'às\' HH:mm', 'pt_BR')
          .format(dateTime);
    } catch (e) {
      // Fallback to English if Portuguese locale is not available
      return DateFormat('EEEE, MMMM d, yyyy \'at\' h:mm a').format(dateTime);
    }
  }

  /// Returns standardized error response
  String _errorResponse(String message) {
    return json.encode({
      'status': 'error',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
