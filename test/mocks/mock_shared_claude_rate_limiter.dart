import 'package:mockito/mockito.dart';
import 'package:ai_personas_app/services/shared_claude_rate_limiter.dart';

/// Mock implementation of SharedClaudeRateLimiter for testing FT-185
/// 
/// This mock allows tests to simulate various rate limiting scenarios
/// including normal operation, rate limit errors, and recovery conditions.
class MockSharedClaudeRateLimiter extends Mock implements SharedClaudeRateLimiter {
  bool shouldSimulateRateLimit = false;
  bool shouldSimulateOverload = false;
  Duration simulatedDelay = Duration.zero;
  
  @override
  Future<void> waitAndRecord({bool isUserFacing = false}) async {
    // Simulate the delay that would normally be applied
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    
    // Simulate rate limit errors when configured
    if (shouldSimulateRateLimit) {
      throw Exception('429: Rate limit exceeded');
    }
    
    // Simulate overload errors when configured
    if (shouldSimulateOverload) {
      throw Exception('529: Service overloaded');
    }
    
    // Normal operation - no error thrown
  }
  
  @override
  void recordRateLimit() {
    // Mock implementation - would normally record rate limit event
    super.noSuchMethod(Invocation.method(#recordRateLimit, []));
  }
  
  @override
  Map<String, dynamic> getStatus() {
    // Return mock status for testing
    return {
      'hasRecentRateLimit': shouldSimulateRateLimit,
      'hasHighApiUsage': false,
      'lastRateLimit': shouldSimulateRateLimit ? DateTime.now().toIso8601String() : null,
      'apiCallsLastMinute': shouldSimulateRateLimit ? 10 : 2,
      'maxCallsPerMinute': 8,
    };
  }
  
  /// Test helper methods
  
  /// Configure the mock to simulate rate limit errors
  void enableRateLimitSimulation() {
    shouldSimulateRateLimit = true;
  }
  
  /// Configure the mock to simulate normal operation
  void disableRateLimitSimulation() {
    shouldSimulateRateLimit = false;
  }
  
  /// Configure the mock to simulate overload errors
  void enableOverloadSimulation() {
    shouldSimulateOverload = true;
  }
  
  /// Configure the mock to simulate normal operation
  void disableOverloadSimulation() {
    shouldSimulateOverload = false;
  }
  
  /// Set a custom delay to simulate rate limiting delays
  void setSimulatedDelay(Duration delay) {
    simulatedDelay = delay;
  }
  
  /// Reset the mock to default state
  void resetToDefaults() {
    shouldSimulateRateLimit = false;
    shouldSimulateOverload = false;
    simulatedDelay = Duration.zero;
  }
}
