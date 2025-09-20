import 'dart:convert';

/// FT-149.1: Generates intelligent summaries from metadata for UI display
class MetadataInsightGenerator {
  
  /// Generate smart summary insights from metadata
  static List<String> generateSummary(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return [];
    
    final insights = <String>[];
    
    // Extract quantitative highlights
    final quantitative = _extractQuantitativeInsights(metadata);
    if (quantitative.isNotEmpty) insights.addAll(quantitative);
    
    // Extract behavioral highlights
    final behavioral = _extractBehavioralInsights(metadata);
    if (behavioral.isNotEmpty) insights.addAll(behavioral);
    
    // Extract performance highlights
    final performance = _extractPerformanceInsights(metadata);
    if (performance.isNotEmpty) insights.addAll(performance);
    
    // Return top 3 most interesting insights
    return insights.take(3).toList();
  }
  
  /// Extract quantitative insights (numbers, metrics, measurements)
  static List<String> _extractQuantitativeInsights(Map<String, dynamic> metadata) {
    final insights = <String>[];
    
    // Activity details and metrics
    final activityDetails = metadata['activity_details'] as Map<String, dynamic>?;
    if (activityDetails != null) {
      final metrics = activityDetails['metrics'] as Map<String, dynamic>?;
      if (metrics != null) {
        // Distance
        final distance = metrics['distance'] as Map<String, dynamic>?;
        if (distance != null) {
          final value = distance['value'];
          final unit = distance['unit'];
          if (value != null && unit != null) {
            insights.add('${value}${unit}');
          }
        }
        
        // Heart rate
        final heartRate = metrics['heart_rate'] as Map<String, dynamic>?;
        if (heartRate != null) {
          final peak = heartRate['peak'] as Map<String, dynamic>?;
          final zones = heartRate['zones'] as Map<String, dynamic>?;
          if (peak != null && zones != null) {
            final peakValue = peak['value'];
            final finalZone = zones['final'];
            if (peakValue != null && finalZone != null) {
              insights.add('Peak HR ${peakValue} → ${finalZone}');
            }
          }
        }
      }
    }
    
    // Quantitative dimensions
    final quantitative = metadata['quantitative'] as Map<String, dynamic>?;
    if (quantitative != null) {
      quantitative.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final amount = value['amount'] ?? value['value'] ?? value['quantity'];
          final unit = value['unit'];
          if (amount != null && unit != null) {
            insights.add('${amount}${unit}');
          }
        } else if (value != null) {
          insights.add('$key: $value');
        }
      });
    }
    
    return insights;
  }
  
  /// Extract behavioral insights (patterns, sophistication, awareness)
  static List<String> _extractBehavioralInsights(Map<String, dynamic> metadata) {
    final insights = <String>[];
    
    // Behavioral insights
    final behavioral = metadata['behavioral_insights'] as Map<String, dynamic>?;
    if (behavioral != null) {
      final sophistication = behavioral['training_sophistication'] as String?;
      final management = behavioral['intensity_management'] as String?;
      final stacking = behavioral['habit_stacking'] as String?;
      
      if (sophistication != null && sophistication.contains('understands')) {
        insights.add('Sophisticated training');
      }
      if (management != null && management.contains('awareness')) {
        insights.add('Intensity control');
      }
      if (stacking != null) {
        insights.add('Habit stacking');
      }
    }
    
    // Behavioral dimensions
    final behavioralDim = metadata['behavioral'] as Map<String, dynamic>?;
    if (behavioralDim != null) {
      final motivation = behavioralDim['motivation'] as String?;
      final intention = behavioralDim['intention'] as String?;
      
      if (motivation != null) {
        insights.add(_formatBehavioralInsight(motivation));
      }
      if (intention != null) {
        insights.add(_formatBehavioralInsight(intention));
      }
    }
    
    return insights;
  }
  
  /// Extract performance insights (intensity, patterns, progression)
  static List<String> _extractPerformanceInsights(Map<String, dynamic> metadata) {
    final insights = <String>[];
    
    // Intensity patterns
    final intensityPattern = metadata['intensity_pattern'] as Map<String, dynamic>?;
    if (intensityPattern != null) {
      final progression = intensityPattern['progression'] as String?;
      final peakEffort = intensityPattern['peak_effort'] as bool?;
      
      if (progression != null) {
        insights.add(_formatProgressionInsight(progression));
      }
      if (peakEffort == true) {
        insights.add('Peak effort');
      }
    }
    
    // Technical awareness
    final technical = metadata['technical_awareness'] as Map<String, dynamic>?;
    if (technical != null) {
      final hrMonitoring = technical['heart_rate_monitoring'] as bool?;
      final zoneKnowledge = technical['zone_knowledge'] as bool?;
      
      if (hrMonitoring == true && zoneKnowledge == true) {
        insights.add('HR zone tracking');
      }
    }
    
    // Qualitative dimensions
    final qualitative = metadata['qualitative'] as Map<String, dynamic>?;
    if (qualitative != null) {
      final state = qualitative['physical_state'] as String?;
      final context = qualitative['timing_context'] as String?;
      
      if (state != null) {
        insights.add(_formatQualitativeInsight(state));
      }
      if (context != null) {
        insights.add(_formatQualitativeInsight(context));
      }
    }
    
    return insights;
  }
  
  /// Format behavioral insight for display
  static String _formatBehavioralInsight(String insight) {
    // Convert technical terms to user-friendly language
    final formatted = insight
        .replaceAll('_', ' ')
        .replaceAll('thirst_response', 'thirst-driven')
        .replaceAll('need_driven', 'need-based')
        .replaceAll('physiological_need', 'natural need');
    
    return _capitalize(formatted);
  }
  
  /// Format progression insight for display
  static String _formatProgressionInsight(String progression) {
    switch (progression.toLowerCase()) {
      case 'high to low':
        return 'High→Low intensity';
      case 'low to high':
        return 'Progressive intensity';
      case 'steady':
        return 'Steady pace';
      default:
        return _capitalize(progression);
    }
  }
  
  /// Format qualitative insight for display
  static String _formatQualitativeInsight(String insight) {
    final formatted = insight
        .replaceAll('_', ' ')
        .replaceAll('before_sleep', 'bedtime')
        .replaceAll('after_work', 'post-work')
        .replaceAll('morning_routine', 'morning');
    
    return _capitalize(formatted);
  }
  
  /// Capitalize first letter
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  /// Generate detailed metadata sections for expansion
  static List<MetadataSection> generateDetailedSections(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return [];
    
    final sections = <MetadataSection>[];
    
    // Performance section
    final performance = _buildPerformanceSection(metadata);
    if (performance != null) sections.add(performance);
    
    // Behavioral section
    final behavioral = _buildBehavioralSection(metadata);
    if (behavioral != null) sections.add(behavioral);
    
    // Context section
    final context = _buildContextSection(metadata);
    if (context != null) sections.add(context);
    
    return sections;
  }
  
  /// Build performance section
  static MetadataSection? _buildPerformanceSection(Map<String, dynamic> metadata) {
    final items = <MetadataItem>[];
    
    // Extract performance metrics
    final activityDetails = metadata['activity_details'] as Map<String, dynamic>?;
    if (activityDetails != null) {
      final metrics = activityDetails['metrics'] as Map<String, dynamic>?;
      if (metrics != null) {
        metrics.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final displayValue = _formatMetricValue(value);
            if (displayValue.isNotEmpty) {
              items.add(MetadataItem(key: _formatKey(key), value: displayValue));
            }
          }
        });
      }
    }
    
    // Extract quantitative data
    final quantitative = metadata['quantitative'] as Map<String, dynamic>?;
    if (quantitative != null) {
      quantitative.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final displayValue = _formatMetricValue(value);
          if (displayValue.isNotEmpty) {
            items.add(MetadataItem(key: _formatKey(key), value: displayValue));
          }
        }
      });
    }
    
    return items.isNotEmpty ? MetadataSection(
      title: '📊 Performance',
      icon: '📊',
      items: items,
    ) : null;
  }
  
  /// Build behavioral section
  static MetadataSection? _buildBehavioralSection(Map<String, dynamic> metadata) {
    final items = <MetadataItem>[];
    
    // Behavioral insights
    final behavioral = metadata['behavioral_insights'] as Map<String, dynamic>?;
    if (behavioral != null) {
      behavioral.forEach((key, value) {
        if (value is String && key != 'confidence') {
          items.add(MetadataItem(
            key: _formatKey(key),
            value: _formatBehavioralInsight(value),
          ));
        }
      });
    }
    
    // Behavioral dimensions
    final behavioralDim = metadata['behavioral'] as Map<String, dynamic>?;
    if (behavioralDim != null) {
      behavioralDim.forEach((key, value) {
        if (value is String && key != 'confidence') {
          items.add(MetadataItem(
            key: _formatKey(key),
            value: _formatBehavioralInsight(value),
          ));
        }
      });
    }
    
    return items.isNotEmpty ? MetadataSection(
      title: '🧠 Behavioral Pattern',
      icon: '🧠',
      items: items,
    ) : null;
  }
  
  /// Build context section
  static MetadataSection? _buildContextSection(Map<String, dynamic> metadata) {
    final items = <MetadataItem>[];
    
    // Qualitative data
    final qualitative = metadata['qualitative'] as Map<String, dynamic>?;
    if (qualitative != null) {
      qualitative.forEach((key, value) {
        if (value is String && key != 'confidence') {
          items.add(MetadataItem(
            key: _formatKey(key),
            value: _formatQualitativeInsight(value),
          ));
        }
      });
    }
    
    // Relational data
    final relational = metadata['relational'] as Map<String, dynamic>?;
    if (relational != null) {
      relational.forEach((key, value) {
        if (value is String) {
          items.add(MetadataItem(
            key: _formatKey(key),
            value: _formatQualitativeInsight(value),
          ));
        }
      });
    }
    
    return items.isNotEmpty ? MetadataSection(
      title: '🎯 Context',
      icon: '🎯',
      items: items,
    ) : null;
  }
  
  /// Format metric value for display
  static String _formatMetricValue(Map<String, dynamic> metric) {
    final value = metric['value'] ?? metric['amount'] ?? metric['quantity'];
    final unit = metric['unit'];
    
    if (value != null && unit != null) {
      return '$value $unit';
    } else if (value != null) {
      return value.toString();
    }
    
    return '';
  }
  
  /// Format key for display
  static String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// Metadata section for organized display
class MetadataSection {
  final String title;
  final String icon;
  final List<MetadataItem> items;
  
  MetadataSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

/// Individual metadata item
class MetadataItem {
  final String key;
  final String value;
  
  MetadataItem({
    required this.key,
    required this.value,
  });
}
