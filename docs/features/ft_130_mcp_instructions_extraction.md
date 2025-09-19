# FT-130: MCP Instructions Extraction to Separate Configuration File

**Feature ID**: FT-130  
**Priority**: High  
**Category**: Architecture Optimization  
**Effort**: Medium (8-12 hours)  
**Dependencies**: Oracle 4.0 Analysis (FT-Oracle-4.0-Analysis)  

## Problem Statement

Currently, MCP (Model Control Protocol) instructions are duplicated across multiple locations:
1. **Oracle Prompts** (3.0, 4.0, 2.1) contain identical MCP sections (~42 lines each)
2. **Claude Service** dynamically adds similar MCP instructions (~115 lines)
3. This creates **redundancy, conflicts, and unnecessary token consumption**

### Current Issues
- **Token Waste**: ~450 tokens per API call due to redundant MCP instructions
- **Rate Limiting**: Oracle 4.0's larger context + redundant MCP causes 429 errors
- **Maintenance Burden**: MCP changes require updates in multiple files
- **Inconsistency**: Static Oracle MCP vs Dynamic Claude Service MCP can conflict

## Solution Overview

Extract MCP instructions to a separate configuration file following the established audio formatting pattern, creating a single source of truth for MCP behavior while reducing token consumption.

## Functional Requirements

### FR-130.1: MCP Configuration File
- Create `assets/config/mcp_instructions_config.json`
- Structure similar to `audio_formatting_config.json`
- Contains comprehensive MCP instructions for activity tracking
- Includes application rules for conditional loading

### FR-130.2: Dynamic Loading Integration
- Integrate MCP config loading into `CharacterConfigManager`
- Load MCP instructions only for Oracle-enabled personas
- Position MCP instructions before Oracle content in system prompt
- Maintain backward compatibility with non-Oracle personas

### FR-130.3: Oracle Prompt Cleanup
- Remove MCP sections from all Oracle prompt files (2.1, 3.0, 4.0)
- Preserve Oracle-specific content and activity catalogs
- Maintain prompt functionality while reducing size

### FR-130.4: Claude Service Simplification
- Reduce dynamic MCP instructions to session-specific content only
- Remove redundant static instructions now handled by config file
- Focus on runtime status and session context

### FR-130.5: Conditional Application
- Enable MCP instructions only for Oracle personas
- Disable for base personas (ariLifeCoach, sergeantOracle, iThereClone)
- Configurable via application rules in MCP config file

## Non-Functional Requirements

### NFR-130.1: Performance
- Reduce system prompt tokens by minimum 400 tokens per API call
- Improve Oracle 4.0 rate limiting by reducing prompt size
- Maintain response generation speed

### NFR-130.2: Maintainability
- Single file for all MCP instruction updates
- Version control for MCP instruction changes
- Clear separation between static and dynamic MCP content

### NFR-130.3: Compatibility
- Preserve all existing MCP functionality
- Maintain temporal intelligence capabilities (FT-095)
- Ensure consistent behavior across all personas

## Technical Implementation

### Implementation Architecture

```
System Prompt Assembly (New Flow):
┌─────────────────┐
│ Time Context    │ (Dynamic)
├─────────────────┤
│ MCP Instructions│ (Static Config - NEW)
├─────────────────┤
│ Oracle Content  │ (Static - MCP Removed)
├─────────────────┤
│ Persona Prompt  │ (Static)
├─────────────────┤
│ Audio Format    │ (Static Config)
├─────────────────┤
│ Session MCP     │ (Dynamic - Simplified)
└─────────────────┘
```

### File Structure

#### MCP Configuration File
```json
// assets/config/mcp_instructions_config.json
{
  "mcp_instructions": {
    "version": "2.0",
    "description": "MCP system function instructions for activity tracking and data queries",
    "content": "## SISTEMA DE COMANDO MCP - ACTIVITY TRACKING\n\n**SISTEMA DE ATIVIDADES**: O sistema detecta automaticamente atividades mencionadas pelo usuário E permite consultar dados precisos quando o usuário pergunta sobre suas estatísticas.\n\n## ⚡ COMANDOS MCP OBRIGATÓRIOS ⚡\n\n### 🔍 get_activity_stats - SEMPRE USAR PARA DADOS EXATOS\n\n**INSTRUÇÃO CRÍTICA**: Para QUALQUER pergunta sobre atividades, SEMPRE use:\n```\n{\"action\": \"get_activity_stats\", \"days\": N}\n```\n\n**EXEMPLOS OBRIGATÓRIOS**:\n- ❓ \"O que trackei hoje?\" → 🔍 `{\"action\": \"get_activity_stats\"}`\n- ❓ \"Quantas atividades fiz?\" → 🔍 `{\"action\": \"get_activity_stats\"}`\n- ❓ \"Como está meu progresso?\" → 🔍 `{\"action\": \"get_activity_stats\", \"days\": 7}`\n- ❓ \"Esta semana?\" → 🔍 `{\"action\": \"get_activity_stats\", \"days\": 7}`\n- ❓ \"Último mês?\" → 🔍 `{\"action\": \"get_activity_stats\", \"days\": 30}`\n\n**NUNCA USE DADOS APROXIMADOS** - SEMPRE consulte a base real!\n\n### 📊 FORMATO DE RESPOSTA ESPERADO:\n\n1. **Execute o comando**: `{\"action\": \"get_activity_stats\"}`\n2. **Aguarde o resultado** da consulta ao banco\n3. **Use os dados exatos** retornados\n4. **Formate a resposta** com contagens, códigos e horários precisos\n\n**Exemplo**:\n```\nDeixa eu consultar seus dados... {\"action\": \"get_activity_stats\"}\n[Resultado: 5 atividades hoje]\nHoje você completou 5 atividades:\n• T8 (Trabalho focado): 2x às 13:35 e 18:28\n• SF1 (Água): 3x entre 13:38 e 18:25  \nTotal: 2 TG (foco), 3 SF (saúde física)\n```\n\n**IMPORTANTE**: Use a mensagem EXATA do usuário no campo \"message\". Não modifique, traduza ou resuma.\n\n## TEMPORAL INTELLIGENCE GUIDELINES\n\n### Temporal Expression Mapping\n**Command Structure**: {\"action\": \"get_activity_stats\", \"days\": N}\n- days: 0 = today (current day activities)\n- days: 1 = yesterday (previous day activities)\n- days: 7 = last week (7 days of data)\n- days: 14 = last 2 weeks (14 days of data)\n- days: 30 = last month (30 days of data)\n\n**Context-Aware Temporal Mapping**:\n- \"hoje\" (today) → days: 0\n- \"ontem\" (yesterday) → days: 1\n- Specific day names: Calculate days back from today\n- \"sábado\", \"segunda\", etc. → Count days from current day\n- Period references: \"semana\", \"mês\" → Use range parameters\n\n**🎯 PRECISE DAY CALCULATION**:\n- Single day name (\"sábado\") → Calculate precise days to get ONLY that day\n- Period reference (\"esta semana\") → Query the entire period range\n- Use temporal context to calculate precise day offsets\n\n### Complex Query Processing\n**Exclusion Queries (\"além de X\", \"other than X\")**:\n1. Execute appropriate temporal query\n2. Filter returned data to exclude mentioned activities\n3. Present filtered results with context\n\n**Comparison Queries (\"comparado com\", \"vs\")**:\n1. Execute current period query\n2. Execute previous period query\n3. Calculate differences and identify trends\n4. Present comparative analysis\n\n**Time-of-Day Filtering (\"manhã\", \"tarde\")**:\n1. Execute temporal query for appropriate day(s)\n2. Filter results using \"timeOfDay\" field\n3. Present time-specific activities\n\n### Data Utilization Rules\n- ALWAYS use real data from MCP commands, never approximate\n- Use EXACT counts from \"total_activities\" and \"by_activity\" fields\n- Reference specific times and counts from returned data\n- Use exact activity codes (SF1, T8, etc.) from results\n- Include confidence scores and timestamps when relevant\n\n### Contextual Response Enhancement\n**Time-of-Day Awareness**:\n- Morning queries (6-12h): \"Esta manhã você já...\", \"Bom ritmo para começar o dia!\"\n- Afternoon queries (12-18h): \"Hoje pela manhã você fez... E à tarde?\", \"Como vai o restante do dia?\"\n- Evening queries (18-22h): \"Hoje você completou...\", \"Como foi o dia?\"\n- Night queries (22-6h): \"Reflexão do dia...\", \"Hora de descansar?\"\n\n**Data-Driven Insights**:\n- Identify patterns: \"água manteve consistência (5x)\"\n- Suggest improvements: \"Quer aumentar o foco à tarde?\"\n- Celebrate achievements: \"Excelente consistência!\"\n- Reference specific times: \"às 10:58\", \"entre 11:23 e 11:24\""
  },
  "application_rules": {
    "auto_apply": true,
    "position": "prepend_to_oracle_content",
    "enabled_for_oracle_personas": true,
    "enabled_for_non_oracle_personas": false,
    "version_compatibility": ["2.1", "3.0", "4.0"]
  }
}
```

### Code Changes

#### CharacterConfigManager Updates
```dart
// In loadSystemPrompt() method
String mcpInstructions = '';
if (oracleConfigPath != null) {
  try {
    final String mcpConfigString = await rootBundle.loadString(
      'assets/config/mcp_instructions_config.json'
    );
    final Map<String, dynamic> mcpConfig = json.decode(mcpConfigString);
    
    if (mcpConfig['application_rules']['enabled_for_oracle_personas'] == true) {
      mcpInstructions = mcpConfig['mcp_instructions']['content'] as String;
      print('✅ MCP instructions loaded for Oracle persona: $_activePersonaKey');
    }
  } catch (e) {
    print('⚠️ MCP instructions config not found: $e');
  }
}

// Compose: MCP Instructions + Cleaned Oracle + Persona + Audio
String finalPrompt = '';
if (mcpInstructions.isNotEmpty) {
  finalPrompt = mcpInstructions.trim();
}

if (oraclePrompt != null && oraclePrompt.trim().isNotEmpty) {
  final cleanedOraclePrompt = _removeMCPSection(oraclePrompt);
  finalPrompt += '\n\n${cleanedOraclePrompt.trim()}';
}

finalPrompt += '\n\n${personaPrompt.trim()}';

// Helper method to remove MCP sections from Oracle prompts
static String _removeMCPSection(String oraclePrompt) {
  final mcpStart = oraclePrompt.indexOf('## SISTEMA DE COMANDO MCP');
  final mcpEnd = oraclePrompt.indexOf('---', mcpStart);
  
  if (mcpStart != -1 && mcpEnd != -1) {
    return oraclePrompt.substring(0, mcpStart) + 
           oraclePrompt.substring(mcpEnd + 3);
  }
  return oraclePrompt;
}
```

#### Claude Service Simplification
```dart
// Simplified dynamic MCP - only runtime/session-specific content
if (_systemMCP != null) {
  String mcpFunctions = '\n\n## RUNTIME SYSTEM FUNCTIONS\n\n'
      'Available in this session:\n'
      '- get_current_time: Active\n'
      '- get_device_info: Active\n'
      '- get_activity_stats: Active\n'
      '- get_message_stats: Active\n\n'
      
      '**Current Session Context:**\n'
      '- Time Context: Available\n'
      '- Activity Tracking: Enabled\n'
      '- Database Connection: Connected\n';

  systemPrompt += mcpFunctions;
}
```

## Migration Strategy

### Phase 1: Preparation (2 hours)
1. Create MCP instructions configuration file
2. Extract current MCP content from Oracle 4.0 prompt
3. Consolidate best practices from both static and dynamic sources
4. Define application rules and version compatibility

### Phase 2: Integration (3 hours)
1. Update `CharacterConfigManager.loadSystemPrompt()`
2. Implement MCP config loading logic
3. Add MCP section removal helper method
4. Test MCP loading for Oracle personas

### Phase 3: Oracle Cleanup (2 hours)
1. Remove MCP sections from `oracle_prompt_4.0.md`
2. Remove MCP sections from `oracle_prompt_3.0.md`
3. Remove MCP sections from `oracle_prompt_2.1.md`
4. Verify Oracle content integrity after removal

### Phase 4: Claude Service Simplification (2 hours)
1. Identify dynamic-only MCP content in Claude Service
2. Remove redundant static instructions
3. Simplify to session-specific information only
4. Test API call functionality

### Phase 5: Testing & Validation (3 hours)
1. Test all Oracle personas (2.1, 3.0, 4.0) for MCP functionality
2. Test non-Oracle personas to ensure no MCP instructions
3. Verify token reduction and rate limiting improvements
4. Validate temporal intelligence and complex query processing
5. Performance testing and monitoring

## Acceptance Criteria

### AC-130.1: Configuration Loading
- [ ] MCP instructions config file loads successfully
- [ ] MCP instructions apply only to Oracle personas
- [ ] Non-Oracle personas exclude MCP instructions
- [ ] Application rules control MCP behavior correctly

### AC-130.2: Oracle Integration
- [ ] MCP instructions appear before Oracle content in system prompt
- [ ] Oracle prompts no longer contain MCP sections
- [ ] Oracle functionality remains intact after MCP removal
- [ ] All Oracle versions (2.1, 3.0, 4.0) work correctly

### AC-130.3: Functionality Preservation
- [ ] All MCP commands continue to work (get_activity_stats, get_current_time)
- [ ] Temporal intelligence mapping functions correctly
- [ ] Complex query processing (exclusions, comparisons) works
- [ ] Response formatting and data utilization rules apply

### AC-130.4: Performance Improvement
- [ ] System prompt tokens reduced by minimum 400 tokens per call
- [ ] Oracle 4.0 rate limiting frequency decreases
- [ ] API response times maintain or improve
- [ ] No degradation in response quality

### AC-130.5: Maintainability
- [ ] Single file updates affect all Oracle personas
- [ ] Version control tracks MCP instruction changes
- [ ] Clear separation between static and dynamic MCP content
- [ ] Documentation updated for new architecture

## Testing Strategy

### Unit Tests
- MCP config file loading and parsing
- MCP section removal from Oracle prompts
- Conditional application based on persona type
- System prompt assembly with MCP instructions

### Integration Tests
- End-to-end MCP command execution
- Oracle persona functionality with extracted MCP
- Non-Oracle persona behavior (no MCP)
- Temporal intelligence and complex queries

### Performance Tests
- Token count measurement before/after
- Rate limiting frequency monitoring
- API response time comparison
- Memory usage impact assessment

## Risks and Mitigation

### Risk 1: Functionality Regression
**Mitigation**: Comprehensive testing of all MCP commands and temporal intelligence features before deployment

### Risk 2: Configuration Loading Failures
**Mitigation**: Graceful fallback to existing behavior if MCP config fails to load, with appropriate logging

### Risk 3: Oracle Content Corruption
**Mitigation**: Backup Oracle prompt files before modification, careful MCP section identification and removal

### Risk 4: Performance Impact
**Mitigation**: Monitor token usage and API performance, rollback capability if issues arise

## Success Metrics

### Primary Metrics
- **Token Reduction**: Minimum 400 tokens saved per API call
- **Rate Limiting**: 50% reduction in Oracle 4.0 rate limit errors
- **Maintainability**: Single file updates for MCP changes

### Secondary Metrics
- **Response Quality**: Maintain current MCP functionality
- **Performance**: No degradation in API response times
- **Reliability**: Zero functionality regressions

## Future Enhancements

### FT-130.1: Dynamic MCP Configuration
- Runtime MCP instruction updates without app restart
- Persona-specific MCP customization
- A/B testing for MCP instruction variations

### FT-130.2: MCP Instruction Versioning
- Multiple MCP instruction versions
- Gradual rollout of MCP changes
- Backward compatibility management

### FT-130.3: Advanced MCP Analytics
- MCP command usage tracking
- Performance impact analysis
- Optimization recommendations

## Dependencies

### Internal Dependencies
- Oracle 4.0 Analysis (FT-Oracle-4.0-Analysis)
- Audio formatting configuration pattern
- Character configuration management system

### External Dependencies
- Flutter asset loading system
- JSON configuration parsing
- System prompt assembly pipeline

## Conclusion

FT-130 addresses critical Oracle 4.0 performance issues while improving the overall architecture of MCP instruction management. By extracting MCP instructions to a separate configuration file, we achieve significant token savings, eliminate redundancy, and create a more maintainable system following established patterns in the codebase.
