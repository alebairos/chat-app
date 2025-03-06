import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/life_plan_mcp_service.dart';
import 'package:character_ai_clone/services/life_plan_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Flag to control logging in tests
const bool enableTestLogging = false;

// Helper function for controlled logging
void testLog(String message) {
  if (enableTestLogging) {
    print(message);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testLog('\n🚀 Starting System Prompt MCP Integration Test');

  late ClaudeService claudeService;
  late LifePlanService lifePlanService;
  late LifePlanMCPService mcpService;

  setUp(() async {
    testLog('\n📝 Setting up test environment...');

    // Load environment variables
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
      OPENAI_API_KEY=test_key
    ''');
    testLog('✓ Environment variables loaded');

    // Initialize the life plan service with CSV data
    lifePlanService = LifePlanService();
    // Disable logging in the service
    lifePlanService.setLogging(enableTestLogging);
    await lifePlanService.initialize();
    testLog('✓ Life Plan Service initialized with CSV data');

    // Initialize the MCP service
    mcpService = LifePlanMCPService(lifePlanService);
    // Disable logging in the service
    mcpService.setLogging(enableTestLogging);
    testLog('✓ Life Plan MCP Service initialized');

    // Initialize the Claude service with the real MCP service
    claudeService = ClaudeService(
      lifePlanMCP: mcpService,
    );
    // Disable logging in the service
    claudeService.setLogging(enableTestLogging);
    await claudeService.initialize();
    testLog('✓ Claude Service initialized with real MCP service');
  });

  test('system prompt can call MCP to retrieve goals by dimension', () async {
    testLog('\n🧪 Testing get_goals_by_dimension MCP command...');

    // 1. Get goals directly from the Life Plan Service
    final goalsFromService = lifePlanService.getGoalsByDimension('SF');
    testLog('📊 Goals from service: ${goalsFromService.length} goals found');
    expect(goalsFromService, isNotEmpty,
        reason: 'Should find goals for SF dimension');

    // 2. Create a command to get goals through the Claude service
    final command =
        json.encode({'action': 'get_goals_by_dimension', 'dimension': 'SF'});
    testLog('📤 Sending command through Claude service: $command');

    // 3. Send the command through the Claude service
    final response = await claudeService.sendMessage(command);
    testLog('📥 Response received: $response');

    // 4. Parse the response
    final parsedResponse = json.decode(response);
    testLog('🔍 Parsed response: $parsedResponse');

    // 5. Verify the response
    expect(parsedResponse['status'], equals('success'),
        reason: 'Response should have success status');
    expect(parsedResponse['data'], isA<List>(),
        reason: 'Response data should be a list');
    expect(parsedResponse['data'], isNotEmpty,
        reason: 'Response data should not be empty');

    // 6. Compare the data from both sources
    final goalsFromMCP = parsedResponse['data'];
    expect(goalsFromMCP.length, equals(goalsFromService.length),
        reason: 'Number of goals should match between direct service and MCP');

    // 7. Verify the first goal's properties
    final firstGoalFromService = goalsFromService.first;
    final firstGoalFromMCP = goalsFromMCP.first;

    expect(
        firstGoalFromMCP['dimension'], equals(firstGoalFromService.dimension),
        reason: 'Goal dimension should match');
    expect(firstGoalFromMCP['id'], equals(firstGoalFromService.id),
        reason: 'Goal ID should match');
    expect(firstGoalFromMCP['description'],
        equals(firstGoalFromService.description),
        reason: 'Goal description should match');
    expect(firstGoalFromMCP['trackId'], equals(firstGoalFromService.trackId),
        reason: 'Goal trackId should match');

    testLog('✓ Test completed successfully - MCP integration verified');
  });

  test('system prompt can call MCP to retrieve track by ID', () async {
    testLog('\n🧪 Testing get_track_by_id MCP command...');

    // 1. Get a track directly from the Life Plan Service
    const trackId = 'ME1'; // Using a known track ID
    final trackFromService = lifePlanService.getTrackById(trackId);
    testLog('📊 Track from service: ${trackFromService?.name}');
    expect(trackFromService, isNotNull,
        reason: 'Should find track with ID $trackId');

    // 2. Create a command to get the track through the Claude service
    final command =
        json.encode({'action': 'get_track_by_id', 'trackId': trackId});
    testLog('📤 Sending command through Claude service: $command');

    // 3. Send the command through the Claude service
    final response = await claudeService.sendMessage(command);
    testLog('📥 Response received: $response');

    // 4. Parse the response
    final parsedResponse = json.decode(response);
    testLog('🔍 Parsed response: $parsedResponse');

    // 5. Verify the response
    expect(parsedResponse['status'], equals('success'),
        reason: 'Response should have success status');
    expect(parsedResponse['data'], isA<Map>(),
        reason: 'Response data should be a map');

    // 6. Compare the data from both sources
    final trackFromMCP = parsedResponse['data'];
    expect(trackFromMCP['code'], equals(trackFromService!.code),
        reason: 'Track code should match');
    expect(trackFromMCP['name'], equals(trackFromService.name),
        reason: 'Track name should match');
    expect(trackFromMCP['dimension'], equals(trackFromService.dimension),
        reason: 'Track dimension should match');

    // 7. Verify the challenges
    expect(trackFromMCP['challenges'], isA<List>(),
        reason: 'Track challenges should be a list');
    expect(trackFromMCP['challenges'].length,
        equals(trackFromService.challenges.length),
        reason: 'Number of challenges should match');

    testLog('✓ Test completed successfully - MCP integration verified');
  });

  test('system prompt can call MCP to retrieve recommended habits', () async {
    testLog('\n🧪 Testing get_recommended_habits MCP command...');

    // 1. Get recommended habits directly from the Life Plan Service
    const dimension = 'SM'; // Mental dimension
    const minImpact = 4; // High impact
    final habitsFromService =
        lifePlanService.getRecommendedHabits(dimension, minImpact: minImpact);
    testLog('📊 Habits from service: ${habitsFromService.length} habits found');
    expect(habitsFromService, isNotEmpty,
        reason: 'Should find habits for $dimension dimension');

    // 2. Create a command to get habits through the Claude service
    final command = json.encode({
      'action': 'get_recommended_habits',
      'dimension': dimension,
      'minImpact': minImpact
    });
    testLog('📤 Sending command through Claude service: $command');

    // 3. Send the command through the Claude service
    final response = await claudeService.sendMessage(command);
    testLog('📥 Response received: $response');

    // 4. Parse the response
    final parsedResponse = json.decode(response);
    testLog('🔍 Parsed response: $parsedResponse');

    // 5. Verify the response
    expect(parsedResponse['status'], equals('success'),
        reason: 'Response should have success status');
    expect(parsedResponse['data'], isA<List>(),
        reason: 'Response data should be a list');
    expect(parsedResponse['data'], isNotEmpty,
        reason: 'Response data should not be empty');

    // 6. Compare the data from both sources
    final habitsFromMCP = parsedResponse['data'];
    expect(habitsFromMCP.length, equals(habitsFromService.length),
        reason: 'Number of habits should match between direct service and MCP');

    // 7. Verify the first habit's properties
    if (habitsFromService.isNotEmpty && habitsFromMCP.isNotEmpty) {
      final firstHabitFromService = habitsFromService.first;
      final firstHabitFromMCP = habitsFromMCP.first;

      expect(firstHabitFromMCP['id'], equals(firstHabitFromService.id),
          reason: 'Habit ID should match');
      expect(firstHabitFromMCP['description'],
          equals(firstHabitFromService.description),
          reason: 'Habit description should match');

      // 8. Verify the impact values
      final impactFromMCP = firstHabitFromMCP['impact'];
      expect(
          impactFromMCP['mental'], equals(firstHabitFromService.impact.mental),
          reason: 'Mental impact should match');

      // 9. Verify the minimum impact threshold is respected
      expect(impactFromMCP['mental'], greaterThanOrEqualTo(minImpact),
          reason: 'Mental impact should be at least $minImpact');
    }

    testLog('✓ Test completed successfully - MCP integration verified');
  });

  // EDGE CASE 1: Test with non-existent dimension
  test('MCP handles non-existent dimension gracefully', () async {
    testLog(
        '\n🧪 Testing get_goals_by_dimension with non-existent dimension...');

    // 1. Create a command with a non-existent dimension
    final command = json.encode({
      'action': 'get_goals_by_dimension',
      'dimension': 'XX' // Non-existent dimension
    });
    testLog('📤 Sending command with non-existent dimension: $command');

    // 2. Send the command through the Claude service
    final response = await claudeService.sendMessage(command);
    testLog('📥 Response received: $response');

    // 3. Parse the response
    final parsedResponse = json.decode(response);
    testLog('🔍 Parsed response: $parsedResponse');

    // 4. Verify the response is still successful but with empty data
    expect(parsedResponse['status'], equals('success'),
        reason:
            'Response should have success status even with non-existent dimension');
    expect(parsedResponse['data'], isA<List>(),
        reason: 'Response data should be a list');
    expect(parsedResponse['data'], isEmpty,
        reason: 'Response data should be empty for non-existent dimension');

    testLog(
        '✓ Test completed successfully - MCP handles non-existent dimension gracefully');
  });

  // EDGE CASE 2: Test with non-existent track ID
  test('MCP handles non-existent track ID gracefully', () async {
    testLog('\n🧪 Testing get_track_by_id with non-existent track ID...');

    // 1. Create a command with a non-existent track ID
    final command = json.encode({
      'action': 'get_track_by_id',
      'trackId': 'NONEXISTENT' // Non-existent track ID
    });
    testLog('📤 Sending command with non-existent track ID: $command');

    // 2. Send the command through the Claude service
    final response = await claudeService.sendMessage(command);
    testLog('📥 Response received: $response');

    // 3. Parse the response
    final parsedResponse = json.decode(response);
    testLog('🔍 Parsed response: $parsedResponse');

    // 4. Verify the response indicates no track was found
    expect(parsedResponse['status'], equals('error'),
        reason: 'Response should have error status for non-existent track ID');
    expect(parsedResponse['message'], contains('not found'),
        reason: 'Response message should indicate track was not found');

    testLog(
        '✓ Test completed successfully - MCP handles non-existent track ID gracefully');
  });

  // EDGE CASE 3: Test with missing required parameter
  test('MCP handles missing required parameter gracefully', () async {
    testLog(
        '\n🧪 Testing get_goals_by_dimension with missing required parameter...');

    // 1. Create a command with missing required parameter
    final command = json.encode({
      'action': 'get_goals_by_dimension'
      // Missing 'dimension' parameter
    });
    testLog('📤 Sending command with missing parameter: $command');

    // 2. Send the command through the Claude service
    final response = await claudeService.sendMessage(command);
    testLog('📥 Response received: $response');

    // 3. Verify the response contains an error message about the missing parameter
    expect(response, contains('Missing required parameter'),
        reason: 'Response should indicate missing required parameter');
    expect(response, contains('dimension'),
        reason: 'Response should specify which parameter is missing');

    testLog(
        '✓ Test completed successfully - MCP handles missing parameter gracefully');
  });

  // EDGE CASE 4: Test with invalid action
  test('MCP handles invalid action gracefully', () async {
    testLog('\n🧪 Testing with invalid action...');

    // 1. Create a command with an invalid action
    final command =
        json.encode({'action': 'invalid_action', 'parameter': 'value'});
    testLog('📤 Sending command with invalid action: $command');

    // 2. Send the command through the Claude service
    final response = await claudeService.sendMessage(command);
    testLog('📥 Response received: $response');

    // 3. Verify the response contains an error message about the invalid action
    expect(response, contains('Unknown action'),
        reason: 'Response should indicate unknown action');
    expect(response, contains('invalid_action'),
        reason: 'Response should specify which action is invalid');

    testLog(
        '✓ Test completed successfully - MCP handles invalid action gracefully');
  });

  // EDGE CASE 5: Test with very high minImpact that returns no results
  test('MCP handles empty results gracefully', () async {
    testLog('\n🧪 Testing get_recommended_habits with very high minImpact...');

    // 1. Create a command with a very high minImpact that should return no results
    final command = json.encode({
      'action': 'get_recommended_habits',
      'dimension': 'SM',
      'minImpact': 10 // Very high impact that shouldn't match any habits
    });
    testLog('📤 Sending command with very high minImpact: $command');

    // 2. Send the command through the Claude service
    final response = await claudeService.sendMessage(command);
    testLog('📥 Response received: $response');

    // 3. Parse the response
    final parsedResponse = json.decode(response);
    testLog('🔍 Parsed response: $parsedResponse');

    // 4. Verify the response is still successful but with empty data
    expect(parsedResponse['status'], equals('success'),
        reason:
            'Response should have success status even with no matching habits');
    expect(parsedResponse['data'], isA<List>(),
        reason: 'Response data should be a list');
    expect(parsedResponse['data'], isEmpty,
        reason: 'Response data should be empty for very high minImpact');

    testLog(
        '✓ Test completed successfully - MCP handles empty results gracefully');
  });

  // EDGE CASE 6: Test with malformed JSON
  test('MCP handles malformed JSON gracefully', () async {
    testLog('\n🧪 Testing with malformed JSON...');

    // 1. Create a malformed JSON string
    const malformedJson =
        '{action: get_goals_by_dimension, dimension: SF}'; // Missing quotes
    testLog('📤 Sending malformed JSON: $malformedJson');

    // 2. Send the malformed JSON through the Claude service
    final response = await claudeService.sendMessage(malformedJson);
    testLog('📥 Response received: $response');

    // 3. Verify the response contains an error message about the malformed JSON
    expect(response, contains('Invalid command format'),
        reason: 'Response should indicate invalid command format');

    testLog(
        '✓ Test completed successfully - MCP handles malformed JSON gracefully');
  });
}
