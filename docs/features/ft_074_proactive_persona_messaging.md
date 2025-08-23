# FT-074 Proactive Persona Messaging

**Feature ID**: FT-074  
**Priority**: High  
**Category**: AI/Persona Management  
**Effort Estimate**: 3-4 weeks  
**Dependencies**: FT-073 (Multi-Persona Agentic Behavior), Oracle Framework integration  
**Status**: Specification  

## Overview

Transform AI personas from reactive responders to proactive companions that initiate conversations, send wellness reminders, and provide contextual support without waiting for user input. This system enables personas to act as caring life coaches, sending timely messages based on user patterns, goals, and the Oracle framework's activity tracking system.

## User Story

As a user who wants consistent support and accountability, I want my AI personas to proactively reach out with relevant messages, reminders, and insights, so that I feel supported throughout my day and stay on track with my goals without having to constantly initiate conversations.

## Problem Statement

**Current Limitations:**
- **Reactive Only**: AI personas only respond when users initiate conversations
- **Missed Opportunities**: No proactive support during critical moments
- **Inconsistent Engagement**: Users must remember to check in for support
- **Limited Accountability**: No external prompts to maintain momentum

**User Pain Points:**
- Forgetting to check in with AI for support
- Missing optimal timing for habit formation
- Lack of consistent accountability and encouragement
- No proactive wellness or goal reminders

## Solution: Autonomous Proactive Messaging

### Core Concept
- **Autonomous Initiation**: Personas send messages without user prompting
- **Contextual Timing**: Messages based on time, user patterns, and goals
- **Oracle Integration**: Leverage activity tracking data for personalized insights
- **Multi-Persona Coordination**: Different personas handle different types of proactive outreach

### Message Types
1. **Wellness Reminders**: Hydration, movement, breaks, sleep
2. **Goal Check-ins**: Progress updates, milestone celebrations, next steps
3. **Pattern Insights**: Behavioral observations and suggestions
4. **Emotional Support**: Check-ins during difficult times
5. **Habit Formation**: Gentle nudges for new routines

## Functional Requirements

### Message Generation & Scheduling
- **FR-074-01**: Generate proactive messages based on user patterns and goals
- **FR-074-02**: Schedule messages at optimal times for user engagement
- **FR-074-03**: Adapt message frequency based on user response patterns
- **FR-074-04**: Support multiple message types (reminders, insights, celebrations)
- **FR-074-05**: Generate contextually relevant content using Oracle framework data

### Oracle Framework Integration
- **FR-074-06**: Access real-time activity tracking data for personalized insights
- **FR-074-07**: Reference user's current trail progress and level
- **FR-074-08**: Provide proactive support based on pillar scores (Energy, Skills, Connection)
- **FR-074-09**: Suggest next steps in user's current trail progression
- **FR-074-10**: Celebrate achievements and milestones automatically

### Multi-Persona Coordination
- **FR-074-11**: Primary persona handles main proactive outreach
- **FR-074-12**: Secondary persona provides specialized insights and observations
- **FR-074-13**: Coordinate proactive messages to avoid duplication
- **FR-074-14**: Maintain persona-specific voice and style in proactive messages
- **FR-074-15**: Support both single and multi-persona proactive modes

### User Control & Preferences
- **FR-074-16**: Allow users to enable/disable proactive messaging
- **FR-074-17**: Configure preferred message types and frequency
- **FR-074-18**: Set quiet hours and do-not-disturb periods
- **FR-074-19**: Provide feedback on message relevance and timing
- **FR-074-20**: Support gradual onboarding of proactive features

## Non-Functional Requirements

### Performance
- **NFR-074-01**: Proactive message generation completes within 500ms
- **NFR-074-02**: Support up to 10 proactive messages per user per day
- **NFR-074-03**: Maintain app performance during proactive message processing
- **NFR-074-04**: Efficient database queries for Oracle framework data

### Reliability
- **NFR-074-05**: 99.9% uptime for proactive message generation
- **NFR-074-06**: Graceful fallback if Oracle framework is unavailable
- **NFR-074-07**: Message queuing system for offline users
- **NFR-074-08**: Retry mechanism for failed message deliveries

### Privacy & Ethics
- **NFR-074-09**: User consent required for proactive messaging
- **NFR-074-10**: Transparent data usage for message personalization
- **NFR-074-11**: No proactive messages during user-defined quiet hours
- **NFR-074-12**: Respect user boundaries and communication preferences

## Technical Specifications

### Architecture Components

#### 1. Proactive Message Engine
```dart
class ProactiveMessageEngine {
  final OracleFrameworkService _oracleService;
  final UserPreferencesService _preferencesService;
  final MultiPersonaCoordinator _personaCoordinator;
  
  Future<List<ProactiveMessage>> generateDailyMessages(String userId) async {
    final userData = await _oracleService.getUserData(userId);
    final preferences = await _preferencesService.getProactivePreferences(userId);
    
    if (!preferences.enabled) return [];
    
    final messages = <ProactiveMessage>[];
    
    // Generate wellness reminders
    messages.addAll(await _generateWellnessReminders(userData, preferences));
    
    // Generate goal check-ins
    messages.addAll(await _generateGoalCheckins(userData, preferences));
    
    // Generate pattern insights
    messages.addAll(await _generatePatternInsights(userData, preferences));
    
    return messages;
  }
  
  Future<List<ProactiveMessage>> _generateWellnessReminders(
    UserData userData,
    ProactivePreferences preferences,
  ) async {
    final reminders = <ProactiveMessage>[];
    
    // Hydration reminder based on SF1 (water) activity
    if (preferences.wellnessReminders.hydration) {
      final lastWater = userData.getLastActivity('SF1');
      if (lastWater == null || _hoursSince(lastWater) > 3) {
        reminders.add(ProactiveMessage(
          type: MessageType.wellnessReminder,
          personaKey: userData.primaryPersonaKey,
          content: _generateHydrationReminder(userData),
          priority: MessagePriority.medium,
          scheduledFor: DateTime.now(),
        ));
      }
    }
    
    return reminders;
  }
}
```

#### 2. Message Scheduler
```dart
class ProactiveMessageScheduler {
  final ProactiveMessageEngine _messageEngine;
  final NotificationService _notificationService;
  
  Future<void> scheduleDailyMessages(String userId) async {
    final messages = await _messageEngine.generateDailyMessages(userId);
    
    for (final message in messages) {
      await _scheduleMessage(message);
    }
  }
  
  Future<void> _scheduleMessage(ProactiveMessage message) async {
    final scheduledTime = _calculateOptimalTime(message);
    
    await _notificationService.scheduleNotification(
      id: message.id,
      title: message.personaName,
      body: message.content,
      scheduledTime: scheduledTime,
      payload: {
        'messageId': message.id,
        'type': message.type.toString(),
        'personaKey': message.personaKey,
      },
    );
  }
  
  DateTime _calculateOptimalTime(ProactiveMessage message) {
    // Consider user's activity patterns, timezone, and preferences
    final userPatterns = _getUserActivityPatterns(message.userId);
    final optimalHour = _findOptimalHour(userPatterns, message.type);
    
    return DateTime.now().copyWith(
      hour: optimalHour,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
  }
}
```

#### 3. Oracle Framework Integration
```dart
class OracleFrameworkService {
  final ActivityMemoryService _activityService;
  final TrailProgressService _trailService;
  
  Future<UserData> getUserData(String userId) async {
    final activities = await _activityService.getEnhancedActivityStats(days: 7);
    final trailProgress = await _trailService.getCurrentTrail(userId);
    final pillarScores = await _calculatePillarScores(activities);
    
    return UserData(
      userId: userId,
      activities: activities,
      trailProgress: trailProgress,
      pillarScores: pillarScores,
      lastInteraction: await _getLastInteraction(userId),
    );
  }
  
  Future<Map<String, double>> _calculatePillarScores(
    Map<String, dynamic> activities,
  ) async {
    // Calculate Energy, Skills, and Connection pillar scores
    // based on Oracle framework activity dimensions
    return {
      'energy': _calculateEnergyScore(activities),
      'skills': _calculateSkillsScore(activities),
      'connection': _calculateConnectionScore(activities),
    };
  }
}
```

### Data Models

#### 1. Proactive Message
```dart
class ProactiveMessage {
  final String id;
  final MessageType type;
  final String personaKey;
  final String content;
  final MessagePriority priority;
  final DateTime scheduledFor;
  final DateTime? sentAt;
  final String? responseId;
  final Map<String, dynamic> metadata;
  
  const ProactiveMessage({
    required this.id,
    required this.type,
    required this.personaKey,
    required this.content,
    required this.priority,
    required this.scheduledFor,
    this.sentAt,
    this.responseId,
    this.metadata = const {},
  });
}

enum MessageType {
  wellnessReminder,
  goalCheckin,
  patternInsight,
  emotionalSupport,
  habitFormation,
  milestoneCelebration,
}

enum MessagePriority {
  low,
  medium,
  high,
  urgent,
}
```

#### 2. User Preferences
```dart
class ProactivePreferences {
  final bool enabled;
  final WellnessReminders wellnessReminders;
  final GoalCheckins goalCheckins;
  final PatternInsights patternInsights;
  final QuietHours quietHours;
  final int maxDailyMessages;
  
  const ProactivePreferences({
    required this.enabled,
    required this.wellnessReminders,
    required this.goalCheckins,
    required this.patternInsights,
    required this.quietHours,
    this.maxDailyMessages = 10,
  });
}

class WellnessReminders {
  final bool hydration;
  final bool movement;
  final bool breaks;
  final bool sleep;
  final bool nutrition;
  
  const WellnessReminders({
    this.hydration = true,
    this.movement = true,
    this.breaks = true,
    this.sleep = true,
    this.nutrition = true,
  });
}
```

## User Interface Design

### Settings & Preferences

#### 1. Proactive Messaging Toggle
- **Main Switch**: Enable/disable proactive messaging
- **Feature Breakdown**: Individual toggles for each message type
- **Frequency Control**: Slider for maximum daily messages (1-20)
- **Quiet Hours**: Time range picker for do-not-disturb periods

#### 2. Message Type Configuration
```dart
class ProactiveSettingsScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Proactive Messages')),
      body: ListView(
        children: [
          // Main toggle
          SwitchListTile(
            title: Text('Enable Proactive Messages'),
            subtitle: Text('AI personas will send you helpful messages'),
            value: _preferences.enabled,
            onChanged: _toggleProactiveMessaging,
          ),
          
          // Message type breakdown
          if (_preferences.enabled) ...[
            _buildWellnessRemindersSection(),
            _buildGoalCheckinsSection(),
            _buildPatternInsightsSection(),
            _buildQuietHoursSection(),
          ],
        ],
      ),
    );
  }
}
```

### Message Display

#### 1. Proactive Message Styling
- **Distinct Visual Design**: Different from regular chat messages
- **Persona Attribution**: Clear indication of which persona sent the message
- **Message Type Icons**: Visual cues for different message types
- **Quick Response Options**: Buttons for common responses

#### 2. Message Interaction
```dart
class ProactiveMessageWidget extends StatelessWidget {
  final ProactiveMessage message;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getMessageColor(message.type),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persona header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: _getPersonaAvatar(message.personaKey),
              ),
              SizedBox(width: 8),
              Text(
                _getPersonaName(message.personaKey),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              _getMessageTypeIcon(message.type),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Message content
          Text(
            message.content,
            style: TextStyle(fontSize: 16),
          ),
          
          SizedBox(height: 16),
          
          // Quick response buttons
          _buildQuickResponseButtons(message),
        ],
      ),
    );
  }
}
```

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- **Proactive Message Engine**: Core message generation logic
- **Oracle Framework Integration**: Access to activity and trail data
- **Basic Message Types**: Wellness reminders and goal check-ins
- **User Preferences**: Basic enable/disable functionality

### Phase 2: Scheduling & Delivery (Week 3-4)
- **Message Scheduler**: Timing and delivery system
- **Notification Service**: Push notifications for proactive messages
- **Optimal Timing**: Algorithm for best message timing
- **Message Queue**: Storage and delivery management

### Phase 3: Advanced Features (Week 5-6)
- **Pattern Recognition**: Behavioral insights and suggestions
- **Multi-Persona Coordination**: Different personas for different message types
- **User Feedback**: Response tracking and preference learning
- **Performance Optimization**: Efficient data processing and delivery

### Phase 4: Polish & Testing (Week 7-8)
- **UI Refinements**: Visual design and user experience
- **A/B Testing**: Message effectiveness and user engagement
- **Analytics**: Proactive message performance metrics
- **User Onboarding**: Gradual introduction of proactive features

## Message Examples

### Wellness Reminder (I-There)
```
🌅 Good morning! It's been 3 hours since your last water break. 
According to your SF1 (hydration) goal, you should have 2 glasses by now. 
How about a quick water break? 💧
```

### Goal Check-in (Ari)
```
📊 Weekly Progress Check: You're on track with your DM1PP trail! 
Completed 4/5 meditation sessions this week. 
Ready to try the next level challenge?
```

### Pattern Insight (Sergeant Oracle)
```
🔍 Pattern Observation: Your T8 (focused work) sessions peak at 9-11 AM. 
Consider scheduling your most challenging tasks during this window. 
Want to optimize your daily schedule?
```

### Milestone Celebration (I-There)
```
🎉 Congratulations! You've completed 7 consecutive days of SF1 (water) - 
that's your longest streak yet! 🌟 
Your Energy pillar is now at 8/10. Keep up the amazing work!
```

## Testing Strategy

### Unit Tests
- **Message Generation**: Test different message types and content
- **Scheduling Logic**: Verify optimal timing calculations
- **Oracle Integration**: Test data retrieval and processing
- **User Preferences**: Validate preference handling and constraints

### Integration Tests
- **End-to-End Flow**: Complete message generation to delivery
- **Multi-Persona Coordination**: Test persona-specific message handling
- **Notification Service**: Verify push notification delivery
- **User Response Tracking**: Test feedback and learning systems

### User Acceptance Tests
- **Message Relevance**: Users rate message helpfulness and timing
- **Preference Control**: Users can easily adjust settings
- **Engagement Metrics**: Measure response rates and user interaction
- **Boundary Respect**: Verify quiet hours and frequency limits

## Success Metrics

### User Engagement
- **Adoption Rate**: Percentage of users who enable proactive messaging
- **Response Rate**: Users who interact with proactive messages
- **Retention Impact**: Effect on overall app usage and engagement
- **Message Effectiveness**: User ratings and feedback scores

### Technical Performance
- **Message Generation Time**: Average time to create personalized messages
- **Delivery Success Rate**: Percentage of messages successfully delivered
- **System Performance**: App performance during proactive message processing
- **Data Processing Efficiency**: Oracle framework query performance

### User Experience
- **Message Relevance**: User satisfaction with message content and timing
- **Preference Satisfaction**: Alignment with user-configured preferences
- **Learning Effectiveness**: Improvement in message relevance over time
- **User Control**: Satisfaction with proactive messaging controls

## Risk Assessment

### Technical Risks
- **Performance Impact**: Proactive message generation could slow the app
- **Data Overload**: Too many messages could overwhelm users
- **Oracle Framework Dependencies**: Heavy reliance on external data sources
- **Message Quality**: Risk of irrelevant or poorly timed messages

### Mitigation Strategies
- **Performance Monitoring**: Continuous monitoring and optimization
- **User Control**: Comprehensive preference settings and frequency limits
- **Fallback Systems**: Graceful degradation if Oracle framework is unavailable
- **Quality Assurance**: Extensive testing and user feedback loops

### User Experience Risks
- **Message Fatigue**: Users might find proactive messages annoying
- **Privacy Concerns**: Users might worry about data usage for personalization
- **Timing Issues**: Messages might arrive at inconvenient times
- **Content Relevance**: Messages might not match user needs or preferences

### Mitigation Strategies
- **Gradual Onboarding**: Start with minimal proactive features
- **Transparent Controls**: Clear user control over all proactive features
- **Smart Timing**: Intelligent algorithms for optimal message timing
- **User Feedback**: Continuous learning and improvement based on user input

## Future Enhancements

### Phase 2 Features
- **Emotional Intelligence**: Detect user mood and provide appropriate support
- **Predictive Analytics**: Anticipate user needs before they arise
- **Social Integration**: Coordinate proactive support with human relationships
- **Voice Proactive Messages**: Audio-based proactive outreach

### Phase 3 Features
- **Cross-Platform Proactive**: Extend proactive messaging to other devices
- **Community Proactive**: Group-based proactive support and accountability
- **AI Learning**: Advanced personalization based on user interaction patterns
- **Proactive Coaching**: Structured proactive support for specific goals

### Long-term Vision
- **Proactive Life Partner**: AI that anticipates and supports all life aspects
- **Predictive Wellness**: Prevent issues before they arise
- **Emotional Intelligence**: Deep understanding of user emotional states
- **Holistic Support**: Integration with health, work, and relationship systems

## Dependencies

### Technical Dependencies
- **FT-073 Multi-Persona System**: Required for persona coordination
- **Oracle Framework**: Activity tracking and trail progression data
- **Notification Service**: Push notification infrastructure
- **User Preferences System**: Settings and configuration management

### Integration Points
- **Activity Memory Service**: Access to user activity data
- **Persona Configuration**: Persona-specific message generation
- **Chat System**: Integration with existing conversation flow
- **Analytics Platform**: Message effectiveness and user engagement tracking

## Conclusion

Proactive Persona Messaging represents a fundamental shift from reactive to proactive AI assistance, transforming personas from conversation partners to life coaches that actively support users throughout their day. By leveraging the Oracle framework's rich data and the multi-persona system's collaborative capabilities, this feature provides users with timely, relevant, and personalized support that helps them achieve their goals and maintain healthy habits.

The implementation approach prioritizes user control, message quality, and system performance, ensuring that proactive messaging enhances rather than detracts from the user experience. Through careful testing, user feedback, and continuous improvement, this feature can significantly increase user engagement and provide genuine value in users' daily lives.

This feature positions the app as a pioneer in proactive AI assistance, offering users a level of support and accountability that goes beyond traditional reactive chatbot interactions.

