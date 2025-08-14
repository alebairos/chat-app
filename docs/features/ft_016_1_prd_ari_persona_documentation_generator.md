# ft_016_1_prd_ari_persona_documentation_generator.md

## Product Requirements Document: Ari Persona Documentation Generator

**Created:** January 17, 2025  
**Status:** 📋 DRAFT - Ready for Implementation  
**Priority:** Medium (Documentation & Maintenance)  
**Estimated Implementation Time:** 2-3 hours

---

## Problem Statement

### Current Challenge
The Ari persona configuration in `assets/config/ari_life_coach_config.json` contains extensive and sophisticated coaching methodologies, but it's stored in a JSON format that's difficult to read and understand for:

1. **Development Team**: Hard to review and understand the full scope of Ari's capabilities
2. **Product Owners**: Cannot easily assess what coaching frameworks are implemented  
3. **QA/Testing**: Difficult to validate coaching behavior against documented methodology
4. **Documentation**: No human-readable reference for Ari's personality and capabilities

### Specific Issues
- **JSON Format**: Complex nested structure makes prompt content hard to read
- **No Overview**: Missing high-level summary of Ari's capabilities and frameworks
- **Hidden Complexity**: The 13-line JSON file contains ~15,000 tokens of sophisticated coaching methodology
- **Scattered Prompts**: Other prompts in the system are distributed across multiple files and not documented

## Solution Overview

Create a **Ari Persona Documentation Generator** that:

1. **Parses the JSON configuration** and generates a comprehensive, human-readable markdown document
2. **Extracts and organizes** all coaching frameworks, methodologies, and communication patterns
3. **Identifies all prompts** used in the Ari conversation flow (system prompt + exploration prompts + any hardcoded prompts)
4. **Creates structured documentation** that serves as both technical reference and product specification

## Target Users

### Primary Users
- **Development Team**: Understanding Ari's implementation and capabilities
- **Product Managers**: Assessing coaching methodology and planning enhancements
- **QA Engineers**: Validating behavior against documented specifications

### Secondary Users  
- **Technical Writers**: Creating user-facing documentation
- **Customer Support**: Understanding Ari's capabilities for user inquiries
- **Marketing Team**: Understanding product features for communication

## Core Requirements

### 1. Configuration Parser & Documentation Generator

**Primary Input:**
- `assets/config/ari_life_coach_config.json` - Main Ari configuration

**Secondary Inputs:**
- `assets/config/personas_config.json` - Persona metadata
- External prompt files (if they exist)
- Hardcoded prompts in source code

**Output:**
- `docs/personas/ari_life_coach_documentation.md` - Comprehensive readable documentation

### 2. Document Structure Requirements

The generated markdown should include:

#### **2.1 Executive Summary**
- Persona overview and core philosophy
- Communication style summary (TARS-inspired brevity)
- Key differentiators and capabilities

#### **2.2 Character Profile**
- Identity and gender (male coach)
- Personality traits and communication patterns
- Core philosophy and principles

#### **2.3 Communication Framework**
- **Response Length Rules** (strict guidelines)
- **Engagement Progression** (5-stage framework)
- **Word Economy Principles** (active voice, brevity rules)
- **Forbidden Phrases List** (coaching clichés to avoid)
- **Approved Response Patterns** (discovery, action, support phases)

#### **2.4 Expert Frameworks Integration**
Detailed documentation of all 9 integrated frameworks:
1. **Tiny Habits** (BJ Fogg)
2. **Behavioral Design** (Jason Hreha)  
3. **Dopamine Nation** (Anna Lembke)
4. **The Molecule of More** (Lieberman)
5. **Flourish/PERMA** (Martin Seligman)
6. **Maslow's Hierarchy** 
7. **Huberman Protocols**
8. **Scarcity Brain** (Michael Easter)
9. **Words Can Change Your Mind** (Andrew Newberg)

#### **2.5 Coaching Methodology**
- **Assessment Framework** (5-step initial evaluation)
- **Intervention Design** (5-component system)
- **Progression Structure** (12-week coaching timeline)

#### **2.6 Habit Catalog System**
- **5 Dimensions** of human potential (SF, SM, R, TG, E)
- **Habit Categories** by intensity (micro, moderate, advanced)
- **Progressive Tracks** (999 structured challenges)
- **Specific Objectives** (21 mapped goals)

#### **2.7 Advanced Tools & Frameworks**
- **OKR Integration** (personal objectives & key results)
- **Assessment Tools** (weekly/monthly/quarterly reviews)
- **Practical Implementation** guidelines

#### **2.8 Language & Communication Guidelines**
- Tone and style specifications
- What to avoid vs. prioritize
- Interaction style principles

### 3. Prompt Flow Analysis

**Requirement**: Identify and document ALL prompts used in Ari conversations:

#### **3.1 System Prompts**
- **Primary**: `ari_life_coach_config.json` → `system_prompt.content`
- **External** (if exists): `assets/prompts/ari_life_coach_system.txt`
- **Fallback behavior**: JSON config used when external file missing

#### **3.2 Exploration Prompts** 
From `ari_life_coach_config.json` → `exploration_prompts`:
- **Physical**: "Energy patterns?"
- **Mental**: "Mental clarity when?"
- **Relationships**: "Which relationship needs attention?"
- **Work**: "What energizes you most?"
- **Spirituality**: "What gives meaning now?"

#### **3.3 Hardcoded Prompts**
Search codebase for any hardcoded prompts specifically for Ari:
- Welcome messages
- Transition prompts
- Error handling messages
- Coaching intervention templates

#### **3.4 Life Planning Integration**
Document any prompts from the life planning system that interact with Ari:
- MCP commands (hidden from user)
- Life plan command handlers
- Habit recommendation prompts

### 4. Technical Implementation Requirements

#### **4.1 Script Architecture**
Create a Dart script: `scripts/generate_ari_docs.dart`

**Core Functions:**
```dart
// Parse JSON configuration
Map<String, dynamic> parseAriConfig()

// Extract system prompt content
String extractSystemPrompt()

// Parse exploration prompts  
Map<String, String> extractExplorationPrompts()

// Search for hardcoded prompts
List<String> findHardcodedPrompts()

// Generate structured markdown
String generateMarkdownDoc()

// Write output file
void writeDocumentation()
```

#### **4.2 Markdown Generation**
- **Clean formatting**: Proper headers, lists, code blocks
- **Table of contents**: Auto-generated navigation
- **Cross-references**: Link between related sections
- **Code examples**: Show actual prompt text in formatted blocks
- **Metadata**: Include generation date, source files, versions

#### **4.3 Error Handling**
- Handle missing configuration files gracefully
- Validate JSON structure before parsing
- Provide meaningful error messages
- Create partial documentation if some sections fail

## Technical Specifications

### Input File Analysis

**Primary Configuration**: `assets/config/ari_life_coach_config.json`
```json
{
  "system_prompt": {
    "role": "system",
    "content": "[~15,000 tokens of sophisticated coaching methodology]"
  },
  "exploration_prompts": {
    "physical": "Energy patterns?",
    "mental": "Mental clarity when?", 
    "relationships": "Which relationship needs attention?",
    "work": "What energizes you most?",
    "spirituality": "What gives meaning now?"
  }
}
```

**Persona Metadata**: `assets/config/personas_config.json`
```json
{
  "personas": {
    "ariLifeCoach": {
      "enabled": true,
      "displayName": "Ari - Life Coach",
      "description": "TARS-inspired life coach combining 9 expert frameworks..."
    }
  }
}
```

### Prompt Flow Discovery

**System Prompt Loading Logic** (from `character_config_manager.dart`):
1. Try external file: `assets/prompts/ari_life_coach_system.txt` (currently missing)
2. Fallback to JSON: `ari_life_coach_config.json` → `system_prompt.content`
3. Error handling if both fail

**Exploration Prompts** (from `life_plan_command_handler.dart`):
- Loaded via `ConfigLoader.loadExplorationPrompts()`
- Used when user enters dimension codes (SF, SM, R, TG, E)
- Fallback defaults if configuration missing

### Documentation Output Structure

```markdown
# Ari Life Coach - Complete Documentation

## Table of Contents
1. Executive Summary
2. Character Profile  
3. Communication Framework
4. Expert Frameworks (9 integrated systems)
5. Coaching Methodology
6. Habit Catalog System
7. Advanced Tools & OKRs
8. Language Guidelines
9. Prompt Flow Analysis
10. Implementation Notes

## 1. Executive Summary
[Generated from parsed config + analysis]

## 2. Character Profile
### Identity & Gender
- Name: Ari (male life coach)
- Personality: TARS-inspired brevity + warmth
[...]

## 9. Prompt Flow Analysis
### System Prompts Used
1. **Primary System Prompt** (Source: ari_life_coach_config.json)
   [Full prompt content in code block]

2. **Exploration Prompts** (Source: ari_life_coach_config.json)
   - Physical: "Energy patterns?"
   - Mental: "Mental clarity when?"
   [...]

3. **Hardcoded Prompts** (Source: Codebase Analysis)
   [Any discovered hardcoded prompts]

4. **Life Planning Integration**
   [MCP commands and related prompts]
```

## Success Criteria

### **Primary Success Metrics**
1. ✅ **Complete Documentation Generated**: Full markdown document created from JSON config
2. ✅ **All Prompts Identified**: System, exploration, and hardcoded prompts documented  
3. ✅ **Readable Format**: Technical team can quickly understand Ari's capabilities
4. ✅ **Structured Navigation**: Clear sections with table of contents

### **Secondary Success Metrics**
1. ✅ **Framework Analysis**: All 9 expert frameworks clearly documented
2. ✅ **Communication Rules**: TARS-inspired brevity rules are extractable
3. ✅ **Maintenance Value**: Document serves as specification for future updates
4. ✅ **QA Reference**: Testing team can validate behavior against documentation

### **Quality Indicators**
- Documentation accurately reflects current JSON configuration
- All coaching methodologies are clearly explained
- Prompt flow is completely mapped
- Generated markdown is well-formatted and readable
- No information loss from JSON to markdown conversion

## Implementation Phases

### **Phase 1: Core Parser (1 hour)**
- Create `scripts/generate_ari_docs.dart`
- Implement JSON config parsing
- Extract system prompt and exploration prompts
- Generate basic markdown structure

### **Phase 2: Content Organization (1 hour)**  
- Parse and organize the 9 expert frameworks
- Extract communication rules and methodology
- Structure habit catalog and coaching tools
- Format all content sections

### **Phase 3: Prompt Flow Analysis (30 minutes)**
- Search codebase for hardcoded Ari prompts
- Document life planning integration
- Map complete conversation flow
- Validate prompt discovery

### **Phase 4: Documentation Polish (30 minutes)**
- Generate table of contents
- Add metadata and generation info  
- Validate markdown formatting
- Create final output file

## Files to Create/Modify

### **New Files**
- `scripts/generate_ari_docs.dart` - Documentation generator script
- `docs/personas/ari_life_coach_documentation.md` - Generated documentation output
- `docs/features/ft_016_2_impl_summary_ari_documentation_generator.md` - Implementation summary

### **Reference Files** (Input)
- `assets/config/ari_life_coach_config.json` - Primary configuration
- `assets/config/personas_config.json` - Persona metadata  
- `lib/config/character_config_manager.dart` - Prompt loading logic
- `lib/life_plan/services/life_plan_command_handler.dart` - Exploration prompt usage

## Dependencies & Constraints

### **Technical Dependencies**
- Dart JSON parsing capabilities
- File I/O for reading configs and writing documentation
- String processing for markdown generation

### **Constraints**
- Must accurately represent current configuration without interpretation
- Should be maintainable as Ari's configuration evolves
- Must not expose any sensitive information or API keys
- Generated documentation should be version-controlled

### **Future Considerations**
- Script could be extended to document other personas
- Could integrate with CI/CD to auto-generate docs on config changes
- Might be enhanced to validate configuration structure
- Could generate user-facing documentation in addition to technical docs

## Risk Assessment

### **Low Risk Areas**
- JSON parsing (standard Dart functionality)
- Markdown generation (simple string manipulation)
- File operations (standard file I/O)

### **Medium Risk Areas**  
- **Complex content structure**: Ari's system prompt contains deeply nested coaching methodology
- **Prompt discovery**: Finding all hardcoded prompts requires thorough codebase analysis
- **Content organization**: 15,000+ token system prompt needs careful parsing and structuring

### **Mitigation Strategies**
- Start with basic structure, then enhance content organization
- Use systematic search patterns for prompt discovery
- Implement graceful error handling for malformed JSON
- Create modular script architecture for easier debugging

---

## Conclusion

The Ari Persona Documentation Generator addresses a critical need for understanding and maintaining one of the most sophisticated AI personas in the application. By converting the complex JSON configuration into human-readable documentation and mapping the complete prompt flow, this feature will significantly improve development efficiency, QA processes, and product management capabilities.

The implementation follows the established principle of creating focused, simple tools that provide immediate value while being easy to understand and maintain.

**Next Steps**: Proceed with Phase 1 implementation to create the core parsing and generation functionality.

---

**Document Version:** 1.0  
**Author:** AI Assistant  
**Approval Status:** Ready for Implementation
**Estimated Completion:** January 17, 2025 