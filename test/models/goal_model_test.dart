import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:ai_personas_app/models/goal_model.dart';

/// FT-174: Simple and focused GoalModel tests
///
/// Testing philosophy:
/// - Very focused: Each test targets a specific scenario
/// - Simple: Tests are straightforward and easy to understand
/// - No mocks needed: Direct testing of model behavior
void main() {
  group('GoalModel', () {
    test('should create goal with fromObjective constructor', () {
      // Arrange & Act
      final goal = GoalModel.fromObjective(
        objectiveCode: 'OPP1',
        objectiveName: 'Perder peso',
      );

      // Assert
      expect(goal.objectiveCode, equals('OPP1'));
      expect(goal.objectiveName, equals('Perder peso'));
      expect(goal.isActive, isTrue);
      expect(goal.createdAt, isNotNull);
      expect(goal.displayName, equals('Perder peso'));
    });

    test('should format creation date correctly for today', () {
      // Arrange
      final goal = GoalModel.fromObjective(
        objectiveCode: 'OGM1',
        objectiveName: 'Ganhar massa',
      );

      // Act
      final formattedDate = goal.formattedCreatedDate;

      // Assert
      expect(formattedDate, equals('Today'));
    });

    test('should format creation date correctly for yesterday', () {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final goal = GoalModel.fromObjective(
        objectiveCode: 'ODM1',
        objectiveName: 'Dormir melhor',
      );
      // Manually set createdAt to yesterday for testing
      goal.createdAt = yesterday;

      // Act
      final formattedDate = goal.formattedCreatedDate;

      // Assert
      expect(formattedDate, equals('Yesterday'));
    });

    test('should format creation date correctly for older dates', () {
      // Arrange
      final oldDate = DateTime(2024, 1, 15);
      final goal = GoalModel.fromObjective(
        objectiveCode: 'OSPM1',
        objectiveName: 'Gerenciar tempo',
      );
      goal.createdAt = oldDate;

      // Act
      final formattedDate = goal.formattedCreatedDate;

      // Assert
      expect(formattedDate, equals('15/1/2024'));
    });

    test('should format creation date correctly for recent days', () {
      // Arrange
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final goal = GoalModel.fromObjective(
        objectiveCode: 'ORA1',
        objectiveName: 'Reduzir ansiedade',
      );
      goal.createdAt = threeDaysAgo;

      // Act
      final formattedDate = goal.formattedCreatedDate;

      // Assert
      expect(formattedDate, equals('3 days ago'));
    });

    test('should have correct toString representation', () {
      // Arrange
      final goal = GoalModel.fromObjective(
        objectiveCode: 'OLM1',
        objectiveName: 'Ler mais',
      );
      goal.id = 123;

      // Act
      final stringRepresentation = goal.toString();

      // Assert
      expect(stringRepresentation, contains('GoalModel'));
      expect(stringRepresentation, contains('id: 123'));
      expect(stringRepresentation, contains('code: OLM1'));
      expect(stringRepresentation, contains('name: Ler mais'));
      expect(stringRepresentation, contains('active: true'));
    });

    test('should create goal with default constructor', () {
      // Arrange & Act
      final goal = GoalModel();

      // Assert
      expect(goal.id, equals(Isar.autoIncrement)); // Isar.autoIncrement default
      expect(goal.isActive, isTrue);
    });
  });
}
