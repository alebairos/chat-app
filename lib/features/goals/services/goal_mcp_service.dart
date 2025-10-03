import 'dart:convert';
import 'goal_storage_service.dart';
import '../../../utils/logger.dart';

/// FT-176: Service for handling goal MCP commands
///
/// Extracted from SystemMCPService to provide clean separation
/// between MCP interface and business logic
class GoalMCPService {
  static final Logger _logger = Logger();

  /// Handle create_goal MCP command
  ///
  /// Expected command format:
  /// {"action": "create_goal", "objective_code": "OPP1", "objective_name": "Perder peso"}
  static Future<String> handleCreateGoal(Map<String, dynamic> parsedCommand) async {
    try {
      _logger.debug('GoalMCP: Processing create_goal command');

      final objectiveCode = parsedCommand['objective_code'] as String?;
      final objectiveName = parsedCommand['objective_name'] as String?;

      if (objectiveCode == null || objectiveName == null) {
        _logger.warning('GoalMCP: Missing required parameters');
        return _errorResponse('Missing required parameters: objective_code and objective_name are required');
      }

      // Validate that objectiveCode and objectiveName are not empty
      if (objectiveCode.trim().isEmpty || objectiveName.trim().isEmpty) {
        _logger.warning('GoalMCP: Empty parameters provided');
        return _errorResponse('Empty parameters: objective_code and objective_name cannot be empty');
      }

      // Validate that it's a real Oracle objective code (not trilha code)
      final validOracleCodes = [
        'OPP1', 'OPP2', 'OGM1', 'OGM2', 'ODM1', 'ODM2', 
        'OSPM1', 'OSPM2', 'OSPM3', 'OSPM4', 'OSPM5',
        'ORA1', 'ORA2', 'OLM1', 'OVG1', 'OME2', 'OMF1',
        'ODE1', 'ODE2', 'OREQ1', 'OREQ2', 'OSF1', 'OAE1',
        'OLV1', 'OCX1', 'OMMA1', 'OMMA2'
      ];

      if (!validOracleCodes.contains(objectiveCode)) {
        _logger.warning('GoalMCP: REJECTED invalid Oracle code: $objectiveCode (might be trilha code)');
        return _errorResponse(
            'Invalid Oracle objective code: $objectiveCode. Use valid codes like OCX1 (not CX1), OPP1, etc. Check the Oracle framework for valid codes.');
      }

      _logger.debug('GoalMCP: Oracle code validation PASSED: $objectiveCode');

      // Delegate to GoalStorageService for actual goal creation
      final goal = await GoalStorageService.createGoal(
        objectiveCode: objectiveCode,
        objectiveName: objectiveName,
      );

      _logger.info('GoalMCP: ✅ Created goal: $objectiveCode - $objectiveName');

      return json.encode({
        'status': 'success',
        'data': {
          'goal_id': goal.id,
          'objective_code': goal.objectiveCode,
          'objective_name': goal.objectiveName,
          'created_at': goal.createdAt.toIso8601String(),
          'is_active': goal.isActive,
        },
        'message': 'Goal created successfully',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('GoalMCP: Error creating goal: $e');
      return _errorResponse('Failed to create goal: $e');
    }
  }

  /// Handle get_active_goals MCP command
  ///
  /// Expected command format:
  /// {"action": "get_active_goals"}
  static Future<String> handleGetActiveGoals() async {
    try {
      _logger.debug('GoalMCP: Processing get_active_goals command');

      // Delegate to GoalStorageService for actual goal retrieval
      final goals = await GoalStorageService.getActiveGoals();

      _logger.info('GoalMCP: ✅ Retrieved ${goals.length} active goals');

      return json.encode({
        'status': 'success',
        'data': {
          'goals': goals
              .map((goal) => {
                    'id': goal.id,
                    'objective_code': goal.objectiveCode,
                    'objective_name': goal.objectiveName,
                    'display_name': goal.displayName,
                    'created_at': goal.createdAt.toIso8601String(),
                    'formatted_created_date': goal.formattedCreatedDate,
                    'is_active': goal.isActive,
                  })
              .toList(),
          'total_count': goals.length,
        },
        'message': 'Active goals retrieved successfully',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('GoalMCP: Error retrieving goals: $e');
      return _errorResponse('Failed to retrieve goals: $e');
    }
  }

  /// Handle update_goal MCP command (future functionality)
  ///
  /// Expected command format:
  /// {"action": "update_goal", "goal_id": 1, "is_active": false}
  static Future<String> handleUpdateGoal(Map<String, dynamic> parsedCommand) async {
    try {
      _logger.debug('GoalMCP: Processing update_goal command');

      final goalId = parsedCommand['goal_id'] as int?;
      final isActive = parsedCommand['is_active'] as bool?;

      if (goalId == null) {
        _logger.warning('GoalMCP: Missing goal_id parameter');
        return _errorResponse('Missing required parameter: goal_id');
      }

      // Get existing goal
      final existingGoal = await GoalStorageService.getGoalById(goalId);
      if (existingGoal == null) {
        _logger.warning('GoalMCP: Goal not found: $goalId');
        return _errorResponse('Goal not found with ID: $goalId');
      }

      // Update goal properties
      if (isActive != null) {
        existingGoal.isActive = isActive;
      }

      // Save updated goal
      await GoalStorageService.updateGoal(existingGoal);

      _logger.info('GoalMCP: ✅ Updated goal: ${existingGoal.objectiveCode}');

      return json.encode({
        'status': 'success',
        'data': {
          'goal_id': existingGoal.id,
          'objective_code': existingGoal.objectiveCode,
          'objective_name': existingGoal.objectiveName,
          'is_active': existingGoal.isActive,
          'updated_at': DateTime.now().toIso8601String(),
        },
        'message': 'Goal updated successfully',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('GoalMCP: Error updating goal: $e');
      return _errorResponse('Failed to update goal: $e');
    }
  }

  /// Handle delete_goal MCP command (future functionality)
  ///
  /// Expected command format:
  /// {"action": "delete_goal", "goal_id": 1}
  static Future<String> handleDeleteGoal(Map<String, dynamic> parsedCommand) async {
    try {
      _logger.debug('GoalMCP: Processing delete_goal command');

      final goalId = parsedCommand['goal_id'] as int?;

      if (goalId == null) {
        _logger.warning('GoalMCP: Missing goal_id parameter');
        return _errorResponse('Missing required parameter: goal_id');
      }

      // Delegate to GoalStorageService for actual goal deletion
      final deleted = await GoalStorageService.deleteGoal(goalId);

      if (deleted) {
        _logger.info('GoalMCP: ✅ Deleted goal ID: $goalId');
        return json.encode({
          'status': 'success',
          'data': {'goal_id': goalId},
          'message': 'Goal deleted successfully',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        _logger.warning('GoalMCP: Goal not found for deletion: $goalId');
        return _errorResponse('Goal not found with ID: $goalId');
      }
    } catch (e) {
      _logger.error('GoalMCP: Error deleting goal: $e');
      return _errorResponse('Failed to delete goal: $e');
    }
  }

  /// Returns standardized error response
  static String _errorResponse(String message) {
    return json.encode({
      'status': 'error',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
