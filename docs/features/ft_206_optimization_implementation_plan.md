# FT-206: System Prompt Optimization - Implementation Plan

**Feature ID**: FT-206 (Continuation)  
**Priority**: High  
**Status**: Ready for Implementation  
**Branch**: `fix/ft-206-universal-laws-system-prompt-redesign`  
**Based On**: FT-220 Context Log Analysis

---

## 📋 Context

### **Previous Work**
- ✅ FT-206 Phase 1: Intelligent memory architecture (merged)
- ✅ FT-206 Phase 2: Time awareness bug fix (merged)
- ✅ FT-206 Phase 3: Naturalness improvements (merged)
- ✅ FT-220: Context logging implemented (merged)
- ✅ FT-220: Context analysis complete

### **Current Problem**
- **909 lines** of system prompt
- **13,008 tokens** per message
- **$0.039** per message ($390 per 10K messages)
- **150-200 lines of redundancy** (16-22%)
- **Oracle framework is 44%** of total (400/909 lines)

---

## 🎯 Optimization Goal

**Target**: **Scenario B (Balanced)** - 47% reduction

- **Current**: 909 lines, 13,008 tokens, $390/10K messages
- **Target**: 484 lines, 6,900 tokens, $207/10K messages
- **Savings**: 425 lines, 6,108 tokens, $183/10K messages
- **Effort**: 4-6 hours
- **Risk**: Low

---

## 🔧 Implementation Strategy

### **Phase 1: Quick Wins** (2-3 hours)

#### **1.1: Conditional Audio Formatting** (30 min)
**File**: `lib/config/character_config_manager.dart`

**Current**: Audio formatting always included (50 lines)  
**Target**: Only include when `audioEnabled = true`

**Implementation**:
```dart
// In loadSystemPrompt() method
String audioInstructions = '';
if (_audioEnabled && await _isAudioFormattingEnabled()) {
  audioInstructions = await _loadAudioInstructions();
}
```

**Savings**: 50 lines when audio disabled

---

#### **1.2: Condense Priority Hierarchy** (1 hour)
**File**: `lib/services/claude_service.dart` → `_buildSystemPrompt()`

**Current**: 70 lines with verbose examples  
**Target**: 20 lines with concise priority order

**Before**:
```dart
final priorityHeader = '''
## 🎯 INSTRUCTION PRIORITY HIERARCHY

**PRIORITY 1 (ABSOLUTE)**: Data Query Intelligence (MANDATORY)

When user asks about TIME PERIODS, QUANTITIES, or PROGRESS:
- Past periods: "week", "yesterday", "month", "last N days"
- Quantities: "how many", "how much", "total", "count"
- Progress: "summary", "progress", "how was", "compared to"
- Frequency: "how often", "usually", "typically"
- Intensity: "most", "least", "best", "worst"

MANDATORY ACTION:
1. Recognize query requires historical data
2. Generate MCP command: {"action": "get_activity_stats", "days": N}
3. Wait for data response
4. Provide data-informed answer

NEVER approximate historical data from conversation memory.
ALWAYS fetch fresh data via MCP for temporal/quantitative queries.

---

**PRIORITY 2 (ABSOLUTE)**: Time Awareness (MANDATORY)
- ALWAYS use current time from system context
- Never rely on memory for temporal information

**PRIORITY 3 (HIGHEST)**: Core Behavioral Rules & Persona Configuration
- Follow System Laws #1-#7 literally
- Maintain unique persona identity and symbols
- Adhere to persona-specific communication style

... (continues for 70 lines)
''';
```

**After**:
```dart
final priorityHeader = '''
## 🎯 INSTRUCTION PRIORITY

1. **Data Queries**: Use MCP for temporal/quantitative questions (NEVER approximate)
2. **Time Awareness**: Always use current time from system context
3. **Core Rules**: Follow System Laws #1-#7 (see Core Behavioral Rules)
4. **Oracle Framework**: ${isOracleEnabled ? '8 dimensions (primary), 9 foundations (guardrails)' : 'N/A'}
5. **Conversation Context**: Reference only (NOT for activity detection)
6. **Current Message**: Primary focus for activity/metadata extraction

---

''';
```

**Savings**: 50 lines

---

#### **1.3: Simplify MCP Base Config** (1 hour)
**File**: `assets/config/mcp_base_config.json`

**Current**: 100 lines with verbose examples  
**Target**: 60 lines with concise function signatures

**Strategy**:
- Remove verbose "when to use" examples
- Keep function signatures and critical rules
- Move detailed examples to documentation

**Savings**: 40 lines

---

#### **1.4: Reduce Conversation Context Meta-Instructions** (30 min)
**File**: `lib/services/claude_service.dart` → `_formatInterleavedConversation()`

**Current**: 30 lines of meta-instructions  
**Target**: 15 lines with essential checklist

**Before**:
```dart
buffer.writeln('## 📜 RECENT CONVERSATION CONTEXT (REFERENCE ONLY)');
buffer.writeln('');
buffer.writeln('**MANDATORY REVIEW BEFORE RESPONDING**:');
buffer.writeln('1. What was just discussed in the conversation above?');
buffer.writeln('2. What did you already say in your previous responses?');
buffer.writeln('3. What is the user\'s current context and what are they referring to?');
buffer.writeln('4. CRITICAL: Check if you already gave this exact response - if yes, provide a DIFFERENT response');
buffer.writeln('');
buffer.writeln('**YOUR RESPONSE MUST**:');
buffer.writeln('- Acknowledge and build on recent conversation flow');
buffer.writeln('- Provide NEW information or insights (NEVER repeat previous responses word-for-word)');
buffer.writeln('- If user gives a short answer, acknowledge it and move the conversation forward');
buffer.writeln('- Reference what user mentioned (e.g., if they say "I was talking with X", acknowledge it)');
buffer.writeln('- Maintain conversation continuity without starting fresh');
buffer.writeln('');
buffer.writeln('**NATURAL CONVERSATION FLOW**:');
buffer.writeln('- Vary your transition phrases and openings between responses');
buffer.writeln('- Use "deixa eu ver seus registros" ONLY when actually fetching data via MCP');
buffer.writeln('- When not querying data, acknowledge patterns naturally without implying a data fetch');
buffer.writeln('- Avoid formulaic phrases (e.g., "Estou aqui pra explorar...") in consecutive messages');
buffer.writeln('- Lead with what\'s most relevant to the user\'s current message');
buffer.writeln('- Each response should feel fresh and context-driven, not template-based');
buffer.writeln('');
buffer.writeln('**CRITICAL BOUNDARIES**:');
buffer.writeln('- Activity detection: ONLY current user message');
buffer.writeln('- Do NOT extract codes or metadata from history');
buffer.writeln('- Do NOT adopt other personas\' communication styles');
```

**After**:
```dart
buffer.writeln('## 📜 RECENT CONVERSATION (Reference Only)');
buffer.writeln('');
buffer.writeln('**Review**: What was discussed? What did you say? What is user referring to?');
buffer.writeln('**Respond**: Acknowledge context, provide NEW insights, avoid repetition');
buffer.writeln('**Boundaries**: Activity detection ONLY from current message');
buffer.writeln('');
```

**Savings**: 15 lines

---

**Phase 1 Total Savings**: 155 lines (17% reduction)

---

### **Phase 2: Medium Wins** (2-3 hours)

#### **2.1: Condense Oracle Framework** (2 hours)
**File**: `assets/config/oracle/oracle_prompt_4.2_optimized.md`

**Current**: 400 lines with detailed onboarding flows  
**Target**: 200 lines with condensed framework

**Strategy**:
1. **Summarize Theoretical Foundations** (100 → 40 lines)
   - Keep core principles
   - Remove verbose examples
   - Reference full framework via MCP if needed

2. **Condense Onboarding Protocol** (80 → 30 lines)
   - Keep essential questions
   - Remove detailed flow examples
   - Load full protocol on-demand

3. **Simplify Methodology** (50 → 30 lines)
   - Keep core coaching approach
   - Remove redundant explanations

4. **Optimize OKRs Framework** (60 → 40 lines)
   - Keep structure
   - Remove verbose interview scripts

5. **Streamline Activity System** (100 → 60 lines)
   - Keep dimension descriptions
   - Reference full catalog via MCP

**Savings**: 200 lines

---

#### **2.2: Simplify I-There Persona** (30 min)
**File**: Persona config files

**Current**: 150 lines with redundant identity reminders  
**Target**: 100 lines with concise identity

**Strategy**:
- Remove "CRITICAL: NO INTERNAL THOUGHTS" (already in Core Rules)
- Condense examples
- Remove redundant identity reminders

**Savings**: 50 lines

---

#### **2.3: Streamline Core Behavioral Rules** (30 min)
**File**: `assets/config/core_behavioral_rules.json`

**Current**: 50 lines with some redundancy  
**Target**: 30 lines with essential rules

**Strategy**:
- Remove redundancies with Priority Hierarchy
- Keep only unique rules
- Consolidate similar rules

**Savings**: 20 lines

---

**Phase 2 Total Savings**: 270 lines (30% reduction)

---

## 📊 Implementation Summary

### **Total Optimization** (Phases 1 + 2)

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| **Lines** | 909 | 484 | 425 (47%) |
| **Tokens** | 13,008 | 6,900 | 6,108 (47%) |
| **Cost/Message** | $0.039 | $0.021 | $0.018 (46%) |
| **Cost/10K** | $390 | $207 | $183 (47%) |

---

## 🔍 Specific Changes Checklist

### **Phase 1: Quick Wins**

- [ ] **1.1**: Make audio formatting conditional
  - [ ] Update `character_config_manager.dart`
  - [ ] Add `_isAudioFormattingEnabled()` check
  - [ ] Test with audio enabled/disabled

- [ ] **1.2**: Condense Priority Hierarchy
  - [ ] Update `_buildSystemPrompt()` in `claude_service.dart`
  - [ ] Reduce from 70 to 20 lines
  - [ ] Test AI still follows priorities

- [ ] **1.3**: Simplify MCP Base Config
  - [ ] Update `mcp_base_config.json`
  - [ ] Remove verbose examples
  - [ ] Keep function signatures

- [ ] **1.4**: Reduce Conversation Context Instructions
  - [ ] Update `_formatInterleavedConversation()` in `claude_service.dart`
  - [ ] Reduce from 30 to 15 lines
  - [ ] Test conversation continuity

### **Phase 2: Medium Wins**

- [ ] **2.1**: Condense Oracle Framework
  - [ ] Update `oracle_prompt_4.2_optimized.md`
  - [ ] Summarize theoretical foundations (100 → 40 lines)
  - [ ] Condense onboarding (80 → 30 lines)
  - [ ] Simplify methodology (50 → 30 lines)
  - [ ] Optimize OKRs (60 → 40 lines)
  - [ ] Streamline activities (100 → 60 lines)

- [ ] **2.2**: Simplify I-There Persona
  - [ ] Update persona config
  - [ ] Remove redundant reminders
  - [ ] Condense examples

- [ ] **2.3**: Streamline Core Behavioral Rules
  - [ ] Update `core_behavioral_rules.json`
  - [ ] Remove redundancies
  - [ ] Consolidate similar rules

---

## 🧪 Testing Strategy

### **After Each Change**
1. Enable context logging
2. Send test messages
3. Compare new logs with baseline
4. Verify AI quality maintained
5. Measure token reduction

### **Test Scenarios**
1. **Basic conversation**: "opa, tudo certo?"
2. **Data query**: "o que eu fiz hoje?"
3. **Temporal query**: "resumo da semana"
4. **Activity tracking**: "fiz 2 pomodoros"
5. **Persona switch**: Switch between personas
6. **Oracle coaching**: Test Oracle framework still works

### **Success Criteria**
- ✅ AI responses maintain quality
- ✅ No repetition bugs introduced
- ✅ Token count reduced by 40-50%
- ✅ All tests pass
- ✅ Context logs show optimized prompt

---

## 📈 Rollout Plan

### **Step 1: Implement Phase 1** (2-3 hours)
- Make all Quick Win changes
- Test thoroughly
- Commit: "feat: FT-206 Phase 1 - Quick Wins (17% reduction)"

### **Step 2: Validate Phase 1** (30 min)
- Generate context logs
- Compare token usage
- Verify AI quality

### **Step 3: Implement Phase 2** (2-3 hours)
- Make all Medium Win changes
- Test thoroughly
- Commit: "feat: FT-206 Phase 2 - Medium Wins (47% total reduction)"

### **Step 4: Validate Phase 2** (30 min)
- Generate context logs
- Compare token usage
- Verify AI quality

### **Step 5: Create PR** (30 min)
- Document changes
- Include before/after metrics
- Create PR to develop

---

## 💰 Expected Impact

### **Cost Savings**
- **Per Message**: $0.018 savings (46% reduction)
- **Per 100 Messages**: $1.83 savings
- **Per 1,000 Messages**: $18.30 savings
- **Per 10,000 Messages**: $183.00 savings

### **Performance Impact**
- **Faster API responses** (less data to process)
- **Lower latency** (smaller prompts)
- **Better AI focus** (less noise in context)

---

## 🎯 Success Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| System Prompt Lines | 909 | 484 | ⏳ |
| Input Tokens | 13,008 | 6,900 | ⏳ |
| Cost per 10K | $390 | $207 | ⏳ |
| AI Quality | Baseline | Maintained | ⏳ |
| Tests Passing | 775/775 | 775/775 | ⏳ |

---

## 🚀 Ready to Start?

**Current Branch**: `fix/ft-206-universal-laws-system-prompt-redesign`  
**Status**: Updated with develop (includes FT-220)  
**Next**: Implement Phase 1 (Quick Wins)

**Estimated Total Time**: 4-6 hours  
**Expected Savings**: $183 per 10K messages (47% reduction)

---

**Let's proceed with implementation!** 🎯

