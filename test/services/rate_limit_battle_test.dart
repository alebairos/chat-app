import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../lib/services/shared_claude_rate_limiter.dart';
import '../../lib/utils/logger.dart';

/// FT-152 Battle Test: Stress testing rate limit management
/// 
/// Tests realistic scenarios including:
/// - Concurrent user and background requests
/// - Rate limit recovery behavior
/// - High usage protection
/// - Performance under load
/// - Edge cases and race conditions
void main() {
  group('Rate Limit Battle Tests', () {
    late SharedClaudeRateLimiter rateLimiter;
    late Logger logger;

    setUpAll(() async {
      // Load environment for realistic testing
      await dotenv.load(fileName: ".env");
      logger = Logger();
    });

    setUp(() {
      // Get fresh instance for each test
      rateLimiter = SharedClaudeRateLimiter();
      
      logger.info('🧪 Starting rate limit battle test');
    });

    testWidgets('Battle Test 1: Concurrent User vs Background Load', (tester) async {
      logger.info('⚔️ Battle Test 1: Concurrent requests simulation');
      
      final stopwatch = Stopwatch()..start();
      final results = <String, Duration>{};
      
      // Simulate realistic app usage pattern
      final futures = <Future<void>>[];
      
      // 3 rapid user conversations (should be fast)
      for (int i = 0; i < 3; i++) {
        futures.add(() async {
          final userStopwatch = Stopwatch()..start();
          await rateLimiter.waitAndRecord(isUserFacing: true);
          userStopwatch.stop();
          results['user_$i'] = userStopwatch.elapsed;
          logger.debug('👤 User request $i completed in ${userStopwatch.elapsedMilliseconds}ms');
        }());
      }
      
      // 5 background processes (should be slower)
      for (int i = 0; i < 5; i++) {
        futures.add(() async {
          final bgStopwatch = Stopwatch()..start();
          await rateLimiter.waitAndRecord(isUserFacing: false);
          bgStopwatch.stop();
          results['background_$i'] = bgStopwatch.elapsed;
          logger.debug('🔄 Background request $i completed in ${bgStopwatch.elapsedMilliseconds}ms');
        }());
      }
      
      // Wait for all concurrent requests
      await Future.wait(futures);
      stopwatch.stop();
      
      logger.info('⏱️ Total test time: ${stopwatch.elapsedMilliseconds}ms');
      
      // Verify user requests were faster than background
      final userTimes = results.entries
          .where((e) => e.key.startsWith('user_'))
          .map((e) => e.value.inMilliseconds)
          .toList();
      
      final backgroundTimes = results.entries
          .where((e) => e.key.startsWith('background_'))
          .map((e) => e.value.inMilliseconds)
          .toList();
      
      logger.info('👤 User response times: ${userTimes}ms');
      logger.info('🔄 Background response times: ${backgroundTimes}ms');
      
      // Battle test assertions
      expect(userTimes.isNotEmpty, true, reason: 'Should have user response times');
      expect(backgroundTimes.isNotEmpty, true, reason: 'Should have background response times');
      
      // User requests should generally be faster (allowing some variance)
      final avgUserTime = userTimes.reduce((a, b) => a + b) / userTimes.length;
      final avgBackgroundTime = backgroundTimes.reduce((a, b) => a + b) / backgroundTimes.length;
      
      logger.info('📊 Average user time: ${avgUserTime.toInt()}ms');
      logger.info('📊 Average background time: ${avgBackgroundTime.toInt()}ms');
      
      expect(avgUserTime < avgBackgroundTime, true, 
          reason: 'User requests should be faster on average');
      
      logger.info('✅ Battle Test 1 PASSED: User requests prioritized correctly');
    });

    testWidgets('Battle Test 2: Rate Limit Recovery Simulation', (tester) async {
      logger.info('⚔️ Battle Test 2: Rate limit recovery behavior');
      
      // Simulate rate limit condition
      rateLimiter.recordRateLimit();
      logger.info('🚨 Rate limit event recorded');
      
      final recoveryStopwatch = Stopwatch()..start();
      
      // Test both user and background during recovery
      final userFuture = () async {
        final userStopwatch = Stopwatch()..start();
        await rateLimiter.waitAndRecord(isUserFacing: true);
        userStopwatch.stop();
        return userStopwatch.elapsed;
      }();
      
      final backgroundFuture = () async {
        final bgStopwatch = Stopwatch()..start();
        await rateLimiter.waitAndRecord(isUserFacing: false);
        bgStopwatch.stop();
        return bgStopwatch.elapsed;
      }();
      
      final results = await Future.wait([userFuture, backgroundFuture]);
      recoveryStopwatch.stop();
      
      final userRecoveryTime = results[0].inSeconds;
      final backgroundRecoveryTime = results[1].inSeconds;
      
      logger.info('👤 User recovery time: ${userRecoveryTime}s');
      logger.info('🔄 Background recovery time: ${backgroundRecoveryTime}s');
      logger.info('⏱️ Total recovery test time: ${(recoveryStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s');
      
      // During rate limit recovery, both should use aggressive delays
      expect(userRecoveryTime, greaterThanOrEqualTo(14), 
          reason: 'User should respect rate limit recovery (15s delay)');
      expect(backgroundRecoveryTime, greaterThanOrEqualTo(14), 
          reason: 'Background should respect rate limit recovery (15s delay)');
      
      // Both should be approximately equal during recovery
      final timeDifference = (userRecoveryTime - backgroundRecoveryTime).abs();
      expect(timeDifference, lessThan(2), 
          reason: 'Recovery times should be similar (both use 15s delay)');
      
      logger.info('✅ Battle Test 2 PASSED: Rate limit recovery works correctly');
    });

    testWidgets('Battle Test 3: High Usage Protection', (tester) async {
      logger.info('⚔️ Battle Test 3: High usage protection simulation');
      
      // Simulate high API usage by making many calls quickly
      logger.info('🔥 Generating high API usage...');
      
      // Make 10 rapid calls to trigger high usage condition
      // We'll use the actual waitAndRecord method to build up history
      for (int i = 0; i < 10; i++) {
        await rateLimiter.waitAndRecord(isUserFacing: false);
        await Future.delayed(Duration(milliseconds: 50)); // Rapid succession
      }
      
      final status = rateLimiter.getStatus();
      logger.info('📈 High usage condition created (${status['apiCallsLastMinute']} calls)');
      
      // Test behavior under high usage
      final highUsageStopwatch = Stopwatch()..start();
      
      final userHighUsageFuture = () async {
        final userStopwatch = Stopwatch()..start();
        await rateLimiter.waitAndRecord(isUserFacing: true);
        userStopwatch.stop();
        return userStopwatch.elapsed;
      }();
      
      final backgroundHighUsageFuture = () async {
        final bgStopwatch = Stopwatch()..start();
        await rateLimiter.waitAndRecord(isUserFacing: false);
        bgStopwatch.stop();
        return bgStopwatch.elapsed;
      }();
      
      final highUsageResults = await Future.wait([userHighUsageFuture, backgroundHighUsageFuture]);
      highUsageStopwatch.stop();
      
      final userHighUsageTime = highUsageResults[0].inSeconds;
      final backgroundHighUsageTime = highUsageResults[1].inSeconds;
      
      logger.info('👤 User high usage time: ${userHighUsageTime}s');
      logger.info('🔄 Background high usage time: ${backgroundHighUsageTime}s');
      logger.info('⏱️ Total high usage test time: ${(highUsageStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s');
      
      // Verify high usage protection
      expect(userHighUsageTime, greaterThanOrEqualTo(1), 
          reason: 'User should have some delay during high usage (2s expected)');
      expect(backgroundHighUsageTime, greaterThanOrEqualTo(7), 
          reason: 'Background should have longer delay during high usage (8s expected)');
      
      // User should still be faster than background during high usage
      expect(userHighUsageTime < backgroundHighUsageTime, true,
          reason: 'User should still be prioritized during high usage');
      
      logger.info('✅ Battle Test 3 PASSED: High usage protection maintains user priority');
    });

    testWidgets('Battle Test 4: Performance Under Extreme Load', (tester) async {
      logger.info('⚔️ Battle Test 4: Extreme load performance test');
      
      final extremeLoadStopwatch = Stopwatch()..start();
      final concurrentRequests = <Future<Duration>>[];
      
      // Simulate extreme concurrent load (20 requests)
      logger.info('💥 Launching 20 concurrent requests...');
      
      for (int i = 0; i < 20; i++) {
        final isUser = i % 3 == 0; // Every 3rd request is user-facing
        
        concurrentRequests.add(() async {
          final requestStopwatch = Stopwatch()..start();
          await rateLimiter.waitAndRecord(isUserFacing: isUser);
          requestStopwatch.stop();
          
          logger.debug('${isUser ? "👤" : "🔄"} Request $i completed in ${requestStopwatch.elapsedMilliseconds}ms');
          return requestStopwatch.elapsed;
        }());
      }
      
      final allResults = await Future.wait(concurrentRequests);
      extremeLoadStopwatch.stop();
      
      final userResults = <Duration>[];
      final backgroundResults = <Duration>[];
      
      for (int i = 0; i < allResults.length; i++) {
        if (i % 3 == 0) {
          userResults.add(allResults[i]);
        } else {
          backgroundResults.add(allResults[i]);
        }
      }
      
      final avgUserTime = userResults.map((d) => d.inMilliseconds).reduce((a, b) => a + b) / userResults.length;
      final avgBackgroundTime = backgroundResults.map((d) => d.inMilliseconds).reduce((a, b) => a + b) / backgroundResults.length;
      
      logger.info('📊 Extreme load results:');
      logger.info('👤 User requests: ${userResults.length}, avg: ${avgUserTime.toInt()}ms');
      logger.info('🔄 Background requests: ${backgroundResults.length}, avg: ${avgBackgroundTime.toInt()}ms');
      logger.info('⏱️ Total extreme load time: ${(extremeLoadStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s');
      
      // Performance assertions
      expect(userResults.isNotEmpty, true, reason: 'Should have user results');
      expect(backgroundResults.isNotEmpty, true, reason: 'Should have background results');
      expect(avgUserTime < avgBackgroundTime, true, reason: 'Users should be faster under extreme load');
      
      // System should remain responsive (no timeouts)
      expect(extremeLoadStopwatch.elapsedMilliseconds, lessThan(180000), 
          reason: 'Extreme load test should complete within 3 minutes');
      
      logger.info('✅ Battle Test 4 PASSED: System handles extreme load correctly');
    });

    testWidgets('Battle Test 5: Edge Cases and Race Conditions', (tester) async {
      logger.info('⚔️ Battle Test 5: Edge cases and race conditions');
      
      // Test rapid successive calls
      logger.info('🏃‍♂️ Testing rapid successive calls...');
      
      final rapidStopwatch = Stopwatch()..start();
      final rapidFutures = <Future<void>>[];
      
      // Launch 5 requests with minimal delay
      for (int i = 0; i < 5; i++) {
        rapidFutures.add(() async {
          await rateLimiter.waitAndRecord(isUserFacing: i % 2 == 0);
          logger.debug('🚀 Rapid request $i completed');
        }());
        
        // Minimal delay between launches
        await Future.delayed(Duration(milliseconds: 10));
      }
      
      await Future.wait(rapidFutures);
      rapidStopwatch.stop();
      
      logger.info('⏱️ Rapid requests completed in ${rapidStopwatch.elapsedMilliseconds}ms');
      
      // Test status consistency
      final status = rateLimiter.getStatus();
      logger.info('📊 Rate limiter status: $status');
      
      expect(status['apiCallsLastMinute'], greaterThan(0), 
          reason: 'Should track API calls');
      expect(status['maxCallsPerMinute'], equals(8), 
          reason: 'Max calls per minute should be configured');
      
      // Test multiple status calls don't interfere
      final status1 = rateLimiter.getStatus();
      final status2 = rateLimiter.getStatus();
      final status3 = rateLimiter.getStatus();
      
      expect(status1['apiCallsLastMinute'], equals(status2['apiCallsLastMinute']),
          reason: 'Status should be consistent');
      expect(status2['apiCallsLastMinute'], equals(status3['apiCallsLastMinute']),
          reason: 'Multiple status calls should not interfere');
      
      logger.info('✅ Battle Test 5 PASSED: Edge cases handled correctly');
    });

    testWidgets('Battle Test 6: Real-World Usage Pattern', (tester) async {
      logger.info('⚔️ Battle Test 6: Real-world usage pattern simulation');
      
      // Simulate realistic app usage over time
      logger.info('🌍 Simulating real-world usage pattern...');
      
      final realWorldStopwatch = Stopwatch()..start();
      final usageResults = <String, List<int>>{
        'user_times': [],
        'background_times': [],
      };
      
      // Pattern: User conversation followed by background processing
      for (int cycle = 0; cycle < 3; cycle++) {
        logger.info('🔄 Usage cycle ${cycle + 1}/3');
        
        // User sends message
        final userStopwatch = Stopwatch()..start();
        await rateLimiter.waitAndRecord(isUserFacing: true);
        userStopwatch.stop();
        usageResults['user_times']!.add(userStopwatch.elapsedMilliseconds);
        
        logger.debug('👤 User message ${cycle + 1}: ${userStopwatch.elapsedMilliseconds}ms');
        
        // Background activity detection triggers
        await Future.delayed(Duration(milliseconds: 500)); // Realistic delay
        
        final bgStopwatch = Stopwatch()..start();
        await rateLimiter.waitAndRecord(isUserFacing: false);
        bgStopwatch.stop();
        usageResults['background_times']!.add(bgStopwatch.elapsedMilliseconds);
        
        logger.debug('🔄 Background processing ${cycle + 1}: ${bgStopwatch.elapsedMilliseconds}ms');
        
        // Wait before next cycle (realistic user behavior)
        await Future.delayed(Duration(seconds: 2));
      }
      
      realWorldStopwatch.stop();
      
      final avgUserTime = usageResults['user_times']!.reduce((a, b) => a + b) / 3;
      final avgBackgroundTime = usageResults['background_times']!.reduce((a, b) => a + b) / 3;
      
      logger.info('🌍 Real-world pattern results:');
      logger.info('👤 User times: ${usageResults['user_times']} (avg: ${avgUserTime.toInt()}ms)');
      logger.info('🔄 Background times: ${usageResults['background_times']} (avg: ${avgBackgroundTime.toInt()}ms)');
      logger.info('⏱️ Total real-world test: ${(realWorldStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s');
      
      // Real-world performance expectations
      expect(avgUserTime, lessThan(3000), 
          reason: 'User responses should be under 3s in normal usage');
      expect(avgBackgroundTime, greaterThan(avgUserTime), 
          reason: 'Background should be slower than user requests');
      
      // Consistency check
      final userTimeVariance = _calculateVariance(usageResults['user_times']!.map((t) => t.toDouble()).toList());
      logger.info('📊 User time variance: ${userTimeVariance.toStringAsFixed(2)}');
      
      expect(userTimeVariance, lessThan(1000000), // 1000ms variance
          reason: 'User response times should be reasonably consistent');
      
      logger.info('✅ Battle Test 6 PASSED: Real-world usage pattern optimized');
    });
  });
}

/// Calculate variance for consistency testing
double _calculateVariance(List<double> values) {
  if (values.isEmpty) return 0;
  
  final mean = values.reduce((a, b) => a + b) / values.length;
  final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
  return squaredDiffs.reduce((a, b) => a + b) / values.length;
}
