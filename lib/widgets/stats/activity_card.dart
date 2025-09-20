import 'package:flutter/material.dart';
import '../../services/dimension_display_service.dart';

/// Widget for displaying individual activity information
class ActivityCard extends StatelessWidget {
  final String? code;
  final String name;
  final String time;
  final String dimension;
  final String source;

  const ActivityCard({
    super.key,
    this.code,
    required this.name,
    required this.time,
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
                      color: DimensionDisplayService.getColor(dimension).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: DimensionDisplayService.getColor(dimension).withOpacity(0.3),
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
                    color: DimensionDisplayService.getColor(dimension).withOpacity(0.1),
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
                        DimensionDisplayService.getDisplayName(dimension),
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
          ],
        ),
      ),
    );
  }

}
