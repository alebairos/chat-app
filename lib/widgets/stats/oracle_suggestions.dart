import 'package:flutter/material.dart';

/// Widget for displaying Oracle activity suggestions (activities not yet tried)
class OracleSuggestions extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;

  const OracleSuggestions({
    super.key,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.explore,
                  size: 20,
                  color: Colors.purple,
                ),
                SizedBox(width: 8),
                Text(
                  'Discover New Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Oracle activities you haven\'t tried yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Suggestions List
            ...suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildSuggestionCard(suggestion),
              );
            }).toList(),

            // Encouragement message
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.purple,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Try these activities to expand your Oracle framework coverage!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final code = suggestion['code'] as String;
    final name = suggestion['name'] as String;
    final dimension = suggestion['dimension'] as String;
    final description = suggestion['description'] as String? ?? name;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with code and dimension
          Row(
            children: [
              // Oracle Code Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getDimensionColor(dimension).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getDimensionColor(dimension).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getDimensionColor(dimension),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Dimension Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getDimensionColor(dimension).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getDimensionIcon(dimension),
                      size: 10,
                      color: _getDimensionColor(dimension),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDimensionDisplayName(dimension),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getDimensionColor(dimension),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // "Try it" indicator
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey[400],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Activity Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Description (if different from name)
          if (description != name) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getDimensionColor(String dimension) {
    switch (dimension.toUpperCase()) {
      case 'SF': // Saúde Física
        return Colors.green;
      case 'SM': // Saúde Mental
        return Colors.blue;
      case 'TG': // Trabalho & Gestão
        return Colors.orange;
      case 'R': // Relacionamentos
        return Colors.pink;
      case 'CE': // Criatividade & Expressão
        return Colors.purple;
      case 'AE': // Aventura & Exploração
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getDimensionIcon(String dimension) {
    switch (dimension.toUpperCase()) {
      case 'SF':
        return Icons.fitness_center;
      case 'SM':
        return Icons.psychology;
      case 'TG':
        return Icons.work;
      case 'R':
        return Icons.people;
      case 'CE':
        return Icons.palette;
      case 'AE':
        return Icons.explore;
      default:
        return Icons.category;
    }
  }

  String _getDimensionDisplayName(String dimension) {
    switch (dimension.toUpperCase()) {
      case 'SF':
        return 'Physical Health';
      case 'SM':
        return 'Mental Health';
      case 'TG':
        return 'Work & Management';
      case 'R':
        return 'Relationships';
      case 'CE':
        return 'Creativity';
      case 'AE':
        return 'Adventure';
      default:
        return dimension;
    }
  }
}
