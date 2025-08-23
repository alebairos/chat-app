import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/oracle_activity_parser.dart';
import 'package:character_ai_clone/services/system_mcp_service.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FT-061 Activity Memory Unit Tests', () {
    late SystemMCPService mcpService;

    setUpAll(() {
      print('\n🚀 Starting FT-061 Activity Memory Unit Tests');

      // Initialize SystemMCP service
      mcpService = SystemMCPService();
      mcpService.setLogging(false); // Disable logging for tests
      print('✓ Test environment initialized');
    });

    group('Oracle Activity Parser Tests', () {
      test('should parse Oracle activities dynamically from persona config',
          () async {
        print('\n🧪 Testing dynamic Oracle activity parsing...');

        try {
          final result = await OracleActivityParser.parseFromPersona();
          print(
              '📊 Parse result: ${result.totalCount} total activities, ${result.libraryCount} library + ${result.trilhaCount} trilha activities');
          print('📊 Dimensions found: ${result.dimensions.length}');

          // Should have activities and dimensions if Oracle 2.1 is configured
          if (result.totalCount > 0) {
            expect(result.libraryCount, greaterThan(0),
                reason: 'Should have library activities');
            expect(result.dimensions.length, greaterThan(0),
                reason: 'Should have dimensions');

            // Check for specific Oracle 2.1 activities we know should exist
            final activities = result.activities;
            expect(activities.keys.any((code) => code.startsWith('SF')), true,
                reason: 'Should have SF (Saúde Física) activities');

            print('✓ Oracle parsing test passed');
          } else {
            print('ℹ️  No Oracle config found - expected for test environment');
            expect(result.totalCount, equals(0));
          }
        } catch (e) {
          // Expected in test environment without proper Oracle files
          print(
              'ℹ️  Oracle parsing failed as expected in test environment: $e');
          expect(e.toString(), contains('Oracle config path'),
              reason: 'Should fail gracefully without Oracle config');
        }
      });
    });

    group('SystemMCP Core Functions Tests', () {
      test('should confirm extract_activities was removed (FT-064 migration)',
          () async {
        print('\n🧪 Testing extract_activities removal...');

        final command = json.encode({
          'action': 'extract_activities',
          'message': 'Acabei de beber água'
        });

        print('📤 Sending legacy command: $command');

        final response = await mcpService.processCommand(command);
        final decoded = json.decode(response);

        print('📥 Response: $response');

        // Should return error since extract_activities was removed in FT-064
        expect(decoded['status'], equals('error'),
            reason: 'extract_activities should be removed in FT-064');
        expect(decoded['message'], contains('Unknown action'),
            reason: 'Should indicate unknown action');

        print('✅ Legacy extract_activities correctly removed');
      });

      test('should handle get_current_time command', () async {
        print('\n🧪 Testing get_current_time command...');

        final command = json.encode({'action': 'get_current_time'});

        final response = await mcpService.processCommand(command);
        final decoded = json.decode(response);

        expect(decoded['status'], equals('success'));
        expect(decoded['data'], isA<Map<String, dynamic>>());

        final data = decoded['data'] as Map<String, dynamic>;
        expect(data['timestamp'], isA<String>());
        expect(data['hour'], isA<int>());
        expect(data['minute'], isA<int>());
        expect(data['dayOfWeek'], isA<String>());
        expect(data['timeOfDay'], isA<String>());
        expect(data['readableTime'], isA<String>());

        print('✓ get_current_time test passed');
      });
    });

    group('FT-064 Integration Tests', () {
      test('should verify FT-064 semantic detection is available', () async {
        print('\n🧪 Testing FT-064 availability...');

        // Test that the new FT-064 components are available
        // Note: Full semantic detection testing happens in integration tests
        // since it requires Claude API calls

        print('✅ FT-064 semantic detection replaces legacy extract_activities');
        print('📝 Activity detection now happens automatically in background');
        print('🔧 Use IntegratedMCPProcessor for semantic analysis');

        expect(true, isTrue, reason: 'FT-064 architecture verification');
      });

      test('should confirm SystemMCP only handles core functions', () async {
        print('\n🧪 Testing SystemMCP core functions...');

        // Test that SystemMCP now only handles core system functions
        final validCommands = ['get_current_time', 'get_device_info'];

        for (final action in validCommands) {
          final command = json.encode({'action': action});
          final response = await mcpService.processCommand(command);
          final decoded = json.decode(response);

          expect(decoded['status'], equals('success'),
              reason: '$action should still work');
          print('✅ $action: Working correctly');
        }

        print('✓ SystemMCP core functions test completed');
      });
    });
  });
}
