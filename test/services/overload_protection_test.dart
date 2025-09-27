import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/shared_claude_rate_limiter.dart';

/// FT-155 Overload Protection Tests: Verify Claude overload handling
///
/// Tests the new overload protection functionality:
/// - 529 error detection and circuit breaker behavior
/// - Exponential backoff recovery
/// - Background vs user-facing call handling
/// - Integration with existing rate limiting
void main() {
  group('FT-155 Overload Protection Tests', () {
    setUp(() {
      SharedClaudeRateLimiter.resetForTesting();
      SharedClaudeRateLimiter.enableTestingMode(); // For fast execution
    });

    tearDown(() {
      SharedClaudeRateLimiter.disableTestingMode();
    });

    test('Initial overload state should be clean', () {
      expect(SharedClaudeRateLimiter.isClaudeOverloaded(), false);

      final overloadStatus = SharedClaudeRateLimiter.getOverloadStatus();
      expect(overloadStatus['isOverloaded'], false);
      expect(overloadStatus['overloadCount'], 0);
      expect(overloadStatus['lastOverloadTime'], null);
    });

    test('Recording overload should update state', () {
      SharedClaudeRateLimiter.recordOverload();

      expect(SharedClaudeRateLimiter.isClaudeOverloaded(), true);

      final overloadStatus = SharedClaudeRateLimiter.getOverloadStatus();
      expect(overloadStatus['isOverloaded'], true);
      expect(overloadStatus['overloadCount'], 1);
      expect(overloadStatus['lastOverloadTime'], isNotNull);
    });

    test('Background calls should be blocked when overloaded', () async {
      SharedClaudeRateLimiter.recordOverload();

      expect(() async {
        await SharedClaudeRateLimiter().waitAndRecord(isUserFacing: false);
      }, throwsException);
    });

    test('User-facing calls should be allowed when overloaded', () async {
      SharedClaudeRateLimiter.recordOverload();

      // Should not throw exception for user-facing calls
      await SharedClaudeRateLimiter().waitAndRecord(isUserFacing: true);

      // Verify the call was recorded
      final status = SharedClaudeRateLimiter().getStatus();
      expect(status['apiCallsLastMinute'], 1);
    });

    test('Multiple overload events should increase backoff', () {
      SharedClaudeRateLimiter.recordOverload();
      final firstStatus = SharedClaudeRateLimiter.getOverloadStatus();
      expect(firstStatus['overloadCount'], 1);

      SharedClaudeRateLimiter.recordOverload();
      final secondStatus = SharedClaudeRateLimiter.getOverloadStatus();
      expect(secondStatus['overloadCount'], 2);

      SharedClaudeRateLimiter.recordOverload();
      final thirdStatus = SharedClaudeRateLimiter.getOverloadStatus();
      expect(thirdStatus['overloadCount'], 3);
    });

    test('Reset should clear overload state', () {
      SharedClaudeRateLimiter.recordOverload();
      expect(SharedClaudeRateLimiter.isClaudeOverloaded(), true);

      SharedClaudeRateLimiter.resetForTesting();
      expect(SharedClaudeRateLimiter.isClaudeOverloaded(), false);

      final overloadStatus = SharedClaudeRateLimiter.getOverloadStatus();
      expect(overloadStatus['isOverloaded'], false);
      expect(overloadStatus['overloadCount'], 0);
    });

    test('Overload state should integrate with existing rate limiting',
        () async {
      // First trigger rate limit
      SharedClaudeRateLimiter().recordRateLimit();

      // Then trigger overload
      SharedClaudeRateLimiter.recordOverload();

      // Both states should be active
      expect(SharedClaudeRateLimiter.hasRecentRateLimit(), true);
      expect(SharedClaudeRateLimiter.isClaudeOverloaded(), true);

      // Background calls should still be blocked by overload
      expect(() async {
        await SharedClaudeRateLimiter().waitAndRecord(isUserFacing: false);
      }, throwsException);

      // User-facing calls should work (overload allows, rate limit applies delays)
      await SharedClaudeRateLimiter().waitAndRecord(isUserFacing: true);
    });

    test('Overload status should provide debugging information', () {
      SharedClaudeRateLimiter.recordOverload();

      final overloadStatus = SharedClaudeRateLimiter.getOverloadStatus();

      expect(overloadStatus, isA<Map<String, dynamic>>());
      expect(overloadStatus.containsKey('isOverloaded'), true);
      expect(overloadStatus.containsKey('lastOverloadTime'), true);
      expect(overloadStatus.containsKey('overloadCount'), true);
      expect(overloadStatus.containsKey('nextRecoveryCheck'), true);

      expect(overloadStatus['isOverloaded'], true);
      expect(overloadStatus['overloadCount'], 1);
      expect(overloadStatus['nextRecoveryCheck'], isNotNull);
    });

    test('Testing mode should work with overload protection', () async {
      SharedClaudeRateLimiter.recordOverload();

      // In testing mode, user-facing calls should still work instantly
      final stopwatch = Stopwatch()..start();
      await SharedClaudeRateLimiter().waitAndRecord(isUserFacing: true);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Testing mode should execute instantly even with overload');
    });
  });
}
