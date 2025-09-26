#!/usr/bin/env dart

import 'dart:io';
import 'package:ai_personas_app/services/activity_tracking_monitor.dart';
import 'package:ai_personas_app/services/activity_memory_service.dart';
import 'package:ai_personas_app/utils/logger.dart';

/// Simple script to test FT-119 implementation effectiveness
Future<void> main() async {
  // Enable logging
  Logger().setLogging(true);

  print('🔍 FT-119 Implementation Test');
  print('============================');

  try {
    // Generate status report
    print('\n📊 Generating status report...');
    final report = await ActivityTrackingMonitor.generateStatusReport();
    print(report);

    // Test key metrics
    print('\n📈 Key Metrics:');
    final metrics = await ActivityTrackingMonitor.getKeyMetrics();
    metrics.forEach((key, value) {
      print('  $key: $value');
    });

    // Health check
    print('\n🏥 Health Check:');
    final isHealthy = await ActivityTrackingMonitor.isSystemHealthy();
    print('  System Status: ${isHealthy ? '✅ Healthy' : '❌ Issues Detected'}');

    // Queue status
    print('\n📋 Queue Details:');
    final queueStatus = ActivityQueue.getQueueStatus();
    print('  Pending: ${queueStatus['pendingCount']}');
    print('  Max Size: ${queueStatus['maxQueueSize']}');

    if (queueStatus['pendingCount'] > 0) {
      print('  Requests:');
      for (final request in queueStatus['requests']) {
        print(
            '    - "${request['message']}" (retry: ${request['retryCount']})');
      }
    }
  } catch (e) {
    print('❌ Test failed: $e');
    exit(1);
  }

  print('\n✅ FT-119 test completed successfully!');
}
