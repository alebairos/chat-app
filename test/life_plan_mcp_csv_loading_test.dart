import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/life_plan_mcp_service.dart';
import 'package:character_ai_clone/services/life_plan_service.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LifePlanMCPService mcpService;
  late LifePlanService lifePlanService;

  setUp(() async {
    // Initialize asset bundle for loading CSV files with mock data
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;

        final String key = utf8.decode(message.buffer
            .asUint8List(message.offsetInBytes, message.lengthInBytes));

        // Return mock data based on the requested asset
        if (key == 'AssetManifest.json') {
          final Map<String, List<String>> manifest = {
            'assets/data/Objetivos.csv': ['assets/data/Objetivos.csv'],
            'assets/data/habitos.csv': ['assets/data/habitos.csv'],
            'assets/data/Trilhas.csv': ['assets/data/Trilhas.csv'],
          };
          final String json = jsonEncode(manifest);
          return ByteData.view(Uint8List.fromList(utf8.encode(json)).buffer);
        }

        if (key == 'assets/data/Objetivos.csv') {
          const String mockData = '''Dimensão;ID Objetivo;Descrição;Trilha
SF;OPP1;Perder peso;ME1
SF;OPP2;Perder peso avançado;ME2
SF;OGM1;Ganhar massa;GM1
SF;OGM2;Ganhar massa avançado;GM2
SF;ODM1;Dormir melhor;DM1
SF;ODM2;Dormir melhor : avançado;DM2
TG;OAE1;Aprender de forma mais eficaz;AE1''';
          return ByteData.view(
              Uint8List.fromList(utf8.encode(mockData)).buffer);
        }

        if (key == 'assets/data/habitos.csv') {
          const String mockData =
              '''ID;Hábito;Intensidade;Duração;Relacionamento;Trabalho;Saúde física;Espiritualidade;Saúde mental
SF1;Dormir 8 horas;2;30;0;1;5;0;4
SF10;Treino de força;3;45;0;0;5;0;2
SF18;Beber 2L de água;1;1;0;0;4;0;1
SM1;Meditar;2;15;0;0;1;3;5''';
          return ByteData.view(
              Uint8List.fromList(utf8.encode(mockData)).buffer);
        }

        if (key == 'assets/data/Trilhas.csv') {
          const String mockData =
              '''Dimensão;Código Trilha;Nome Trilha;Código Desafio;Nome Desafio;Nível;Hábitos;Frequencia
SF;ER1;Energia recarregada;ER1PC;Primeiro contato;1;SF1;7
SF;ER1;Energia recarregada;ER1PC;Primeiro contato;1;SF18;3
SF;ER1;Energia recarregada;ER1PC;Primeiro contato;1;SM1;7
SF;ME1;Metabolismo eficiente;ME1PC;Primeiro contato;1;SF1;7
SF;GM1;Ganho de massa;GM1PC;Primeiro contato;1;SF10;5''';
          return ByteData.view(
              Uint8List.fromList(utf8.encode(mockData)).buffer);
        }

        return null;
      },
    );

    print('🔄 Setting up test environment...');
    lifePlanService = LifePlanService();
    await lifePlanService.initialize();
    mcpService = LifePlanMCPService(lifePlanService);
    print('✓ Services initialized');
  });

  group('LifePlanMCPService CSV Data Loading', () {
    test('correctly loads goals from CSV file', () async {
      print('🧪 Testing goals loading from CSV...');

      // Use the MCP service to get goals for a specific dimension
      final command = {'action': 'get_goals_by_dimension', 'dimension': 'SF'};
      final response = mcpService.processCommand(jsonEncode(command));
      final decodedResponse = jsonDecode(response);

      // Verify the response structure
      expect(decodedResponse['status'], 'success');
      expect(decodedResponse['data'], isA<List>());

      // Verify that goals were loaded correctly
      if (decodedResponse['data'].isNotEmpty) {
        final goals = decodedResponse['data'];

        // Check that all goals have the correct dimension
        for (final goal in goals) {
          expect(goal['dimension'], equals('SF'));
          expect(goal['id'], isNotEmpty);
          expect(goal['description'], isNotEmpty);
          expect(goal['trackId'], isNotEmpty);
        }

        // Check for specific expected goals
        final goalIds = goals.map<String>((g) => g['id'].toString()).toList();
        expect(goalIds, contains('OPP1')); // "Perder peso"
        expect(goalIds, contains('OGM1')); // "Ganhar massa"
      }

      print('✓ Goals loaded correctly from CSV');
    });

    test('correctly loads habits from CSV file', () async {
      print('🧪 Testing habits loading from CSV...');

      // Use the MCP service to get recommended habits
      final command = {
        'action': 'get_recommended_habits',
        'dimension': 'SF',
        'minImpact': 3
      };
      final response = mcpService.processCommand(jsonEncode(command));
      final decodedResponse = jsonDecode(response);

      // Verify the response structure
      expect(decodedResponse['status'], 'success');
      expect(decodedResponse['data'], isA<List>());

      // Verify that habits were loaded correctly
      if (decodedResponse['data'].isNotEmpty) {
        final habits = decodedResponse['data'];

        // Check habit structure
        for (final habit in habits) {
          expect(habit['id'], isNotEmpty);
          expect(habit['description'], isNotEmpty);
          expect(habit['impact'], isA<Map>());

          // Convert the physical impact to int for comparison
          final physicalImpact =
              int.parse(habit['impact']['physical'].toString());
          expect(physicalImpact, greaterThanOrEqualTo(3));
        }

        // Check for specific expected habits (assuming SF10 is a physical habit with impact >= 3)
        final habitIds = habits.map<String>((h) => h['id'].toString()).toList();

        // Check if any habit ID starts with 'SF'
        bool hasSFHabit = false;
        for (final id in habitIds) {
          if (id.startsWith('SF')) {
            hasSFHabit = true;
            break;
          }
        }
        expect(hasSFHabit, isTrue);
      }

      print('✓ Habits loaded correctly from CSV');
    });

    test('correctly loads tracks from CSV file', () async {
      print('🧪 Testing tracks loading from CSV...');

      // Use the MCP service to get a specific track
      final command = {'action': 'get_track_by_id', 'trackId': 'ER1'};
      final response = mcpService.processCommand(jsonEncode(command));
      final decodedResponse = jsonDecode(response);

      // Verify the response structure
      expect(decodedResponse['status'], 'success');
      expect(decodedResponse['data'], isA<Map>());

      // Verify that the track was loaded correctly
      final track = decodedResponse['data'];
      expect(track['code'], equals('ER1'));
      expect(track['name'], equals('Energia recarregada'));
      expect(track['dimension'], equals('SF'));
      expect(track['challenges'], isA<List>());

      // Verify challenge structure
      if (track['challenges'].isNotEmpty) {
        final challenge = track['challenges'][0];
        expect(challenge['code'], isNotEmpty);
        expect(challenge['name'], isNotEmpty);
        expect(challenge['level'], isA<int>());
        expect(challenge['habits'], isA<List>());

        // Verify that the first challenge is "Primeiro contato"
        expect(challenge['code'], equals('ER1PC'));
        expect(challenge['name'], equals('Primeiro contato'));

        // Verify habits in the challenge
        if (challenge['habits'].isNotEmpty) {
          final habit = challenge['habits'][0];
          expect(habit['habitId'], isNotEmpty);
          expect(habit['frequency'], isA<int>());
        }
      }

      print('✓ Tracks loaded correctly from CSV');
    });

    test('correctly processes complex queries across multiple CSV files',
        () async {
      print('🧪 Testing complex queries across CSV files...');

      // First get a goal
      final goalCommand = {
        'action': 'get_goals_by_dimension',
        'dimension': 'SF'
      };
      final goalResponse = mcpService.processCommand(jsonEncode(goalCommand));
      final goalData = jsonDecode(goalResponse);

      expect(goalData['status'], 'success');
      expect(goalData['data'], isA<List>());
      expect(goalData['data'].isNotEmpty, isTrue);

      // Get the track ID from the first goal
      final trackId = goalData['data'][0]['trackId'].toString();

      // Now get the track using that ID
      final trackCommand = {'action': 'get_track_by_id', 'trackId': trackId};
      final trackResponse = mcpService.processCommand(jsonEncode(trackCommand));
      final trackData = jsonDecode(trackResponse);

      expect(trackData['status'], 'success');
      expect(trackData['data'], isA<Map>());
      expect(trackData['data']['code'], equals(trackId));

      // Get the challenge code from the first challenge
      final challengeCode =
          trackData['data']['challenges'][0]['code'].toString();

      // Now get habits for this challenge
      final habitCommand = {
        'action': 'get_habits_for_challenge',
        'trackId': trackId,
        'challengeCode': challengeCode
      };
      final habitResponse = mcpService.processCommand(jsonEncode(habitCommand));
      final habitData = jsonDecode(habitResponse);

      expect(habitData['status'], 'success');
      expect(habitData['data'], isA<List>());
      expect(habitData['data'].isNotEmpty, isTrue);

      // Verify that the habits returned match those specified in the track's challenge
      final habitIds =
          habitData['data'].map<String>((h) => h['id'].toString()).toList();

      // Get the habit IDs from the challenge
      final challengeHabitIds = trackData['data']['challenges'][0]['habits']
          .map<String>((h) => h['habitId'].toString())
          .toList();

      // Verify that all habit IDs from the challenge are in the returned habits
      for (final habitId in challengeHabitIds) {
        expect(habitIds, contains(habitId));
      }

      print('✓ Complex queries across CSV files processed correctly');
    });

    test('handles invalid data gracefully', () async {
      print('🧪 Testing handling of invalid data...');

      // Test with invalid dimension
      final invalidDimensionCommand = {
        'action': 'get_goals_by_dimension',
        'dimension': 'INVALID'
      };
      final invalidDimensionResponse =
          mcpService.processCommand(jsonEncode(invalidDimensionCommand));
      final invalidDimensionData = jsonDecode(invalidDimensionResponse);

      expect(invalidDimensionData['status'], 'success');
      expect(invalidDimensionData['data'], isEmpty);

      // Test with invalid track ID
      final invalidTrackCommand = {
        'action': 'get_track_by_id',
        'trackId': 'NONEXISTENT'
      };
      final invalidTrackResponse =
          mcpService.processCommand(jsonEncode(invalidTrackCommand));
      final invalidTrackData = jsonDecode(invalidTrackResponse);

      // The service returns 'error' status when track is not found
      expect(invalidTrackData['status'], 'error');
      expect(invalidTrackData['message'], contains('Track not found'));

      // Test with invalid challenge code
      final invalidChallengeCommand = {
        'action': 'get_habits_for_challenge',
        'trackId': 'ER1',
        'challengeCode': 'NONEXISTENT'
      };
      final invalidChallengeResponse =
          mcpService.processCommand(jsonEncode(invalidChallengeCommand));
      final invalidChallengeData = jsonDecode(invalidChallengeResponse);

      // The service returns 'success' with empty data when no habits are found
      expect(invalidChallengeData['status'], 'success');
      expect(invalidChallengeData['data'], isEmpty);

      print('✓ Invalid data handled gracefully');
    });

    test('compares goals from MCP service with direct CSV loading', () async {
      print(
          '🧪 Testing comparison between MCP service and direct CSV loading...');

      // Step 1: Create a Claude prompt that explicitly calls an MCP function
      const claudePrompt = '''
      I need to see all the goals related to physical health. 
      Please use the get_goals_by_dimension command with dimension SF to retrieve them.
      ''';

      print('📝 Claude prompt: $claudePrompt');
      print(
          '🔍 This prompt would trigger the MCP service to fetch goals with dimension "SF"');

      // Step 2: Use the MCP service to get goals (simulating what Claude would do)
      final mcpCommand = {
        'action': 'get_goals_by_dimension',
        'dimension': 'SF'
      };
      final mcpResponse = mcpService.processCommand(jsonEncode(mcpCommand));
      final mcpData = jsonDecode(mcpResponse);
      final mcpGoals = mcpData['data'] as List;
      print('📊 Retrieved ${mcpGoals.length} goals via MCP service');

      // Step 3: Directly load goals from the CSV using LifePlanService
      final directGoals = lifePlanService.getGoalsByDimension('SF');
      print('📊 Retrieved ${directGoals.length} goals directly from CSV');

      // Step 4: Compare the results
      expect(mcpGoals.length, equals(directGoals.length),
          reason:
              'MCP service and direct CSV loading should return the same number of goals');

      // Step 5: Verify that the expected number of SF goals are returned
      // According to Objetivos.csv, there should be 6 SF goals
      expect(mcpGoals.length, equals(6),
          reason: 'There should be 6 SF goals in the CSV file');

      // Step 6: Create maps for easier comparison
      final mcpGoalsMap = {
        for (var goal in mcpGoals) goal['id']: goal,
      };
      final directGoalsMap = {
        for (var goal in directGoals) goal.id: goal,
      };

      // Step 7: Verify specific expected goals from the CSV
      final expectedGoals = [
        {'id': 'OPP1', 'description': 'Perder peso', 'trackId': 'ME1'},
        {'id': 'OPP2', 'description': 'Perder peso avançado', 'trackId': 'ME2'},
        {'id': 'OGM1', 'description': 'Ganhar massa', 'trackId': 'GM1'},
        {
          'id': 'OGM2',
          'description': 'Ganhar massa avançado',
          'trackId': 'GM2'
        },
        {'id': 'ODM1', 'description': 'Dormir melhor', 'trackId': 'DM1'},
        {
          'id': 'ODM2',
          'description': 'Dormir melhor : avançado',
          'trackId': 'DM2'
        },
      ];

      for (final expectedGoal in expectedGoals) {
        final goalId = expectedGoal['id'];
        expect(mcpGoalsMap.containsKey(goalId), isTrue,
            reason: 'MCP results should contain goal $goalId');

        if (mcpGoalsMap.containsKey(goalId)) {
          expect(mcpGoalsMap[goalId]!['description'],
              equals(expectedGoal['description']),
              reason: 'Goal $goalId should have correct description');
          expect(
              mcpGoalsMap[goalId]!['trackId'], equals(expectedGoal['trackId']),
              reason: 'Goal $goalId should have correct trackId');
        }
      }

      print('✓ MCP service and direct CSV loading return identical goals');
      print(
          '✓ All expected goals from Objetivos.csv are present in the results');
    });
  });
}
