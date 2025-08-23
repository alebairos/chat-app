# FT-063 Adaptive Activity Detection System

**Feature ID**: FT-063  
**Priority**: High  
**Category**: AI/ML Enhancement  
**Effort Estimate**: 4-6 weeks  
**Dependencies**: FT-061 (Oracle Activity Memory), FT-062 (Oracle Preprocessing)

## Feature Summary

Replace the current hardcoded keyword-based activity detection with an adaptive machine learning system that learns from user interactions and provides intelligent activity recognition for Oracle-compatible personas.

## Problem Statement

### Current Limitations (FT-061/062)
- **Brittle Detection**: Only ~15 hardcoded Portuguese keywords
- **No Context Awareness**: Cannot distinguish past vs future tense
- **Limited Vocabulary**: Misses natural language variations and synonyms
- **No Learning**: Cannot improve from user feedback or corrections
- **Language Rigidity**: Exact keyword matches only, no fuzzy matching
- **Poor Precision**: False positives from keyword fragments in longer sentences

### User Impact
- **Missed Activities**: Users say "exercitei-me" but system expects "exercício"
- **Manual Corrections**: Users must repeat themselves with exact keywords
- **Frustration**: Natural conversation doesn't trigger activity tracking
- **Inconsistent Experience**: Same activity expressed differently gets different results

## Proposed Solution

### Adaptive Activity Detection System
A progressive enhancement approach that evolves from enhanced keyword matching to machine learning-based detection with user feedback learning.

## Functional Requirements

### FR-1: Enhanced Keyword Matching
**As an Oracle persona user, I want the system to understand activity variations so that natural language is recognized.**

#### Acceptance Criteria:
- ✅ Fuzzy string matching for Portuguese activity terms
- ✅ Synonym expansion: "malhar" = "exercitar" = "treinar"
- ✅ Stemming support: "corri", "correndo", "correr" → same activity
- ✅ Confidence scoring for each detection (0.0-1.0)
- ✅ Duration extraction with improved regex patterns
- ✅ Context-aware tense detection (past vs future/intention)

#### Examples:
```
Input: "acabei de malhar na academia"
Output: SF12 (Fazer exercício de força) - confidence: 0.85

Input: "vou meditar amanhã"  
Output: No detection (future tense)

Input: "exercitei-me por 30 min"
Output: SF12 (Fazer exercício de força) - confidence: 0.80, duration: 30
```

### FR-2: Confidence-Based Decision Making
**As a system, I want to make intelligent decisions about when to trigger activity detection based on confidence levels.**

#### Acceptance Criteria:
- ✅ High confidence (>0.8): Auto-detect without confirmation
- ✅ Medium confidence (0.5-0.8): Detect with subtle UI indicator
- ✅ Low confidence (0.3-0.5): Ask for user confirmation
- ✅ Very low confidence (<0.3): No detection, fallback to conversation
- ✅ Configurable confidence thresholds per activity type

### FR-3: User Feedback Learning System
**As an Oracle persona user, I want to correct activity detections so that the system learns my patterns.**

#### Acceptance Criteria:
- ✅ Simple correction UI: thumbs up/down on detected activities
- ✅ "Not quite right" option with activity selector
- ✅ "I meant something else" with custom activity input
- ✅ Silent learning: track user patterns without explicit feedback
- ✅ Personal vocabulary expansion: learn user-specific terms

#### User Flow:
```
1. User: "fiz minha corrida matinal"
2. System: Detects SF13 (cardio) with confidence 0.7
3. UI: Shows "Registered your cardio workout ✓" with edit option
4. User: Taps edit → "Actually, it was just a walk"
5. System: Learns "corrida matinal" + user correction pattern
```

### FR-4: Sentence Embedding Integration
**As a system, I want to understand semantic similarity between user messages and Oracle activities.**

#### Acceptance Criteria:
- ✅ Portuguese sentence embeddings for user messages
- ✅ Pre-computed embeddings for all 70 Oracle activities
- ✅ Cosine similarity scoring between message and activities
- ✅ Semantic clustering of similar activities
- ✅ Multi-language support foundation (Portuguese primary)

### FR-5: Progressive Learning Pipeline
**As a system, I want to continuously improve detection accuracy through user interactions.**

#### Acceptance Criteria:
- ✅ Local training data collection (privacy-preserving)
- ✅ Periodic model weight updates based on user feedback
- ✅ Cold start handling for new users
- ✅ Graceful degradation to keyword matching if ML fails
- ✅ A/B testing framework for different detection strategies

## Non-Functional Requirements

### NFR-1: Performance
- **Response Time**: Activity detection adds <300ms to conversation flow
- **Memory Usage**: ML model <15MB total app memory increase
- **Battery Impact**: Negligible impact on device battery life
- **Offline Capability**: Full functionality without internet connection

### NFR-2: Privacy & Security
- **Local Processing**: All ML training and inference on-device only
- **Data Minimization**: Only store essential correction feedback
- **User Control**: Users can clear learning data and reset model
- **No Telemetry**: No activity detection data sent to external servers

### NFR-3: Reliability
- **Fallback Strategy**: Graceful degradation to keyword matching
- **Error Handling**: Silent failure with logging, no conversation disruption
- **Model Versioning**: Ability to rollback to previous model versions
- **Cross-Platform**: Consistent behavior across iOS/Android/Web

## Technical Architecture

### Phase 1: Enhanced Keywords (Weeks 1-2)
```dart
class EnhancedActivityMatcher {
  // Fuzzy string matching with confidence
  // Portuguese stemming and synonyms
  // Regex improvements for duration/context
  // Confidence calibration
}
```

### Phase 2: Semantic Similarity (Weeks 3-4)
```dart
class SemanticActivityDetector {
  // Sentence embedding integration
  // Oracle activity pre-computation
  // Hybrid scoring (keywords + semantics)
  // Performance optimization
}
```

### Phase 3: Learning System (Weeks 5-6)
```dart
class AdaptiveActivityLearner {
  // User feedback collection
  // On-device model updates
  // Personal pattern recognition
  // Confidence threshold adaptation
}
```

## Integration Points

### Existing System Integration
- **FT-061**: Replaces `_analyzeActivitiesBasic()` in SystemMCPService
- **FT-062**: Uses Oracle JSON activity definitions as training data
- **Claude Service**: Enhanced MCP command processing with confidence
- **Activity Memory**: Improved activity storage with confidence scores

### New Components
- **Activity Detection Engine**: Core ML/rule-based hybrid system
- **User Feedback Collector**: UI components for corrections
- **Learning Pipeline**: Background model training and updates
- **Confidence Calibrator**: Dynamic threshold adjustment

## Success Metrics

### Detection Quality
- **Precision**: >90% of detected activities are correct
- **Recall**: >85% of actual activities mentioned are detected  
- **User Satisfaction**: <5% of detections require user correction
- **False Positive Rate**: <10% incorrect activity detections

### Learning Effectiveness
- **Improvement Rate**: 10% accuracy increase after 100 user interactions
- **Personalization**: 15% better accuracy for frequent user patterns
- **Cold Start**: >70% accuracy for new users with zero training data

### Performance
- **Response Time**: <300ms average detection latency
- **Memory Efficiency**: <15MB total memory footprint increase
- **Battery Impact**: <2% additional battery consumption per day

## Testing Strategy

### Unit Testing
- Enhanced keyword matching algorithms
- Confidence scoring accuracy
- Fuzzy matching edge cases
- Duration extraction patterns

### Integration Testing  
- MCP command processing with new detection
- Oracle activity mapping accuracy
- Database storage with confidence scores
- UI feedback collection flow

### User Acceptance Testing
- Natural conversation flow testing
- Correction UI usability
- Learning system effectiveness
- Cross-language detection quality

### Performance Testing
- Detection latency under load
- Memory usage during extended conversations
- Battery impact measurement
- Model training performance

## Risk Analysis

### Technical Risks
- **High**: ML model size/performance on older devices
- **Medium**: Portuguese language model availability/quality
- **Low**: Integration complexity with existing MCP system

### Mitigation Strategies
- Progressive rollout with feature flags
- Comprehensive fallback to keyword matching
- Performance monitoring and automatic degradation
- A/B testing between old and new detection systems

## Migration Strategy

### Phase 1: Parallel Implementation
- Deploy enhanced detection alongside existing keywords
- A/B test with 10% of Oracle persona users
- Collect performance and accuracy metrics
- User feedback on detection quality

### Phase 2: Gradual Rollout
- Increase rollout to 50% of users based on Phase 1 results
- Monitor user correction rates and satisfaction
- Fine-tune confidence thresholds based on real usage
- Address any performance issues discovered

### Phase 3: Full Migration
- Replace hardcoded keywords entirely
- Maintain fallback capability for edge cases
- Continue learning system improvements
- Evaluate next-generation ML approaches

## Future Enhancements

### Potential Extensions
- **Multi-language Support**: Spanish, English activity detection
- **Voice Activity Recognition**: Audio message activity extraction
- **Contextual Intelligence**: Time-of-day and location-aware detection
- **Social Learning**: Anonymous federated learning across users
- **Advanced ML**: Transformer-based models for complex reasoning

### Research Opportunities
- **Reinforcement Learning**: True RL agent for activity prediction
- **Attention Mechanisms**: Focus on relevant parts of user messages
- **Cross-Modal Learning**: Text + audio + temporal pattern recognition
- **Explainable AI**: Help users understand why activities were detected

---

## Implementation Notes

This feature represents a significant evolution from rule-based to learning-based activity detection. The phased approach ensures we maintain system reliability while progressively enhancing detection capabilities.

The focus on user feedback and personalization aligns with the Oracle system's goal of supporting individual behavioral change journeys through intelligent technology assistance.

**Dependencies**: Requires completion of FT-061 and FT-062 for Oracle activity foundation and preprocessing pipeline.

**Timeline**: 4-6 weeks for full implementation across all three phases, with production-ready enhanced keyword matching available after 2 weeks.
