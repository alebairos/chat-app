import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/goal_mcp_service.dart';
import '../widgets/goal_card.dart';
import '../widgets/empty_goals_state.dart';
import '../../../utils/logger.dart';
import '../../../config/feature_flags.dart';
import 'dart:convert';

/// FT-174: Goals screen for displaying user goals
///
/// Minimal first cut - shows list of goals created via LLM conversation
/// with basic information and empty state guidance
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Logger _logger = Logger();

  List<GoalModel> _goals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  /// Load goals from database via MCP service
  Future<void> _loadGoals() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _logger.debug('GoalsScreen: Loading goals via GoalMCPService');

      final response = await GoalMCPService.handleGetActiveGoals();
      final data = json.decode(response);

      if (data['status'] == 'success') {
        final goalsList = data['data']['goals'] as List;
        _goals = goalsList
            .map((goalData) => GoalModel.fromObjective(
                  objectiveCode: goalData['objective_code'],
                  objectiveName: goalData['objective_name'],
                ))
            .toList();

        _logger.info('GoalsScreen: ✅ Loaded ${_goals.length} goals');
      } else {
        _error = data['message'] ?? 'Failed to load goals';
        _logger.warning('GoalsScreen: Failed to load goals: $_error');
      }
    } catch (e) {
      _error = 'Error loading goals: $e';
      _logger.error('GoalsScreen: Error loading goals: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh goals list
  Future<void> _refreshGoals() async {
    await _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    // FT-178: Feature flag check
    if (!FeatureFlags.isGoalsTabEnabled) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Goals Feature Not Available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'This feature is currently disabled',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshGoals,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Goals',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshGoals,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_goals.isEmpty) {
      return const EmptyGoalsState();
    }

    return _buildGoalsList();
  }

  Widget _buildGoalsList() {
    return ListView.builder(
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return GoalCard(goal: goal);
      },
    );
  }

  // FT-176: UI methods moved to dedicated widgets (GoalCard, EmptyGoalsState)
}
