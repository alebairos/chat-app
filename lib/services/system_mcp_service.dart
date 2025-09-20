import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';
import '../services/activity_memory_service.dart';
import '../services/chat_storage_service.dart';
import '../services/oracle_static_cache.dart';
import '../services/oracle_context_manager.dart';
import '../services/semantic_activity_detector.dart';
import '../config/character_config_manager.dart';

/// Generic MCP (Model Context Protocol) service for system functions
///
/// This service provides AI-callable functions for system operations like
/// getting current time, device info, and other non-domain-specific utilities.
/// It replaces the legacy LifePlan-specific MCP service with a clean,
/// extensible foundation for future system functions.
class SystemMCPService {
  final Logger _logger = Logger();

  // FT-102: Time cache to prevent rate limiting
  static String? _cachedTimeResponse;
  static DateTime? _cacheTimestamp;
  static const Duration CACHE_DURATION = Duration(seconds: 30);

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
          // Parse days parameter safely, default to 0 (today) if invalid
          int days = 0;
          if (parsedCommand['days'] is int) {
            days = parsedCommand['days'] as int;
          } else if (parsedCommand['days'] is String) {
            days = int.tryParse(parsedCommand['days'] as String) ?? 0;
          }
          return await _getActivityStats(days);

        case 'get_message_stats':
          final limit =
              parsedCommand['limit'] as int? ?? 10; // Default to last 10
          return await _getMessageStats(limit);

        // FT-140: Oracle-specific MCP commands
        case 'oracle_detect_activities':
          return await _oracleDetectActivities(parsedCommand);

        case 'oracle_query_activities':
          return await _oracleQueryActivities(parsedCommand);

        case 'oracle_get_compact_context':
          return await _getCompactOracleContext();

        // FT-144: Oracle statistics command for precise data queries
        case 'oracle_get_statistics':
          return await _getOracleStatistics();

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
    // FT-102: Check cache validity to prevent rate limiting
    if (_cachedTimeResponse != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < CACHE_DURATION) {
      _logger.info('SystemMCP: Using cached time data');
      return _cachedTimeResponse!;
    }

    _logger.info('SystemMCP: Getting fresh current time');

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

      // FT-102: Cache the response
      _cachedTimeResponse = json.encode(response);
      _cacheTimestamp = DateTime.now();

      _logger.info('SystemMCP: Current time retrieved successfully');
      return _cachedTimeResponse!;
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
      _logger.debug('Formatting date: ${dateTime.toIso8601String()}');

      // Try Portuguese format first
      final portugueseFormat = DateFormat(
        'EEEE, d \'de\' MMMM \'de\' yyyy \'às\' HH:mm',
        'pt_BR',
      );
      final result = portugueseFormat.format(dateTime);
      _logger.debug('Portuguese format result: $result');
      return result;
    } catch (e) {
      _logger.warning('Portuguese locale failed, using English fallback: $e');
      // Fallback to English if Portuguese locale is not available
      try {
        final englishResult =
            DateFormat('EEEE, MMMM d, yyyy \'at\' h:mm a').format(dateTime);
        _logger.debug('English fallback result: $englishResult');
        return englishResult;
      } catch (e2) {
        _logger.error('Both date formats failed: $e2');
        // Ultimate fallback - simple ISO format
        return dateTime.toIso8601String();
      }
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

  /// FT-140: Oracle activity detection via MCP
  ///
  /// Detects Oracle activities using complete 265-activity context from static cache.
  /// Maintains Oracle methodology compliance by ensuring all activities are accessible.
  Future<String> _oracleDetectActivities(
      Map<String, dynamic> parsedCommand) async {
    try {
      _logger.debug('SystemMCP: Processing oracle_detect_activities command');

      // Validate required parameters
      final userMessage = parsedCommand['message'] as String?;
      if (userMessage == null || userMessage.trim().isEmpty) {
        return _errorResponse('Missing required parameter: message');
      }

      // Use shared Oracle initialization helper
      final oracleContext = await _ensureOracleInitialized();
      if (oracleContext == null) {
        return _errorResponse('Oracle cache not available');
      }

      // Get compact Oracle context (ALL 265 activities)
      final compactOracle = OracleStaticCache.getCompactOracleForLLM();

      _logger.debug(
          'SystemMCP: Using Oracle context with ${OracleStaticCache.totalActivities} activities');

      // Build LLM prompt with complete Oracle context
      final prompt = '''
User message: "$userMessage"
Oracle activities: $compactOracle

MULTILINGUAL DETECTION RULES:
1. ONLY COMPLETED activities (past tense in ANY language)
2. Completion indicators:
   - Portuguese: "fiz", "completei", "bebi", "caminhei", "terminei", "acabei", "realizei"
   - English: "did", "completed", "finished", "drank", "walked", "exercised", "meditated"  
   - Spanish: "hice", "completé", "bebí", "caminé", "terminé", "realicé", "medité"
   - Past tense patterns: "-ed", "-ou", "-í", "-é" endings
3. IGNORE future/planning in ALL languages:
   - Portuguese: "vou fazer", "preciso", "quero", "planejo", "vai fazer"
   - English: "will do", "going to", "need to", "want to", "plan to"
   - Spanish: "voy a hacer", "necesito", "quiero", "planeo"
4. Return EXACT Oracle catalog names, not custom descriptions
5. Semantic understanding: detect meaning beyond keywords
6. CRITICAL: Use ONLY the exact activity names from the Oracle catalog
7. NEVER create custom phrases like "vai fazer um pomodoro (will do a pomodoro session)"
8. NEVER add translations or explanations in parentheses

Required JSON format:
{"activities": [{"code": "SF1", "confidence": "high", "catalog_name": "Beber água"}]}

EXAMPLES:
✅ CORRECT: {"code": "SF1", "catalog_name": "Beber água"}
❌ WRONG: {"code": "SF1", "catalog_name": "bebeu um copo d'água (drank a glass of water)"}
❌ WRONG: {"code": "T8", "catalog_name": "vai fazer um pomodoro (will do a pomodoro session)"}

Return empty array if NO COMPLETED activities detected.
''';

      // Call Claude for activity detection
      final claudeResponse = await _callClaude(prompt);
      final detectedActivities = await _parseDetectionResults(claudeResponse);

      _logger.info(
          'SystemMCP: Oracle detection completed - ${detectedActivities.length} activities detected');

      // Get current persona name and Oracle context for metadata
      final configManager = CharacterConfigManager();
      final personaName = _getPersonaDisplayName(configManager.activePersonaKey);
      final oracleContextForMetadata = await _ensureOracleInitialized();

      // Return MCP response with enhanced metadata
      return json.encode({
        'status': 'success',
        'data': {
          'detected_activities': detectedActivities
              .map((a) => {
                    'code': a.oracleCode,
                    'confidence': a.confidence.toString(),
                    'description': a.userDescription,
                    'duration_minutes': a.durationMinutes,
                    'persona_name': personaName,
                    'dimension_name': _getDimensionDisplayName(a.oracleCode, oracleContextForMetadata),
                    'dimension_code': _getDimensionCode(a.oracleCode),
                  })
              .toList(),
          'oracle_context_size': compactOracle.length,
          'total_activities_available': OracleStaticCache.totalActivities,
          'method': 'mcp_oracle_detection',
          'oracle_compliance': 'all_265_activities_accessible',
          'persona_name': personaName,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('SystemMCP: Error in oracle_detect_activities: $e');
      return _errorResponse('Oracle activity detection failed: $e');
    }
  }

  /// FT-140: Oracle activity query via MCP
  ///
  /// Allows querying specific Oracle activities by codes or semantic search
  Future<String> _oracleQueryActivities(
      Map<String, dynamic> parsedCommand) async {
    try {
      _logger.debug('SystemMCP: Processing oracle_query_activities command');

      // Use shared Oracle initialization helper
      final oracleContext = await _ensureOracleInitialized();
      if (oracleContext == null) {
        return _errorResponse('Oracle cache not available');
      }

      final query = parsedCommand['query'] as String?;
      final codes = parsedCommand['codes'] as List<dynamic>?;

      List<Map<String, dynamic>> results = [];

      // Query by specific codes
      if (codes != null && codes.isNotEmpty) {
        final stringCodes = codes.map((c) => c.toString()).toList();
        final activities = OracleStaticCache.getActivitiesByCodes(stringCodes);

        results = activities
            .map((activity) => {
                  'code': activity.code,
                  'name': activity.description,
                  'dimension': activity.dimension,
                })
            .toList();
      }

      // Semantic query (if query parameter provided)
      if (query != null && query.trim().isNotEmpty) {
        // For now, return compact context - could be enhanced with semantic search
        final compactOracle = OracleStaticCache.getCompactOracleForLLM();
        results.add({
          'query_type': 'semantic',
          'compact_context': compactOracle,
          'total_activities': OracleStaticCache.totalActivities,
        });
      }

      return json.encode({
        'status': 'success',
        'data': {
          'results': results,
          'query': query,
          'codes': codes,
          'total_activities_available': OracleStaticCache.totalActivities,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('SystemMCP: Error in oracle_query_activities: $e');
      return _errorResponse('Oracle query failed: $e');
    }
  }

  /// FT-140: Get compact Oracle context via MCP
  ///
  /// Returns the ultra-compact representation of all Oracle activities
  Future<String> _getCompactOracleContext() async {
    try {
      _logger.debug('SystemMCP: Processing oracle_get_compact_context command');

      // Use shared Oracle initialization helper
      final oracleContext = await _ensureOracleInitialized();
      if (oracleContext == null) {
        return _errorResponse('Oracle cache not available');
      }

      final compactOracle = OracleStaticCache.getCompactOracleForLLM();
      final debugInfo = OracleStaticCache.getDebugInfo();

      return json.encode({
        'status': 'success',
        'data': {
          'compact_context': compactOracle,
          'format': 'CODE:NAME,CODE:NAME,...',
          'total_activities': OracleStaticCache.totalActivities,
          'context_size_chars': compactOracle.length,
          'estimated_tokens': debugInfo['estimatedTokens'],
          'oracle_compliance': 'all_265_activities_included',
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('SystemMCP: Error in oracle_get_compact_context: $e');
      return _errorResponse('Failed to get Oracle context: $e');
    }
  }

  /// FT-144: Get precise Oracle statistics
  ///
  /// Returns EXACT Oracle statistics from loaded data - NEVER approximates
  Future<String> _getOracleStatistics() async {
    try {
      _logger.debug('SystemMCP: Processing oracle_get_statistics command');

      // Use shared Oracle initialization helper (eliminates duplication)
      final oracleContext = await _ensureOracleInitialized();
      if (oracleContext == null) {
        return _errorResponse('Oracle context not available');
      }

      // Build dimension breakdown
      final dimensionBreakdown = <String, int>{};
      for (final entry in oracleContext.dimensions.entries) {
        dimensionBreakdown[entry.key] = entry.value.activities.length;
      }

      // Get enhanced debug info with Oracle validation details (no hardcoded logic)
      final debugInfo = await OracleContextManager.getDebugInfo();
      final oracle42Info =
          debugInfo['oracle42Validation'] as Map<String, dynamic>?;

      _logger.info(
          'SystemMCP: Retrieved Oracle statistics - ${oracleContext.totalActivities} activities, ${oracleContext.dimensions.length} dimensions');

      return jsonEncode({
        'status': 'success',
        'data': {
          'total_activities': oracleContext.totalActivities,
          'dimensions': oracleContext.dimensions.length,
          'oracle_version': oracle42Info?['isOracle42'] == true
              ? '4.2'
              : (oracleContext.dimensions.length == 5 ? '2.1/3.0' : 'Unknown'),
          'dimension_breakdown': dimensionBreakdown,
          'dimensions_available': oracleContext.dimensions.keys.toList(),
          'oracle_validation':
              oracle42Info, // Dynamic validation info instead of hardcoded strings
          'cache_status': OracleStaticCache.isInitialized
              ? 'initialized'
              : 'not_initialized',
          'data_source': 'oracle_context_manager',
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('SystemMCP: Error in oracle_get_statistics: $e');
      return _errorResponse('Failed to get Oracle statistics: $e');
    }
  }

  /// Shared helper to ensure Oracle is initialized and return context
  /// Eliminates duplication across Oracle MCP methods
  Future<OracleContext?> _ensureOracleInitialized() async {
    // Check if Oracle cache is initialized
    if (!OracleStaticCache.isInitialized) {
      _logger.warning(
          'SystemMCP: Oracle cache not initialized, attempting initialization');
      await OracleStaticCache.initializeAtStartup();

      if (!OracleStaticCache.isInitialized) {
        return null;
      }
    }

    // Get Oracle context
    return await OracleContextManager.getForCurrentPersona();
  }

  /// Call Claude API for Oracle activity detection
  Future<String> _callClaude(String prompt) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    final model =
        (dotenv.env['ANTHROPIC_MODEL'] ?? 'claude-3-5-sonnet-20241022').trim();

    if (apiKey.isEmpty) {
      throw Exception('Claude API key not configured');
    }

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: json.encode({
        'model': model,
        'max_tokens': 1024,
        'temperature': 0.1, // Low temperature for consistent detection
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Claude API error: ${response.statusCode} - ${response.body}');
    }

    final data = json.decode(response.body);
    return data['content'][0]['text'] as String;
  }

  /// Parse Claude detection results into ActivityDetection objects
  Future<List<ActivityDetection>> _parseDetectionResults(String claudeResponse) async {
    try {
      // Extract JSON from Claude response
      final jsonMatch =
          RegExp(r'\{.*\}', dotAll: true).firstMatch(claudeResponse);
      if (jsonMatch == null) {
        _logger.debug('SystemMCP: No JSON found in Claude response');
        return [];
      }

      final jsonStr = jsonMatch.group(0)!;
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final activities = data['activities'] as List<dynamic>? ?? [];

      // Oracle context is available from static cache for activity lookup
      
      return activities.map((activityData) {
        final code = activityData['code'] as String? ?? '';
        final confidence =
            _parseConfidence(activityData['confidence'] as String? ?? 'medium');
        final catalogName = activityData['catalog_name'] as String? ?? '';
        final duration = activityData['duration_minutes'] as int? ?? 0;

        // Get exact catalog name from Oracle cache to ensure proper encoding
        String activityName = catalogName;
        if (code.isNotEmpty && OracleStaticCache.isInitialized) {
          final oracleActivity = OracleStaticCache.getActivityByCode(code);
          if (oracleActivity != null) {
            // Use Oracle cache name to ensure proper UTF-8 encoding
            activityName = oracleActivity.description;
          }
        }

        // Fallback to code if no name found
        if (activityName.isEmpty) {
          activityName = code;
        }

        return ActivityDetection(
          oracleCode: code,
          activityName: activityName,
          userDescription: activityName, // Use exact catalog name
          confidence: confidence,
          reasoning: 'Detected via MCP Oracle detection (multilingual)',
          timestamp: DateTime.now(),
          durationMinutes: duration,
        );
      }).toList();
    } catch (e) {
      _logger.debug('SystemMCP: Failed to parse Claude response: $e');
      return [];
    }
  }

  /// Parse confidence level from string
  ConfidenceLevel _parseConfidence(String confidenceStr) {
    switch (confidenceStr.toLowerCase()) {
      case 'high':
        return ConfidenceLevel.high;
      case 'low':
        return ConfidenceLevel.low;
      default:
        return ConfidenceLevel.medium;
    }
  }

  /// Get dimension code from activity code (e.g., SF1 -> SF)
  String _getDimensionCode(String activityCode) {
    if (activityCode.isEmpty) return '';
    
    // Extract dimension prefix (letters before numbers)
    final match = RegExp(r'^([A-Z]+)').firstMatch(activityCode);
    return match?.group(1) ?? '';
  }

  /// Get human-readable dimension name from activity code
  String _getDimensionDisplayName(String activityCode, OracleContext? oracleContext) {
    final dimensionCode = _getDimensionCode(activityCode);
    if (dimensionCode.isEmpty || oracleContext == null) return '';

    final dimension = oracleContext.dimensions[dimensionCode];
    if (dimension != null) {
      return dimension.name;
    }

    // Fallback to English names for common dimensions
    switch (dimensionCode) {
      case 'SF':
        return 'Physical Health';
      case 'R':
        return 'Relationships';
      case 'TG':
      case 'T':
        return 'Work & Management';
      case 'SM':
        return 'Mental Health';
      case 'E':
        return 'Spirituality';
      case 'TT':
        return 'Screen Time';
      case 'PR':
        return 'Anti-Procrastination';
      case 'F':
        return 'Finance';
      default:
        return dimensionCode;
    }
  }

  /// Get display name for persona key
  String _getPersonaDisplayName(String personaKey) {
    switch (personaKey) {
      case 'ariWithOracle42':
        return 'Ari 4.2';
      case 'iThereWithOracle42':
        return 'I-There 4.2';
      case 'ryoTzuWithOracle42':
        return 'Ryo Tzu 4.2';
      case 'ariLifeCoach':
        return 'Ari - Life Coach';
      case 'iThere':
        return 'I-There';
      default:
        // Extract display name from persona key (fallback)
        return personaKey.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
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
