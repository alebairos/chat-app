# FT-144: Persona Configuration Optimization

**Feature ID:** FT-144  
**Priority:** Medium  
**Category:** Persona Enhancement  
**Effort Estimate:** 2-3 hours  

## Overview

Create optimized persona configurations (Ari 3.0 and I-There 2.0) addressing communication issues in current versions and update Oracle 4.2 personas to use the improved configurations.

## Problem Statement

Current persona configurations have communication inefficiencies:
- **Ari 2.0**: Overly strict initial word limits (3-6 words) create unnatural coaching interactions
- **I-There 1.0**: Verbose system prompt (300+ lines) leads to overly detailed responses contradicting casual personality

## Solution

### 1. Create Ari Life Coach 3.0 Configuration
**File:** `assets/config/ari_life_coach_config_3.0.json`

**Key Changes:**
- Relax initial word limits: 8-12 words (vs 3-6) for first message
- Allow 1-2 sentences (vs 1 sentence) for messages 2-3
- Maintain progression model but with more natural entry point
- Permit brief empathy acknowledgments in early responses
- Keep question focus with slightly more natural phrasing

### 2. Create I-There 2.0 Configuration  
**File:** `assets/config/i_there_config_2.0.json`

**Key Changes:**
- Compress system prompt from 300+ to ~100 lines
- Remove redundant personality discovery frameworks
- Simplify language guidelines to basic tone instructions
- Consolidate conversation examples
- Add explicit brevity instruction: "Keep responses conversational and concise (2-3 sentences typical)"
- Maintain core Mirror Realm identity and curiosity focus

### 3. Update Oracle 4.2 Personas
Update `personas_config.json` to use new configurations:
- `ariWithOracle42`: Update configPath to `ari_life_coach_config_3.0.json`
- `iThereWithOracle42`: Update configPath to `i_there_config_2.0.json`

## Functional Requirements

### FR-144.1: Ari 3.0 Configuration
- Create new config file with relaxed initial communication constraints
- Maintain TARS-inspired brevity progression but with natural entry point
- Preserve coaching effectiveness while improving initial user experience
- Keep all existing Oracle 4.2 integration capabilities

### FR-144.2: I-There 2.0 Configuration
- Create streamlined config with 60% reduction in system prompt length
- Maintain Mirror Realm personality and curiosity-driven interactions
- Add explicit brevity guidelines for natural conversation flow
- Preserve voice settings and exploration prompts structure

### FR-144.3: Personas Config Update
- Update Oracle 4.2 persona entries to reference new config files
- Maintain all existing Oracle integration and MCP extension configurations
- Keep old config files for backward compatibility with other persona versions
- Preserve all other persona configurations unchanged

## Non-Functional Requirements

### NFR-144.1: Backward Compatibility
- Keep existing config files (`ari_life_coach_config_2.0.json`, `i_there_config.json`)
- Ensure other persona versions continue using original configs
- No breaking changes to existing persona functionality

### NFR-144.2: Configuration Consistency
- Follow established JSON structure and naming conventions
- Maintain consistent voice_settings and exploration_prompts format
- Ensure proper integration with MCP and Oracle systems

## Technical Implementation

### Files to Create
1. `assets/config/ari_life_coach_config_3.0.json`
2. `assets/config/i_there_config_2.0.json`

### Files to Modify
1. `assets/config/personas_config.json` - Update Oracle 4.2 persona configPath references

### Configuration Structure
Both new configs maintain existing structure:
- `system_prompt` with optimized content
- `exploration_prompts` (unchanged)
- `voice_settings` (unchanged)

## Dependencies

- Oracle 4.2 framework integration
- MCP base configuration system
- Audio formatting configuration
- Existing persona management system

## Acceptance Criteria

### AC-144.1: Ari 3.0 Behavior
- First message allows 8-12 words instead of 3-6
- Messages 2-3 allow 1-2 sentences with natural coaching tone
- Maintains progression to deeper engagement after user investment
- Preserves all Oracle 4.2 coaching capabilities

### AC-144.2: I-There 2.0 Behavior  
- Responses are naturally concise (2-3 sentences typical)
- Maintains Mirror Realm personality and curiosity
- System prompt reduced to ~100 lines while preserving core identity
- Natural conversation flow without verbose explanations

### AC-144.3: Integration Verification
- Oracle 4.2 personas load new configurations successfully
- All existing functionality preserved (voice, MCP, Oracle integration)
- Other persona versions unaffected by changes
- Configuration validation passes for new files

## Testing Strategy

### Manual Testing
1. Load Aristios 4.2 persona and verify natural initial conversation flow
2. Load I-There 4.2 persona and verify concise, curious responses
3. Test Oracle 4.2 integration with both updated personas
4. Verify other personas (3.0, 2.1) continue working with original configs

### Configuration Testing
1. Validate JSON structure of new config files
2. Test persona loading and initialization
3. Verify MCP and Oracle integration functionality
4. Confirm voice settings and audio formatting work correctly

## Implementation Notes

- Preserve all existing persona functionality while optimizing communication patterns
- Focus on natural conversation flow improvements without losing core persona characteristics
- Maintain scientific rigor in Ari while allowing more natural initial interactions
- Keep I-There's Mirror Realm identity while reducing verbose system instructions

## Success Metrics

- Ari 3.0: More natural initial coaching conversations (subjective evaluation)
- I-There 2.0: Concise responses maintaining personality authenticity
- Zero regression in Oracle 4.2 functionality
- Successful configuration loading and persona switching
