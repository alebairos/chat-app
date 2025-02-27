import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/life_plan_service.dart';
import 'package:character_ai_clone/services/life_plan_mcp_service.dart';
import 'package:character_ai_clone/models/life_plan/goal.dart';
import 'package:character_ai_clone/models/life_plan/habit.dart';
import 'package:character_ai_clone/models/life_plan/track.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  print('\n🚀 Starting Life Plan Integration Tests');

  late LifePlanService lifePlanService;
  late LifePlanMCPService mcpService;

  // Store original data for teardown
  List<Goal>? originalGoals;
  List<Habit>? originalHabits;
  Map<String, Track>? originalTracks;

  setUpAll(() async {
    print('\n📝 Setting up test environment...');
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
      OPENAI_API_KEY=test_key
    ''');

    // Initialize services with real data
    lifePlanService = LifePlanService();
    await lifePlanService.initialize();
    print('✓ Life Plan Service initialized with real CSV data');

    // Store original data for teardown
    originalGoals = List.from(lifePlanService.goals);
    originalHabits = List.from(lifePlanService.habits);
    originalTracks = Map.from(lifePlanService.tracks);
    print('✓ Original data stored for teardown');

    // Initialize MCP service
    mcpService = LifePlanMCPService(lifePlanService);
    print('✓ MCP Service initialized');
  });

  tearDown(() {
    print('\n🧹 Cleaning up test case...');
  });

  tearDownAll(() {
    print('\n🧹 Cleaning up test environment...');
    // Restore original data if needed
    print('✓ Test environment cleaned up');
  });

  group('Life Plan Integration Tests with CSV Data', () {
    test('retrieves goals by dimension through MCP service', () async {
      print('\n🧪 Testing goal retrieval by dimension...');

      // Step 1: Create an MCP command to fetch goals
      final mcpCommand = {
        'action': 'get_goals_by_dimension',
        'dimension': 'SF'
      };
      print('📤 MCP command: ${json.encode(mcpCommand)}');

      // Step 2: Process the command through the MCP service
      final response = mcpService.processCommand(json.encode(mcpCommand));
      print('📥 Received response: $response');

      // Step 3: Parse the response
      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      // Step 4: Validate the response structure
      expect(decoded['status'], equals('success'),
          reason: 'Response status should be success');
      expect(decoded['data'], isA<List>(),
          reason: 'Response data should be a list');
      expect(decoded['data'].isNotEmpty, isTrue,
          reason: 'Response data should not be empty');

      // Step 5: Validate the goals data
      final goals = decoded['data'] as List;
      print('📊 Found ${goals.length} physical health goals');

      // Step 6: Verify all goals have the correct dimension
      for (final goal in goals) {
        expect(goal['dimension'], equals('SF'),
            reason: 'All goals should have SF dimension');
        expect(goal['id'], isNotEmpty, reason: 'Goal ID should not be empty');
        expect(goal['description'], isNotEmpty,
            reason: 'Goal description should not be empty');
        expect(goal['trackId'], isNotEmpty,
            reason: 'Goal trackId should not be empty');
      }

      // Step 7: Compare with direct service call to ensure consistency
      final directGoals = lifePlanService.getGoalsByDimension('SF');
      expect(goals.length, equals(directGoals.length),
          reason:
              'MCP should return the same number of goals as direct service call');

      print('✅ Goal retrieval test completed successfully');
    });

    test('retrieves track by ID through MCP service', () async {
      print('\n🧪 Testing track retrieval by ID...');

      // Get a valid track ID from a goal
      final goals = await lifePlanService.getGoalsByDimension('SF');
      final trackId = goals.first.trackId
          .trim(); // Trim to remove any whitespace or carriage returns
      print('🔍 Using track ID: $trackId');

      // Send command to get track by ID
      final command = {
        'action': 'get_track_by_id',
        'trackId': trackId,
      };
      print('📤 MCP command: ${jsonEncode(command)}');

      final response = await mcpService.processCommand(jsonEncode(command));
      print('📥 Received response: $response');

      final Map<String, dynamic> decodedResponse = jsonDecode(response);
      print('🔍 Decoded response: $decodedResponse');

      // Verify response structure
      expect(decodedResponse['status'], 'success');
      expect(decodedResponse['data'], isA<Map<String, dynamic>>());

      // Verify track data
      final trackData = decodedResponse['data'];
      expect(trackData['code'], trackId,
          reason: 'Track code should match the requested ID');
      expect(trackData['name'], isNotEmpty);
      expect(trackData['challenges'], isA<List>());

      print('✅ Track retrieval test completed successfully');
      print('\n🧹 Cleaning up test case...');
    });

    test('retrieves habits for challenge through MCP service', () async {
      print('\n🧪 Testing habits retrieval for challenge...');

      // Step 1: Get a valid track and challenge
      final tracks = lifePlanService.tracks.values.toList();
      expect(tracks.isNotEmpty, isTrue,
          reason: 'Should have at least one track');

      // Find a track with challenges
      Track? trackWithChallenges;
      String? challengeCode;

      for (final track in tracks) {
        if (track.challenges.isNotEmpty) {
          trackWithChallenges = track;
          challengeCode = track.challenges.first.code;
          break;
        }
      }

      expect(trackWithChallenges, isNotNull,
          reason: 'Should have a track with challenges');
      expect(challengeCode, isNotNull, reason: 'Should have a challenge code');

      print(
          '🔍 Using track: ${trackWithChallenges!.code}, challenge: $challengeCode');

      // Step 2: Create an MCP command to fetch habits
      final mcpCommand = {
        'action': 'get_habits_for_challenge',
        'trackId': trackWithChallenges.code,
        'challengeCode': challengeCode
      };
      print('📤 MCP command: ${json.encode(mcpCommand)}');

      // Step 3: Process the command through the MCP service
      final response = mcpService.processCommand(json.encode(mcpCommand));
      print('📥 Received response: $response');

      // Step 4: Parse the response
      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      // Step 5: Validate the response structure
      expect(decoded['status'], equals('success'),
          reason: 'Response status should be success');
      expect(decoded['data'], isA<List>(),
          reason: 'Response data should be a list');

      // Step 6: Validate habits data if any exist
      final habits = decoded['data'] as List;
      print('📊 Found ${habits.length} habits for the challenge');

      // Some challenges might not have habits, so we only validate if there are any
      if (habits.isNotEmpty) {
        final firstHabit = habits.first;
        expect(firstHabit['id'], isNotEmpty,
            reason: 'Habit ID should not be empty');
        expect(firstHabit['description'], isNotEmpty,
            reason: 'Habit description should not be empty');
        expect(firstHabit['impact'], isA<Map>(),
            reason: 'Habit should have impact data');
      }

      // Step 7: Compare with direct service call
      final directHabits = lifePlanService.getHabitsForChallenge(
          trackWithChallenges.code, challengeCode!);
      expect(habits.length, equals(directHabits.length),
          reason:
              'MCP should return same number of habits as direct service call');

      print('✅ Habits retrieval test completed successfully');
    });

    test('retrieves recommended habits through MCP service', () async {
      print('\n🧪 Testing recommended habits retrieval...');

      // Step 1: Create an MCP command to fetch recommended habits
      final mcpCommand = {
        'action': 'get_recommended_habits',
        'dimension': 'SF',
        'minImpact': 3
      };
      print('📤 MCP command: ${json.encode(mcpCommand)}');

      // Step 2: Process the command through the MCP service
      final response = mcpService.processCommand(json.encode(mcpCommand));
      print('📥 Received response: $response');

      // Step 3: Parse the response
      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      // Step 4: Validate the response structure
      expect(decoded['status'], equals('success'),
          reason: 'Response status should be success');
      expect(decoded['data'], isA<List>(),
          reason: 'Response data should be a list');

      // Step 5: Validate the habits data
      final habits = decoded['data'] as List;
      print('📊 Found ${habits.length} recommended habits');

      // Verify we have habits and they meet the criteria
      expect(habits.isNotEmpty, isTrue,
          reason: 'Should have at least one recommended habit');

      for (final habit in habits) {
        expect(habit['id'], isNotEmpty, reason: 'Habit ID should not be empty');
        expect(habit['description'], isNotEmpty,
            reason: 'Habit description should not be empty');
        expect(habit['impact'], isA<Map>(),
            reason: 'Habit should have impact data');
        expect(habit['impact']['physical'], greaterThanOrEqualTo(3),
            reason: 'Physical impact should meet minimum threshold');
      }

      // Step 6: Compare with direct service call
      final directHabits =
          lifePlanService.getRecommendedHabits('SF', minImpact: 3);
      expect(habits.length, equals(directHabits.length),
          reason:
              'MCP should return same number of habits as direct service call');

      print('✅ Recommended habits test completed successfully');
    });

    test('handles error cases gracefully', () async {
      print('\n🧪 Testing error handling...');

      // Test case 1: Unknown action
      final unknownCommand = {'action': 'unknown_action'};
      final unknownResponse =
          mcpService.processCommand(json.encode(unknownCommand));
      final unknownDecoded = json.decode(unknownResponse);

      expect(unknownDecoded['status'], equals('error'),
          reason: 'Unknown action should return error status');
      expect(unknownDecoded['message'], contains('Unknown action'),
          reason: 'Error message should mention unknown action');

      // Test case 2: Missing required parameter
      final missingParamCommand = {
        'action': 'get_goals_by_dimension'
        // Missing 'dimension' parameter
      };
      final missingParamResponse =
          mcpService.processCommand(json.encode(missingParamCommand));
      final missingParamDecoded = json.decode(missingParamResponse);

      expect(missingParamDecoded['status'], equals('error'),
          reason: 'Missing parameter should return error status');
      expect(missingParamDecoded['message'],
          contains('Missing required parameter'),
          reason: 'Error message should mention missing parameter');

      // Test case 3: Invalid track ID
      final invalidTrackCommand = {
        'action': 'get_track_by_id',
        'trackId': 'INVALID_ID'
      };
      final invalidTrackResponse =
          mcpService.processCommand(json.encode(invalidTrackCommand));
      final invalidTrackDecoded = json.decode(invalidTrackResponse);

      expect(invalidTrackDecoded['status'], equals('error'),
          reason: 'Invalid track ID should return error status');
      expect(invalidTrackDecoded['message'], contains('Track not found'),
          reason: 'Error message should mention track not found');

      print('✅ Error handling test completed successfully');
    });

    test('end-to-end flow from goal to track to habits', () async {
      print('\n🧪 Testing end-to-end flow from goal to track to habits...');

      // Step 1: Get goals for a dimension
      final getGoalsCommand = {
        'action': 'get_goals_by_dimension',
        'dimension': 'SF',
      };
      final goalsResponse =
          await mcpService.processCommand(jsonEncode(getGoalsCommand));
      final Map<String, dynamic> goalsData = jsonDecode(goalsResponse);
      expect(goalsData['status'], 'success');
      expect(goalsData['data'], isA<List>());

      // Step 2: Get track for the first goal
      final goals = goalsData['data'] as List;
      expect(goals, isNotEmpty);
      final firstGoal = goals.first;
      final trackId = firstGoal['trackId']
          .toString()
          .trim(); // Trim to remove any whitespace or carriage returns

      final getTrackCommand = {
        'action': 'get_track_by_id',
        'trackId': trackId,
      };
      final trackResponse =
          await mcpService.processCommand(jsonEncode(getTrackCommand));
      final Map<String, dynamic> trackData = jsonDecode(trackResponse);
      expect(trackData['status'], 'success');
      expect(trackData['data'], isA<Map<String, dynamic>>());

      // Verify track data
      final track = trackData['data'];
      expect(track['code'], trackId,
          reason: 'Track code should match the goal\'s trackId');
      expect(track['challenges'], isA<List>());

      // Step 3: Get habits for the first challenge
      final challenges = track['challenges'] as List;
      expect(challenges, isNotEmpty);
      final firstChallenge = challenges.first;
      final challengeCode = firstChallenge['code'];

      final getHabitsCommand = {
        'action': 'get_habits_for_challenge',
        'trackId': trackId,
        'challengeCode': challengeCode,
      };
      final habitsResponse =
          await mcpService.processCommand(jsonEncode(getHabitsCommand));
      final Map<String, dynamic> habitsData = jsonDecode(habitsResponse);
      expect(habitsData['status'], 'success');
      expect(habitsData['data'], isA<List>());

      // Verify habits data
      final habits = habitsData['data'] as List;
      if (habits.isNotEmpty) {
        final firstHabit = habits.first;
        expect(firstHabit['id'], isNotEmpty);
        expect(firstHabit['description'], isNotEmpty);
        expect(firstHabit['impact'], isA<Map<String, dynamic>>());
      }

      print('✅ End-to-end flow test completed successfully');
      print('\n🧹 Cleaning up test case...');
    });
  });
}
