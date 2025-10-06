# FT-183: Goal Checklist Analysis - Sleep Goal Example

**Feature ID**: FT-183  
**Related To**: FT-183 (Modular Goal-Aware Activity Board), FT-182 (Automated Goal Checklist)  
**Category**: Feature Analysis  
**Date**: October 2024

## Overview

Analysis of the automated goal checklist system using a real sleep improvement goal (ODM1 "Dormir melhor") as a concrete example to demonstrate the complete goal-aware workflow.

## Sleep Goal Example Analysis

### Goal Creation Context
```
User: "Quero melhorar meu sono"
Persona Response: "sim! 🪞 acabei de registrar seu objetivo de dormir melhor. começamos hoje, 4 de outubro, às 19h30.

vamos trabalhar juntos naqueles 3 hábitos básicos que conversamos:
- horário fixo de dormir e acordar (23h - 7h)
- 30 minutos sem telas antes de dormir
- ambiente do quarto preparado

inclusive, já vou te lembrar às 22h30 pra começar seu ritual do sono. tô aqui pra te ajudar a conquistar noites de sono muito melhores! 🪞"
```

## Goals Tab Display Implementation

```
┌─────────────────────────────────────┐
│ 🌙 Dormir melhor                    │
│ Progress: 67% today ████████░░░     │
├─────────────────────────────────────┤
│ Daily Habits:                       │
│ ✅ Horário fixo (23h-7h) ← auto     │
│ ✅ 30 min sem telas ← auto          │
│ ✅ Ambiente preparado ← confirmed   │
│                                     │
│ Coach Support:                      │
│ ✅ Lembrete 22h30 configurado       │
│ ⏳ Verificação diária ativa         │
│ ☐ Review semanal (domingo)          │
│                                     │
│ 📈 Streak: 2 dias consecutivos      │
└─────────────────────────────────────┘
```

## Technical Implementation Analysis

### Goal Structure
```dart
GoalModel {
  objectiveCode: "ODM1", // Oracle objective "Dormir melhor"
  objectiveName: "Dormir melhor",
  createdAt: DateTime(2024, 10, 4, 19, 30),
  isActive: true,
}
```

### Generated Checklist Components

#### User Tasks (Oracle Activities)
```dart
List<GoalChecklistItem> userTasks = [
  GoalChecklistItem(
    title: "Horário fixo de dormir e acordar (23h - 7h)",
    ownership: TaskOwnership.user,
    type: TaskType.daily,
    oracleActivityCode: "SF10", // Sleep schedule from Oracle
    autoCompletable: false, // Requires user reporting
    targetSchedule: "23:00 - 07:00",
  ),
  
  GoalChecklistItem(
    title: "30 minutos sem telas antes de dormir", 
    ownership: TaskOwnership.user,
    type: TaskType.daily,
    oracleActivityCode: "TT1", // Screen time control
    autoCompletable: true, // Could be detected via digital wellness
    targetTime: "22:30 - 23:00",
  ),
  
  GoalChecklistItem(
    title: "Ambiente do quarto preparado",
    ownership: TaskOwnership.user, 
    type: TaskType.daily,
    oracleActivityCode: "SF11", // Sleep environment
    autoCompletable: false, // Requires user confirmation
    description: "Quarto escuro, temperatura adequada, silencioso",
  ),
];
```

#### Coach Tasks (Persona Responsibilities)
```dart
List<GoalChecklistItem> coachTasks = [
  GoalChecklistItem(
    title: "Lembrete diário às 22h30 para ritual do sono",
    ownership: TaskOwnership.coach,
    type: TaskType.daily,
    coachTaskType: CoachTaskType.createReminder,
    scheduledTime: TimeOfDay(22, 30),
    reminderText: "🌙 Hora do ritual do sono! 30 min sem telas e preparar o ambiente.",
    isCompleted: true, // ✅ Already set up
  ),
  
  GoalChecklistItem(
    title: "Acompanhamento semanal do progresso do sono",
    ownership: TaskOwnership.coach,
    type: TaskType.weekly,
    coachTaskType: CoachTaskType.weeklyReview,
    scheduledDay: DayOfWeek.sunday,
    isCompleted: false, // Pending first review
  ),
  
  GoalChecklistItem(
    title: "Verificação diária se usuário seguiu rotina",
    ownership: TaskOwnership.coach,
    type: TaskType.daily,
    coachTaskType: CoachTaskType.dailyCheck,
    expectedActivities: ["SF10", "TT1", "SF11"],
    isCompleted: false, // Ongoing responsibility
  ),
];
```

## User Flow Analysis

### Day 1 - Goal Creation
```
User: "Quero melhorar meu sono"
Persona: [Creates ODM1 + generates checklist automatically]
Persona: "Registrei seu objetivo! Vamos trabalhar com 3 hábitos básicos..."
System: ✅ Goal created with structured checklist
```

### Day 1 - Evening (22:30)
```
System: [Coach task executes - reminder]
Persona: "🌙 Hora do ritual do sono! 30 min sem telas e preparar o ambiente."
```

### Day 2 - Morning Check
```
User: "Dormi às 23h15 ontem e acordei às 7h hoje"
FT-181: Detects sleep-related activity
System: ✅ Auto-updates "Horário fixo" checklist item
Persona: "Ótimo! Conseguiu manter o horário. Como foi a qualidade do sono?"
```

### Day 2 - Evening Report
```
User: "Desliguei as telas às 22h45 e arrumei o quarto"
System: ✅ "30 min sem telas" - auto-completed
System: ✅ "Ambiente preparado" - user confirmed
Persona: "Perfeito! 3/3 hábitos do sono hoje. Continue assim! 🌙"
```

## Key Implementation Components

### Oracle Framework Compliance
```dart
// ODM1 "Dormir melhor" maps to specific Oracle activities
final odmActivities = OracleGoalsMapping.getActivities("ODM1");
// Returns: ["SF1", "SF10", "SF11", "SF12", "TT1", ...]

// Persona selects most relevant 3-5 activities for user
final selectedActivities = PersonaActivitySelector.selectForGoal("ODM1", context: userPreferences);
```

### Automatic Checklist Generation
```dart
class GoalChecklistGenerator {
  static List<GoalChecklistItem> generateForGoal(GoalModel goal) {
    final oracleActivities = OracleGoalsMapping.getActivities(goal.objectiveCode);
    final userTasks = _generateUserTasks(oracleActivities);
    final coachTasks = _generateCoachTasks(goal);
    
    return [...userTasks, ...coachTasks];
  }
}
```

### Smart Activity Detection
```dart
// User: "Dormi às 23h15 ontem"
// FT-181 Enhancement:
class GoalAwareActivityDetector {
  static Future<List<EnhancedActivityDetection>> detectWithGoalContext(String message) {
    final detections = await StandardActivityDetector.detect(message);
    
    // Enhance with goal context
    for (final detection in detections) {
      final relatedGoals = await GoalActivityMapper.getGoalsForActivity(detection.oracleCode);
      detection.relatedGoals = relatedGoals;
      detection.isGoalRelated = relatedGoals.isNotEmpty;
    }
    
    return detections;
  }
}
```

## System Integration Points

### 1. Natural Goal Creation
- Persona creates structured goal from conversation
- Automatic checklist generation based on Oracle framework
- Immediate coaching setup (reminders, check-ins)

### 2. Oracle Compliance
- Uses real Oracle activities (SF10, SF11, TT1)
- Maintains framework integrity and methodology
- Enables cross-goal insights and patterns

### 3. Automated Progress Tracking
- Combines auto-detection + user confirmation
- Real-time checklist updates
- Streak tracking and progress visualization

### 4. Proactive Coaching
- Scheduled reminders based on goal requirements
- Daily progress checks and encouragement
- Weekly reviews and plan adjustments

### 5. Contextual Guidance
- Goal-specific activity suggestions
- Progress-aware coaching responses
- Celebration of achievements and milestones

## Success Metrics

This example demonstrates the complete integration of:
- ✅ **Natural Goal Creation**: From conversation to structured goal
- ✅ **Oracle Compliance**: Real framework activities (SF10, SF11, TT1)
- ✅ **Automated Checklist**: User + coach tasks generated automatically
- ✅ **Proactive Coaching**: Reminders and check-ins set up immediately
- ✅ **Progress Tracking**: Auto-detection + user confirmation combined
- ✅ **Contextual Guidance**: Specific, actionable, goal-aware advice

## Conclusion

This sleep goal example perfectly illustrates how FT-183 transforms the persona from a conversational AI into a true **goal-aware coach**. The system provides:

1. **Intelligent Structure**: Converts natural conversation into actionable checklists
2. **Maximum Automation**: Reduces manual tracking through smart detection
3. **Proactive Support**: Anticipates user needs with reminders and check-ins
4. **Oracle Compliance**: Maintains scientific framework integrity
5. **Natural Experience**: Feels supportive rather than mechanical

The result is a coaching experience that combines the warmth of human interaction with the precision of systematic goal management.
