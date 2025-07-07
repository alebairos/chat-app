# Semantic Action Dictionary System - Feature Proposal

## Problem Analysis

### Current Redundancy Issues

Our current implementation has significant code duplication between two services:

1. **TTSTextProcessor** - Contains action detection lists for removal
2. **EmotionalToneMapper** - Contains similar action lists for emotion detection

**Redundant Data**:
```dart
// In TTSTextProcessor._isActionDescription()
final actionIndicators = [
  'pensativamente', 'sorri', 'chuckles', 'leans', 'smirk', // etc.
];

// In EmotionalToneMapper._isThoughtfulAction()
final thoughtfulIndicators = [
  'pensativamente', 'thoughtfully', 'inclina a cabeça', // etc.
];

// In EmotionalToneMapper._isWarmAction()
final warmIndicators = [
  'sorri', 'chuckles', 'warmly', // etc.
];
```

**Problems**:
- **Maintainability**: Adding new actions requires updating multiple files
- **Consistency**: Easy to miss updates in one service but not the other
- **Scalability**: Hard to add new languages or emotional categories
- **Performance**: Multiple string matching operations on same text
- **Testing**: Duplicate test scenarios for same action patterns

## Proposed Solution: Semantic Action Dictionary

### Architecture Overview

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│ Original Text       │───▶│ ActionAnalyzer       │───▶│ ActionAnalysis      │
│ "*chuckles warmly*" │    │ - Parse actions      │    │ - actions: [...]    │
└─────────────────────┘    │ - Query dictionary   │    │ - emotions: [...]   │
                           └──────────────────────┘    │ - shouldRemove: []  │
                                    │                  └─────────────────────┘
                                    ▼                                        
┌─────────────────────┐    ┌──────────────────────┐                         
│ SemanticDictionary  │◀───│ Dictionary Service   │                         
│ - actions.json      │    │ - Fast lookup        │                         
│ - emotions.json     │    │ - Multi-language     │                         
│ - voice_params.json │    │ - Extensible         │                         
└─────────────────────┘    └──────────────────────┘                         
```

### 1. Semantic Dictionary Structure

#### Core Data Files

**`assets/dictionaries/actions.json`**:
```json
{
  "version": "1.0",
  "languages": ["en", "pt_BR"],
  "actions": {
    "physical_gestures": {
      "cross_arms": {
        "patterns": ["cruza os braços", "crosses arms", "folds arms"],
        "emotions": ["defensive", "thoughtful"],
        "intensity": 0.6,
        "removal_priority": "high"
      },
      "nod_head": {
        "patterns": ["inclina a cabeça", "nods head", "tilts head"],
        "emotions": ["thoughtful", "agreeable"],
        "intensity": 0.4,
        "removal_priority": "high"
      }
    },
    "facial_expressions": {
      "smirk": {
        "patterns": ["with a smirk", "smirking", "sorri malicioso"],
        "emotions": ["playful", "mischievous"],
        "intensity": 0.8,
        "removal_priority": "high"
      },
      "smile": {
        "patterns": ["sorri", "smiles", "grins"],
        "emotions": ["warm", "friendly"],
        "intensity": 0.7,
        "removal_priority": "medium"
      }
    },
    "vocalizations": {
      "chuckle": {
        "patterns": ["chuckles", "ri baixinho", "gives a soft laugh"],
        "emotions": ["warm", "amused"],
        "intensity": 0.6,
        "removal_priority": "high"
      }
    }
  }
}
```

**`assets/dictionaries/emotions.json`**:
```json
{
  "emotions": {
    "thoughtful": {
      "voice_adjustments": {
        "stability_multiplier": 0.8,
        "style_addition": 0.1,
        "similarity_boost_addition": 0.0
      },
      "description": "More contemplative, deliberate"
    },
    "warm": {
      "voice_adjustments": {
        "stability_multiplier": 1.0,
        "style_addition": 0.2,
        "similarity_boost_addition": 0.1
      },
      "description": "Friendlier, more approachable"
    },
    "playful": {
      "voice_adjustments": {
        "stability_multiplier": 0.7,
        "style_addition": 0.3,
        "similarity_boost_addition": 0.0
      },
      "description": "More dynamic, expressive"
    }
  }
}
```

**`assets/dictionaries/language_patterns.json`**:
```json
{
  "pt_BR": {
    "action_connectors": ["e", "enquanto", "ao mesmo tempo"],
    "common_particles": ["de", "da", "do", "para", "com"],
    "temporal_indicators": ["esperando", "aguardando", "pensando"]
  },
  "en": {
    "action_connectors": ["and", "while", "as"],
    "common_particles": ["to", "with", "for", "of"],
    "temporal_indicators": ["waiting", "thinking", "considering"]
  }
}
```

### 2. Unified Service Architecture

#### ActionAnalyzer Service
```dart
class ActionAnalyzer {
  final SemanticDictionary _dictionary;
  
  /// Analyze text and return comprehensive action analysis
  ActionAnalysis analyzeText(String text) {
    final actions = _extractActions(text);
    final emotions = _deriveEmotions(actions);
    final removalDecisions = _determineRemovals(actions);
    
    return ActionAnalysis(
      actions: actions,
      emotions: emotions,
      shouldRemove: removalDecisions,
      voiceAdjustments: _calculateVoiceParams(emotions),
    );
  }
}
```

#### SemanticDictionary Service
```dart
class SemanticDictionary {
  static SemanticDictionary? _instance;
  late Map<String, ActionDefinition> _actionMap;
  late Map<String, EmotionDefinition> _emotionMap;
  
  /// Fast O(1) lookup for action patterns
  List<ActionMatch> findActionMatches(String text) {
    // Use trie or hash map for efficient pattern matching
    return _performFastLookup(text);
  }
  
  /// Get emotional context from actions
  List<String> deriveEmotions(List<ActionMatch> actions) {
    // Apply emotion inference rules
    return _inferEmotions(actions);
  }
}
```

### 3. Performance Optimizations

#### Fast Pattern Matching
```dart
class PatternMatcher {
  final Trie _actionTrie;      // O(m) pattern matching
  final Map<String, int> _hash; // O(1) exact lookups
  
  /// Build optimized data structures from dictionary
  void buildOptimizedStructures(SemanticDictionary dictionary) {
    // Create trie for substring matching
    // Create hash map for exact matching
    // Pre-compile regex patterns
  }
}
```

#### Caching Strategy
```dart
class ActionAnalysisCache {
  final LRU<String, ActionAnalysis> _cache;
  
  /// Cache results for repeated patterns
  ActionAnalysis? getCached(String text) {
    return _cache.get(_hashText(text));
  }
}
```

### 4. Implementation Benefits

#### Maintainability
- **Single Source of Truth**: All action patterns in JSON files
- **Easy Updates**: Add new actions/emotions without code changes
- **Version Control**: Dictionary files can be versioned independently
- **Hot Reload**: Update dictionaries without app restart (in development)

#### Scalability
- **Multi-Language**: Easy to add new languages
- **Extensible**: New emotional categories without architecture changes
- **Character-Specific**: Different dictionaries per character type
- **Community Driven**: External contributors can improve dictionaries

#### Performance
- **O(1) Lookups**: Hash-based pattern matching
- **Single Pass**: Analyze text once for all information
- **Efficient Caching**: Avoid repeated analysis of similar patterns
- **Lazy Loading**: Load dictionaries on demand

#### Testing
- **Data-Driven Tests**: Test cases from dictionary entries
- **Automated Validation**: Verify dictionary consistency
- **A/B Testing**: Compare different emotional mappings
- **Regression Detection**: Ensure updates don't break existing patterns

### 5. Migration Strategy

#### Phase 1: Dictionary Creation
1. Extract existing patterns from both services
2. Create initial JSON dictionary files
3. Add emotional mappings and intensity scores
4. Validate data completeness

#### Phase 2: Core Service Implementation  
1. Implement `SemanticDictionary` service
2. Create `ActionAnalyzer` with unified API
3. Build performance optimization layer
4. Add comprehensive testing

#### Phase 3: Integration
1. Replace `TTSTextProcessor` action detection
2. Replace `EmotionalToneMapper` emotion detection  
3. Update integration points in `ElevenLabsProvider`
4. Migrate existing tests

#### Phase 4: Enhancement
1. Add emoji pattern recognition
2. Implement context-aware emotion inference
3. Add character-specific dictionaries
4. Performance monitoring and optimization

### 6. Advanced Features

#### Contextual Emotion Inference
```json
{
  "context_rules": {
    "combined_actions": {
      "thoughtful_warm": {
        "pattern": ["thoughtful", "warm"],
        "result_emotion": "wise_mentor",
        "voice_adjustments": {
          "stability_multiplier": 0.85,
          "style_addition": 0.15
        }
      }
    }
  }
}
```

#### Intensity-Based Adjustments
```json
{
  "intensity_mappings": {
    "low": {"style_multiplier": 1.0},
    "medium": {"style_multiplier": 1.2}, 
    "high": {"style_multiplier": 1.5}
  }
}
```

#### Character-Specific Dictionaries
```json
{
  "characters": {
    "oracle": {
      "base_dictionary": "standard",
      "overrides": {
        "thoughtful": {
          "voice_adjustments": {
            "stability_multiplier": 0.7,
            "style_addition": 0.2
          }
        }
      }
    }
  }
}
```

### 7. API Design

#### Unified Interface
```dart
// Current (redundant)
final processedText = TTSTextProcessor.processForTTS(text);
final emotions = EmotionalToneMapper.extractEmotionalTone(text);

// Proposed (unified)
final analysis = ActionAnalyzer.analyzeText(text);
final processedText = analysis.getCleanedText();
final voiceParams = analysis.getVoiceParameters();
```

#### Flexible Configuration
```dart
final analyzer = ActionAnalyzer(
  dictionary: SemanticDictionary.forCharacter('oracle'),
  language: 'pt_BR',
  emotionalSensitivity: 0.8,
  cacheEnabled: true,
);
```

### 8. Development Tools

#### Dictionary Editor
- Visual interface for managing action patterns
- Real-time pattern testing
- Emotional mapping visualizer
- Export/import functionality

#### Debug Dashboard
- Action detection visualization
- Emotional inference debugging
- Performance metrics
- A/B testing results

### 9. Success Metrics

#### Code Quality
- **Reduce LOC**: ~60% reduction in action-related code
- **Eliminate Duplication**: 0% code redundancy
- **Improve Test Coverage**: Automated test generation from dictionary

#### Performance
- **Faster Analysis**: Single-pass vs. multiple pattern matching
- **Memory Efficiency**: Shared data structures
- **Cache Hit Rate**: >80% for repeated patterns

#### Maintainability  
- **Update Speed**: Add new actions in minutes vs. hours
- **Bug Reduction**: Fewer inconsistencies between services
- **Team Velocity**: Faster feature development

### 10. Risk Mitigation

#### Data Quality
- **Validation Rules**: Ensure dictionary consistency
- **Automated Testing**: Verify all patterns work as expected
- **Rollback Strategy**: Quick revert to hardcoded patterns if needed

#### Performance
- **Benchmarking**: Compare with current implementation
- **Memory Monitoring**: Ensure dictionary size doesn't impact performance
- **Fallback Options**: Graceful degradation if dictionary fails

#### Complexity
- **Incremental Rollout**: Phase-by-phase implementation
- **Documentation**: Comprehensive guides for dictionary management
- **Training**: Team education on new architecture

---

**Estimated Development Time**: 3-4 weeks
**Priority**: High (addresses technical debt and scalability)
**Risk Level**: Medium (new architecture but clear migration path)

This proposal transforms a hardcoded, redundant system into a flexible, data-driven architecture that scales with the application's growing emotional intelligence requirements while dramatically improving maintainability and performance. 