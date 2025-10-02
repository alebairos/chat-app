# FT-174: Minimal Goals Tab - Oracle Guided

**Feature ID**: FT-174  
**Priority**: High  
**Category**: LLM-Driven Goal Management  
**Effort Estimate**: 2-3 hours (Minimal First Cut)  
**Depends On**: Oracle Framework, Activity Tracking System, MCP Infrastructure

## Overview

Implement a minimal first cut of LLM-driven goal management focusing on immediate user value: natural goal creation through conversation and basic visualization. This establishes the foundation for LLM goal management while proving the concept with minimal implementation effort.

## Problem Statement

**Immediate User Need**: 
Users want to set meaningful life goals through natural conversation and see them persisted somewhere, proving that the LLM understands and remembers their aspirations.

**Current Gap**: 
- No way to set goals conversationally with the LLM
- No persistent storage of user goals  
- No visual confirmation that goals were understood and saved

## Solution Architecture

### Core Principle: LLM-Driven Goal Management

**Intelligent Conversational Interface** - The LLM handles all goal operations:
```
User: "I want to lose weight"
Persona: "Great! I can help you create a weight loss goal. This involves activities like drinking water, eating protein, doing cardio, and tracking food. Should I create this goal for you?"
User: "Yes"
→ Goal created with Oracle objective OPP1 and associated activities
```

### Minimal First Cut Components

1. **Basic GoalModel**: Simple data storage for goals (30 minutes)
2. **Single MCP Function**: `create_goal` for LLM goal creation (45 minutes)  
3. **Simple Goals Tab**: Basic list view of created goals (60 minutes)
4. **Persona Integration**: Enable goal creation in conversations (30 minutes)

**Total Implementation**: 2-3 hours for immediate user value

## Functional Requirements (Minimal First Cut)

### FR-1: Basic Goal Creation

**FR-1.1**: LLM Goal Creation via Conversation
- User expresses intent ("I want to lose weight", "I need to be more productive")
- Persona identifies matching Oracle objective (OPP1, OSPM1, etc.)
- Persona creates goal via MCP command
- Goal stored in database with Oracle objective code

**FR-1.2**: Single MCP Function
```json
{"action": "create_goal", "objective_code": "OPP1", "objective_name": "Perder peso"}
```

### FR-2: Basic Goals Visualization

**FR-2.1**: Simple Goals List
- Shows created goals with names from Oracle framework
- Basic list view with goal names and creation dates
- Empty state with guidance to talk to persona

**FR-2.2**: No Progress Tracking (Future Enhancement)
- First cut focuses on goal creation and persistence
- Progress tracking to be added in next iteration
- Users see their goals are saved and remembered

### FR-3: Oracle Framework Compliance

**FR-3.1**: Use Existing Oracle Objectives
- Goals must map to existing 28 Oracle objectives (OPP1, OGM1, etc.)
- No custom goal creation in first cut
- Leverage existing Oracle framework structure

## Technical Requirements

### TR-1: Minimal Database Model

```dart
@collection
class GoalModel {
  Id id = Isar.autoIncrement;
  late String objectiveCode;    // "OPP1", "OGM1", etc.
  late String objectiveName;    // "Perder peso", "Ganhar massa"
  late DateTime createdAt;
  bool isActive = true;
}
```

### TR-2: Single MCP Function

**TR-2.1**: Goal Creation Only
```dart
case 'create_goal':
  // Parse objective_code and objective_name from command
  // Create GoalModel in Isar database
  // Return success/error response
```

### TR-3: Basic Oracle Integration

**TR-3.1**: Use Oracle Objective Names
- Use `oracle_prompt_4.2.json` for objective definitions
- Store objective code and name only
- No activity association in first cut

## UI/UX Requirements

### UX-1: Minimal Interface Design

**UX-1.1**: Basic Goals Tab
- Bottom navigation tab labeled "Goals"
- Simple ListView of goals
- Each item shows: goal name and creation date only

**UX-1.2**: Simple Goal Items
```
┌─────────────────────────────────┐
│ 🏃 Perder peso                  │
│ Created: 2 days ago             │
└─────────────────────────────────┘
```

**UX-1.3**: Empty State
- Message: "Talk to your persona about your goals and aspirations"
- Subtitle: "Your AI assistant can help you set meaningful objectives"
- No buttons - emphasizes conversation

### UX-2: No Detail View (First Cut)

**UX-2.1**: Keep It Simple
- No tap interactions on goals in first cut
- Focus on proving goal creation and persistence works
- Detail views to be added in next iteration

## Implementation Strategy (Minimal First Cut)

### Single Phase: Immediate Value (2-3 hours total)

**Step 1: GoalModel (30 minutes)**
- Create basic Isar model with objective code and name
- Add to existing Isar schema

**Step 2: MCP Function (45 minutes)**  
- Add `create_goal` case to SystemMCPService
- Parse objective_code and objective_name from command
- Store in Isar database

**Step 3: Goals Tab UI (60 minutes)**
- Add "Goals" to bottom navigation
- Create simple ListView showing goal names and dates
- Add empty state with conversation guidance

**Step 4: Persona Integration (30 minutes)**
- Add MCP instruction to persona prompts
- Test goal creation through conversation

## Success Metrics (Minimal First Cut)

### Functional Success
- Users can create goals through natural conversation
- Goals are saved and persist in database
- Goals display correctly in Goals tab
- LLM can successfully call MCP create_goal function

### User Experience Success  
- Goal creation feels natural and conversational
- Users see their goals are remembered by the system
- No confusion about how to create goals
- Clear empty state guidance for new users

## Benefits

### For Users (Immediate Value)
- **Natural Goal Setting**: Just talk about aspirations, no forms
- **Persistent Memory**: LLM remembers and stores goals
- **Oracle-Backed**: Scientifically-based goal framework
- **Zero Learning Curve**: No new UI patterns to learn

### For System  
- **Minimal Implementation**: 2-3 hours for immediate value
- **Foundation**: Perfect base for future enhancements
- **Oracle Compliant**: Uses existing framework structure
- **Low Risk**: Simple, proven patterns

### For Development
- **Proof of Concept**: Validates LLM goal management approach
- **User Validation**: Test demand before building complex features
- **Iterative**: Can add progress tracking after proving core value
- **Cost Effective**: Maximum user impact with minimal effort

## Future Enhancements (Next Iterations)

**Phase 2: Progress Tracking**
- Calculate progress based on existing activity tracking
- Add progress bars and percentages to goal cards
- Connect Oracle objectives to specific activities

**Phase 3: Advanced Features**
- Goal detail views with activity breakdown
- Goal modification/deletion via conversation
- Progress celebrations and motivational elements

**Phase 4: Analytics & Insights**
- Advanced progress analytics
- Goal completion patterns
- Personalized recommendations

---

## User Flow Example (Day 1)

```
1. User: "I want to get healthier and lose some weight"

2. Persona: "I understand you want to focus on health and weight loss. 
   I can create a weight loss goal for you based on proven methods 
   like proper nutrition, exercise, and hydration. Should I set this 
   up as one of your goals?"

3. User: "Yes, that sounds good"

4. Persona: [MCP Call] {"action": "create_goal", "objective_code": "OPP1", 
   "objective_name": "Perder peso"}

5. User opens Goals tab → sees "Perder peso" goal listed

6. User feels motivated knowing the LLM understands and remembers their aspiration
```

**Result**: Immediate user value with minimal implementation effort, proving the LLM goal management concept works before investing in complex progress tracking features.

---

*This minimal first cut establishes the foundation for LLM-driven goal management while delivering immediate user value and validating the approach with minimal risk and effort.*
