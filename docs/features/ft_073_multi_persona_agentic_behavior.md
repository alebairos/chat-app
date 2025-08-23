# FT-073 Multi-Persona Agentic Behavior

**Feature ID**: FT-073  
**Priority**: High  
**Category**: AI/Persona Management  
**Effort Estimate**: 4-6 weeks  
**Dependencies**: FT-065 (Three-Tab Navigation), FT-066 (Activity Stats Display), Existing persona selection system  
**Status**: Specification  

## Overview

Transform the single-persona chat experience into a collaborative multi-persona system where users can select multiple AI guides that work together. The first selected persona becomes the primary conversationalist (80% active), while the second becomes an active observer (20% active) providing insights, tracking activities, and occasionally commenting. This creates a more dynamic, intelligent, and personalized AI assistant experience.

## User Story

As a user who wants deeper insights and multiple perspectives, I want to select multiple AI personas that work together collaboratively, so that I can benefit from specialized expertise while maintaining coherent conversation flow. The primary persona handles direct responses while the secondary persona observes, tracks patterns, and provides contextual insights.

## Problem Statement

**Current Limitations:**
- **Single Perspective**: Only one AI persona can be active at a time
- **Limited Insights**: No cross-persona pattern recognition or suggestions
- **Missed Opportunities**: Secondary personas can't contribute their specialized knowledge
- **Static Experience**: Users can't experiment with persona combinations

**User Pain Points:**
- Having to choose between different AI personalities
- Missing insights that could come from multiple perspectives
- No collaborative problem-solving between personas
- Limited activity tracking and pattern recognition

## Solution: Dynamic Multi-Persona Selection

### Core Concept
- **Primary Persona (80%)**: Main conversationalist, handles direct responses
- **Secondary Persona (20%)**: Active observer, provides insights, tracks activities
- **Dynamic Selection**: Users can select/deselect personas, first selected becomes primary
- **Automatic Role Assignment**: No manual configuration needed

### Selection Logic
```
User selects: [Ari] → Ari becomes Primary
User selects: [Ari, Sergeant] → Ari = Primary, Sergeant = Secondary  
User selects: [Sergeant, I-There] → Sergeant = Primary, I-There = Secondary
User deselects: [Ari] → Sergeant becomes Primary, I-There = Secondary
User deselects: [Sergeant] → I-There becomes Primary (no secondary)
```

## Functional Requirements

### Persona Selection & Management
- **FR-073-01**: Allow users to select multiple personas simultaneously
- **FR-073-02**: First selected persona automatically becomes primary
- **FR-073-03**: Second selected persona automatically becomes secondary
- **FR-073-04**: Support drag-and-drop reordering of selected personas
- **FR-073-05**: Visual indicators showing primary vs secondary roles
- **FR-073-06**: Easy addition/removal of personas from selection

### Response Coordination
- **FR-073-07**: Primary persona generates main conversational responses
- **FR-073-08**: Secondary persona provides contextual insights and observations
- **FR-073-09**: Maintain 80/20 response ratio between primary and secondary
- **FR-073-10**: Seamless integration of responses without conversation disruption
- **FR-073-11**: Clear attribution of which persona is speaking

### Active Observation System
- **FR-073-12**: Secondary persona continuously monitors conversation context
- **FR-073-13**: Track user activity patterns and provide insights
- **FR-073-14**: Identify opportunities for intervention or suggestions
- **FR-073-15**: Maintain conversation history awareness across personas
- **FR-073-16**: Provide proactive recommendations based on observed patterns

### Activity Tracking Enhancement
- **FR-073-17**: Secondary persona specializes in activity pattern recognition
- **FR-073-18**: Cross-persona insights about user behavior and habits
- **FR-073-19**: Collaborative goal setting and progress tracking
- **FR-073-20**: Enhanced Oracle framework integration with multiple perspectives

## Non-Functional Requirements

### Performance
- **NFR-073-01**: Multi-persona responses generate within 2 seconds
- **NFR-073-02**: Support up to 3 personas simultaneously without performance degradation
- **NFR-073-03**: Maintain existing single-persona performance levels

### Usability
- **NFR-073-04**: Intuitive persona selection interface
- **NFR-073-05**: Clear visual distinction between primary and secondary personas
- **NFR-073-06**: Smooth transition between single and multi-persona modes
- **NFR-073-07**: No learning curve for existing single-persona users

### Compatibility
- **NFR-073-08**: Full backward compatibility with existing single-persona functionality
- **NFR-073-09**: No breaking changes to existing persona configurations
- **NFR-073-10**: Gradual migration path for users

## Technical Specifications

### Architecture Changes

#### 1. Extend CharacterConfigManager
```dart
class CharacterConfigManager {
  // Existing single-persona support (unchanged)
  String _activePersonaKey = 'ariWithOracle21';
  
  // New multi-persona support
  List<String> _selectedPersonas = ['ariWithOracle21'];
  
  // Backward compatibility methods
  String get activePersonaKey => _activePersonaKey;
  void setActivePersona(String personaKey) => setSelectedPersonas([personaKey]);
  
  // New multi-persona methods
  List<String> get selectedPersonas => List.unmodifiable(_selectedPersonas);
  String? get primaryPersonaKey => _selectedPersonas.isNotEmpty ? _selectedPersonas.first : null;
  String? get secondaryPersonaKey => _selectedPersonas.length > 1 ? _selectedPersonas[1] : null;
  bool get isMultiPersonaMode => _selectedPersonas.length > 1;
  
  void setSelectedPersonas(List<String> personaKeys) {
    _selectedPersonas = personaKeys;
    if (_selectedPersonas.isNotEmpty) {
      _activePersonaKey = _selectedPersonas.first; // Maintain compatibility
    }
  }
}
```

#### 2. Multi-Persona Response Coordinator
```dart
class MultiPersonaResponseCoordinator {
  final CharacterConfigManager _configManager;
  
  Future<ChatResponse> generateCoordinatedResponse({
    required String userMessage,
    required ConversationContext context,
  }) async {
    if (!_configManager.isMultiPersonaMode) {
      // Single persona mode - use existing logic
      return await _generateSinglePersonaResponse(userMessage, context);
    }
    
    // Multi-persona mode
    final primaryResponse = await _generatePrimaryResponse(userMessage, context);
    final secondaryInsights = await _generateSecondaryInsights(
      userMessage, 
      primaryResponse, 
      context
    );
    
    return _combineResponses(primaryResponse, secondaryInsights);
  }
  
  Future<ChatResponse> _generateSecondaryInsights(
    String userMessage,
    ChatResponse primaryResponse,
    ConversationContext context,
  ) async {
    final secondaryPersona = _configManager.secondaryPersonaKey;
    if (secondaryPersona == null) return ChatResponse.empty();
    
    // Generate insights based on conversation context and activity patterns
    return await _generatePersonaInsights(
      secondaryPersona,
      userMessage,
      primaryResponse,
      context
    );
  }
}
```

#### 3. Enhanced Persona Selection UI
```dart
class MultiPersonaSelectionScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMultiPersonaMode ? 'Choose Your Guides' : 'Choose Your Guide'),
        actions: [
          IconButton(
            icon: Icon(_isMultiPersonaMode ? Icons.people : Icons.person),
            onPressed: _toggleMode,
            tooltip: 'Toggle Multi-Persona Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode indicator
          if (_isMultiPersonaMode) _buildMultiPersonaModeIndicator(),
          
          // Persona selection
          Expanded(child: _buildPersonaSelection()),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }
}
```

### Data Flow

#### Single Persona Mode (Existing)
```
User Message → Primary Persona → Response → Display
```

#### Multi-Persona Mode (New)
```
User Message → Primary Persona → Main Response
                ↓
            Secondary Persona → Insights & Observations
                ↓
            Response Coordinator → Combined Response → Display
```

### Token Allocation Strategy
- **Primary Persona**: 80% of response tokens
- **Secondary Persona**: 20% of response tokens
- **Dynamic Adjustment**: Based on context importance and response complexity

## User Interface Design

### Persona Selection Interface

#### 1. Selection Cards
- **Checkbox Selection**: Replace radio buttons with checkboxes
- **Role Indicators**: Clear visual distinction between primary and secondary
- **Reorder Handles**: Drag-and-drop for changing persona order
- **Status Display**: Show current role and selection state

#### 2. Visual Role Indicators
```dart
class PersonaRoleIndicator extends StatelessWidget {
  final int index;
  final bool isSelected;
  
  @override
  Widget build(BuildContext context) {
    if (!isSelected) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: index == 0 ? Colors.blue : Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            index == 0 ? Icons.star : Icons.visibility,
            color: Colors.white,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            index == 0 ? 'Primary' : 'Secondary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 3. Mode Toggle
- **Single Persona Icon**: Person icon for single mode
- **Multi-Persona Icon**: People icon for multi mode
- **Tooltip**: Clear explanation of current mode
- **Smooth Transition**: Animated switching between modes

### Chat Interface Enhancements

#### 1. Response Attribution
- **Primary Responses**: Standard chat bubble styling
- **Secondary Insights**: Indented, smaller, with distinct styling
- **Collaborative Responses**: Special formatting for joint insights
- **Persona Indicators**: Clear labels showing who's speaking

#### 2. Activity Tracking Display
- **Enhanced Stats**: Secondary persona provides additional insights
- **Pattern Recognition**: Cross-persona observations about user behavior
- **Proactive Suggestions**: Recommendations based on combined analysis

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- Extend `CharacterConfigManager` for multi-persona support
- Update `ConfigLoader` with backward compatibility
- Basic multi-selection UI with checkboxes
- Core data structure changes

### Phase 2: Enhanced UI (Week 3-4)
- Drag-and-drop reordering interface
- Role indicators (Primary/Secondary)
- Mode toggle between single/multi
- Visual refinements and animations

### Phase 3: Response Coordination (Week 5-6)
- Basic response combination logic
- Token allocation (80/20 split)
- Conversation flow management
- Response attribution system

### Phase 4: Advanced Features (Week 7-8)
- Active observation system
- Enhanced activity tracking
- Pattern recognition algorithms
- Performance optimization

## Conversation Examples

### Example 1: Work Session Planning
```
User: "I need to plan my work week ahead"

Primary (Ari): "Great! Let's create a balanced week plan. 
What are your main priorities?"

Secondary (Sergeant Oracle): [Interjecting] "Based on your recent patterns, 
you're most productive in morning sessions (T8 activities peak at 9-11 AM). 
Consider scheduling your most challenging tasks then. Also, I notice you've 
been skipping SF12 exercises - maybe integrate them into your morning routine?"

Primary (Ari): "Excellent observation! Let's build on that..."
```

### Example 2: Activity Recognition
```
User: "I'm feeling tired today"

Primary (Ari): "It's okay to feel tired. Let's adjust our plans."

Secondary (I-There): [Observing] "I see you've completed 8 T8 sessions today 
- that's above your daily average. The fatigue might be from mental exertion. 
Consider switching to SF18 (movement) or SM8 (breaks) activities for the 
next hour to rebalance your energy."
```

### Example 3: Goal Setting
```
User: "I want to improve my fitness routine"

Primary (Sergeant Oracle): "Let's create a structured fitness plan! 
What's your current fitness level?"

Secondary (Ari): [Insight] "Looking at your activity patterns, you're 
consistently active in the evenings but struggle with morning routines. 
Maybe we can design a plan that builds on your evening energy while 
gradually introducing morning habits."
```

## Testing Strategy

### Unit Tests
- **CharacterConfigManager**: Multi-persona selection and role assignment
- **Response Coordinator**: Response combination and token allocation
- **UI Components**: Selection, reordering, and role indicators

### Integration Tests
- **Persona Switching**: Single to multi-persona mode transitions
- **Response Generation**: Coordinated responses from multiple personas
- **Activity Tracking**: Enhanced tracking with secondary persona insights

### User Acceptance Tests
- **Mode Switching**: Intuitive transition between single and multi modes
- **Persona Selection**: Easy addition/removal/reordering of personas
- **Response Quality**: Coherent and valuable multi-persona interactions

## Success Metrics

### User Engagement
- **Adoption Rate**: Percentage of users who try multi-persona mode
- **Retention Rate**: Users who continue using multi-persona after initial trial
- **Session Length**: Average conversation duration with multi-persona

### Response Quality
- **User Satisfaction**: Ratings for multi-persona responses vs single-persona
- **Insight Value**: User feedback on secondary persona contributions
- **Conversation Coherence**: Natural flow of multi-persona interactions

### Technical Performance
- **Response Time**: Maintain sub-2 second response generation
- **Memory Usage**: Efficient handling of multiple persona contexts
- **Error Rate**: Minimal failures in multi-persona coordination

## Risk Assessment

### Technical Risks
- **Response Coordination Complexity**: Risk of disjointed or confusing responses
- **Performance Impact**: Multiple persona processing could slow response times
- **Context Management**: Maintaining conversation coherence across personas

### Mitigation Strategies
- **Phased Implementation**: Start with simple coordination, gradually enhance
- **Performance Monitoring**: Continuous monitoring and optimization
- **User Testing**: Extensive testing with real users to refine coordination

### User Experience Risks
- **Confusion**: Users might find multi-persona overwhelming
- **Role Confusion**: Unclear distinction between primary and secondary personas
- **Response Quality**: Risk of lower quality compared to single-persona

### Mitigation Strategies
- **Clear Visual Indicators**: Distinct styling for different persona roles
- **Gradual Introduction**: Optional feature with clear onboarding
- **Quality Assurance**: Extensive testing and refinement of response coordination

## Future Enhancements

### Phase 2 Features
- **Dynamic Role Switching**: Automatic switching based on conversation context
- **Persona Learning**: Secondary personas learn from primary persona interactions
- **Advanced Coordination**: More sophisticated response combination algorithms

### Phase 3 Features
- **Persona Networks**: Support for more than 2 personas simultaneously
- **Contextual Activation**: Automatic persona activation based on conversation topics
- **Collaborative Problem Solving**: Multiple personas working together on complex tasks

### Long-term Vision
- **Persona Ecosystems**: Rich networks of specialized AI personas
- **Adaptive Coordination**: AI-driven optimization of persona combinations
- **Personalized Personas**: User-customized persona behaviors and interactions

## Dependencies

### Technical Dependencies
- **Existing Persona System**: Current persona selection and configuration
- **Chat Infrastructure**: Message handling and response generation
- **Activity Tracking**: FT-064 activity detection and storage
- **Stats Display**: FT-066 stats visualization for enhanced insights

### Integration Points
- **Persona Selection UI**: Extend existing selection screen
- **Response Generation**: Integrate with current chat system
- **Activity Memory**: Enhance with multi-persona observations
- **Configuration Management**: Extend persona configuration system

## Conclusion

The Multi-Persona Agentic Behavior system represents a significant evolution of the AI assistant experience, transforming it from a single-voice interaction to a collaborative, multi-perspective conversation. By leveraging the existing persona infrastructure and maintaining full backward compatibility, this feature provides users with enhanced insights, better activity tracking, and more engaging AI interactions.

The implementation approach prioritizes user experience, technical stability, and gradual adoption, ensuring that existing users can continue using the app while new users can explore the enhanced multi-persona capabilities. The 80/20 response ratio ensures that conversations remain coherent while providing valuable secondary insights and observations.

This feature positions the app as a leader in AI assistant technology, offering users a unique collaborative AI experience that goes beyond traditional single-persona interactions.
