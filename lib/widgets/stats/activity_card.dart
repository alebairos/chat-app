import 'package:flutter/material.dart';
import '../../services/dimension_display_service.dart';
import '../../services/metadata_config.dart';
import '../../utils/logger.dart';
import 'metadata_insights.dart';

/// Widget for displaying individual activity information
class ActivityCard extends StatelessWidget {
  static final Logger _logger = Logger();

  final String? code;
  final String name;
  final String time;
  final String dimension;
  final String source;
  final Map<String, dynamic> metadata;

  const ActivityCard({
    super.key,
    this.code,
    required this.name,
    required this.time,
    required this.dimension,
    required this.source,
    this.metadata = const {},
  });

  @override
  Widget build(BuildContext context) {
    // FT-147: Debug dimension display issue
    _logger.info(
        'FT-147: ActivityCard requesting display name for dimension: "$dimension"');
    final displayName = DimensionDisplayService.getDisplayName(dimension);
    _logger.info('FT-147: ActivityCard received display name: "$displayName"');

    // Log service state for debugging
    final debugInfo = DimensionDisplayService.getDebugInfo();
    _logger.info(
        'FT-147: Service state - initialized: ${debugInfo['initialized']}, hasContext: ${debugInfo['hasOracleContext']}');

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
                      color: DimensionDisplayService.getColor(dimension)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: DimensionDisplayService.getColor(dimension)
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      code!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: DimensionDisplayService.getColor(dimension),
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
                    color: DimensionDisplayService.getColor(dimension)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        DimensionDisplayService.getIcon(dimension),
                        size: 12,
                        color: DimensionDisplayService.getColor(dimension),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: DimensionDisplayService.getColor(dimension),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // FT-089: Replace confidence indicator with simple completion badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Colors.green),
                      SizedBox(width: 2),
                      Text('Completed',
                          style: TextStyle(fontSize: 11, color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),

            // FT-149: Metadata insights (conditionally displayed)
            FutureBuilder<bool>(
              future: MetadataConfig.isEnabled(),
              builder: (context, snapshot) {
                _logger.debug(
                    '🔍 [FT-149] ActivityCard metadata check: enabled=${snapshot.data}, hasMetadata=${metadata.isNotEmpty}, metadata=$metadata');
                if (snapshot.hasData &&
                    snapshot.data == true &&
                    metadata.isNotEmpty) {
                  _logger.debug(
                      '🔍 [FT-149] ActivityCard showing MetadataInsights for: $metadata');
                  return MetadataInsights(metadata: metadata);
                }
                _logger.debug(
                    '🔍 [FT-149] ActivityCard hiding MetadataInsights - enabled=${snapshot.data}, hasMetadata=${metadata.isNotEmpty}');
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
