import 'package:flutter/material.dart';
import '../../services/flat_metadata_parser.dart';
import '../../utils/logger.dart';

/// FT-149: Separate metadata insights widget for easy feature flag control
class MetadataInsights extends StatelessWidget {
  static final Logger _logger = Logger();
  final Map<String, dynamic> metadata;

  const MetadataInsights({
    super.key,
    required this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    _logger.debug('🔍 [FT-149] MetadataInsights build called with: $metadata');

    // Check if metadata has quantitative data
    final hasQuantitative = FlatMetadataParser.hasQuantitativeData(metadata);
    _logger.debug(
        '🔍 [FT-149] MetadataInsights hasQuantitativeData: $hasQuantitative');

    if (!hasQuantitative) {
      _logger.debug(
          '🔍 [FT-149] MetadataInsights returning empty widget - no quantitative data');
      return const SizedBox.shrink(); // Return empty widget
    }

    // Extract quantitative measurements
    final measurements = FlatMetadataParser.extractQuantitative(metadata);
    _logger.debug(
        '🔍 [FT-149] MetadataInsights extracted measurements: $measurements');

    if (measurements.isEmpty) {
      _logger.debug(
          '🔍 [FT-149] MetadataInsights returning empty widget - no measurements extracted');
      return const SizedBox.shrink();
    }

    // Build insights display
    final insights =
        measurements.map((m) => '${m["icon"]} ${m["display"]}').join(' • ');

    _logger
        .debug('🔍 [FT-149] MetadataInsights displaying insights: $insights');

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insights,
            size: 14,
            color: Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            insights,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
