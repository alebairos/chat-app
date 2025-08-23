import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../utils/logger.dart';
import '../services/activity_memory_service.dart';
import '../services/chat_storage_service.dart';

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
  Future<String> processCommand(String command) async {
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

        case 'get_activity_stats':
          // Parse days parameter safely, default to 1 if invalid
          int days = 1;
          if (parsedCommand['days'] is int) {
            days = parsedCommand['days'] as int;
          } else if (parsedCommand['days'] is String) {
            days = int.tryParse(parsedCommand['days'] as String) ?? 1;
          }
          return await _getActivityStats(days);

        case 'get_message_stats':
          final limit =
              parsedCommand['limit'] as int? ?? 10; // Default to last 10
          return await _getMessageStats(limit);

        // extract_activities removed - now handled by FT-064 semantic detection

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
        },
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
        },
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
      'Sunday',
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
      return DateFormat(
        'EEEE, d \'de\' MMMM \'de\' yyyy \'às\' HH:mm',
        'pt_BR',
      ).format(dateTime);
    } catch (e) {
      // Fallback to English if Portuguese locale is not available
      return DateFormat('EEEE, MMMM d, yyyy \'at\' h:mm a').format(dateTime);
    }
  }

  /// Gets activity statistics from the database
  /// Gets comprehensive activity statistics using unified ActivityMemoryService method
  Future<String> _getActivityStats(int days) async {
    _logger.info('SystemMCP: Getting activity stats for $days days');

    try {
      // Use the unified getActivityStats method from ActivityMemoryService
      final statsData =
          await ActivityMemoryService.getActivityStats(days: days);

      final response = {
        'status': 'success',
        'data': statsData,
      };

      _logger.info(
          'SystemMCP: Activity stats retrieved successfully (${statsData['total_activities']} activities)');
      return json.encode(response);
    } catch (e) {
      _logger.error('SystemMCP: Error getting activity stats: $e');
      return _errorResponse('Error getting activity stats: $e');
    }
  }

  /// Format time as HH:MM
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Gets chat message statistics from the database
  Future<String> _getMessageStats(int limit) async {
    _logger.info('SystemMCP: Getting message stats (limit: $limit)');

    try {
      final storageService = ChatStorageService();
      final messages = await storageService.getMessages(limit: limit);

      final messagesData = messages
          .map((message) => {
                'id': message.id,
                'text': message.text.length > 100
                    ? '${message.text.substring(0, 100)}...'
                    : message.text,
                'is_user': message.isUser,
                'timestamp': message.timestamp.toIso8601String(),
                'time': _formatTime(message.timestamp),
                'type': message.type.toString(),
                'has_audio': message.mediaPath != null,
              })
          .toList();

      // Calculate summary
      final userMessages = messages.where((m) => m.isUser).length;
      final aiMessages = messages.where((m) => !m.isUser).length;
      final audioMessages = messages.where((m) => m.mediaPath != null).length;

      final response = {
        'status': 'success',
        'data': {
          'total_messages': messages.length,
          'messages': messagesData,
          'summary': {
            'user_messages': userMessages,
            'ai_messages': aiMessages,
            'audio_messages': audioMessages,
            'oldest_message': messages.isNotEmpty
                ? _formatTime(messages.last.timestamp)
                : null,
            'newest_message': messages.isNotEmpty
                ? _formatTime(messages.first.timestamp)
                : null,
          },
        },
      };

      _logger.info(
          'SystemMCP: Message stats retrieved successfully (${messages.length} messages)');
      return json.encode(response);
    } catch (e) {
      _logger.error('SystemMCP: Error getting message stats: $e');
      return _errorResponse('Error getting message stats: $e');
    }
  }

  // Legacy activity extraction methods removed - now handled by FT-064

  /// Returns standardized error response
  String _errorResponse(String message) {
    return json.encode({
      'status': 'error',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
