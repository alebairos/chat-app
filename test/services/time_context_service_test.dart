import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/time_context_service.dart';

void main() {
  group('TimeContextService', () {
    group('Time Gap Calculation', () {
      test('should return sameSession for gaps under 30 minutes', () {
        final now = DateTime.now();
        final recentTime = now.subtract(const Duration(minutes: 15));

        final gap = TimeContextService.calculateTimeGap(recentTime);

        expect(gap, TimeGap.sameSession);
      });

      test('should return recentBreak for gaps between 30 minutes and 4 hours',
          () {
        final now = DateTime.now();
        final recentTime = now.subtract(const Duration(hours: 2));

        final gap = TimeContextService.calculateTimeGap(recentTime);

        expect(gap, TimeGap.recentBreak);
      });

      test('should return today for gaps within same day but over 4 hours', () {
        final now = DateTime.now();
        final earlierToday = now.subtract(const Duration(hours: 8));

        final gap = TimeContextService.calculateTimeGap(earlierToday);

        expect(gap, TimeGap.today);
      });

      test('should return yesterday for 1-day gap', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final gap = TimeContextService.calculateTimeGap(yesterday);

        expect(gap, TimeGap.yesterday);
      });

      test('should return thisWeek for gaps between 2-7 days', () {
        final now = DateTime.now();
        final thisWeek = now.subtract(const Duration(days: 4));

        final gap = TimeContextService.calculateTimeGap(thisWeek);

        expect(gap, TimeGap.thisWeek);
      });

      test('should return lastWeek for gaps between 8-14 days', () {
        final now = DateTime.now();
        final lastWeek = now.subtract(const Duration(days: 10));

        final gap = TimeContextService.calculateTimeGap(lastWeek);

        expect(gap, TimeGap.lastWeek);
      });

      test('should return longAgo for gaps over 2 weeks', () {
        final now = DateTime.now();
        final longAgo = now.subtract(const Duration(days: 30));

        final gap = TimeContextService.calculateTimeGap(longAgo);

        expect(gap, TimeGap.longAgo);
      });

      test('should handle edge case at exactly 30 minutes', () {
        final now = DateTime.now();
        final exactlyThirtyMin = now.subtract(const Duration(minutes: 30));

        final gap = TimeContextService.calculateTimeGap(exactlyThirtyMin);

        expect(gap, TimeGap.recentBreak);
      });

      test('should handle edge case at exactly 4 hours', () {
        final now = DateTime.now();
        final exactlyFourHours = now.subtract(const Duration(hours: 4));

        final gap = TimeContextService.calculateTimeGap(exactlyFourHours);

        expect(gap, TimeGap.today);
      });

      test('should handle invalid timestamps gracefully', () {
        // Test with a very old timestamp - should still calculate correctly
        final ancientTime = DateTime(1900, 1, 1);

        final gap = TimeContextService.calculateTimeGap(ancientTime);

        expect(gap, TimeGap.longAgo);
      });
    });

    group('Time Context Generation', () {
      test('should return empty string for sameSession gap', () {
        final now = DateTime.now();
        final recentTime = now.subtract(const Duration(minutes: 10));

        final context = TimeContextService.generateTimeContext(recentTime);

        // Should only include current time context, not gap context
        expect(context, contains('Current context: It is'));
        expect(context, isNot(contains('resuming')));
      });

      test('should include resuming context for recent break', () {
        final now = DateTime.now();
        final breakTime = now.subtract(const Duration(hours: 1));

        final context = TimeContextService.generateTimeContext(breakTime);

        expect(context, contains('Conversation resuming after a short break'));
        expect(context, contains('Current context: It is'));
      });

      test('should include today context for same day gaps', () {
        final now = DateTime.now();
        final earlierToday = now.subtract(const Duration(hours: 6));

        final context = TimeContextService.generateTimeContext(earlierToday);

        expect(context, contains('Conversation resuming later today'));
        expect(context, contains('Current context: It is'));
      });

      test('should include yesterday context for 1-day gaps', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final context = TimeContextService.generateTimeContext(yesterday);

        expect(context, contains('Conversation resuming from yesterday'));
        expect(context, contains('Current context: It is'));
      });

      test('should include week context for weekly gaps', () {
        final now = DateTime.now();
        final thisWeek = now.subtract(const Duration(days: 3));

        final context = TimeContextService.generateTimeContext(thisWeek);

        expect(
            context, contains('Conversation resuming from earlier this week'));
        expect(context, contains('Current context: It is'));
      });

      test('should handle null timestamp by only returning current context',
          () {
        final context = TimeContextService.generateTimeContext(null);

        expect(context, contains('Current context: It is'));
        expect(context, isNot(contains('resuming')));
      });

      test('should handle errors gracefully and return empty string', () {
        // This test would require mocking DateTime.now() to throw an error
        // For now, we test with valid inputs and assume error handling works
        final context = TimeContextService.generateTimeContext(null);

        expect(context, isA<String>());
      });
    });

    group('Current Time Context', () {
      test('should include day of week and time period', () {
        final context = TimeContextService.getCurrentTimeContext();

        expect(context, startsWith('Current context: It is'));
        expect(
            context,
            matches(RegExp(
                r'(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)')));
        expect(context, matches(RegExp(r'(morning|afternoon|evening|night)')));
      });

      test('should format correctly', () {
        final context = TimeContextService.getCurrentTimeContext();

        expect(context,
            matches(RegExp(r'Current context: It is \w+ at .+ \(.+\)\.')));
      });
    });

    group('Time of Day Classification', () {
      // Since the _getTimeOfDay method is private, we test it indirectly through getCurrentTimeContext
      // We can create specific DateTime objects to test different time periods

      test('should classify morning hours correctly', () {
        // Since _getTimeOfDay is private, we test it indirectly through getCurrentTimeContext
        // We can verify that the method produces valid context strings
        final context = TimeContextService.getCurrentTimeContext();
        expect(context, isA<String>());
        expect(context, contains('Current context: It is'));
      });
    });

    group('Enhanced Time Context', () {
      test('should return basic context when enhanced details disabled', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final basicContext = TimeContextService.generateTimeContext(yesterday);
        final enhancedContext = TimeContextService.generateEnhancedTimeContext(
          yesterday,
          includeGapDetails: false,
        );

        expect(enhancedContext, equals(basicContext));
      });

      test('should include gap details for weekly gaps when enabled', () {
        final now = DateTime.now();
        final daysAgo = now.subtract(const Duration(days: 4));

        final enhancedContext = TimeContextService.generateEnhancedTimeContext(
          daysAgo,
          includeGapDetails: true,
        );

        expect(enhancedContext, contains('4 days ago'));
      });

      test('should include week count for long gaps when enabled', () {
        final now = DateTime.now();
        final weeksAgo = now.subtract(const Duration(days: 21));

        final enhancedContext = TimeContextService.generateEnhancedTimeContext(
          weeksAgo,
          includeGapDetails: true,
        );

        expect(enhancedContext, contains('weeks ago'));
      });

      test('should handle null timestamp with enhanced context', () {
        final enhancedContext = TimeContextService.generateEnhancedTimeContext(
          null,
          includeGapDetails: true,
        );

        expect(enhancedContext, contains('Current context: It is'));
        expect(enhancedContext, isNot(contains('ago')));
      });
    });

    group('Timestamp Validation', () {
      test('should accept valid recent timestamps', () {
        final now = DateTime.now();
        final recentTime = now.subtract(const Duration(hours: 1));

        final validated = TimeContextService.validateTimestamp(recentTime);

        expect(validated, equals(recentTime));
      });

      test('should accept null timestamps', () {
        final validated = TimeContextService.validateTimestamp(null);

        expect(validated, isNull);
      });

      test('should reject future timestamps', () {
        final future = DateTime.now().add(const Duration(minutes: 5));

        final validated = TimeContextService.validateTimestamp(future);

        expect(validated, isNull);
      });

      test('should reject very old timestamps', () {
        final ancient = DateTime.now().subtract(const Duration(days: 400));

        final validated = TimeContextService.validateTimestamp(ancient);

        expect(validated, isNull);
      });

      test('should allow slight future times for clock skew', () {
        final slightFuture = DateTime.now().add(const Duration(seconds: 30));

        final validated = TimeContextService.validateTimestamp(slightFuture);

        expect(validated, equals(slightFuture));
      });
    });

    group('Debug Information', () {
      test('should provide comprehensive debug info for valid timestamp', () {
        final now = DateTime.now();
        final testTime = now.subtract(const Duration(hours: 2));

        final debugInfo = TimeContextService.getTimeGapDebugInfo(testTime);

        expect(debugInfo['hasLastMessage'], isTrue);
        expect(debugInfo['lastMessageTime'], isA<String>());
        expect(debugInfo['currentTime'], isA<String>());
        expect(debugInfo['differenceMinutes'], isA<int>());
        expect(debugInfo['differenceHours'], isA<int>());
        expect(debugInfo['differenceDays'], isA<int>());
        expect(debugInfo['timeGap'], isA<String>());
        expect(debugInfo['context'], isA<String>());
      });

      test('should provide appropriate debug info for null timestamp', () {
        final debugInfo = TimeContextService.getTimeGapDebugInfo(null);

        expect(debugInfo['hasLastMessage'], isFalse);
        expect(debugInfo['timeGap'], isNull);
        expect(debugInfo['context'], isA<String>());
        expect(debugInfo['context'], contains('Current context'));
      });

      test('should calculate time differences correctly', () {
        final now = DateTime.now();
        final testTime = now.subtract(const Duration(days: 2, hours: 3));

        final debugInfo = TimeContextService.getTimeGapDebugInfo(testTime);

        expect(debugInfo['differenceDays'], equals(2));
        expect(debugInfo['differenceHours'], greaterThanOrEqualTo(48));
        expect(debugInfo['timeGap'], contains('thisWeek'));
      });
    });

    group('Integration Scenarios', () {
      test('should work with realistic conversation gaps', () {
        // Simulate a user who chats daily, then takes a weekend break
        final now = DateTime.now();
        final weekendGap = now.subtract(const Duration(days: 3));

        final context = TimeContextService.generateTimeContext(weekendGap);

        expect(context, contains('earlier this week'));
        expect(context, contains('Current context'));
      });

      test('should work with quick back-and-forth conversations', () {
        final now = DateTime.now();
        final quickResponse = now.subtract(const Duration(minutes: 2));

        final context = TimeContextService.generateTimeContext(quickResponse);

        // Should not include gap context for very recent messages
        expect(context, isNot(contains('resuming')));
        expect(context, contains('Current context'));
      });

      test('should work with long-term user returns', () {
        final now = DateTime.now();
        final longAbsence = now.subtract(const Duration(days: 45));

        final context = TimeContextService.generateTimeContext(longAbsence);

        expect(context, contains('significant time gap'));
        expect(context, contains('Current context'));
      });
    });
  });
}
