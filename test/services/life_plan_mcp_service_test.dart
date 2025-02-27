import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/life_plan_mcp_service.dart';
import 'package:character_ai_clone/services/life_plan_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LifePlanMCPService mcpService;
  late LifePlanService lifePlanService;

  setUp(() async {
    print('🔄 Setting up test environment...');
    lifePlanService = LifePlanService();
    await lifePlanService.initialize();
    mcpService = LifePlanMCPService(lifePlanService);
    print('✓ Services initialized');
  });

  group('LifePlanMCPService', () {
    test('processes get_goals_by_dimension command', () async {
      print('🧪 Testing get_goals_by_dimension command...');
      final command = {'action': 'get_goals_by_dimension', 'dimension': 'SF'};
      final response = mcpService.processCommand(jsonEncode(command));

      final decodedResponse = jsonDecode(response);
      expect(decodedResponse['status'], 'success');
      expect(decodedResponse['data'], isA<List>());
      if (decodedResponse['data'].isNotEmpty) {
        final firstGoal = decodedResponse['data'][0];
        expect(firstGoal['dimension'], equals('SF'));
        expect(firstGoal['id'], isNotNull);
        expect(firstGoal['description'], isNotNull);
        expect(firstGoal['trackId'], isNotNull);
      }
      print('✓ Command processed successfully');
    });

    test('processes get_track_by_id command', () async {
      print('🧪 Testing get_track_by_id command...');
      final command = {'action': 'get_track_by_id', 'trackId': 'ME1'};
      final response = mcpService.processCommand(jsonEncode(command));

      final decodedResponse = jsonDecode(response);
      expect(decodedResponse['status'], 'success');
      expect(decodedResponse['data'], isA<Map>());
      expect(decodedResponse['data']['code'], equals('ME1'));
      expect(decodedResponse['data']['challenges'], isA<List>());
      print('✓ Command processed successfully');
    });

    test('processes get_habits_for_challenge command', () async {
      print('🧪 Testing get_habits_for_challenge command...');
      final command = {
        'action': 'get_habits_for_challenge',
        'trackId': 'ME1',
        'challengeCode': 'ME1PC'
      };
      final response = mcpService.processCommand(jsonEncode(command));

      final decodedResponse = jsonDecode(response);
      expect(decodedResponse['status'], 'success');
      expect(decodedResponse['data'], isA<List>());
      if (decodedResponse['data'].isNotEmpty) {
        final firstHabit = decodedResponse['data'][0];
        expect(firstHabit['id'], isNotNull);
        expect(firstHabit['description'], isNotNull);
        expect(firstHabit['impact'], isA<Map>());
      }
      print('✓ Command processed successfully');
    });

    test('processes get_recommended_habits command', () async {
      print('🧪 Testing get_recommended_habits command...');
      final command = {
        'action': 'get_recommended_habits',
        'dimension': 'SF',
        'minImpact': 3
      };
      final response = mcpService.processCommand(jsonEncode(command));

      final decodedResponse = jsonDecode(response);
      expect(decodedResponse['status'], 'success');
      expect(decodedResponse['data'], isA<List>());
      if (decodedResponse['data'].isNotEmpty) {
        final firstHabit = decodedResponse['data'][0];
        expect(firstHabit['id'], isNotNull);
        expect(firstHabit['description'], isNotNull);
        expect(firstHabit['impact'], isA<Map>());
        expect(firstHabit['impact']['physical'], greaterThanOrEqualTo(3));
      }
      print('✓ Command processed successfully');
    });

    test('handles unknown command gracefully', () async {
      print('🧪 Testing unknown command handling...');
      final command = {'action': 'unknown_command'};
      final response = mcpService.processCommand(jsonEncode(command));

      final decodedResponse = jsonDecode(response);
      expect(decodedResponse['status'], 'error');
      expect(decodedResponse['message'], 'Unknown action: unknown_command');
      print('✓ Unknown command handled correctly');
    });

    test('handles missing required parameters gracefully', () async {
      print('🧪 Testing missing parameters handling...');
      final command = {'action': 'get_goals_by_dimension'};
      final response = mcpService.processCommand(jsonEncode(command));

      final decodedResponse = jsonDecode(response);
      expect(decodedResponse['status'], 'error');
      expect(
          decodedResponse['message'], contains('Missing required parameter'));
      print('✓ Missing parameters handled correctly');
    });

    test('handles invalid track ID gracefully', () async {
      print('🧪 Testing invalid track ID handling...');
      final command = {'action': 'get_track_by_id', 'trackId': 'INVALID_ID'};
      final response = mcpService.processCommand(jsonEncode(command));

      final decodedResponse = jsonDecode(response);
      expect(decodedResponse['status'], 'error');
      expect(decodedResponse['message'], 'Track not found');
      print('✓ Invalid track ID handled correctly');
    });
  });
}
