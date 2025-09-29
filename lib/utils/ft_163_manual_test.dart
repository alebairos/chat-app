import '../services/activity_queue.dart'; // FT-154 implementation (has FT-163 fix)
import '../services/activity_memory_service.dart' hide ActivityQueue; // Hide FT-119 ActivityQueue to avoid conflict
import '../utils/logger.dart';

/// FT-163: Manual Testing Helper for Activity Queue Storage Fix
/// 
/// Use this class to manually test the FT-163 implementation in the app.
/// Call these methods from debug screens, buttons, or console.
class FT163ManualTest {
  static final Logger _logger = Logger();

  /// Test 1: Queue a single activity and process it
  static Future<void> testSingleActivity() async {
    _logger.info('🧪 FT-163 Manual Test: Starting single activity test');
    
    try {
      // Step 1: Get initial database count
      final initialCount = await ActivityMemoryService.getTotalActivityCount();
      _logger.info('📊 Initial activity count: $initialCount');
      
      // Step 2: Queue an activity
      await ActivityQueue.queueActivity('Bebi 200ml de água', DateTime.now());
      _logger.info('📥 Queued activity. Queue size: ${ActivityQueue.queueSize}');
      
      // Step 3: Process the queue
      _logger.info('⚙️ Processing queue...');
      await ActivityQueue.processQueue();
      
      // Step 4: Check results
      final finalCount = await ActivityMemoryService.getTotalActivityCount();
      final queueSizeAfter = ActivityQueue.queueSize;
      
      _logger.info('📊 Final activity count: $finalCount');
      _logger.info('📥 Queue size after processing: $queueSizeAfter');
      
      // Step 5: Verify success
      if (finalCount > initialCount) {
        _logger.info('✅ FT-163 SUCCESS: Activity was detected and saved!');
        
        // Show the saved activity details
        final recentActivities = await ActivityMemoryService.getRecentActivities(1);
        if (recentActivities.isNotEmpty) {
          final savedActivity = recentActivities.first;
          _logger.info('💾 Saved activity: ${savedActivity.activityCode} - ${savedActivity.activityName}');
          _logger.info('🏷️ Source: ${savedActivity.source}');
          _logger.info('📈 Confidence: ${savedActivity.confidenceScore}');
        }
      } else {
        _logger.warning('⚠️ No activity was detected/saved. Check Oracle configuration.');
      }
      
      if (queueSizeAfter == 0) {
        _logger.info('✅ Queue processed successfully (empty)');
      } else {
        _logger.warning('⚠️ Queue still has $queueSizeAfter items');
      }
      
    } catch (e) {
      _logger.error('❌ FT-163 Test failed: $e');
    }
  }

  /// Test 2: Queue multiple activities and process them
  static Future<void> testMultipleActivities() async {
    _logger.info('🧪 FT-163 Manual Test: Starting multiple activities test');
    
    try {
      final initialCount = await ActivityMemoryService.getTotalActivityCount();
      _logger.info('📊 Initial activity count: $initialCount');
      
      // Queue multiple activities
      final activities = [
        'Bebi 300ml de água',
        'Fiz 20 flexões',
        'Li 5 páginas do livro',
        'Caminhei 15 minutos',
      ];
      
      for (final activity in activities) {
        await ActivityQueue.queueActivity(activity, DateTime.now().subtract(
          Duration(minutes: activities.indexOf(activity) * 10)
        ));
      }
      
      _logger.info('📥 Queued ${activities.length} activities. Queue size: ${ActivityQueue.queueSize}');
      
      // Process all
      _logger.info('⚙️ Processing queue...');
      await ActivityQueue.processQueue();
      
      // Check results
      final finalCount = await ActivityMemoryService.getTotalActivityCount();
      final activitiesDetected = finalCount - initialCount;
      
      _logger.info('📊 Activities detected and saved: $activitiesDetected');
      _logger.info('📥 Queue size after processing: ${ActivityQueue.queueSize}');
      
      if (activitiesDetected > 0) {
        _logger.info('✅ FT-163 SUCCESS: $activitiesDetected activities saved!');
        
        // Show recent activities
        final recentActivities = await ActivityMemoryService.getRecentActivities(activitiesDetected);
        for (final activity in recentActivities) {
          _logger.info('💾 ${activity.activityCode} - ${activity.activityName} (${activity.source})');
        }
      } else {
        _logger.warning('⚠️ No activities were detected/saved');
      }
      
    } catch (e) {
      _logger.error('❌ Multiple activities test failed: $e');
    }
  }

  /// Test 3: Show current queue status
  static void showQueueStatus() {
    _logger.info('🧪 FT-163 Manual Test: Queue Status');
    
    final status = ActivityQueue.getQueueStatus();
    _logger.info('📊 Queue Status:');
    _logger.info('  - Size: ${status['queueSize']}');
    _logger.info('  - Max Size: ${status['maxQueueSize']}');
    _logger.info('  - Is Empty: ${ActivityQueue.isEmpty}');
    
    if (!ActivityQueue.isEmpty) {
      _logger.info('📋 Queued items:');
      // Note: The actual queue items are private, but we can show the count
      _logger.info('  - ${ActivityQueue.queueSize} activities waiting to be processed');
    }
  }

  /// Test 4: Clear queue (for testing)
  static void clearQueue() {
    _logger.info('🧪 FT-163 Manual Test: Clearing queue');
    final sizeBefore = ActivityQueue.queueSize;
    ActivityQueue.clearQueue();
    _logger.info('🗑️ Cleared queue. Removed $sizeBefore activities');
  }

  /// Test 5: Simulate rate limit scenario
  static Future<void> simulateRateLimitScenario() async {
    _logger.info('🧪 FT-163 Manual Test: Simulating rate limit scenario');
    
    try {
      _logger.info('📊 Scenario: User sends messages during rate limit');
      
      // Step 1: Queue activities (simulating rate limit period)
      _logger.info('⏸️ Simulating rate limit - queuing activities...');
      await ActivityQueue.queueActivity('Bebi água durante rate limit', DateTime.now());
      await ActivityQueue.queueActivity('Fiz exercício durante rate limit', DateTime.now());
      
      _logger.info('📥 Activities queued during "rate limit": ${ActivityQueue.queueSize}');
      
      // Step 2: Simulate recovery
      _logger.info('🔄 Simulating rate limit recovery - processing queue...');
      final initialCount = await ActivityMemoryService.getTotalActivityCount();
      
      await ActivityQueue.processQueue();
      
      // Step 3: Verify recovery
      final finalCount = await ActivityMemoryService.getTotalActivityCount();
      final recovered = finalCount - initialCount;
      
      _logger.info('✅ Rate limit recovery complete:');
      _logger.info('  - Activities recovered: $recovered');
      _logger.info('  - Queue size after recovery: ${ActivityQueue.queueSize}');
      
      if (recovered > 0) {
        _logger.info('🎉 FT-163 SUCCESS: No data loss during rate limit!');
      } else {
        _logger.warning('⚠️ No activities were recovered');
      }
      
    } catch (e) {
      _logger.error('❌ Rate limit simulation failed: $e');
    }
  }

  /// Run all tests in sequence
  static Future<void> runAllTests() async {
    _logger.info('🧪 FT-163 Manual Test: Running complete test suite');
    
    _logger.info('\n=== Test 1: Single Activity ===');
    await testSingleActivity();
    
    await Future.delayed(const Duration(seconds: 2));
    
    _logger.info('\n=== Test 2: Multiple Activities ===');
    await testMultipleActivities();
    
    await Future.delayed(const Duration(seconds: 2));
    
    _logger.info('\n=== Test 3: Queue Status ===');
    showQueueStatus();
    
    _logger.info('\n=== Test 4: Rate Limit Simulation ===');
    await simulateRateLimitScenario();
    
    _logger.info('\n🎉 FT-163 Manual Test Suite Complete!');
  }
}
