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
    
    // Universal Framework: Core activity metrics
    final coreActivity = metadata['core_activity'] as Map<String, dynamic>?;
    if (coreActivity != null) {
      final volume = coreActivity['volume'] as Map<String, dynamic>?;
      if (volume != null) {
        final amount = volume['amount'];
        final unit = volume['unit'];
        if (amount != null && unit != null) {
          insights.add('$amount $unit');
        }
      }
    }
    
    // Universal Framework: Session metrics
    final session = metadata['session'] as Map<String, dynamic>?;
    if (session != null) {
      final activityCount = session['activity_count'];
      final totalDuration = session['total_duration_inferred'];
      
      if (activityCount != null) {
        insights.add('$activityCount activities');
      }
      if (totalDuration != null) {
        insights.add('~$totalDuration');
      }
    }
    
    // Universal Framework: Metrics section
    final metrics = metadata['metrics'] as Map<String, dynamic>?;
    if (metrics != null) {
      // Distance metrics
      final distance = metrics['distance'] as Map<String, dynamic>?;
      if (distance != null) {
        final total = distance['total'];
        final running = distance['running'];
        final walking = distance['walking'];
        
        if (total != null) {
          insights.add('Total: $total');
        } else if (running != null && walking != null) {
          insights.add('Run: $running + Walk: $walking');
        } else if (running != null) {
          insights.add('Run: $running');
        } else if (walking != null) {
          insights.add('Walk: $walking');
        }
      }
      
      // Hydration metrics
      final hydration = metrics['hydration'] as Map<String, dynamic>?;
      if (hydration != null) {
        final volume = hydration['volume'];
        if (volume != null) {
          insights.add('💧 $volume');
        }
      }
      
      // Balance metrics
      final balance = metrics['balance'] as Map<String, dynamic>?;
      if (balance != null) {
        final duration = balance['duration'];
        final type = balance['type'];
        if (duration != null && type != null) {
          insights.add('⚖️ $duration ($type)');
        } else if (duration != null) {
          insights.add('⚖️ $duration');
        }
      }
    }
    
    // Legacy: Activity details and metrics (backward compatibility)
    final activityDetails = metadata['activity_details'] as Map<String, dynamic>?;
    if (activityDetails != null) {
      final legacyMetrics = activityDetails['metrics'] as Map<String, dynamic>?;
      if (legacyMetrics != null) {
        // Distance
        final distance = legacyMetrics['distance'] as Map<String, dynamic>?;
        if (distance != null) {
          final value = distance['value'];
          final unit = distance['unit'];
          if (value != null && unit != null) {
            insights.add('$value $unit');
          }
        }
        
        // Heart rate
        final heartRate = legacyMetrics['heart_rate'] as Map<String, dynamic>?;
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
    
    return insights;
  }
  
  /// Extract behavioral insights (patterns, sophistication, awareness)
  static List<String> _extractBehavioralInsights(Map<String, dynamic> metadata) {
    final insights = <String>[];
    
    // Universal Framework: Behavioral indicators
    final behavioralIndicators = metadata['behavioral_indicators'] as Map<String, dynamic>?;
    if (behavioralIndicators != null) {
      // Energy level
      final energyLevel = behavioralIndicators['energy_level'] as Map<String, dynamic>?;
      if (energyLevel != null) {
        final state = energyLevel['state'] as String?;
        final evidence = energyLevel['evidence'] as String?;
        if (state != null) {
          insights.add('🔥 ${_capitalize(state)}');
        }
      }
      
      // Structure patterns (can be Map or String)
      final structure = behavioralIndicators['structure'];
      if (structure is Map<String, dynamic>) {
        final pattern = structure['pattern'] as String?;
        final planningLevel = structure['planning_level'] as String?;
        if (pattern != null) {
          insights.add('📋 ${_formatBehavioralInsight(pattern)}');
        }
      } else if (structure is String) {
        insights.add('📋 ${_formatBehavioralInsight(structure)}');
      }
      
      // Energy, variety, structure (flat structure - only if they are strings)
      final energy = behavioralIndicators['energy'];
      final variety = behavioralIndicators['variety'];
      final structureFlat = behavioralIndicators['structure'];
      
      if (energy is String) {
        insights.add('⚡ ${_capitalize(energy)}');
      }
      if (variety is String) {
        insights.add('🎯 ${_formatBehavioralInsight(variety)}');
      }
      if (structureFlat is String) {
        insights.add('📊 ${_formatBehavioralInsight(structureFlat)}');
      }
    }
    
    // Universal Framework: Context behavioral patterns
    final context = metadata['context'] as Map<String, dynamic>?;
    if (context != null) {
      final energyState = context['energy_state'] as Map<String, dynamic>?;
      if (energyState != null) {
        final level = energyState['level'] as String?;
        if (level != null) {
          insights.add('⚡ ${_capitalize(level)} energy');
        }
      }
      
      final sessionType = context['session_type'] as String?;
      if (sessionType != null) {
        insights.add('🎯 ${_formatBehavioralInsight(sessionType)}');
      }
    }
    
    // Universal Framework: Qualitative markers
    final qualitativeMarkers = metadata['qualitative_markers'] as Map<String, dynamic>?;
    if (qualitativeMarkers != null) {
      final languageTone = qualitativeMarkers['language_tone'] as String?;
      final sessionIntensity = qualitativeMarkers['session_intensity'] as String?;
      final activityDiversity = qualitativeMarkers['activity_diversity'] as String?;
      
      if (languageTone != null) {
        insights.add('💬 ${_capitalize(languageTone)}');
      }
      if (sessionIntensity != null) {
        insights.add('🎯 ${_formatBehavioralInsight(sessionIntensity)}');
      }
      if (activityDiversity != null) {
        insights.add('🌈 ${_capitalize(activityDiversity)} variety');
      }
    }
    
    // Legacy: Behavioral insights (backward compatibility)
    final behavioral = metadata['behavioral_insights'] as Map<String, dynamic>?;
    if (behavioral != null) {
      final sophistication = behavioral['training_sophistication'] as String?;
      final management = behavioral['intensity_management'] as String?;
      final stacking = behavioral['habit_stacking'] as String?;
      
      if (sophistication != null && sophistication.contains('understands')) {
        insights.add('🧠 Sophisticated training');
      }
      if (management != null && management.contains('awareness')) {
        insights.add('⚖️ Intensity control');
      }
      if (stacking != null) {
        insights.add('🔗 Habit stacking');
      }
    }
    
    return insights;
  }
  
  /// Extract performance insights (intensity, patterns, progression)
  static List<String> _extractPerformanceInsights(Map<String, dynamic> metadata) {
    final insights = <String>[];
    
    // Universal Framework: Breathing details
    final breathingDetails = metadata['breathing_details'] as Map<String, dynamic>?;
    if (breathingDetails != null) {
      final types = breathingDetails['types'] as List<dynamic>?;
      final context = breathingDetails['context'] as String?;
      
      if (types != null && types.isNotEmpty) {
        final breathingTypes = types
            .where((type) => type is Map<String, dynamic>)
            .map((type) => type['name'] as String?)
            .where((name) => name != null)
            .take(2)
            .join(' + ');
        if (breathingTypes.isNotEmpty) {
          insights.add('🫁 $breathingTypes');
        }
      }
      
      if (context != null) {
        insights.add('📍 ${_formatBehavioralInsight(context)}');
      }
    }
    
    // Universal Framework: Associated activities
    final associatedActivities = metadata['associated_activities'] as List<dynamic>?;
    if (associatedActivities != null && associatedActivities.isNotEmpty) {
      final activityTypes = associatedActivities
          .where((activity) => activity is Map<String, dynamic>)
          .map((activity) => activity['type'] as String?)
          .where((type) => type != null)
          .take(3)
          .join(', ');
      if (activityTypes.isNotEmpty) {
        insights.add('🔗 $activityTypes');
      }
    }
    
    // Universal Framework: Session sequence
    final session = metadata['session'] as Map<String, dynamic>?;
    if (session != null) {
      final compoundActivity = session['compound_activity'] as bool?;
      final sequence = session['sequence'] as List<dynamic>?;
      
      if (compoundActivity == true && sequence != null) {
        final sequenceStr = sequence.take(3).join(' → ');
        if (sequenceStr.isNotEmpty) {
          insights.add('🔄 $sequenceStr');
        }
      }
    }
    
    // Legacy: Intensity patterns (backward compatibility)
    final intensityPattern = metadata['intensity_pattern'] as Map<String, dynamic>?;
    if (intensityPattern != null) {
      final progression = intensityPattern['progression'] as String?;
      final peakEffort = intensityPattern['peak_effort'] as bool?;
      
      if (progression != null) {
        insights.add('📈 ${_formatProgressionInsight(progression)}');
      }
      if (peakEffort == true) {
        insights.add('🔥 Peak effort');
      }
    }
    
    // Legacy: Technical awareness (backward compatibility)
    final technical = metadata['technical_awareness'] as Map<String, dynamic>?;
    if (technical != null) {
      final hrMonitoring = technical['heart_rate_monitoring'] as bool?;
      final zoneKnowledge = technical['zone_knowledge'] as bool?;
      
      if (hrMonitoring == true && zoneKnowledge == true) {
        insights.add('❤️ HR zone tracking');
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
    
    // Universal Framework: Core activity metrics
    final coreActivity = metadata['core_activity'] as Map<String, dynamic>?;
    if (coreActivity != null) {
      final volume = coreActivity['volume'] as Map<String, dynamic>?;
      if (volume != null) {
        final amount = volume['amount'];
        final unit = volume['unit'];
        if (amount != null && unit != null) {
          items.add(MetadataItem(key: 'Volume', value: '$amount $unit'));
        }
      }
    }
    
    // Universal Framework: Metrics section
    final metrics = metadata['metrics'] as Map<String, dynamic>?;
    if (metrics != null) {
      metrics.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final displayValue = _formatUniversalMetricValue(key, value);
          if (displayValue.isNotEmpty) {
            items.add(MetadataItem(key: _formatKey(key), value: displayValue));
          }
        }
      });
    }
    
    // Universal Framework: Session details
    final session = metadata['session'] as Map<String, dynamic>?;
    if (session != null) {
      final activityCount = session['activity_count'];
      final totalDuration = session['total_duration_inferred'];
      final sequence = session['sequence'] as List<dynamic>?;
      
      if (activityCount != null) {
        items.add(MetadataItem(key: 'Activities', value: '$activityCount'));
      }
      if (totalDuration != null) {
        items.add(MetadataItem(key: 'Duration', value: '$totalDuration'));
      }
      if (sequence != null && sequence.isNotEmpty) {
        items.add(MetadataItem(key: 'Sequence', value: sequence.join(' → ')));
      }
    }
    
    // Legacy: Extract performance metrics (backward compatibility)
    final activityDetails = metadata['activity_details'] as Map<String, dynamic>?;
    if (activityDetails != null) {
      final legacyMetrics = activityDetails['metrics'] as Map<String, dynamic>?;
      if (legacyMetrics != null) {
        legacyMetrics.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final displayValue = _formatMetricValue(value);
            if (displayValue.isNotEmpty) {
              items.add(MetadataItem(key: _formatKey(key), value: displayValue));
            }
          }
        });
      }
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
    
    // Universal Framework: Behavioral indicators
    final behavioralIndicators = metadata['behavioral_indicators'] as Map<String, dynamic>?;
    if (behavioralIndicators != null) {
      behavioralIndicators.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final state = value['state'] as String?;
          final level = value['level'] as String?;
          final pattern = value['pattern'] as String?;
          
          final displayValue = state ?? level ?? pattern ?? value.toString();
          if (displayValue.isNotEmpty && key != 'confidence') {
            items.add(MetadataItem(
              key: _formatKey(key),
              value: _formatBehavioralInsight(displayValue),
            ));
          }
        } else if (value is String && key != 'confidence') {
          items.add(MetadataItem(
            key: _formatKey(key),
            value: _formatBehavioralInsight(value),
          ));
        }
      });
    }
    
    // Universal Framework: Context behavioral patterns
    final context = metadata['context'] as Map<String, dynamic>?;
    if (context != null) {
      final energyState = context['energy_state'] as Map<String, dynamic>?;
      if (energyState != null) {
        final level = energyState['level'] as String?;
        if (level != null) {
          items.add(MetadataItem(
            key: 'Energy Level',
            value: _capitalize(level),
          ));
        }
      }
      
      final sessionType = context['session_type'] as String?;
      if (sessionType != null) {
        items.add(MetadataItem(
          key: 'Session Type',
          value: _formatBehavioralInsight(sessionType),
        ));
      }
    }
    
    // Universal Framework: Qualitative markers
    final qualitativeMarkers = metadata['qualitative_markers'] as Map<String, dynamic>?;
    if (qualitativeMarkers != null) {
      qualitativeMarkers.forEach((key, value) {
        if (value is String && key != 'confidence') {
          items.add(MetadataItem(
            key: _formatKey(key),
            value: _formatBehavioralInsight(value),
          ));
        }
      });
    }
    
    // Legacy: Behavioral insights (backward compatibility)
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
    
    return items.isNotEmpty ? MetadataSection(
      title: '🧠 Behavioral Pattern',
      icon: '🧠',
      items: items,
    ) : null;
  }
  
  /// Build context section
  static MetadataSection? _buildContextSection(Map<String, dynamic> metadata) {
    final items = <MetadataItem>[];
    
    // Universal Framework: Breathing details
    final breathingDetails = metadata['breathing_details'] as Map<String, dynamic>?;
    if (breathingDetails != null) {
      final types = breathingDetails['types'] as List<dynamic>?;
      final context = breathingDetails['context'] as String?;
      
      if (types != null && types.isNotEmpty) {
        final breathingList = types
            .where((type) => type is Map<String, dynamic>)
            .map((type) {
              final name = type['name'] as String?;
              final style = type['style'] as String?;
              return style != null ? '$name ($style)' : name;
            })
            .where((item) => item != null)
            .join(', ');
        
        if (breathingList.isNotEmpty) {
          items.add(MetadataItem(
            key: 'Breathing Types',
            value: breathingList,
          ));
        }
      }
      
      if (context != null) {
        items.add(MetadataItem(
          key: 'Breathing Context',
          value: _formatBehavioralInsight(context),
        ));
      }
    }
    
    // Universal Framework: Associated activities
    final associatedActivities = metadata['associated_activities'] as List<dynamic>?;
    if (associatedActivities != null && associatedActivities.isNotEmpty) {
      final activitiesList = associatedActivities
          .where((activity) => activity is Map<String, dynamic>)
          .map((activity) {
            final type = activity['type'] as String?;
            final description = activity['description'] as String?;
            return description ?? type;
          })
          .where((item) => item != null)
          .take(3)
          .join(', ');
      
      if (activitiesList.isNotEmpty) {
        items.add(MetadataItem(
          key: 'Associated Activities',
          value: activitiesList,
        ));
      }
    }
    
    // Legacy: Qualitative data (backward compatibility)
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
    
    // Legacy: Relational data (backward compatibility)
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
  
  /// Format Universal Framework metric value for display
  static String _formatUniversalMetricValue(String key, Map<String, dynamic> metric) {
    switch (key) {
      case 'distance':
        final running = metric['running'];
        final walking = metric['walking'];
        final total = metric['total'];
        
        if (total != null) {
          return total.toString();
        } else if (running != null && walking != null) {
          return 'Run: $running, Walk: $walking';
        } else if (running != null) {
          return 'Run: $running';
        } else if (walking != null) {
          return 'Walk: $walking';
        }
        break;
        
      case 'hydration':
        final volume = metric['volume'];
        if (volume != null) {
          return volume.toString();
        }
        break;
        
      case 'balance':
        final duration = metric['duration'];
        final type = metric['type'];
        if (duration != null && type != null) {
          return '$duration ($type)';
        } else if (duration != null) {
          return duration.toString();
        }
        break;
        
      default:
        // Fallback to standard formatting
        return _formatMetricValue(metric);
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

