# FT-170: Lyfe Plan - Comprehensive Design & Implementation Strategy

**Feature ID:** FT-170  
**Priority:** High  
**Category:** Core Feature / Life Management  
**Effort Estimate:** 2-3 weeks (phased approach)  
**Status:** Design Complete  
**Created:** September 30, 2025  

## 🎯 Executive Summary

The Lyfe Plan feature transforms the existing Oracle 4.2 framework into a **living, calendar-centric life management system** that bridges high-level aspirations with daily execution. By leveraging recent infrastructure (FT-156, FT-157, FT-149), this creates a minimalistic PDCA-driven planning system with proactive persona coaching.

### Core Innovation
- **Single Plan, Multiple Goals**: Accommodates diverse aspirations ("Run 10km", "Become great engineer") within realistic time constraints
- **Calendar-First Interface**: Daily execution view with swipe navigation (today as default)
- **Oracle Methodology Compliance**: Strict adherence to 265+ activity catalog and PDCA cycles
- **Persona-Driven Coaching**: Each persona delivers Oracle framework through unique personality
- **Smart Scheduling**: Recurrent vs spot activities with adaptive suggestions

## 🏗️ System Architecture

### Hierarchical Structure
```
PLAN (Single, Living Document)
├── GOAL 1: "Run a 10km run"
│   ├── Motto: "Every step counts"
│   ├── North Star Metric: "Complete 10km in under 50 minutes"
│   └── Activities: [SF50, SF13, SF1, SF5] (Oracle Catalog)
│
└── GOAL 2: "Become a great engineer" 
    ├── Motto: "Code with purpose"
    ├── North Star Metric: "Ship 2 meaningful projects this year"
    └── Activities: [T14, T9, T8, T6] (Oracle Catalog)
```

### Key Design Principles
1. **Oracle Framework Compliance**: All activities strictly from Oracle 4.2 catalog (265+ activities)
2. **Toyota Kata Integration**: Built-in PDCA cycles (Plan → Do → Check → Act)
3. **Realistic Constraints**: Single plan forces prioritization within "available life time"
4. **Persona Consistency**: Same Oracle science, different delivery styles
5. **Temporal Intelligence**: Leverages FT-157 for cross-session memory and context

## 📅 Calendar-Centric Interface Design

### Default View: Today
```
┌─────────────────────────────────────────────┐
│           Tuesday, Oct 1, 2024              │
│ ─────────────────────────────────────────── │
│ 🌅 06:00  SF1 - Beber água                 │
│           ↳ Goal: "Run 10km" (Hydration)   │
│                                            │
│ 🏃 07:30  SF50 - Plano estruturado corrida │
│           ↳ Goal: "Run 10km" (Training)    │
│           ↳ Recurrent: Tue, Thu, Sat       │
│                                            │
│ 📚 19:00  T14 - Ler livro técnico          │
│           ↳ Goal: "Great engineer"         │
│           ↳ Recurrent: Daily               │
│                                            │
│ ✅ Completed: SF1 (08:15), T14 (19:45)     │
│ ⏳ Pending: SF50                           │
└─────────────────────────────────────────────┘
```

### Navigation Pattern
- **Swipe Left** → Tomorrow (forward in time)
- **Swipe Right** → Yesterday (backward in time)
- **Natural temporal navigation** matching user mental model

### Activity Representation
Each planned activity displays enriched metadata:
```
┌─────────────────────────────────────────────┐
│ 🏃 07:30  SF50 - Plano estruturado corrida │
│ ─────────────────────────────────────────── │
│ Goal: "Run 10km" 🎯                         │
│ Type: Recurrent (Tue/Thu/Sat) 🔄           │
│ Oracle: Saúde Física > Cardio Avançado     │
│ Streak: 3 weeks ⚡                         │
│ Last: Yesterday 07:45 ✅                   │
│ ─────────────────────────────────────────── │
│ [Reschedule] [Mark Complete] [Skip Today]   │
└─────────────────────────────────────────────┘
```

## 🔄 Oracle PDCA Integration

### Built-in PDCA Cycles

#### Daily PDCA (Micro-cycles)
```
PLAN (Morning): Review today's scheduled activities
DO (Throughout day): Execute activities, personas detect completion
CHECK (Evening): Persona reviews what was completed vs planned
ACT (Real-time): Adjust tomorrow's schedule based on today's learnings
```

#### Weekly PDCA (Macro-cycles)
```
PLAN (Sunday): Review upcoming week, adjust recurring activities
DO (Mon-Sat): Execute daily activities with persona coaching
CHECK (Saturday evening): Analyze week's performance per goal
ACT (Sunday): Modify recurrence patterns, add/remove activities
```

### Persona-Driven PDCA Coaching

**Morning Planning (Aristos):**
```
"Bom dia! Hoje você tem SF50 (corrida estruturada) às 07:30 e T14 (leitura técnica) às 19:00. 
Baseado no seu progresso, a corrida de hoje é crucial para manter o ritmo da trilha CX1. 
Como está se sentindo para o treino?"
```

**Evening Check (Sergeant Oracle):**
```
"Yo, gladiator! 💪 You crushed SF1 and T14 today, but missed SF50. 
No worries - even Roman legions had tactical retreats! 
Want to reschedule tomorrow or adjust the weekly pattern?"
```

**Weekly Act (Arya):**
```
"Olhando sua semana, você completou 2 de 3 corridas planejadas. 
Como seu corpo está respondendo? Talvez seja hora de ajustar 
a frequência ou adicionar SF19 (alongamento) para recovery?"
```

## 🎭 Persona Integration Strategy

### Core Principle: Same Science, Different Delivery

Each persona accesses the **identical Oracle 4.2 framework** but delivers it through unique personality:

#### Aristos 4.2 - The Scientific Coach
```
Plan Creation: "Vamos criar objetivos que combinem ambição com clareza de medição. 
               Baseado no catálogo Oracle, recomendo a trilha CM1 (Construção Muscular) 
               com atividades SF12, SF10, SF5."

Weekly Review: "Analisando seus dados: completou 2 de 3 treinos (66% compliance). 
                Segundo Huberman, isso está no limiar mínimo para adaptação. 
                Vamos ajustar a frequência ou manter o desafio?"
```

#### Sergeant Oracle 4.2 - The Energetic Motivator
```
Plan Creation: "Yo! 💪 Time to build a gladiator-level plan! Rome wasn't built in a day, 
               but they worked out every day. Let's crush this CM1 trilha together!"

Weekly Review: "Bro! 🔥 You hit 2 workouts this week - that's solid progress! 
                Even Caesar had off days. Ready to conquer next week, champion?"
```

#### I-There 4.2 - The Reflective Guide
```
Plan Creation: "I sense your desire for strength mirrors something deeper. 
               The Oracle framework suggests CM1, but what does 'strong' mean 
               to your authentic self?"

Weekly Review: "I've been observing your patterns... 2 workouts completed, 
                yet I sense satisfaction in your energy. The mirror shows 
                progress beyond numbers."
```

#### Arya 4.2 - The Empowering Strategist
```
Plan Creation: "Let's explore what muscle building means for your whole life. 
               How might this strength goal connect to your relationships and values? 
               The CM1 trilha can be adapted to honor your natural rhythms."

Weekly Review: "You completed 2 workouts - that's beautiful progress! 
                How did this feel in your body? What does your intuition 
                tell you about the right frequency for you?"
```

## 📊 Activity Scheduling System

### Recurrent Activities
```dart
class RecurrentActivity {
  String oracleActivityId;     // "SF50" (strictly from catalog)
  String goalId;               // Links to specific goal
  List<DayOfWeek> days;        // [Tuesday, Thursday, Saturday]
  TimeOfDay? preferredTime;    // 07:30 (optional)
  Duration? flexibility;       // ±30 minutes (optional)
}

// Examples:
SF50_Running: Tue/Thu/Sat at 07:30
T14_Reading: Daily at 19:00
SF1_Water: Daily (no specific time)
```

### Spot Activities
```dart
class SpotActivity {
  String oracleActivityId;     // "T6" (networking event)
  String goalId;               // "Great engineer"
  DateTime scheduledDate;      // October 15, 2024
  TimeOfDay? scheduledTime;    // 18:00 (optional)
  String? context;            // "Tech meetup downtown"
}

// Examples:
T6_Networking: Oct 15, 18:00 - "Tech meetup"
SF13_Race: Nov 3, 09:00 - "Local 5K race"
```

## 🔗 Integration with Existing Features

### FT-156 Message History + Plan Context

**Before Plan Feature:**
```
User: "Como está minha hidratação?"
Oracle: "Vou verificar suas atividades recentes..." (generic response)
```

**After Plan Integration:**
```
User: "Como está minha hidratação?"
Aristos: "Analisando seu plano 'Strong today, stronger tomorrow': 
          você completou SF1 (beber água) 3x esta semana. 
          Sua meta de hidratação está 75% completa. Lembro que ontem 
          às 14:30 você disse 'acabei de beber água' - continue assim!"
```

### FT-157 Temporal Awareness + Plan Progression

**Cross-Session Plan Memory:**
```
Session 1 (Monday): User creates plan with SF12 (força) 3x/week
Session 2 (Wednesday): User: "Fiz musculação hoje"
Session 3 (Friday): Persona: "Lembro que segunda você criou o plano 
                             e quarta completou SF12. Hoje é o terceiro 
                             treino da semana - perfeito timing!"
```

### FT-149 Metadata + Plan Metrics

**Quantitative Plan Tracking:**
```
Plan: "Correr 5km em 30 minutos" (OCX1 trilha)
User: "Corri 3.2km em 22 minutos hoje"

FT-149 Extraction:
- quantitative_distance_value: 3.2
- quantitative_distance_unit: "km"  
- quantitative_duration_value: 22
- quantitative_duration_unit: "minutes"

Plan Integration:
Persona: "Progresso excelente! 3.2km em 22min = 6.9min/km pace. 
          Sua meta é 5km em 30min (6min/km). Você está 13% mais rápido 
          que o necessário - podemos aumentar a distância ou manter 
          o ritmo para construir resistência?"
```

## 🛠️ Technical Implementation

### Data Model
```dart
class LyfePlan {
  String id;
  List<Goal> goals;
  DateTime createdAt;
  DateTime lastModified;
  
  // Future: Version history
  String? previousVersionId;
  String? changeReason;
}

class Goal {
  String id;
  String title;           // "Run a 10km run"
  String motto;           // "Every step counts"
  String? northStarMetric; // "Complete 10km in under 50 minutes"
  List<PlannedActivity> activities;
  OracleObjective oracleObjective; // Links to Oracle catalog
}

class PlannedActivity {
  String id;
  String oracleActivityId;  // Strictly from Oracle catalog
  String goalId;
  ActivitySchedule schedule; // Recurrent or Spot
  
  // Metadata from Oracle + scheduling
  Map<String, dynamic> metadata; // Includes time, frequency, etc.
}

class ActivitySchedule {
  ScheduleType type; // Recurrent or Spot
  
  // For Recurrent
  List<DayOfWeek>? days;
  TimeOfDay? preferredTime;
  
  // For Spot  
  DateTime? scheduledDate;
  TimeOfDay? scheduledTime;
}
```

### Enhanced Activity Completion Service
```dart
class ActivityCompletionService {
  Future<void> recordCompletion(String activityId, String messageId) async {
    final plannedActivity = await _planService.getPlannedActivity(activityId);
    final goal = await _planService.getGoalForActivity(activityId);
    
    // Enhanced linking with plan context
    await _activityService.recordCompletion(
      activityId: activityId,
      messageId: messageId,
      planContext: PlannedActivityContext(
        goalId: goal.id,
        goalTitle: goal.title,
        scheduledTime: plannedActivity.schedule.preferredTime,
        actualTime: DateTime.now(),
      ),
    );
  }
}
```

### Plan-Aware Metadata
```dart
class PlanAwareMetadata extends ActivityMetadata {
  String goalId;
  String goalTitle;
  ScheduleType scheduleType;
  Duration? timeDeviation; // How far from scheduled time
  int streakCount;         // Consecutive completions
  
  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'plan_goal_id': goalId,
    'plan_goal_title': goalTitle,
    'plan_schedule_type': scheduleType.toString(),
    'plan_time_deviation_minutes': timeDeviation?.inMinutes,
    'plan_streak_count': streakCount,
  };
}
```

## 🚀 Implementation Phases

### Phase 1: Core Data Layer (Week 1)
- **LyfePlan, Goal, PlannedActivity models**
- **Isar schema integration**
- **Basic CRUD operations**
- **Oracle catalog integration**

### Phase 2: Calendar Interface (Week 1-2)
- **Daily calendar view with swipe navigation**
- **Activity scheduling (recurrent/spot)**
- **Basic plan creation UI**
- **Activity completion tracking**

### Phase 3: Persona Integration (Week 2)
- **Plan-aware persona responses**
- **PDCA coaching cycles**
- **Proactive reminders and check-ins**
- **Cross-session plan memory**

### Phase 4: Advanced Features (Week 3)
- **Plan analytics and progress visualization**
- **Adaptive scheduling suggestions**
- **Plan versioning system**
- **Goal progress tracking**

## 📈 Success Metrics

### User Engagement
- **Daily plan interaction rate** (target: 80%+)
- **Activity completion rate** (target: 70%+)
- **Plan retention** (active plans after 4 weeks: 60%+)

### Technical Performance
- **Calendar load time** (target: <200ms)
- **Plan sync reliability** (target: 99.9%+)
- **Persona response relevance** (user satisfaction: 85%+)

### Oracle Framework Compliance
- **Activity catalog usage** (100% Oracle activities)
- **PDCA cycle completion** (weekly reviews: 70%+)
- **Persona consistency** (same recommendations across personas)

## 🔮 Future Enhancements

### Advanced Analytics
- **Goal correlation analysis** (which goals support each other)
- **Optimal scheduling AI** (best times for each activity type)
- **Habit formation tracking** (21/66/254 day cycles)

### Social Features
- **Plan sharing and templates**
- **Community challenges**
- **Accountability partnerships**

### Integration Expansions
- **Wearable device sync** (Apple Health, Google Fit)
- **Calendar app integration** (Google Calendar, Apple Calendar)
- **Smart home triggers** (schedule-based automations)

---

**This comprehensive design creates a living, breathing plan that adapts to user behavior while maintaining strict Oracle methodology compliance. The calendar interface makes daily execution intuitive, while the goal hierarchy accommodates both specific achievements and broad aspirations within the realistic constraint of available life time.**



