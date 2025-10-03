import 'package:flutter/material.dart';
import '../models/goal_model.dart';

/// FT-176: Widget for displaying individual goal information
///
/// Extracted from GoalsScreen for better code organization
/// and reusability
class GoalCard extends StatelessWidget {
  final GoalModel goal;

  const GoalCard({
    super.key,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _getGoalIcon(goal.objectiveCode),
        title: Text(
          goal.displayName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Created: ${goal.formattedCreatedDate}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        trailing: goal.isActive
            ? const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              )
            : const Icon(
                Icons.pause_circle,
                color: Colors.grey,
                size: 20,
              ),
      ),
    );
  }

  /// Get appropriate icon for goal based on objective code
  Widget _getGoalIcon(String objectiveCode) {
    IconData iconData;
    Color iconColor;

    // Map objective codes to appropriate icons
    switch (objectiveCode) {
      case 'OCX1': // Running
        iconData = Icons.directions_run;
        iconColor = Colors.orange;
        break;
      case 'OPP1': // Weight loss
      case 'OPP2':
        iconData = Icons.fitness_center;
        iconColor = Colors.red;
        break;
      case 'OGM1': // Muscle gain
      case 'OGM2':
        iconData = Icons.sports_gymnastics;
        iconColor = Colors.blue;
        break;
      case 'ODM1': // Better sleep
      case 'ODM2':
        iconData = Icons.bedtime;
        iconColor = Colors.purple;
        break;
      case 'OSPM1': // Mental health
      case 'OSPM2':
      case 'OSPM3':
      case 'OSPM4':
      case 'OSPM5':
        iconData = Icons.psychology;
        iconColor = Colors.teal;
        break;
      case 'ORA1': // Relationships
      case 'ORA2':
        iconData = Icons.favorite;
        iconColor = Colors.pink;
        break;
      case 'OLM1': // Learning
        iconData = Icons.school;
        iconColor = Colors.indigo;
        break;
      case 'OVG1': // Longevity
        iconData = Icons.eco;
        iconColor = Colors.green;
        break;
      case 'OME2': // Energy
        iconData = Icons.bolt;
        iconColor = Colors.yellow[700] ?? Colors.yellow;
        break;
      case 'OMF1': // Focus
        iconData = Icons.center_focus_strong;
        iconColor = Colors.deepPurple;
        break;
      case 'ODE1': // Detox
      case 'ODE2':
        iconData = Icons.spa;
        iconColor = Colors.lightGreen;
        break;
      case 'OREQ1': // Balance
      case 'OREQ2':
        iconData = Icons.balance;
        iconColor = Colors.cyan;
        break;
      case 'OSF1': // Physical health
        iconData = Icons.health_and_safety;
        iconColor = Colors.red[400] ?? Colors.red;
        break;
      case 'OAE1': // Learning efficiency
        iconData = Icons.trending_up;
        iconColor = Colors.blue[600] ?? Colors.blue;
        break;
      case 'OLV1': // Life vision
        iconData = Icons.visibility;
        iconColor = Colors.deepOrange;
        break;
      case 'OMMA1': // Memory
      case 'OMMA2':
        iconData = Icons.memory;
        iconColor = Colors.brown;
        break;
      default:
        iconData = Icons.flag;
        iconColor = Colors.grey[600] ?? Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withValues(alpha: 0.1),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }
}
