# FT-117: MCP Configuration Separation Architecture

**Feature ID:** FT-117  
**Priority:** Medium  
**Category:** Architecture  
**Effort:** 3-5 days  

## Problem Statement

MCP (Model Context Protocol) instructions are currently embedded within Oracle prompt files, violating separation of concerns. These implementation-specific commands are tightly coupled to the Flutter app's systems but pollute the coaching methodology content.

## Current State

- MCP instructions embedded in `oracle_prompt_2.1.md`
- Technical integration mixed with coaching methodology
- Updating MCP system requires modifying multiple oracle files
- Oracle prompts less reusable across different applications

## Proposed Solution

### Architecture Changes

1. **Separate MCP Configuration Files**
   ```
   assets/config/
   ├── mcp/
   │   ├── activity_tracking_mcp.md
   │   └── future_mcp_extensions.md
   ├── oracle/ (pure methodology)
   └── personas_config.json (references both)
   ```

2. **Enhanced Persona Configuration Schema**
   ```json
   {
     "ariWithOracle30": {
       "configPath": "assets/config/ari_life_coach_config_2.0.json",
       "oracleConfigPath": "assets/config/oracle/oracle_prompt_v3.md",
       "mcpConfigPaths": [
         "assets/config/mcp/activity_tracking_mcp.md"
       ]
     }
   }
   ```

3. **Updated Character Config Manager**
   - Load base persona config
   - Load oracle methodology
   - Load and append MCP instructions
   - Combine into final prompt

## Benefits

- ✅ Clean separation of concerns
- ✅ Single source of truth for MCP instructions
- ✅ Oracle prompts focus on pure methodology
- ✅ Easier MCP system maintenance
- ✅ Modular MCP extensions
- ✅ Better reusability across applications

## Implementation Tasks

1. Extract MCP instructions from oracle prompts into dedicated files
2. Update `character_config_manager.dart` to handle `mcpConfigPaths` array
3. Modify `personas_config.json` schema to include MCP references
4. Clean oracle prompt files to remove technical instructions
5. Update preprocessing scripts to handle new architecture
6. Test all persona configurations load correctly

## Dependencies

- Character configuration system
- Oracle preprocessing pipeline
- Persona management system

## Acceptance Criteria

- [ ] MCP instructions separated from oracle methodology
- [ ] All personas load MCP instructions correctly
- [ ] Oracle prompts contain only coaching methodology
- [ ] MCP system updates don't require oracle file changes
- [ ] Backward compatibility maintained during transition
- [ ] Documentation updated for new architecture

## Notes

This refactoring improves maintainability and follows clean architecture principles while preserving all existing functionality.

