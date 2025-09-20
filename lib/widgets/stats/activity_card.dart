import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/activity_model.dart';
import '../../services/dimension_display_service.dart';
import '../../services/metadata_insight_generator.dart';
import '../../config/metadata_config.dart';
import '../../utils/logger.dart';

/// Widget for displaying individual activity information with metadata intelligence
class ActivityCard extends StatefulWidget {
  static final Logger _logger = Logger();

  // Legacy parameters for backward compatibility
  final String? code;
  final String name;
  final String time;
  final String dimension;
  final String source;
  
  // FT-149: New parameters for metadata support
  final ActivityModel? activityModel;
  final String? dynamicMetadata; // JSON string from ActivityMemoryService
  final bool? dynamicHasMetadata;

  const ActivityCard({
    super.key,
    this.code,
    required this.name,
    required this.time,
    required this.dimension,
    required this.source,
    // FT-149: Optional metadata parameters
    this.activityModel,
    this.dynamicMetadata,
    this.dynamicHasMetadata,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _isExpanded = false;

  /// Get metadata map from either ActivityModel or dynamic metadata
  Map<String, dynamic>? get _metadataMap {
    // Try ActivityModel first
    if (widget.activityModel?.metadataMap != null) {
      return widget.activityModel!.metadataMap;
    }
    
    // Try dynamic metadata
    if (widget.dynamicMetadata != null) {
      try {
        final decoded = json.decode(widget.dynamicMetadata!);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        ActivityCard._logger.debug('FT-149: Failed to parse dynamic metadata: $e');
      }
    }
    
    return null;
  }

  /// Check if metadata should be displayed
  bool get _shouldShowMetadata {
    if (MetadataConfig.isDisabled) return false;
    
    // Check if we have metadata
    final hasMetadata = widget.dynamicHasMetadata ?? 
                       widget.activityModel?.hasMetadata ?? 
                       (_metadataMap?.isNotEmpty ?? false);
    
    ActivityCard._logger.debug('FT-149: Should show metadata: $hasMetadata');
    return hasMetadata;
  }

  @override
  Widget build(BuildContext context) {
    // FT-147: Debug dimension display issue
    ActivityCard._logger.info('FT-147: ActivityCard requesting display name for dimension: "${widget.dimension}"');
    final displayName = DimensionDisplayService.getDisplayName(widget.dimension);
    ActivityCard._logger.info('FT-147: ActivityCard received display name: "$displayName"');
    
    // Log service state for debugging
    final debugInfo = DimensionDisplayService.getDebugInfo();
    ActivityCard._logger.info('FT-147: Service state - initialized: ${debugInfo['initialized']}, hasContext: ${debugInfo['hasOracleContext']}');
    
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
                if (widget.code != null && widget.code!.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: DimensionDisplayService.getColor(widget.dimension)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: DimensionDisplayService.getColor(widget.dimension)
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.code!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: DimensionDisplayService.getColor(widget.dimension),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  widget.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // FT-149: Smart metadata summary
            if (_shouldShowMetadata) ...[
              _buildSmartSummary(),
              const SizedBox(height: 8),
            ],

            // Dimension and confidence info
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DimensionDisplayService.getColor(widget.dimension)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        DimensionDisplayService.getIcon(widget.dimension),
                        size: 12,
                        color: DimensionDisplayService.getColor(widget.dimension),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: DimensionDisplayService.getColor(widget.dimension),
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

            // FT-149: Expandable metadata details
            if (_shouldShowMetadata) ...[
              const SizedBox(height: 8),
              _buildExpandableInsights(),
            ],
          ],
        ),
      ),
    );
  }

  /// Build smart summary of metadata insights
  Widget _buildSmartSummary() {
    final insights = MetadataInsightGenerator.generateSummary(_metadataMap);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.blue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 14,
            color: Colors.blue,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              insights.join(' • '),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build expandable insights section
  Widget _buildExpandableInsights() {
    final sections = MetadataInsightGenerator.generateDetailedSections(_metadataMap);
    if (sections.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _isExpanded ? 'Hide insights' : 'Show insights (${sections.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              ...sections.map((section) => _buildMetadataSection(section)),
            ],
          ],
        ),
      ),
    );
  }

  /// Build individual metadata section
  Widget _buildMetadataSection(MetadataSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          ...section.items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              children: [
                Text(
                  '• ${item.key}: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
