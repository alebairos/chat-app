/// FT-156: Message ID Generator for Activity Message Linking
/// 
/// Generates unique message identifiers to link activities with their source messages.
/// This enables coaching memory by connecting detected activities to what users actually said.
class MessageIdGenerator {
  static int _sequenceCounter = 0;
  
  /// Generate unique message ID with format: msg_{timestamp}_{sequence}
  /// 
  /// Example: "msg_1759017452686749_0001"
  /// 
  /// The timestamp ensures global uniqueness while the sequence number
  /// handles multiple messages within the same millisecond.
  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _sequenceCounter++;
    return "msg_${timestamp}_${_sequenceCounter.toString().padLeft(4, '0')}";
  }
  
  /// Reset sequence counter (primarily for testing)
  /// 
  /// This allows tests to have predictable message IDs and ensures
  /// clean state between test runs.
  static void resetSequence() {
    _sequenceCounter = 0;
  }
  
  /// Get current sequence number (for debugging/testing)
  static int get currentSequence => _sequenceCounter;
}
