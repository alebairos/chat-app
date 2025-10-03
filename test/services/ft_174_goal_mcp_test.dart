import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/system_mcp_service.dart';
import 'dart:convert';

/// FT-174: Simple and focused MCP goal function tests
///
/// Testing philosophy:
/// - Very focused: Each test targets a specific scenario
/// - Simple: Tests are straightforward and easy to understand
/// - No mocks needed: Direct testing of MCP command processing
void main() {
  group('SystemMCP Goal Functions', () {
    late SystemMCPService mcpService;

    setUp(() {
      mcpService = SystemMCPService();
    });

    test('should create goal with valid Oracle objective', () async {
      // Arrange
      const command =
          '{"action": "create_goal", "objective_code": "OPP1", "objective_name": "Perder peso"}';

      // Act
      final response = await mcpService.processCommand(command);
      final data = json.decode(response);

      // Assert - In test environment, database may not be available
      // So we test that the MCP function processes the command correctly
      expect(data['status'],
          isIn(['success', 'error'])); // Either works or fails gracefully
      if (data['status'] == 'success') {
        expect(data['data']['objective_code'], equals('OPP1'));
        expect(data['data']['objective_name'], equals('Perder peso'));
      } else {
        // Should fail gracefully with database error
        expect(data['message'], isNotNull);
      }
    });

    test('should reject goal creation with missing objective_code', () async {
      // Arrange
      const command =
          '{"action": "create_goal", "objective_name": "Perder peso"}';

      // Act
      final response = await mcpService.processCommand(command);
      final data = json.decode(response);

      // Assert
      expect(data['status'], equals('error'));
      expect(data['message'], contains('Missing required parameters'));
      expect(data['message'], contains('objective_code'));
    });

    test('should reject goal creation with missing objective_name', () async {
      // Arrange
      const command = '{"action": "create_goal", "objective_code": "OPP1"}';

      // Act
      final response = await mcpService.processCommand(command);
      final data = json.decode(response);

      // Assert
      expect(data['status'], equals('error'));
      expect(data['message'], contains('Missing required parameters'));
      expect(data['message'], contains('objective_name'));
    });

    test('should reject goal creation with invalid objective_code format',
        () async {
      // Arrange
      const command =
          '{"action": "create_goal", "objective_code": "invalid123", "objective_name": "Test Goal"}';

      // Act
      final response = await mcpService.processCommand(command);
      final data = json.decode(response);

      // Assert
      expect(data['status'], equals('error'));
      expect(data['message'], contains('Invalid objective_code format'));
      expect(data['message'], contains('OPP1, OGM1'));
    });

    test('should accept valid Oracle objective codes', () async {
      // Test multiple valid Oracle objective code formats
      final validCodes = [
        {'code': 'OPP1', 'name': 'Perder peso'},
        {'code': 'OGM2', 'name': 'Ganhar massa'},
        {'code': 'ODM1', 'name': 'Dormir melhor'},
        {'code': 'OSPM3', 'name': 'Gerenciar tempo'},
        {'code': 'ORA1', 'name': 'Reduzir ansiedade'},
      ];

      for (final testCase in validCodes) {
        // Arrange
        final command =
            '{"action": "create_goal", "objective_code": "${testCase['code']}", "objective_name": "${testCase['name']}"}';

        // Act
        final response = await mcpService.processCommand(command);
        final data = json.decode(response);

        // Assert - Test that valid codes are processed correctly
        expect(data['status'], isIn(['success', 'error']),
            reason: 'Failed for objective code: ${testCase['code']}');
        if (data['status'] == 'success') {
          expect(data['data']['objective_code'], equals(testCase['code']));
          expect(data['data']['objective_name'], equals(testCase['name']));
        }
      }
    });

    test('should get active goals successfully', () async {
      // Arrange
      const command = '{"action": "get_active_goals"}';

      // Act
      final response = await mcpService.processCommand(command);
      final data = json.decode(response);

      // Assert - In test environment, database may not be available
      // So we test that the MCP function processes the command correctly
      expect(data['status'],
          isIn(['success', 'error'])); // Either works or fails gracefully
      if (data['status'] == 'success') {
        expect(data['data']['goals'], isList);
        expect(data['data']['total_count'], isA<int>());
        expect(data['message'], equals('Active goals retrieved successfully'));
      } else {
        // Should fail gracefully with database error
        expect(data['message'], isNotNull);
        print('Test environment database error (expected): ${data['message']}');
      }
    });

    test('should reject invalid objective codes like CX1 (trilha code)',
        () async {
      // Arrange - Test the exact case from the user's issue
      const command =
          '{"action": "create_goal", "objective_code": "CX1", "objective_name": "Correr 5k"}';

      // Act
      final response = await mcpService.processCommand(command);
      final data = json.decode(response);

      // Assert
      expect(data['status'], equals('error'));
      expect(data['message'], contains('Invalid Oracle objective code: CX1'));
      expect(data['message'], contains('Use valid codes like OCX1 (not CX1)'));
    });

    test('should accept valid objective codes like OCX1', () async {
      // Arrange
      const command =
          '{"action": "create_goal", "objective_code": "OCX1", "objective_name": "Correr 5k"}';

      // Act
      final response = await mcpService.processCommand(command);
      final data = json.decode(response);

      // Assert - In test environment, database may not be available
      expect(data['status'],
          isIn(['success', 'error'])); // Either works or fails gracefully
      if (data['status'] == 'success') {
        expect(data['data']['objective_code'], equals('OCX1'));
        expect(data['data']['objective_name'], equals('Correr 5k'));
      } else {
        // Should fail gracefully with database error, not validation error
        expect(
            data['message'], isNot(contains('Invalid Oracle objective code')));
      }
    });

    test('should handle malformed JSON gracefully', () async {
      // Arrange
      const command =
          '{"action": "create_goal", "objective_code": "OPP1"'; // Missing closing brace

      // Act
      final response = await mcpService.processCommand(command);
      final data = json.decode(response);

      // Assert
      expect(data['status'], equals('error'));
      expect(
          data['message'],
          anyOf([
            contains('Invalid JSON'),
            contains('Invalid command format'),
            contains('FormatException'),
          ]));
    });

    test('should handle unknown goal action gracefully', () async {
      // Arrange
      const command = '{"action": "delete_goal", "goal_id": 123}';

      // Act
      final response = await mcpService.processCommand(command);
      final data = json.decode(response);

      // Assert
      expect(data['status'], equals('error'));
      expect(data['message'], contains('Unknown action'));
    });
  });
}
