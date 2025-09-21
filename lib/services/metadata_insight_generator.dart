/// FT-149.1: Generates intelligent summaries from metadata for UI display
class MetadataInsightGenerator {
  /// Safely cast dynamic value to Map<String, dynamic>
  static Map<String, dynamic>? _safeMapCast(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// FT-149.6: Extract insights from integrated metadata structure
  static List<String> _extractIntegratedStructureInsights(
      Map<String, dynamic> metadata) {
    final insights = <String>[];

    // Handle activity_analysis structure (cardio exercise)
    if (metadata.containsKey('activity_analysis')) {
      final activityAnalysis = _safeMapCast(metadata['activity_analysis']);
      if (activityAnalysis != null) {
        // Extract running distances
        final sessionComponents = activityAnalysis['session_components'];
        if (sessionComponents is List) {
          for (final component in sessionComponents) {
            if (component is Map<String, dynamic> &&
                component['type'] == 'running') {
              final segments = component['segments'];
              if (segments is List) {
                final totalDistance = segments.fold<int>(0,
                    (sum, segment) => sum + (segment['distance'] as int? ?? 0));
                if (totalDistance > 0) {
                  insights.add('🏃 ${totalDistance}m running');
                }
              }
            } else if (component is Map<String, dynamic> &&
                component['type'] == 'walking') {
              final duration = component['duration'];
              final intensity = component['intensity'];
              if (duration != null) {
                insights.add('🚶 ${duration}s walking ($intensity)');
              }
            }
          }
        }

        // Extract breathing techniques
        final breathingTechniques = activityAnalysis['breathing_techniques'];
        if (breathingTechniques is Map<String, dynamic>) {
          final methods = breathingTechniques['methods'];
          if (methods is List && methods.isNotEmpty) {
            insights.add('🫁 ${methods.length} breathing techniques');
          }
        }
      }
    }

    // Handle breathing_session structure
    if (metadata.containsKey('breathing_session')) {
      final breathingSession = _safeMapCast(metadata['breathing_session']);
      if (breathingSession != null) {
        final primaryChars =
            _safeMapCast(breathingSession['primary_characteristics']);
        if (primaryChars != null) {
          final type = primaryChars['type'];
          if (type != null) {
            insights.add('🫁 $type');
          }

          final style = primaryChars['style'];
          if (style is List && style.isNotEmpty) {
            insights.add('✨ ${style.join(', ')}');
          }
        }
      }
    }

    // Handle activity structure (prayer/meditation)
    if (metadata.containsKey('activity')) {
      final activity = _safeMapCast(metadata['activity']);
      if (activity != null) {
        final primary = activity['primary'];
        final classification = activity['classification'];
        if (primary != null) {
          insights.add('🙏 $primary');
        }
        if (classification != null && classification != primary) {
          insights.add('✨ $classification');
        }
      }
    }

    // Handle sequence information
    if (metadata.containsKey('sequence')) {
      final sequence = _safeMapCast(metadata['sequence']);
      if (sequence != null) {
        final fullSession = sequence['full_session'];
        if (fullSession is List && fullSession.length > 1) {
          insights.add('🔄 ${fullSession.length}-step session');
        }
      }
    }

    return insights.take(3).toList(); // Return top 3 insights
  }

  /// FT-149.5: Extract insights from new metadata structure
  static List<String> _extractNewStructureInsights(
      Map<String, dynamic> metadata) {
    final insights = <String>[];

    // Quantitative - handle actual structure from Claude
    final quantitative = metadata['quantitative'];
    if (quantitative is Map<String, dynamic>) {
      // Distance info
      final distance = quantitative['distance'];
      if (distance is Map<String, dynamic>) {
        final total = distance['total'];
        if (total != null) {
          insights.add('📊 ${total}m total distance');
        }
        final running = distance['running'];
        if (running != null) {
          insights.add('🏃 ${running}m running');
        }
      }

      // Performance info
      final performance = quantitative['performance'];
      if (performance is Map<String, dynamic>) {
        final pace = performance['pace'];
        if (pace != null) {
          insights.add('⚡ Pace: $pace');
        }
      }
    }

    // Qualitative - handle actual structure
    final qualitative = metadata['qualitative'];
    if (qualitative is Map<String, dynamic>) {
      final experience = qualitative['experience'];
      if (experience is Map<String, dynamic>) {
        final difficulty = experience['difficulty'];
        if (difficulty != null) {
          insights.add('✨ Difficulty: $difficulty');
        }
      }

      final method = qualitative['method'];
      if (method is Map<String, dynamic>) {
        final breathing = method['breathing'];
        if (breathing != null) {
          insights.add('🫁 Breathing: $breathing');
        }
      }
    }

    // Behavioral - handle actual structure
    final behavioral = metadata['behavioral'];
    if (behavioral is Map<String, dynamic>) {
      final motivation = behavioral['motivation'];
      if (motivation is Map<String, dynamic>) {
        final internal = motivation['internal'];
        if (internal != null) {
          insights.add('🎯 Motivation: $internal');
        }
      }

      final state = behavioral['state'];
      if (state is Map<String, dynamic>) {
        final physical = state['physical'];
        if (physical != null) {
          insights.add('💪 Physical state: $physical');
        }
      }
    }

    return insights;
  }

  /// FT-149.5: Build sections for new metadata structure
  static List<MetadataSection> _buildNewStructureSections(
      Map<String, dynamic> metadata) {
    final sections = <MetadataSection>[];

    // Quantitative section
    final quantitative = metadata['quantitative'];
    if (quantitative is Map<String, dynamic>) {
      final items = <MetadataItem>[];

      // Distance
      final distance = quantitative['distance'];
      if (distance is Map<String, dynamic>) {
        final total = distance['total'];
        if (total != null)
          items.add(MetadataItem(key: 'Total Distance', value: '${total}m'));
        final running = distance['running'];
        if (running != null)
          items.add(MetadataItem(key: 'Running', value: '${running}m'));
        final walking = distance['walking'];
        if (walking != null)
          items.add(MetadataItem(key: 'Walking', value: '${walking}m'));
      }

      // Duration
      final duration = quantitative['duration'];
      if (duration is Map<String, dynamic>) {
        duration.forEach((key, value) {
          if (value != null) {
            items.add(MetadataItem(
                key: '${_capitalize(key)} Duration', value: value.toString()));
          }
        });
      }

      if (items.isNotEmpty) {
        sections.add(MetadataSection(
            title: 'Quantitative', icon: 'bar_chart', items: items));
      }
    }

    // Qualitative section
    final qualitative = metadata['qualitative'];
    if (qualitative is Map<String, dynamic>) {
      final items = <MetadataItem>[];

      // Experience
      final experience = qualitative['experience'];
      if (experience is Map<String, dynamic>) {
        experience.forEach((key, value) {
          if (value != null) {
            items.add(
                MetadataItem(key: _capitalize(key), value: value.toString()));
          }
        });
      }

      // Method
      final method = qualitative['method'];
      if (method is Map<String, dynamic>) {
        method.forEach((key, value) {
          if (value != null) {
            items.add(
                MetadataItem(key: _capitalize(key), value: value.toString()));
          }
        });
      }

      if (items.isNotEmpty) {
        sections.add(
            MetadataSection(title: 'Qualitative', icon: 'star', items: items));
      }
    }

    // Behavioral section
    final behavioral = metadata['behavioral'];
    if (behavioral is Map<String, dynamic>) {
      final items = <MetadataItem>[];

      // Motivation
      final motivation = behavioral['motivation'];
      if (motivation is Map<String, dynamic>) {
        motivation.forEach((key, value) {
          if (value != null) {
            items.add(MetadataItem(
                key: '${_capitalize(key)} Motivation',
                value: value.toString()));
          }
        });
      }

      // State
      final state = behavioral['state'];
      if (state is Map<String, dynamic>) {
        state.forEach((key, value) {
          if (value != null) {
            items.add(MetadataItem(
                key: '${_capitalize(key)} State', value: value.toString()));
          }
        });
      }

      if (items.isNotEmpty) {
        sections.add(MetadataSection(
            title: 'Behavioral', icon: 'psychology', items: items));
      }
    }

    return sections;
  }

  /// Generate smart summary insights from metadata
  static List<String> generateSummary(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return [];

    final insights = <String>[];

    // FT-149.6: Check for integrated structure first
    if (metadata.containsKey('activity_analysis') ||
        metadata.containsKey('breathing_session') ||
        metadata.containsKey('activity')) {
      final integratedInsights = _extractIntegratedStructureInsights(metadata);
      if (integratedInsights.isNotEmpty) insights.addAll(integratedInsights);
    }
    // FT-149.5: Check for new structure
    else if (metadata.containsKey('quantitative') ||
        metadata.containsKey('qualitative') ||
        metadata.containsKey('behavioral')) {
      final newInsights = _extractNewStructureInsights(metadata);
      if (newInsights.isNotEmpty) insights.addAll(newInsights);
    }

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
  static List<String> _extractQuantitativeInsights(
      Map<String, dynamic> metadata) {
    final insights = <String>[];

    // Fallback Format: Simple extraction_status + category
    if (metadata.containsKey('extraction_status') &&
        metadata['extraction_status'] == 'fallback') {
      final category = metadata['category'] as String?;
      final activityCode = metadata['activity_code'] as String?;
      if (category != null) {
        insights.add('📊 ${_formatCategory(category)}');
      }
      if (activityCode != null) {
        insights.add('🏷️ $activityCode');
      }
      // Add user context preview for fallback
      final userContext = metadata['user_context'] as String?;
      if (userContext != null && userContext.length > 10) {
        final preview = userContext.length > 30
            ? '${userContext.substring(0, 30)}...'
            : userContext;
        insights.add('💬 $preview');
      }
      return insights; // Return early for fallback format
    }

    // Legacy Format 1: Simple activity_code + substance
    if (metadata.containsKey('activity_code') &&
        metadata.containsKey('substance')) {
      final substance = metadata['substance'] as String?;
      if (substance != null) {
        insights.add('💧 ${_capitalize(substance)}');
      }
    }

    // Legacy Format 2: Activity + context structure
    final activity = _safeMapCast(metadata['activity']);
    if (activity != null) {
      final type = activity['type'] as String?;
      final specific = activity['specific'] as String?;
      if (type != null) {
        insights.add('🎯 ${_capitalize(type)}');
      }
      if (specific != null) {
        insights.add('📋 ${_formatBehavioralInsight(specific)}');
      }
    }

    // Legacy Format 3: Associated metrics
    final associatedMetrics = _safeMapCast(metadata['associated_metrics']);
    if (associatedMetrics != null) {
      final running = _safeMapCast(associatedMetrics['running']);
      if (running != null) {
        final distance = _safeMapCast(running['distance']);
        if (distance != null) {
          final value = distance['value'];
          final unit = distance['unit'];
          if (value != null && unit != null) {
            insights.add('🏃 $value $unit');
          }
        }
      }
    }

    // Universal Framework: Core activity metrics
    final coreActivity = metadata['core_activity'];
    if (coreActivity != null) {
      final volume = coreActivity['volume'];
      if (volume != null) {
        final amount = volume['amount'];
        final unit = volume['unit'];
        if (amount != null && unit != null) {
          insights.add('$amount $unit');
        }
      }
    }

    // Universal Framework: Session metrics
    final session = metadata['session'];
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
    final metrics = metadata['metrics'];
    if (metrics != null) {
      // Distance metrics
      final distance = metrics['distance'];
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
      final hydration = metrics['hydration'];
      if (hydration != null) {
        final volume = hydration['volume'];
        if (volume != null) {
          insights.add('💧 $volume');
        }
      }

      // Balance metrics
      final balance = metrics['balance'];
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
    final activityDetails = metadata['activity_details'];
    if (activityDetails != null) {
      final legacyMetrics = activityDetails['metrics'];
      if (legacyMetrics != null) {
        // Distance
        final distance = legacyMetrics['distance'];
        if (distance != null) {
          final value = distance['value'];
          final unit = distance['unit'];
          if (value != null && unit != null) {
            insights.add('$value $unit');
          }
        }

        // Heart rate
        final heartRate = legacyMetrics['heart_rate'];
        if (heartRate != null) {
          final peak = heartRate['peak'];
          final zones = heartRate['zones'];
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
  static List<String> _extractBehavioralInsights(
      Map<String, dynamic> metadata) {
    final insights = <String>[];

    // Legacy Format: Context structure
    final context = metadata['context'];
    if (context != null) {
      final activityCluster = context['activity_cluster'];
      if (activityCluster != null) {
        final primary = activityCluster['primary'] as String?;
        final secondary = activityCluster['secondary'] as String?;
        if (primary != null && secondary != null) {
          insights.add('🔗 $primary + $secondary');
        } else if (primary != null) {
          insights.add('🎯 ${_capitalize(primary)}');
        }
      }
    }

    // Universal Framework: Behavioral indicators
    final behavioralIndicators = metadata['behavioral_indicators'];
    if (behavioralIndicators != null) {
      // Energy level
      final energyLevel = behavioralIndicators['energy_level'];
      if (energyLevel != null) {
        final state = energyLevel['state'] as String?;
        if (state != null) {
          insights.add('🔥 ${_capitalize(state)}');
        }
      }

      // Structure patterns (can be Map or String)
      final structure = behavioralIndicators['structure'];
      if (structure is Map<String, dynamic>) {
        final pattern = structure['pattern'] as String?;
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
    final universalContext = metadata['context'];
    if (universalContext != null) {
      final energyState = universalContext['energy_state'];
      if (energyState != null) {
        final level = energyState['level'] as String?;
        if (level != null) {
          insights.add('⚡ ${_capitalize(level)} energy');
        }
      }

      final sessionType = universalContext['session_type'] as String?;
      if (sessionType != null) {
        insights.add('🎯 ${_formatBehavioralInsight(sessionType)}');
      }
    }

    // Universal Framework: Qualitative markers
    final qualitativeMarkers = metadata['qualitative_markers'];
    if (qualitativeMarkers != null) {
      final languageTone = qualitativeMarkers['language_tone'] as String?;
      final sessionIntensity =
          qualitativeMarkers['session_intensity'] as String?;
      final activityDiversity =
          qualitativeMarkers['activity_diversity'] as String?;

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
    final behavioral = metadata['behavioral_insights'];
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
  static List<String> _extractPerformanceInsights(
      Map<String, dynamic> metadata) {
    final insights = <String>[];

    // Universal Framework: Breathing details
    final breathingDetails = metadata['breathing_details'];
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
    final associatedActivities =
        metadata['associated_activities'] as List<dynamic>?;
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
    final session = metadata['session'];
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
    final intensityPattern = metadata['intensity_pattern'];
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
    final technical = metadata['technical_awareness'];
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

  /// Format category for display
  static String _formatCategory(String category) {
    switch (category.toLowerCase()) {
      case 'physical_health':
        return 'Physical Health';
      case 'mental_health':
        return 'Mental Health';
      case 'relationships':
        return 'Relationships';
      case 'work_productivity':
        return 'Work & Productivity';
      case 'general':
        return 'General';
      default:
        return _capitalize(category.replaceAll('_', ' '));
    }
  }

  /// Generate detailed metadata sections for expansion
  static List<MetadataSection> generateDetailedSections(
      Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return [];

    final sections = <MetadataSection>[];

    // Handle fallback metadata format
    if (metadata.containsKey('extraction_status') &&
        metadata['extraction_status'] == 'fallback') {
      final fallbackSection = _buildFallbackSection(metadata);
      if (fallbackSection != null) sections.add(fallbackSection);
      return sections; // Return early for fallback format
    }

    // FT-149.6: Handle integrated metadata structure format
    if (metadata.containsKey('activity_analysis') ||
        metadata.containsKey('breathing_session') ||
        metadata.containsKey('activity')) {
      final integratedSections = _buildIntegratedStructureSections(metadata);
      sections.addAll(integratedSections);
      return sections; // Return early for integrated structure format
    }

    // FT-149.5: Handle new structure format
    if (metadata.containsKey('quantitative') ||
        metadata.containsKey('qualitative') ||
        metadata.containsKey('behavioral')) {
      final newStructureSections = _buildNewStructureSections(metadata);
      sections.addAll(newStructureSections);
      return sections; // Return early for new structure format
    }

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

  /// FT-149.6: Build sections for integrated metadata structure
  static List<MetadataSection> _buildIntegratedStructureSections(
      Map<String, dynamic> metadata) {
    final sections = <MetadataSection>[];

    // Handle activity_analysis structure (cardio exercise)
    if (metadata.containsKey('activity_analysis')) {
      final activityAnalysis = _safeMapCast(metadata['activity_analysis']);
      if (activityAnalysis != null) {
        final items = <MetadataItem>[];

        // Primary type
        final primaryType = activityAnalysis['primary_type'];
        if (primaryType != null) {
          items.add(MetadataItem(key: 'Type', value: primaryType.toString()));
        }

        // Session components
        final sessionComponents = activityAnalysis['session_components'];
        if (sessionComponents is List) {
          for (final component in sessionComponents) {
            if (component is Map<String, dynamic>) {
              final type = component['type'];
              if (type == 'running') {
                final segments = component['segments'];
                if (segments is List) {
                  final distances = segments
                      .map((s) => '${s['distance']}${s['unit'] ?? 'm'}')
                      .join(', ');
                  items.add(MetadataItem(key: 'Running', value: distances));
                }
              } else if (type == 'walking') {
                final duration = component['duration'];
                final intensity = component['intensity'];
                items.add(MetadataItem(
                    key: 'Walking', value: '${duration}s ($intensity)'));
              }
            }
          }
        }

        // Breathing techniques
        final breathingTechniques = activityAnalysis['breathing_techniques'];
        if (breathingTechniques is Map<String, dynamic>) {
          final methods = breathingTechniques['methods'];
          if (methods is List) {
            final techniques =
                methods.map((m) => '${m['type']} (${m['timing']})').join(', ');
            items.add(MetadataItem(key: 'Breathing', value: techniques));
          }
        }

        if (items.isNotEmpty) {
          sections.add(MetadataSection(
              title: 'Exercise Analysis',
              icon: 'fitness_center',
              items: items));
        }
      }
    }

    // Handle breathing_session structure
    if (metadata.containsKey('breathing_session')) {
      final breathingSession = _safeMapCast(metadata['breathing_session']);
      if (breathingSession != null) {
        final items = <MetadataItem>[];

        // Primary characteristics
        final primaryChars =
            _safeMapCast(breathingSession['primary_characteristics']);
        if (primaryChars != null) {
          final type = primaryChars['type'];
          if (type != null)
            items.add(MetadataItem(key: 'Type', value: type.toString()));

          final style = primaryChars['style'];
          if (style is List) {
            items.add(MetadataItem(key: 'Style', value: style.join(', ')));
          }
        }

        // Components
        final components = breathingSession['components'];
        if (components is List) {
          for (final component in components) {
            if (component is Map<String, dynamic>) {
              final phase = component['phase'];
              final technique = component['technique'];
              if (phase != null && technique != null) {
                items.add(MetadataItem(
                    key: phase.toString(), value: technique.toString()));
              }
            }
          }
        }

        if (items.isNotEmpty) {
          sections.add(MetadataSection(
              title: 'Breathing Session', icon: 'air', items: items));
        }
      }
    }

    // Handle activity structure (prayer/meditation)
    if (metadata.containsKey('activity')) {
      final activity = _safeMapCast(metadata['activity']);
      if (activity != null) {
        final items = <MetadataItem>[];

        final primary = activity['primary'];
        if (primary != null)
          items.add(MetadataItem(key: 'Primary', value: primary.toString()));

        final classification = activity['classification'];
        if (classification != null)
          items
              .add(MetadataItem(key: 'Type', value: classification.toString()));

        final context = activity['context'];
        if (context != null)
          items.add(MetadataItem(key: 'Context', value: context.toString()));

        if (items.isNotEmpty) {
          sections.add(MetadataSection(
              title: 'Activity Details',
              icon: 'self_improvement',
              items: items));
        }
      }
    }

    // Handle sequence information
    if (metadata.containsKey('sequence')) {
      final sequence = _safeMapCast(metadata['sequence']);
      if (sequence != null) {
        final items = <MetadataItem>[];

        final position = sequence['position'];
        if (position != null)
          items.add(MetadataItem(key: 'Position', value: position.toString()));

        final fullSession = sequence['full_session'];
        if (fullSession is List) {
          items.add(MetadataItem(
              key: 'Full Session', value: fullSession.join(' → ')));
        }

        if (items.isNotEmpty) {
          sections.add(MetadataSection(
              title: 'Session Sequence', icon: 'timeline', items: items));
        }
      }
    }

    // Handle behavioral state
    if (metadata.containsKey('behavioral_state')) {
      final behavioralState = _safeMapCast(metadata['behavioral_state']);
      if (behavioralState != null) {
        final items = <MetadataItem>[];

        final physicalState = behavioralState['physical_state'];
        if (physicalState != null)
          items.add(MetadataItem(
              key: 'Physical State', value: physicalState.toString()));

        final mentalState = behavioralState['mental_state'];
        if (mentalState != null)
          items.add(
              MetadataItem(key: 'Mental State', value: mentalState.toString()));

        final breathingPattern = behavioralState['breathing_pattern'];
        if (breathingPattern != null)
          items.add(MetadataItem(
              key: 'Breathing Pattern', value: breathingPattern.toString()));

        if (items.isNotEmpty) {
          sections.add(MetadataSection(
              title: 'Behavioral State', icon: 'psychology', items: items));
        }
      }
    }

    return sections;
  }

  /// Build fallback metadata section
  static MetadataSection? _buildFallbackSection(Map<String, dynamic> metadata) {
    final items = <MetadataItem>[];

    // Activity code
    final activityCode = metadata['activity_code'] as String?;
    if (activityCode != null) {
      items.add(MetadataItem(key: 'Activity Code', value: activityCode));
    }

    // Category
    final category = metadata['category'] as String?;
    if (category != null) {
      items
          .add(MetadataItem(key: 'Category', value: _formatCategory(category)));
    }

    // User context preview
    final userContext = metadata['user_context'] as String?;
    if (userContext != null && userContext.isNotEmpty) {
      final preview = userContext.length > 80
          ? '${userContext.substring(0, 80)}...'
          : userContext;
      items.add(MetadataItem(key: 'Context', value: preview));
    }

    // Extraction reason
    final reason = metadata['extraction_reason'] as String?;
    if (reason != null) {
      items.add(MetadataItem(key: 'Status', value: reason));
    }

    if (items.isEmpty) return null;

    return MetadataSection(
      title: 'Basic Info',
      icon: 'info_outline',
      items: items,
    );
  }

  /// Build performance section
  static MetadataSection? _buildPerformanceSection(
      Map<String, dynamic> metadata) {
    final items = <MetadataItem>[];

    // Universal Framework: Core activity metrics
    final coreActivity = metadata['core_activity'];
    if (coreActivity != null) {
      final volume = coreActivity['volume'];
      if (volume != null) {
        final amount = volume['amount'];
        final unit = volume['unit'];
        if (amount != null && unit != null) {
          items.add(MetadataItem(key: 'Volume', value: '$amount $unit'));
        }
      }
    }

    // Universal Framework: Metrics section
    final metrics = metadata['metrics'];
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
    final session = metadata['session'];
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
    final activityDetails = metadata['activity_details'];
    if (activityDetails != null) {
      final legacyMetrics = activityDetails['metrics'];
      if (legacyMetrics != null) {
        legacyMetrics.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final displayValue = _formatMetricValue(value);
            if (displayValue.isNotEmpty) {
              items
                  .add(MetadataItem(key: _formatKey(key), value: displayValue));
            }
          }
        });
      }
    }

    return items.isNotEmpty
        ? MetadataSection(
            title: '📊 Performance',
            icon: '📊',
            items: items,
          )
        : null;
  }

  /// Build behavioral section
  static MetadataSection? _buildBehavioralSection(
      Map<String, dynamic> metadata) {
    final items = <MetadataItem>[];

    // Universal Framework: Behavioral indicators
    final behavioralIndicators = metadata['behavioral_indicators'];
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
    final context = metadata['context'];
    if (context != null) {
      final energyState = context['energy_state'];
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
    final qualitativeMarkers = metadata['qualitative_markers'];
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
    final behavioral = metadata['behavioral_insights'];
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

    return items.isNotEmpty
        ? MetadataSection(
            title: '🧠 Behavioral Pattern',
            icon: '🧠',
            items: items,
          )
        : null;
  }

  /// Build context section
  static MetadataSection? _buildContextSection(Map<String, dynamic> metadata) {
    final items = <MetadataItem>[];

    // Universal Framework: Breathing details
    final breathingDetails = metadata['breathing_details'];
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
    final associatedActivities =
        metadata['associated_activities'] as List<dynamic>?;
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
    final qualitative = metadata['qualitative'];
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
    final relational = metadata['relational'];
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

    return items.isNotEmpty
        ? MetadataSection(
            title: '🎯 Context',
            icon: '🎯',
            items: items,
          )
        : null;
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
  static String _formatUniversalMetricValue(
      String key, Map<String, dynamic> metric) {
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
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
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
