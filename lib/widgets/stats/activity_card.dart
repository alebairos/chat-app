import 'package:flutter/material.dart';

/// Widget for displaying individual activity information
class ActivityCard extends StatelessWidget {
  final String? code;
  final String name;
  final String time;
  final double confidence;
  final String dimension;
  final String source;

  const ActivityCard({
    super.key,
    this.code,
    required this.name,
    required this.time,
    required this.confidence,
    required this.dimension,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity header with code and time
            Row(
              children: [
                if (code != null && code!.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDimensionColor(dimension).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getDimensionColor(dimension).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      code!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getDimensionColor(dimension),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Dimension and confidence info
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDimensionColor(dimension).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDimensionIcon(dimension),
                        size: 12,
                        color: _getDimensionColor(dimension),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDimensionDisplayName(dimension),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getDimensionColor(dimension),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Confidence indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 12,
                      color: _getConfidenceColor(confidence),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${(confidence * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getConfidenceColor(confidence),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDimensionColor(String dimension) {
    switch (dimension.toUpperCase()) {
      case 'SF': // Saúde Física
      case 'SAUDE_FISICA':
        return Colors.green;
      case 'SM': // Saúde Mental
      case 'SAUDE_MENTAL':
        return Colors.blue;
      case 'TG': // Trabalho & Gestão
      case 'TRABALHO_GESTAO':
        return Colors.orange;
      case 'R': // Relacionamentos
      case 'RELACIONAMENTOS':
        return Colors.pink;
      case 'CE': // Criatividade & Expressão
      case 'CRIATIVIDADE_EXPRESSAO':
        return Colors.purple;
      case 'AE': // Aventura & Exploração
      case 'AVENTURA_EXPLORACAO':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getDimensionIcon(String dimension) {
    switch (dimension.toUpperCase()) {
      case 'SF':
      case 'SAUDE_FISICA':
        return Icons.fitness_center;
      case 'SM':
      case 'SAUDE_MENTAL':
        return Icons.psychology;
      case 'TG':
      case 'TRABALHO_GESTAO':
        return Icons.work;
      case 'R':
      case 'RELACIONAMENTOS':
        return Icons.people;
      case 'CE':
      case 'CRIATIVIDADE_EXPRESSAO':
        return Icons.palette;
      case 'AE':
      case 'AVENTURA_EXPLORACAO':
        return Icons.explore;
      default:
        return Icons.category;
    }
  }

  String _getDimensionDisplayName(String dimension) {
    switch (dimension.toUpperCase()) {
      case 'SF':
      case 'SAUDE_FISICA':
        return 'Physical Health';
      case 'SM':
      case 'SAUDE_MENTAL':
        return 'Mental Health';
      case 'TG':
      case 'TRABALHO_GESTAO':
        return 'Work & Management';
      case 'R':
      case 'RELACIONAMENTOS':
        return 'Relationships';
      case 'CE':
      case 'CRIATIVIDADE_EXPRESSAO':
        return 'Creativity';
      case 'AE':
      case 'AVENTURA_EXPLORACAO':
        return 'Adventure';
      default:
        return dimension;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }
}
