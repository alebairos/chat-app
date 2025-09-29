/// FT-154: Model for activities queued during rate limit recovery
///
/// Represents user activities that need to be processed later when
/// the system recovers from rate limiting.
class PendingActivity {
  final String message;
  final DateTime timestamp;
  final String? userId; // Optional for future user tracking

  PendingActivity({
    required this.message,
    required this.timestamp,
    this.userId,
  });

  /// Create from user message with current timestamp
  factory PendingActivity.fromMessage(String message, {String? userId}) {
    return PendingActivity(
      message: message,
      timestamp: DateTime.now(),
      userId: userId,
    );
  }

  /// Convert to map for logging/debugging
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  @override
  String toString() {
    return 'PendingActivity(message: "${message.length > 50 ? "${message.substring(0, 50)}..." : message}", timestamp: $timestamp)';
  }
}
