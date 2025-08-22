import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/system_mcp_service.dart';

void main() {
  group('SystemMCPService', () {
    late SystemMCPService service;

    setUp(() {
      service = SystemMCPService();
      service.setLogging(false); // Disable logging for tests
    });

    group('processCommand', () {
      test('should handle get_current_time command', () {
        final command = json.encode({'action': 'get_current_time'});
        final response = service.processCommand(command);

        final decoded = json.decode(response);
        expect(decoded['status'], 'success');
        expect(decoded['data'], isA<Map<String, dynamic>>());

        final data = decoded['data'] as Map<String, dynamic>;
        expect(data['timestamp'], isA<String>());
        expect(data['hour'], isA<int>());
        expect(data['minute'], isA<int>());
        expect(data['dayOfWeek'], isA<String>());
        expect(data['timeOfDay'], isA<String>());
        expect(data['readableTime'], isA<String>());

        // Verify hour is in valid range
        expect(data['hour'], greaterThanOrEqualTo(0));
        expect(data['hour'], lessThan(24));

        // Verify minute is in valid range
        expect(data['minute'], greaterThanOrEqualTo(0));
        expect(data['minute'], lessThan(60));
      });

      test('should return error for unknown action', () {
        final command = json.encode({'action': 'unknown_action'});
        final response = service.processCommand(command);

        final decoded = json.decode(response);
        expect(decoded['status'], 'error');
        expect(decoded['message'], contains('Unknown action'));
      });

      test('should return error for missing action parameter', () {
        final command = json.encode({'not_action': 'value'});
        final response = service.processCommand(command);

        final decoded = json.decode(response);
        expect(decoded['status'], 'error');
        expect(
            decoded['message'], contains('Missing required parameter: action'));
      });

      test('should return error for invalid JSON', () {
        final command = 'not valid json';
        final response = service.processCommand(command);

        final decoded = json.decode(response);
        expect(decoded['status'], 'error');
        expect(decoded['message'], contains('Invalid command format'));
      });
    });

    group('time data validation', () {
      test('should return valid day of week', () {
        final command = json.encode({'action': 'get_current_time'});
        final response = service.processCommand(command);

        final decoded = json.decode(response);
        final data = decoded['data'] as Map<String, dynamic>;
        final dayOfWeek = data['dayOfWeek'] as String;

        const validDays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        expect(validDays, contains(dayOfWeek));
      });

      test('should return valid time of day', () {
        final command = json.encode({'action': 'get_current_time'});
        final response = service.processCommand(command);

        final decoded = json.decode(response);
        final data = decoded['data'] as Map<String, dynamic>;
        final timeOfDay = data['timeOfDay'] as String;

        const validTimes = ['morning', 'afternoon', 'evening', 'night'];
        expect(validTimes, contains(timeOfDay));
      });

      test('should return valid timestamp format', () {
        final command = json.encode({'action': 'get_current_time'});
        final response = service.processCommand(command);

        final decoded = json.decode(response);
        final data = decoded['data'] as Map<String, dynamic>;
        final timestamp = data['timestamp'] as String;

        // Should be valid ISO 8601 format
        expect(() => DateTime.parse(timestamp), returnsNormally);
      });
    });
  });
}
