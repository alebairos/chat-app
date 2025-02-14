import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/life_plan_service.dart';
import 'package:character_ai_clone/services/life_plan_mcp_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../mock_config_loader.dart';
import 'claude_service_integration_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  print('\n🚀 Starting Claude Service Integration Tests');

  late ClaudeService claudeService;
  late LifePlanService lifePlanService;
  late LifePlanMCPService mcpService;
  late MockClient mockClient;

  setUpAll(() async {
    print('\n📝 Setting up test environment...');

    // Load environment variables
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
      OPENAI_API_KEY=test_key
    ''');
    print('✓ Environment variables loaded');

    // Initialize services
    lifePlanService = LifePlanService();
    await lifePlanService.initialize();
    print('✓ Life Plan Service initialized');

    mcpService = LifePlanMCPService(lifePlanService);
    print('✓ MCP Service initialized');
  });

  setUp(() {
    print('\n🔄 Setting up test case...');
    mockClient = MockClient();

    // Set up default mock response for Claude API
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
      encoding: anyNamed('encoding'),
    )).thenAnswer((_) async => http.Response(
          json.encode({
            'content': [
              {'text': 'I cannot process that command.'}
            ]
          }),
          200,
        ));
    print('✓ Mock client configured with default response');

    claudeService = ClaudeService(
      client: mockClient,
      lifePlanMCP: mcpService,
      configLoader: MockConfigLoader(),
    );
    print('✓ Claude Service initialized with mock dependencies');
  });

  group('Claude Service Life Plan Integration', () {
    test('successfully retrieves goals by dimension', () async {
      print('\n🧪 Testing goals retrieval by dimension...');

      final command =
          json.encode({'action': 'get_goals_by_dimension', 'dimension': 'SF'});
      print('📤 Sending command: $command');

      final response = await claudeService.sendMessage(command);
      print('📥 Received response: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      expect(decoded['status'], equals('success'));
      expect(decoded['data'], isA<List>());

      // Verify the response contains valid goal data
      if (decoded['data'].isNotEmpty) {
        final firstGoal = decoded['data'][0] as Map<String, dynamic>;
        print('📋 First goal data: $firstGoal');
        expect(firstGoal.containsKey('dimension'), isTrue);
        expect(firstGoal.containsKey('id'), isTrue);
        expect(firstGoal.containsKey('description'), isTrue);
        expect(firstGoal.containsKey('trackId'), isTrue);
      } else {
        print('⚠️ No goals found for dimension SF');
      }
    });

    test('successfully retrieves track information', () async {
      print('\n🧪 Testing track information retrieval...');

      // First get a goal to get a valid trackId
      final goalsCommand =
          json.encode({'action': 'get_goals_by_dimension', 'dimension': 'SF'});
      print('📤 Sending goals command: $goalsCommand');

      final goalsResponse = await claudeService.sendMessage(goalsCommand);
      print('📥 Received goals response: $goalsResponse');

      final goalsData = json.decode(goalsResponse);
      print('🔍 Decoded goals data: $goalsData');

      if (goalsData['data'].isNotEmpty) {
        final trackId = goalsData['data'][0]['trackId'];
        print('🎯 Found trackId: $trackId');

        final trackCommand =
            json.encode({'action': 'get_track_by_id', 'trackId': trackId});
        print('📤 Sending track command: $trackCommand');

        final trackResponse = await claudeService.sendMessage(trackCommand);
        print('📥 Received track response: $trackResponse');

        final decoded = json.decode(trackResponse);
        print('�� Decoded track data: $decoded');

        expect(decoded['status'], equals('success'));
        expect(decoded['data'], isA<Map>());
        expect(decoded['data']['code'], isNotNull);
        expect(decoded['data']['name'], isNotNull);
        expect(decoded['data']['challenges'], isA<List>());
      } else {
        print('⚠️ No goals found to test track retrieval');
      }
    });

    test('successfully retrieves habits for a challenge', () async {
      print('\n🧪 Testing habits retrieval for challenge...');

      final command = json.encode({
        'action': 'get_habits_for_challenge',
        'trackId': 'ME1',
        'challengeCode': 'ME1PC'
      });
      print('📤 Sending command: $command');

      final response = await claudeService.sendMessage(command);
      print('📥 Received response: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      expect(decoded['status'], equals('success'));
      expect(decoded['data'], isA<List>());

      if (decoded['data'].isNotEmpty) {
        final firstHabit = decoded['data'][0] as Map<String, dynamic>;
        print('📋 First habit data: $firstHabit');
        expect(firstHabit.containsKey('id'), isTrue);
        expect(firstHabit.containsKey('description'), isTrue);
        expect(firstHabit.containsKey('impact'), isTrue);
      } else {
        print('⚠️ No habits found for challenge ME1PC');
      }
    });

    test('successfully retrieves recommended habits', () async {
      print('\n🧪 Testing recommended habits retrieval...');

      final command = json.encode({
        'action': 'get_recommended_habits',
        'dimension': 'SF',
        'minImpact': 3
      });
      print('📤 Sending command: $command');

      final response = await claudeService.sendMessage(command);
      print('📥 Received response: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      expect(decoded['status'], equals('success'));
      expect(decoded['data'], isA<List>());

      if (decoded['data'].isNotEmpty) {
        final firstHabit = decoded['data'][0] as Map<String, dynamic>;
        print('📋 First recommended habit: $firstHabit');
        expect(firstHabit.containsKey('id'), isTrue);
        expect(firstHabit.containsKey('description'), isTrue);
        expect(firstHabit.containsKey('impact'), isTrue);

        final impact = firstHabit['impact']['physical'];
        print('💪 Physical impact: $impact');
        expect(impact, greaterThanOrEqualTo(3));
      } else {
        print('⚠️ No recommended habits found');
      }
    });

    test('handles invalid commands gracefully', () async {
      print('\n🧪 Testing invalid command handling...');

      final command = json.encode({'action': 'invalid_action', 'data': 'test'});
      print('📤 Sending invalid command: $command');

      final response = await claudeService.sendMessage(command);
      print('📥 Received response: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded error response: $decoded');

      expect(decoded['status'], equals('error'));
      expect(decoded['message'], contains('Unknown command'));
    });

    test('handles missing required parameters gracefully', () async {
      print('\n🧪 Testing missing parameter handling...');

      final command = json.encode({
        'action': 'get_goals_by_dimension'
        // Missing 'dimension' parameter
      });
      print('📤 Sending command with missing parameter: $command');

      final response = await claudeService.sendMessage(command);
      print('📥 Received response: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded error response: $decoded');

      expect(decoded['status'], equals('error'));
      expect(decoded['message'], contains('Missing required parameter'));
    });
  });
}
