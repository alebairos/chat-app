import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Message ID Matching Tests', () {
    test(
        'extractBaseMessageId correctly handles IDs with and without timestamps',
        () {
      // Function to test
      String extractBaseMessageId(String messageId) {
        // If the message ID contains an underscore followed by digits (timestamp),
        // extract just the base ID part
        final parts = messageId.split('_');
        if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.last)) {
          // Check if the last part is a timestamp (all digits)
          // If so, return everything except the last part
          return messageId.substring(0, messageId.lastIndexOf('_'));
        }
        return messageId;
      }

      // Test cases
      const baseId = '123';
      final timestampedId =
          '${baseId}_${DateTime.now().millisecondsSinceEpoch}';

      // Test with base ID
      expect(extractBaseMessageId(baseId), equals(baseId));

      // Test with timestamped ID
      expect(extractBaseMessageId(timestampedId), equals(baseId));

      // Test with ID containing underscore but not followed by timestamp
      const complexId = '123_abc';
      expect(extractBaseMessageId(complexId), equals(complexId));

      // Test with empty string
      expect(extractBaseMessageId(''), equals(''));

      // Test with null
      expect(extractBaseMessageId('null'), equals('null'));

      // Test with multiple underscores
      const multipleUnderscores = '123_456_789';
      expect(extractBaseMessageId(multipleUnderscores), equals('123_456'));

      // Test with timestamp-like ID but not actually a timestamp
      const timestampLike = '123_456abc';
      expect(extractBaseMessageId(timestampLike), equals(timestampLike));
    });

    test('findMatchingMessageId finds correct message in a map', () {
      // Function to test
      String? findMatchingMessageId(
          String targetId, Map<String, String> audioMap) {
        print('Finding match for targetId: $targetId');
        print('Available keys: ${audioMap.keys.join(', ')}');

        // First try exact match
        if (audioMap.containsKey(targetId)) {
          print('Found exact match: $targetId');
          return targetId;
        }

        // Extract base ID if it's a timestamped ID
        String baseId = targetId;
        final parts = targetId.split('_');
        if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.last)) {
          baseId = targetId.substring(0, targetId.lastIndexOf('_'));
          print('Extracted baseId: $baseId from $targetId');
        }

        // Look for exact matches with the base ID
        if (baseId != targetId && audioMap.containsKey(baseId)) {
          print('Found match with base ID: $baseId');
          return baseId;
        }

        // Special case for IDs with underscores that aren't timestamps
        // Look for keys that start with the target ID followed by underscore and timestamp
        print('Looking for keys starting with: ${targetId}_');
        final prefixMatches = audioMap.keys.where((key) {
          final isMatch = key.startsWith('${targetId}_') &&
              key.length > targetId.length + 1 &&
              RegExp(r'^\d+$').hasMatch(key.substring(targetId.length + 1));
          if (isMatch) {
            print('Found prefix match: $key');
          }
          return isMatch;
        }).toList();

        if (prefixMatches.isNotEmpty) {
          print('Returning prefix match: ${prefixMatches.first}');
          return prefixMatches.first;
        }

        // Look for keys that exactly match the pattern: baseId_timestamp
        print('Looking for keys matching exact pattern: ${baseId}_timestamp');
        final exactMatches = audioMap.keys.where((key) {
          final keyParts = key.split('_');
          final isMatch = keyParts.length > 1 &&
              RegExp(r'^\d+$').hasMatch(keyParts.last) &&
              key.substring(0, key.lastIndexOf('_')) == baseId;
          if (isMatch) {
            print('Found exact match: $key');
          }
          return isMatch;
        }).toList();

        if (exactMatches.isNotEmpty) {
          print('Returning exact match: ${exactMatches.first}');
          return exactMatches.first;
        }

        // If we still haven't found a match, try to find any key that starts with the base ID
        print('Looking for keys starting with: ${baseId}_');
        final partialMatches = audioMap.keys.where((key) {
          final isMatch = key.startsWith('${baseId}_');
          if (isMatch) {
            print('Found partial match: $key');
          }
          return isMatch;
        }).toList();

        if (partialMatches.isNotEmpty) {
          // Sort matches by length of the match to prioritize more specific matches
          partialMatches.sort((a, b) {
            // If one key contains the other as a prefix, prioritize the longer one
            if (a.startsWith(b)) return 1;
            if (b.startsWith(a)) return -1;
            return a.length.compareTo(b.length);
          });

          print('Returning best partial match: ${partialMatches.last}');
          return partialMatches.last;
        }

        print('No match found for $targetId');
        return null;
      }

      // Test data
      final audioMap = <String, String>{
        '123_1677123456789': 'audio1.mp3',
        '456': 'audio2.mp3',
        '789_1677123456790': 'audio3.mp3',
        'abc_def': 'audio4.mp3',
        '123_456_1677123456791': 'audio5.mp3',
      };

      // Test exact match with timestamped ID
      expect(findMatchingMessageId('123_1677123456789', audioMap),
          equals('123_1677123456789'));

      // Test base ID matching timestamped ID
      expect(
          findMatchingMessageId('123', audioMap), equals('123_1677123456789'));

      // Test different timestamped ID matching base ID
      expect(findMatchingMessageId('123_9999999999999', audioMap),
          equals('123_1677123456789'));

      // Test exact match with base ID
      expect(findMatchingMessageId('456', audioMap), equals('456'));

      // Test timestamped ID matching base ID
      expect(
          findMatchingMessageId('456_1677123456789', audioMap), equals('456'));

      // Test ID with underscore but not timestamp
      expect(findMatchingMessageId('abc_def', audioMap), equals('abc_def'));

      // Test ID with multiple underscores and timestamp
      print('\n--- Testing with ID 123_456 ---');
      final result1 = findMatchingMessageId('123_456', audioMap);
      print('Result for 123_456: $result1');
      expect(result1, equals('123_456_1677123456791'));

      print('\n--- Testing with ID 123_456_9999999999999 ---');
      final result2 = findMatchingMessageId('123_456_9999999999999', audioMap);
      print('Result for 123_456_9999999999999: $result2');
      expect(result2, equals('123_456_1677123456791'));

      // Test non-existent ID
      expect(findMatchingMessageId('999', audioMap), isNull);
    });
  });
}
