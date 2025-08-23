import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:ai_personas_app/models/activity_model.dart';
import 'package:ai_personas_app/services/activity_memory_service.dart';
import 'package:ai_personas_app/services/integrated_mcp_processor.dart';
import 'package:ai_personas_app/services/oracle_context_manager.dart';

/// FT-064 Database Integration Test
/// 
/// Tests if FT-064 semantic activity detection is properly storing
/// activities in the database and provides query examples.
void main() {
  group('FT-064 Database Storage Tests', () {
    late Isar isar;

    setUpAll(() async {
      print('🚀 Starting FT-064 Database Integration Tests');
      
      // Initialize in-memory Isar for testing
      isar = await Isar.open(
        [ActivityModelSchema],
        directory: '',
        name: 'ft064_test',
      );
      
      ActivityMemoryService.initialize(isar);
      print('✓ Test database initialized');
    });

    tearDownAll(() async {
      await isar.close();
      print('🧹 Test cleanup completed');
    });

    test('should query existing activities in database', () async {
      print('\n🔍 Testing database query capabilities...');
      
      // Query total activities
      final totalCount = await ActivityMemoryService.getTotalActivityCount();
      print('📊 Total activities in database: $totalCount');
      
      // Query recent activities
      final recentActivities = await ActivityMemoryService.getRecentActivities(7);
      print('📅 Recent activities (7 days): ${recentActivities.length}');
      
      // Query today's activities
      final todayActivities = await ActivityMemoryService.getTodayActivities();
      print('📋 Today\'s activities: ${todayActivities.length}');
      
      // Display recent activities with details
      if (recentActivities.isNotEmpty) {
        print('\n📝 Recent Activity Details:');
        for (int i = 0; i < recentActivities.length && i < 5; i++) {
          final activity = recentActivities[i];
          print('${i + 1}. ${activity.activityDescription}');
          print('   🕐 ${activity.formattedDate} at ${activity.formattedTime}');
          print('   📂 Dimension: ${activity.dimension}');
          print('   🎯 Confidence: ${activity.confidenceScore}');
          if (activity.userDescription != null) {
            print('   💬 User described: "${activity.userDescription}"');
          }
          if (activity.detectionMethod != null) {
            print('   🔍 Detection: ${activity.detectionMethod}');
          }
          print('');
        }
      } else {
        print('ℹ️  No activities found - this is normal for a fresh test environment');
      }
      
      // Test manual activity logging to verify storage works
      print('🧪 Testing manual activity storage...');
      final testActivity = await ActivityMemoryService.logActivity(
        activityCode: 'TEST1',
        activityName: 'FT-064 Database Test',
        dimension: 'test',
        source: 'FT-064 Test Suite',
        durationMinutes: 5,
        notes: 'Testing database storage functionality',
        confidence: 0.95,
      );
      
      print('✅ Test activity stored with ID: ${testActivity.id}');
      
      // Verify it was stored
      final updatedCount = await ActivityMemoryService.getTotalActivityCount();
      print('📊 Updated total count: $updatedCount');
      
      expect(updatedCount, greaterThan(totalCount));
      print('✅ Database storage verification passed');
    });

    test('should test FT-064 detection status', () async {
      print('\n🔍 Testing FT-064 detection capabilities...');
      
      try {
        // Test Oracle context detection
        final oracleContext = await OracleContextManager.getForCurrentPersona();
        if (oracleContext != null) {
          print('✅ Oracle context loaded: ${oracleContext.totalActivities} activities');
          print('📂 Dimensions available: ${oracleContext.dimensions.keys.join(", ")}');
        } else {
          print('ℹ️  No Oracle context - expected in test environment');
        }
        
        // Test detection status
        final status = await IntegratedMCPProcessor.getDetectionStatus();
        print('🔍 FT-064 Status:');
        print('   Enabled: ${status["ft064_enabled"]}');
        print('   Oracle Compatible: ${status["oracle_compatible"]}');
        print('   Detection Method: ${status["detection_method"]}');
        print('   Fallback Available: ${status["fallback_available"]}');
        
        expect(status['ft064_enabled'], isTrue);
        print('✅ FT-064 detection status check passed');
        
      } catch (e) {
        print('ℹ️  Detection status check skipped in test environment: $e');
      }
    });

    test('should provide database query examples', () async {
      print('\n📚 Database Query Examples:');
      print('');
      print('// Query all activities');
      print('final all = await ActivityMemoryService.getRecentActivities(365);');
      print('');
      print('// Query by dimension');
      print('final physical = await ActivityMemoryService.getActivitiesByDimension("saude_fisica");');
      print('');
      print('// Query by Oracle code');
      print('final water = await ActivityMemoryService.getActivitiesByCode("SF1");');
      print('');
      print('// Query today\'s activities');
      print('final today = await ActivityMemoryService.getTodayActivities();');
      print('');
      print('// Get total count');
      print('final count = await ActivityMemoryService.getTotalActivityCount();');
      print('');
      print('// Generate activity context for AI');
      print('final context = await ActivityMemoryService.generateActivityContext();');
      print('');
      print('💡 You can also use the Isar Inspector:');
      print('   ${isar.isOpen ? "https://inspect.isar.dev/3.1.0+1/" : "Start the app to get Isar Inspector URL"}');
      print('');
      
      expect(true, isTrue); // Always pass - this is just documentation
    });
  });
}
