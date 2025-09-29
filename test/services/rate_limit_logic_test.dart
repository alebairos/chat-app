import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/shared_claude_rate_limiter.dart';

/// FT-154 Core Logic Tests: Essential rate limiting logic validation
///
/// Tests only the unique core logic that can't be tested elsewhere:
/// - Singleton pattern (critical for rate limiting coordination)
/// - Multiple rate limit recordings (timestamp progression)
/// - Static interface consistency
/// - Configuration constants
///
/// All other functionality is tested in integration tests.
void main() {
  group('Rate Limit Core Logic Tests', () {
    late SharedClaudeRateLimiter rateLimiter;

    setUp(() {
      SharedClaudeRateLimiter.resetForTesting();
      rateLimiter = SharedClaudeRateLimiter();
    });

    test('Singleton pattern should work correctly', () {
      final instance1 = SharedClaudeRateLimiter();
      final instance2 = SharedClaudeRateLimiter();

      // Should be the same instance (critical for rate limiting coordination)
      expect(identical(instance1, instance2), true);

      // State changes should be reflected across instances
      instance1.recordRateLimit();

      expect(instance1.getStatus()['hasRecentRateLimit'], true);
      expect(instance2.getStatus()['hasRecentRateLimit'], true);
    });

    test('Multiple rate limit recordings should update timestamps', () async {
      rateLimiter.recordRateLimit();
      final firstStatus = rateLimiter.getStatus();
      final firstRateLimit = DateTime.parse(firstStatus['lastRateLimit']);

      // Wait a tiny bit and record again
      await Future.delayed(const Duration(milliseconds: 1));
      rateLimiter.recordRateLimit();
      final secondStatus = rateLimiter.getStatus();
      final secondRateLimit = DateTime.parse(secondStatus['lastRateLimit']);

      expect(secondRateLimit.isAfter(firstRateLimit), true,
          reason: 'Second rate limit should be more recent');
    });

    test('Static interface should match instance interface', () {
      // Test initial state consistency
      expect(SharedClaudeRateLimiter.hasRecentRateLimit(), false);
      expect(rateLimiter.getStatus()['hasRecentRateLimit'], false);

      // Record rate limit and verify both interfaces reflect change
      rateLimiter.recordRateLimit();

      expect(SharedClaudeRateLimiter.hasRecentRateLimit(), true);
      expect(rateLimiter.getStatus()['hasRecentRateLimit'], true);

      // Static status should match instance status
      final staticStatus = SharedClaudeRateLimiter.getStatusStatic();
      final instanceStatus = rateLimiter.getStatus();

      expect(staticStatus['hasRecentRateLimit'],
          instanceStatus['hasRecentRateLimit']);
      expect(staticStatus['maxCallsPerMinute'],
          instanceStatus['maxCallsPerMinute']);
    });

    test('Configuration constants should be correct', () {
      final status = rateLimiter.getStatus();

      expect(status['maxCallsPerMinute'], 8,
          reason: 'Max calls per minute should be 8 as configured');
      expect(status['hasRecentRateLimit'], false,
          reason: 'Initial state should have no recent rate limit');
      expect(status['hasHighApiUsage'], false,
          reason: 'Initial state should have no high API usage');
      expect(status['apiCallsLastMinute'], 0,
          reason: 'Initial state should have no API calls');
      expect(status['lastRateLimit'], null,
          reason: 'Initial state should have no rate limit timestamp');

      // These are the expected delay values from the implementation:
      // Normal: 500ms user, 3000ms background
      // High usage: 2000ms user, 8000ms background
      // Rate limit recovery: 3000ms user, 15000ms background (FT-154)
    });
  });
}
