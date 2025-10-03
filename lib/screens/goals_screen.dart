import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/system_mcp_service.dart';
import '../utils/logger.dart';
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
  final SystemMCPService _mcpService = SystemMCPService();

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

      _logger.debug('GoalsScreen: Loading goals via MCP');

      final response =
          await _mcpService.processCommand('{"action": "get_active_goals"}');
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
      return _buildEmptyState();
    }

    return _buildGoalsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Goals Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Talk to your persona about your goals and aspirations',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI assistant can help you set meaningful objectives',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return _buildGoalCard(goal);
      },
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Goal icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getGoalIcon(goal.objectiveCode),
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Goal details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${goal.formattedCreatedDate}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            // Goal code badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                goal.objectiveCode,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get appropriate icon for goal based on objective code
  IconData _getGoalIcon(String objectiveCode) {
    // Map Oracle objective codes to appropriate icons
    if (objectiveCode.startsWith('OPP'))
      return Icons.fitness_center; // Weight loss
    if (objectiveCode.startsWith('OGM')) return Icons.trending_up; // Gain mass
    if (objectiveCode.startsWith('ODM')) return Icons.bedtime; // Sleep better
    if (objectiveCode.startsWith('OSPM'))
      return Icons.work_outline; // Productivity
    if (objectiveCode.startsWith('ORA'))
      return Icons.psychology; // Reduce anxiety
    if (objectiveCode.startsWith('OLM')) return Icons.menu_book; // Read more
    if (objectiveCode.startsWith('OVG')) return Icons.favorite; // Gratitude
    if (objectiveCode.startsWith('OME'))
      return Icons.family_restroom; // Better spouse/parent
    if (objectiveCode.startsWith('OMF'))
      return Icons.child_care; // Better parent
    if (objectiveCode.startsWith('ODE'))
      return Icons.self_improvement; // Spirituality
    if (objectiveCode.startsWith('OREQ')) return Icons.people; // Relationships
    if (objectiveCode.startsWith('OSF'))
      return Icons.account_balance_wallet; // Financial security
    if (objectiveCode.startsWith('OAE')) return Icons.school; // Learning
    if (objectiveCode.startsWith('OLV'))
      return Icons.health_and_safety; // Longevity
    if (objectiveCode.startsWith('OCX')) return Icons.directions_run; // Running
    if (objectiveCode.startsWith('OMMA'))
      return Icons.restaurant; // Better nutrition

    // Default icon for unknown objectives
    return Icons.flag;
  }
}
