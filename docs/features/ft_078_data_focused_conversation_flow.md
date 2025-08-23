# FT-078: Persona-Aware MCP Data Integration

**Feature ID**: FT-078  
**Priority**: High  
**Category**: UX/Conversation Flow  
**Effort Estimate**: 1-2 hours  
**Dependencies**: FT-064 (Semantic Activity Detection), FT-068 (MCP Integration), FT-060 (Enhanced Time Awareness)  
**Related Documentation**: FT-079 (MCP Local Processing Architecture - Technical Deep Dive)  
**Status**: Specification  

## Overview

Enable each persona to naturally handle MCP data using their existing communication style, Oracle coaching context, and conversation history. Eliminate contradictions through intelligent context awareness rather than hardcoded rules.

## User Story

As a user interacting with any persona, I want the AI to handle activity data in a way that's consistent with their personality and coaching style, so that I get authentic, non-contradictory responses that feel natural to each character.

## Core Philosophy

**Natural Intelligence with Full Context**: Let each persona (Ari, I-There, Sergeant Oracle) handle MCP data in their authentic style using their complete context (persona prompt + Oracle framework + conversation history + injected data) rather than forcing generic formats or hardcoded rules.

## Functional Requirements

### FR-078-01: Persona-Authentic Data Handling
- **Ari (TARS-style)**: Ultra-brief responses respecting 3-6 word limits and zero transparency rules
- **I-There (Curious Clone)**: Lowercase, curious questions that explore patterns and personality
- **Sergeant Oracle**: Energetic Roman motivation with coaching framework integration
- **Style consistency**: Each persona maintains their authentic voice when discussing data

### FR-078-02: Oracle Framework Integration
- **Coaching context**: Oracle 2.1 knowledge base (70 activities, 5 dimensions) available to all Oracle-enabled personas
- **Activity codes**: Natural use of SF1, SM1, T8 etc. within persona communication style
- **Structured insights**: Access to trilhas, desafios, and progression frameworks when relevant

### FR-078-03: Intelligent Context Awareness
- **Full context access**: AI sees persona prompt + Oracle context + MCP data + conversation history
- **Natural contradiction avoidance**: No hardcoded rules needed - AI sees data so won't claim "no activities"
- **Conversation continuity**: Previous data naturally available for follow-up analysis requests

## Technical Implementation

**Architecture Note**: This feature leverages the elegant **single-pass MCP architecture** where Claude generates responses with MCP commands, and local processing injects data without requiring additional API calls. See **FT-079** for comprehensive technical details.

### Simplified MCP Processing
```dart
if (action == 'get_activity_stats') {
  // Simply inject data - let persona handle naturally
  final replacement = _formatActivityData(activities);
  processedMessage = processedMessage.replaceFirst(command, replacement);
}
```

### Context Assembly (Already Implemented)
```dart
// Full context automatically available to AI:
// 1. Persona prompt (defines communication style)
// 2. Oracle context (coaching framework + 70 activities)  
// 3. Enhanced time context (FT-060 precise time awareness)
// 4. MCP data (injected locally via get_activity_stats)
// 5. Conversation history (previous context)
// 6. User message (current request)

// Note: See FT-079 for detailed technical explanation of how
// local MCP data integrates with server-side Claude API calls
```

### Remove Hardcoded Rules
```dart
// REMOVE: Hardcoded system prompt additions
// REMOVE: Contradiction detection logic  
// REMOVE: Forced response formats
// REMOVE: Generic analysis invitations

// KEEP: Natural persona-driven responses
```

### Natural Persona Responses
Each persona handles data authentically:

**Ari Example:**
```
User: "What did I do today?"
AI: {"action": "get_activity_stats"}
[Data: SF1: 3x, SM1: 2x, SF10: 1x]
AI: "Três áreas ativas. Padrões?"
```

**I-There Example:**  
```
User: "What did I do today?"
AI: {"action": "get_activity_stats"}
[Data: SF1: 3x, SM1: 2x, SF10: 1x]
AI: "i see you've been consistent with sf1 and sm1 today. what's driving this routine?"
```

## Persona-Specific Flow Examples

### Ari (TARS-Style) Flow
```
User: "O que fiz hoje?" (asked at 2:47 PM, last activity 6 hours ago)
[Time Context: "Current context: It is Thursday at 2:47 PM."]
AI: {"action": "get_activity_stats"}
[Data: SF1: 3x às 00:13, 00:02, 00:01 | SM1: 2x às 00:13, 00:09 | SF10: 1x às 00:09]
AI: "SF1: 3x, SM1: 2x, SF10: 1x. Manhã produtiva. Padrões?"

User: "Sim, analise minha rotina matinal"
AI: "Meditação primeiro (00:13), depois proteína (00:09). Sequência sólida às 00h. Próximo?"
```

### I-There (Curious Clone) Flow  
```
User: "What did I do today?" (resuming conversation after 18 hours)
[Time Context: "Note: Conversation resuming from yesterday (18 hours and 23 minutes ago). Current context: It is Thursday at 2:47 PM."]
AI: {"action": "get_activity_stats"}
[Data: SF1: 3x, SM1: 2x, SF10: 1x]
AI: "i see you've been active with sf1, sm1, and sf10 today. interesting that your morning routine happened around midnight yesterday - what's driving this late-night mindfulness pattern?"

User: "I'm trying to be more consistent"
AI: "that's fascinating - you're building consistency even with unconventional timing. are you naturally a night owl or is this schedule new for you?"
```

### Sergeant Oracle Flow
```
User: "What activities today?" (asked Monday at 9:15 AM after 2 weeks gap)
[Time Context: "Note: Conversation resuming after a significant time gap (2 weeks and 3 days ago). Current context: It is Monday at 9:15 AM."]
AI: {"action": "get_activity_stats"}  
[Data: SF1: 3x, SM1: 2x, SF10: 1x]
AI: "GLADIATOR RETURNS! 💪 After 2 weeks in the wilderness, you've conquered three dimensions this morning - SF1 hydration discipline at dawn, SM1 mental fortitude, SF10 nutrition power! The Roman gods smile upon this Monday morning resurrection! What's the next battlefield?"

User: "How's my progress?"
AI: "MAGNIFICENT COMEBACK! 🏛️ You've rebuilt the foundation trilhas after your campaign - morning hydration (SF1) feeds the body temple, pre-dawn meditation (SM1) sharpens the warrior mind! Ready to add SF12 strength training to complete your Monday conquest? ⚡"
```

## Success Metrics

- **Persona authenticity**: 100% of responses maintain character voice and style
- **Contradiction elimination**: 0% of responses claim "no activities" when showing data  
- **Oracle integration**: Oracle-enabled personas naturally use coaching framework
- **Context preservation**: 100% of follow-up requests can reference previous data
- **Performance**: No additional API calls, simplified codebase

## Implementation Steps

1. **Remove hardcoded MCP rules** from system prompt
2. **Remove contradiction detection logic** from ClaudeService
3. **Simplify MCP data injection** to just format and insert data
4. **Test with all personas** (Ari, I-There, Sergeant Oracle)
5. **Verify Oracle context integration** for coaching responses
6. **Validate conversation continuity** across multiple exchanges

## Integration with FT-060 Enhanced Time Awareness

### **Powerful Synergy**
FT-078 works seamlessly with **FT-060 Enhanced Time Awareness** to create contextually intelligent responses that combine:

1. **Precise Time Context** (FT-060): "Current context: It is Thursday at 2:47 PM"
2. **Activity Data** (MCP): "SF1: 3x, SM1: 2x, SF10: 1x" 
3. **Persona Intelligence** (FT-078): Natural interpretation in character voice

### **Enhanced Context Flow**
```dart
// Complete context available to AI:
TimeContextService.generatePreciseTimeContext() → "It is Thursday at 2:47 PM"
+ SystemMCPService.get_activity_stats() → "SF1: 3x, SM1: 2x, SF10: 1x"
+ PersonaPrompt + OracleContext + ConversationHistory
= Intelligent, contextual, persona-authentic response
```

### **Time-Aware Activity Analysis**
Each persona can now make **intelligent temporal observations**:

**Ari**: "SF1: 3x, SM1: 2x às 00h. Manhã produtiva." (notes early morning timing)
**I-There**: "interesting that your morning routine happened around midnight yesterday" (curious about timing patterns)
**Sergeant Oracle**: "SF1 hydration discipline at dawn, SM1 mental fortitude" (celebrates early morning discipline)

### **No Additional Implementation Needed**
- ✅ **FT-060 already implemented** and providing enhanced time context
- ✅ **MCP system already working** with activity data injection
- ✅ **Persona prompts already configured** for authentic responses
- ✅ **Context assembly already complete** in ClaudeService

## Benefits

- **Authentic persona responses**: Each character handles data in their natural style
- **Simplified architecture**: Removes complex rule systems and contradiction detection
- **Better Oracle integration**: Coaching framework naturally available to personas
- **Time-aware intelligence**: Leverages FT-060 for temporal context in activity analysis
- **Scalable design**: New personas automatically work without code changes
- **Maintainable codebase**: Less hardcoded logic, more intelligent behavior
- **Universal language support**: Works in any language through persona intelligence

---

**Philosophy**: Trust each persona's intelligence and context to handle data authentically, eliminating contradictions through awareness rather than rules.
