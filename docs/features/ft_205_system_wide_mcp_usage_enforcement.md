# FT-205: System-Wide MCP Usage Enforcement

## Feature Overview

Implement mandatory MCP command usage across all personas through system-level rules and configuration hierarchy, ensuring consistent conversation awareness without contaminating domain-specific persona configurations.

## Problem Statement

### Current Issues
- **Inconsistent MCP Usage**: AI personas don't proactively generate conversation MCP commands
- **Amnesia Behavior**: Personas lack conversation context, leading to repetitive introductions
- **Configuration Contamination**: Technical MCP details mixed with domain-specific persona content
- **Missing System Priority**: MCP usage treated as optional rather than mandatory system behavior

### Impact on User Experience
- Personas appear to "forget" previous conversations
- Repetitive introductions and context loss during persona switching
- Inconsistent conversation quality across different personas
- Manual activity listing redundancy (personas duplicate Oracle detection)

## Solution: Hierarchical MCP Enforcement

### Architecture Principle
```
System Laws (Highest Priority)
    ↓
MCP API Layer (Implementation Skills)
    ↓
Multi-Persona Protocol (Switching Logic)
    ↓
Domain Personas (MCP-Unaware)
```

### Core Design Philosophy
- **Separation of Concerns**: Domain experts write personas without technical MCP knowledge
- **System-Level Enforcement**: MCP usage mandated through core behavioral rules
- **API-Like Skills**: MCP functions treated as available skills/APIs for all personas
- **Mandatory Protocols**: Specific MCP command sequences for persona switching

## Requirements

### Functional Requirements

**FR-1: System Law Integration**
- Add "System Law #5: Mandatory Conversation Awareness" to `core_behavioral_rules.json`
- Enforce proactive MCP command generation before all responses
- Prioritize MCP-retrieved context over assumed knowledge
- Make conversation MCP commands as mandatory as activity queries

**FR-2: MCP API Layer Priority**
- Elevate `mcp_base_config.json` to high-priority system component
- Position MCP instructions as "available skills API" for all personas
- Ensure MCP commands are treated as fundamental system capabilities
- Maintain clear separation between MCP implementation and persona content

**FR-3: Multi-Persona MCP Protocol**
- Add mandatory MCP command sequences to `multi_persona_config.json`
- Define specific STEPS for persona switching scenarios
- Enforce conversation context retrieval during persona transitions
- Prevent persona contamination through proper MCP usage

**FR-4: Domain Persona Isolation**
- Keep individual persona configs (e.g., `tony_life_coach_config.json`) free of MCP technical details
- Allow domain experts to write personas without MCP knowledge
- Maintain clean separation between domain expertise and technical implementation
- Preserve persona authenticity and domain focus

### Non-Functional Requirements

**NFR-1: Configuration Hierarchy**
- Core rules take highest priority in system prompt assembly
- MCP instructions positioned as high-priority system capabilities
- Multi-persona protocols enforced during persona switching
- Domain personas remain technically agnostic

**NFR-2: Backward Compatibility**
- Existing persona configurations remain unchanged
- No technical contamination of domain-specific content
- Gradual rollout through existing feature toggle system
- Seamless integration with current architecture

**NFR-3: Maintainability**
- Clear separation between system rules, MCP layer, and domain content
- Domain experts can modify personas without technical knowledge
- MCP enhancements don't require persona config changes
- System-level changes propagate automatically to all personas

## Technical Implementation

### Phase 1: Core System Laws (Immediate)

#### 1.1 Add System Law #5 to `core_behavioral_rules.json`
```json
"mcp_command_priority": {
  "title": "SYSTEM LAW #5: MANDATORY CONVERSATION AWARENESS",
  "proactive_queries": "Generate conversation MCP commands BEFORE every response",
  "required_commands": [
    "get_recent_user_messages for context understanding",
    "get_current_persona_messages for consistency checking", 
    "search_conversation_context when topics are referenced"
  ],
  "integration_rule": "MCP results must inform response content and tone",
  "priority_level": "highest",
  "override_authority": "This law overrides persona preferences and training data patterns"
}
```

#### 1.2 Elevate MCP Base Config Priority
- Position `mcp_base_config.json` as high-priority system component
- Treat MCP functions as "Skills API" available to all personas
- Ensure MCP instructions appear early in system prompt assembly
- Maintain clear API-like documentation for available MCP functions

### Phase 2: Multi-Persona Protocol Enhancement

#### 2.1 Add Mandatory MCP Steps to `multi_persona_config.json`
```json
"mcp_persona_switching": {
  "enabled": true,
  "mandatory_protocol": {
    "step1": {
      "command": "{\"action\": \"get_recent_user_messages\", \"limit\": 5}",
      "purpose": "Understand user's current conversation context"
    },
    "step2": {
      "command": "{\"action\": \"get_current_persona_messages\", \"limit\": 2}",
      "purpose": "Check for previous interactions to avoid re-introduction"
    },
    "step3": {
      "action": "Acknowledge previous persona context naturally",
      "rule": "Reference other persona contributions respectfully"
    },
    "step4": {
      "action": "Introduce unique approach without repetition",
      "rule": "Build upon previous insights with your distinctive perspective"
    }
  },
  "enforcement_level": "mandatory",
  "applies_to": "all_persona_switches"
}
```

#### 2.2 Conversation Continuity Protocol
```json
"conversation_continuity_protocol": {
  "before_any_response": [
    "Check: get_recent_user_messages to understand context",
    "Check: get_current_persona_messages to avoid repetition",
    "Only then: Generate persona-appropriate response"
  ],
  "topic_references": [
    "Detect: User references to past topics or conversations",
    "Execute: search_conversation_context with extracted topic",
    "Integrate: Found context naturally into response"
  ]
}
```

### Phase 3: System Prompt Assembly Order

#### 3.1 Priority Hierarchy
1. **Core Behavioral Rules** (including System Law #5)
2. **MCP Base Config** (Skills API layer)
3. **Multi-Persona Config** (Switching protocols)
4. **Oracle Extensions** (when applicable)
5. **Individual Persona Config** (domain-specific content)

#### 3.2 Assembly Logic
```
SYSTEM PROMPT = 
  Core Rules (System Laws 1-5) +
  MCP Skills API (Available Functions) +
  Multi-Persona Protocol (Switching Logic) +
  [Oracle Extension] (if persona.oracleEnabled) +
  Persona Content (Domain Expertise)
```

## Expected Benefits

### User Experience Improvements
- **Consistent Conversation Flow**: All personas maintain context across interactions
- **Natural Persona Switching**: Smooth transitions without repetitive introductions
- **Reduced Redundancy**: Elimination of manual activity listing (trust Oracle system)
- **Improved Continuity**: Personas reference previous conversations appropriately

### Developer Experience Improvements
- **Clean Separation**: Domain experts write personas without technical MCP knowledge
- **System-Level Control**: MCP behavior controlled through system configuration
- **Maintainable Architecture**: Clear hierarchy and separation of concerns
- **Scalable Enhancement**: New MCP functions automatically available to all personas

### Technical Benefits
- **Mandatory Enforcement**: System laws ensure consistent MCP usage
- **Configuration Isolation**: Technical and domain concerns properly separated
- **Hierarchical Priority**: Clear precedence order for configuration conflicts
- **Backward Compatibility**: Existing personas work without modification

## Testing Strategy

### Unit Testing
- **Core Rules Loading**: Verify System Law #5 is loaded and applied
- **MCP Priority**: Confirm MCP instructions appear in correct system prompt position
- **Multi-Persona Protocol**: Test mandatory MCP command generation during persona switches
- **Configuration Isolation**: Ensure persona configs remain MCP-free

### Integration Testing
- **Persona Switching**: Verify mandatory MCP steps are executed during transitions
- **Conversation Continuity**: Test MCP command generation before responses
- **Context Integration**: Confirm MCP results inform persona responses
- **Priority Hierarchy**: Validate system prompt assembly order

### User Experience Testing
- **Natural Flow**: Verify personas maintain conversation context
- **No Over-Introduction**: Confirm personas don't repeatedly introduce themselves
- **Contextual Responses**: Test personas reference previous conversations appropriately
- **Smooth Switching**: Validate natural persona transitions

## Risk Assessment

### Technical Risks
- **Configuration Complexity**: Multiple config layers might create conflicts
- **Performance Impact**: Mandatory MCP commands could slow response time
- **System Prompt Size**: Additional rules might exceed token limits

### Mitigation Strategies
- **Clear Hierarchy**: Explicit priority order prevents configuration conflicts
- **Parallel Execution**: MCP commands executed simultaneously for performance
- **Selective Loading**: Only load relevant MCP extensions per persona
- **Gradual Rollout**: Use existing feature toggles for safe deployment

## Success Metrics

### Behavioral Metrics
- **MCP Command Generation**: 100% of responses preceded by conversation MCP commands
- **Context Awareness**: Elimination of "amnesia" behavior across personas
- **Introduction Frequency**: Reduction in repetitive persona introductions
- **Conversation References**: Increase in appropriate past conversation references

### Technical Metrics
- **Configuration Separation**: 0% MCP technical details in persona configs
- **System Law Compliance**: 100% adherence to mandatory MCP usage
- **Protocol Execution**: 100% completion of multi-persona switching steps
- **Performance Impact**: <200ms additional latency for MCP command execution

## Implementation Timeline

### Week 1: Core System Laws
- Add System Law #5 to `core_behavioral_rules.json`
- Elevate MCP base config priority in system prompt assembly
- Test core rule enforcement and MCP command generation

### Week 2: Multi-Persona Protocol
- Add mandatory MCP steps to `multi_persona_config.json`
- Implement conversation continuity protocol
- Test persona switching with mandatory MCP commands

### Week 3: Integration & Testing
- Comprehensive integration testing across all personas
- Performance optimization and monitoring
- User experience validation and refinement

### Week 4: Production Deployment
- Gradual rollout using existing feature toggles
- Monitor system behavior and user feedback
- Documentation and training for domain experts

## Conclusion

FT-205 establishes a clean, hierarchical architecture where MCP usage is enforced at the system level while keeping domain-specific persona configurations free of technical implementation details. This approach ensures consistent conversation awareness across all personas while maintaining the separation of concerns between system capabilities and domain expertise.

The mandatory MCP enforcement through System Law #5, combined with high-priority MCP Skills API and multi-persona switching protocols, creates a robust foundation for natural, context-aware conversations without contaminating the domain-focused persona configurations that specialists create.
