import '../services/semantic_activity_detector.dart';

/// Shared utilities for activity detection across different services
class ActivityDetectionUtils {
  /// Parse confidence string to ConfidenceLevel enum
  ///
  /// Handles case-insensitive parsing with fallback to medium confidence
  static ConfidenceLevel parseConfidence(String? confidenceStr) {
    switch (confidenceStr?.toLowerCase()) {
      case 'high':
        return ConfidenceLevel.high;
      case 'low':
        return ConfidenceLevel.low;
      case 'medium':
      default:
        return ConfidenceLevel.medium;
    }
  }
}
