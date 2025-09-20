import 'dart:async';
import 'dart:collection';
import 'package:isar/isar.dart';
import '../models/activity_model.dart';
import '../utils/logger.dart';
import 'metadata_extraction_service.dart';
import 'activity_memory_service.dart';

/// FT-149: Queue-based metadata extraction with rate limit handling
class MetadataExtractionQueue {
  static final Logger _logger = Logger();
  static MetadataExtractionQueue? _instance;
  static MetadataExtractionQueue get instance => _instance ??= MetadataExtractionQueue._();
  
  MetadataExtractionQueue._();

  final Queue<MetadataExtractionTask> _queue = Queue<MetadataExtractionTask>();
  Timer? _processingTimer;
  bool _isProcessing = false;
  
  // Rate limiting configuration
  static const int _maxRetriesPerTask = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _processingInterval = Duration(seconds: 5);
  static const Duration _rateLimitCooldown = Duration(minutes: 1);
  
  DateTime? _lastRateLimitError;
  int _consecutiveRateLimitErrors = 0;

  /// Initialize the queue processing
  void initialize() {
    _logger.info('FT-149: Initializing metadata extraction queue');
    _startProcessing();
  }

  /// Add a metadata extraction task to the queue
  Future<void> queueMetadataExtraction({
    required ActivityModel activity,
    required String userMessage,
    required String oracleActivityName,
    int priority = 0,
  }) async {
    final task = MetadataExtractionTask(
      activity: activity,
      userMessage: userMessage,
      oracleActivityName: oracleActivityName,
      priority: priority,
      createdAt: DateTime.now(),
    );

    _queue.add(task);
    _logger.info('FT-149: Queued metadata extraction for activity ${activity.activityName} (queue size: ${_queue.length})');
    
    // Try immediate processing if not rate limited
    if (!_isRateLimited()) {
      _processQueue();
    }
  }

  /// Start the background queue processing
  void _startProcessing() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(_processingInterval, (_) {
      if (!_isProcessing && _queue.isNotEmpty && !_isRateLimited()) {
        _processQueue();
      }
    });
  }

  /// Process queued metadata extraction tasks
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty || _isRateLimited()) {
      return;
    }

    _isProcessing = true;
    _logger.info('FT-149: Processing metadata extraction queue (${_queue.length} tasks)');

    try {
      // Process tasks in priority order
      final sortedTasks = _queue.toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
      
      for (final task in sortedTasks.take(3)) { // Process max 3 at a time
        _queue.remove(task);
        await _processTask(task);
        
        // Add delay between tasks to avoid rate limiting
        if (_queue.isNotEmpty) {
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      _logger.error('FT-149: Error processing metadata queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single metadata extraction task
  Future<void> _processTask(MetadataExtractionTask task) async {
    _logger.debug('FT-149: Processing metadata task for ${task.activity.activityName}');

    try {
      final metadata = await MetadataExtractionService.extractMetadata(
        userMessage: task.userMessage,
        detectedActivity: task.activity,
        oracleActivityName: task.oracleActivityName,
      );

      if (metadata != null && metadata.isNotEmpty) {
        await _updateActivityWithMetadata(task.activity, metadata);
        _logger.info('FT-149: ✅ Successfully extracted metadata for ${task.activity.activityName}');
        
        // Reset rate limit tracking on success
        _consecutiveRateLimitErrors = 0;
      } else {
        await _handleFailedExtraction(task, 'Empty metadata response');
      }
    } catch (e) {
      await _handleExtractionError(task, e);
    }
  }

  /// Handle extraction errors with retry logic
  Future<void> _handleExtractionError(MetadataExtractionTask task, dynamic error) async {
    final errorString = error.toString();
    
    if (errorString.contains('429') || errorString.contains('rate limit')) {
      _handleRateLimitError(task);
    } else if (task.retryCount < _maxRetriesPerTask) {
      // Retry for other errors
      task.retryCount++;
      task.nextRetryAt = DateTime.now().add(_baseRetryDelay * task.retryCount);
      _queue.add(task);
      _logger.warning('FT-149: Retrying metadata extraction for ${task.activity.activityName} (attempt ${task.retryCount})');
    } else {
      await _handleFailedExtraction(task, errorString);
    }
  }

  /// Handle rate limit errors specifically
  void _handleRateLimitError(MetadataExtractionTask task) {
    _lastRateLimitError = DateTime.now();
    _consecutiveRateLimitErrors++;
    
    // Exponential backoff for rate limits
    final backoffMultiplier = _consecutiveRateLimitErrors.clamp(1, 8);
    task.nextRetryAt = DateTime.now().add(_rateLimitCooldown * backoffMultiplier);
    task.retryCount++;
    
    if (task.retryCount <= _maxRetriesPerTask) {
      _queue.add(task);
      _logger.warning('FT-149: Rate limited - requeueing ${task.activity.activityName} for retry in ${_rateLimitCooldown * backoffMultiplier}');
    } else {
      _handleFailedExtraction(task, 'Rate limit exceeded after ${_maxRetriesPerTask} retries');
    }
  }

  /// Handle permanently failed extractions with fallback metadata
  Future<void> _handleFailedExtraction(MetadataExtractionTask task, String reason) async {
    _logger.warning('FT-149: Failed to extract metadata for ${task.activity.activityName}: $reason');
    
    // Generate fallback metadata
    final fallbackMetadata = _generateFallbackMetadata(task.activity, task.userMessage);
    if (fallbackMetadata.isNotEmpty) {
      await _updateActivityWithMetadata(task.activity, fallbackMetadata);
      _logger.info('FT-149: Applied fallback metadata for ${task.activity.activityName}');
    }
  }

  /// Update activity with extracted metadata
  Future<void> _updateActivityWithMetadata(ActivityModel activity, Map<String, dynamic> metadata) async {
    try {
      activity.metadataMap = metadata;
      await ActivityMemoryService.updateActivity(activity);
      _logger.debug('FT-149: Updated activity ${activity.id} with metadata');
    } catch (e) {
      _logger.error('FT-149: Failed to update activity with metadata: $e');
    }
  }

  /// Generate fallback metadata when extraction fails
  Map<String, dynamic> _generateFallbackMetadata(ActivityModel activity, String userMessage) {
    final fallback = <String, dynamic>{};
    
    // Basic activity information
    fallback['extraction_status'] = 'fallback';
    fallback['extraction_reason'] = 'LLM extraction failed';
    fallback['activity_code'] = activity.activityCode;
    fallback['user_context'] = userMessage.length > 100 ? '${userMessage.substring(0, 100)}...' : userMessage;
    
    // Dimension-based fallback metadata
    switch (activity.dimension) {
      case 'SF': // Saúde Física
        fallback['category'] = 'physical_health';
        if (userMessage.toLowerCase().contains(RegExp(r'km|metro|distanc'))) {
          fallback['quantitative'] = {'distance_mentioned': true};
        }
        if (userMessage.toLowerCase().contains(RegExp(r'proteína|protein'))) {
          fallback['nutrition'] = {'protein_focus': true};
        }
        break;
      case 'R': // Relacionamentos
        fallback['category'] = 'relationships';
        if (userMessage.toLowerCase().contains(RegExp(r'família|family'))) {
          fallback['social_context'] = {'family_interaction': true};
        }
        break;
      case 'TG': // Trabalho/Gestão
        fallback['category'] = 'work_productivity';
        break;
      default:
        fallback['category'] = 'general';
    }
    
    fallback['confidence'] = 'low';
    fallback['generated_at'] = DateTime.now().toIso8601String();
    
    return fallback;
  }

  /// Check if we're currently rate limited
  bool _isRateLimited() {
    if (_lastRateLimitError == null) return false;
    
    final cooldownMultiplier = _consecutiveRateLimitErrors.clamp(1, 8);
    final cooldownPeriod = _rateLimitCooldown * cooldownMultiplier;
    
    return DateTime.now().difference(_lastRateLimitError!) < cooldownPeriod;
  }

  /// Get queue status for debugging
  Map<String, dynamic> getQueueStatus() {
    return {
      'queue_size': _queue.length,
      'is_processing': _isProcessing,
      'is_rate_limited': _isRateLimited(),
      'consecutive_rate_limit_errors': _consecutiveRateLimitErrors,
      'last_rate_limit_error': _lastRateLimitError?.toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _processingTimer?.cancel();
    _queue.clear();
    _logger.info('FT-149: Metadata extraction queue disposed');
  }
}

/// Metadata extraction task
class MetadataExtractionTask {
  final ActivityModel activity;
  final String userMessage;
  final String oracleActivityName;
  final int priority;
  final DateTime createdAt;
  
  int retryCount = 0;
  DateTime? nextRetryAt;

  MetadataExtractionTask({
    required this.activity,
    required this.userMessage,
    required this.oracleActivityName,
    required this.priority,
    required this.createdAt,
  });
}
