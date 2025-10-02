import 'package:flutter/material.dart';

/// Widget for displaying detailed daily summary information
class DetailedSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> summary;
  final String language;

  const DetailedSummaryWidget({
    super.key,
    required this.summary,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final totalMessages = summary['totalMessages'] as int? ?? 0;
    final totalActivities = summary['totalActivities'] as int? ?? 0;
    final mostActiveTimeOfDay =
        summary['mostActiveTimeOfDay'] as String? ?? 'morning';
    final activityBreakdown =
        summary['activityBreakdown'] as Map<String, int>? ?? <String, int>{};
    final primaryPersonaUsed =
        summary['primaryPersonaUsed'] as String? ?? 'I-There 4.2';
    final topDimensions =
        summary['topActivityDimensions'] as List<String>? ?? <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            language == 'pt_BR'
                ? 'Resumo Detalhado do Dia'
                : 'Detailed Daily Summary',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          // Overview metrics
          _buildOverviewSection(
              context, totalMessages, totalActivities, mostActiveTimeOfDay),

          const SizedBox(height: 24),

          // Activity breakdown
          if (activityBreakdown.isNotEmpty) ...[
            _buildActivityBreakdownSection(
                context, activityBreakdown, totalActivities),
            const SizedBox(height: 24),
          ],

          // Additional insights
          _buildInsightsSection(context, primaryPersonaUsed, topDimensions),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, int totalMessages,
      int totalActivities, String mostActiveTimeOfDay) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language == 'pt_BR' ? 'Visão Geral' : 'Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.chat_bubble_outline,
                    value: totalMessages.toString(),
                    label: language == 'pt_BR' ? 'Mensagens' : 'Messages',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.check_circle_outline,
                    value: totalActivities.toString(),
                    label: language == 'pt_BR' ? 'Atividades' : 'Activities',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.access_time,
                    value: _getTimeOfDayLabel(mostActiveTimeOfDay),
                    label:
                        language == 'pt_BR' ? 'Período Ativo' : 'Active Period',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.trending_up,
                    value: totalActivities > 0
                        ? (language == 'pt_BR' ? 'Ativo' : 'Active')
                        : (language == 'pt_BR' ? 'Tranquilo' : 'Quiet'),
                    label: language == 'pt_BR' ? 'Status do Dia' : 'Day Status',
                    color: totalActivities > 0 ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBreakdownSection(BuildContext context,
      Map<String, int> activityBreakdown, int totalActivities) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language == 'pt_BR'
                  ? 'Atividades por Dimensão'
                  : 'Activities by Dimension',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...activityBreakdown.entries.map((entry) {
              final percentage = totalActivities > 0
                  ? (entry.value / totalActivities * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        _getDimensionLabel(entry.key),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getDimensionColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(BuildContext context, String primaryPersonaUsed,
      List<String> topDimensions) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language == 'pt_BR'
                  ? 'Insights Adicionais'
                  : 'Additional Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInsightRow(
              context,
              icon: Icons.psychology,
              label:
                  language == 'pt_BR' ? 'Persona Principal' : 'Primary Persona',
              value: primaryPersonaUsed,
            ),
            if (topDimensions.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInsightRow(
                context,
                icon: Icons.category,
                label: language == 'pt_BR'
                    ? 'Dimensões Principais'
                    : 'Top Dimensions',
                value: topDimensions.take(3).map(_getDimensionLabel).join(', '),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _getTimeOfDayLabel(String timeOfDay) {
    if (language == 'pt_BR') {
      switch (timeOfDay) {
        case 'morning':
          return 'Manhã';
        case 'afternoon':
          return 'Tarde';
        case 'evening':
          return 'Noite';
        default:
          return 'Manhã';
      }
    } else {
      switch (timeOfDay) {
        case 'morning':
          return 'Morning';
        case 'afternoon':
          return 'Afternoon';
        case 'evening':
          return 'Evening';
        default:
          return 'Morning';
      }
    }
  }

  String _getDimensionLabel(String dimension) {
    if (language == 'pt_BR') {
      switch (dimension) {
        case 'SF':
          return 'Saúde Física';
        case 'SM':
          return 'Saúde Mental';
        case 'R':
          return 'Relacionamentos';
        case 'E':
          return 'Espiritualidade';
        case 'TG':
          return 'Trabalho Gratificante';
        case 'TT':
          return 'Tempo de Tela';
        case 'PR':
          return 'Procrastinação';
        case 'F':
          return 'Finanças';
        default:
          return dimension;
      }
    } else {
      switch (dimension) {
        case 'SF':
          return 'Physical Health';
        case 'SM':
          return 'Mental Health';
        case 'R':
          return 'Relationships';
        case 'E':
          return 'Spirituality';
        case 'TG':
          return 'Meaningful Work';
        case 'TT':
          return 'Screen Time';
        case 'PR':
          return 'Procrastination';
        case 'F':
          return 'Finance';
        default:
          return dimension;
      }
    }
  }

  Color _getDimensionColor(String dimension) {
    switch (dimension) {
      case 'SF':
        return Colors.green;
      case 'SM':
        return Colors.blue;
      case 'R':
        return Colors.pink;
      case 'E':
        return Colors.purple;
      case 'TG':
        return Colors.orange;
      case 'TT':
        return Colors.red;
      case 'PR':
        return Colors.amber;
      case 'F':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
