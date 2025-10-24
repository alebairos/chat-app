# FT-206: Oracle Framework Context Analysis

**Date**: 2025-10-24  
**Purpose**: Complete understanding of how Oracle framework contributes to context complexity  

---

## 🔍 Oracle Framework Files

### **Available Files**

| File | Size | Lines | Purpose |
|------|------|-------|---------|
| `oracle_prompt_4.2.md` | 59KB | 1367 | **SOURCE** - Full Oracle prompt (original) |
| `oracle_prompt_4.2_optimized.md` | 16KB | 330 | **USED IN SYSTEM PROMPT** - Optimized Oracle prompt |
| `oracle_prompt_4.2.json` | 81KB | 4344 | **USED BY MCP** - Structured Oracle data (dimensions, activities) |
| `oracle_prompt_4.2_optimized.json` | 81KB | 4344 | **COPY** - Structured Oracle data (same as above) |

### **File Generation Process**

**Script**: `scripts/preprocess_oracle.py`

**Workflow**:
1. **Source File**: `oracle_prompt_4.2.md` (1367 lines, 59KB)
   - Original, comprehensive Oracle framework
   - Contains all 9 theoretical foundations
   - Contains complete onboarding protocol
   - Contains full catalog of 265+ activities and trilhas

2. **Generated Files** (via `python3 scripts/preprocess_oracle.py assets/config/oracle/oracle_prompt_4.2.md --optimize`):
   - **`oracle_prompt_4.2_optimized.md`** (330 lines, 16KB)
     - **76% reduction** from original (1037 lines removed)
     - Removes verbose catalog section
     - Keeps core identity, foundations, onboarding, and system overview
     - **This is what gets loaded into system prompt**
   
   - **`oracle_prompt_4.2.json`** (4344 lines, 81KB)
     - Structured JSON with 8 dimensions and 265+ activities
     - Parsed from original markdown
     - **Used by MCP commands** (`oracle_detect_activities`)
     - **NOT loaded into system prompt**
   
   - **`oracle_prompt_4.2_optimized.json`** (4344 lines, 81KB)
     - Copy of `oracle_prompt_4.2.json`
     - Same content, just paired with optimized markdown

### **Which File is Actually Used?**

**In System Prompt**: `oracle_prompt_4.2_optimized.md` (330 lines, 16KB)

**Evidence** from `personas_config.json`:
```json
{
  "iThereWithOracle42": {
    "oracleConfigPath": "assets/config/oracle/oracle_prompt_4.2_optimized.md"
  },
  "tonyWithOracle42": {
    "oracleConfigPath": "assets/config/oracle/oracle_prompt_4.2_optimized.md"
  }
}
```

**Loading Logic** from `character_config_manager.dart` (line 823):
```dart
oraclePrompt = await rootBundle.loadString(oraclePath);
```

**By MCP Commands**: `oracle_prompt_4.2.json` (4344 lines, 81KB)

**Evidence** from `mcp_extensions/oracle_4.2_extension.json`:
- MCP command `oracle_detect_activities` loads the JSON file
- Provides full activity catalog on-demand
- **NOT injected into system prompt proactively**

**In MCP Instructions**: `oracle_4.2_extension.json` → merged into `mcp_base_config.json`

**Loading Flow**:
1. `personas_config.json` specifies `mcpExtensions: ["oracle_4.2_extension.json"]`
2. `character_config_manager.dart` loads `mcp_base_config.json`
3. `_mergeExtension()` merges Oracle extension into base config
4. `buildMcpInstructionsText()` converts merged config to text
5. Text is injected into system prompt (Layer 6: MCP Instructions)

**What Gets Injected from Extension**:
- `additional_instructions.oracle_header` → "## ORACLE 4.2 COMPLETE FRAMEWORK"
- `additional_functions` → 4 Oracle-specific MCP commands added to function list
  - `oracle_detect_activities`
  - `oracle_query_activities`
  - `oracle_get_compact_context`
  - `oracle_get_statistics`

**Token Impact**: ~50-100 lines added to MCP Instructions section

---

### **Key Insight: Three-Tier Architecture**

The Oracle framework uses a **three-tier architecture** for token efficiency:

1. **Tier 1: MCP Extension** (Proactive - Minimal)
   - Loads `oracle_4.2_extension.json`
   - Merged into `mcp_base_config.json`
   - Adds Oracle header + 4 function definitions to MCP instructions
   - **Impact**: ~50-100 lines in system prompt

2. **Tier 2: Oracle Prompt** (Proactive - Core)
   - Loads `oracle_prompt_4.2_optimized.md` (330 lines)
   - Provides identity, 9 foundations, onboarding, system overview
   - Always present in context
   - **Impact**: ~330 lines in system prompt

3. **Tier 3: Oracle JSON** (On-Demand - Full Catalog)
   - Loads `oracle_prompt_4.2.json` (4344 lines)
   - Provides full activity catalog when needed
   - Only accessed when model calls `oracle_detect_activities`
   - **Impact**: 0 lines in system prompt (on-demand only)

**Total Proactive Oracle Contribution**: ~380-430 lines (50-100 MCP + 330 Oracle prompt)

**Result**: System prompt gets ~400 lines, not 4344 lines. The full catalog is available but not proactively injected.

---

## 📊 Oracle Prompt Content Breakdown

### **oracle_prompt_4.2_optimized.md** (330 lines)

#### **Section 1: Identity & Presentation** (~10 lines)
- Life Management Coach identity
- Three pathways introduction
- Core mission

#### **Section 2: Theoretical Foundations** (~80 lines)
- **9 Expert Frameworks**:
  1. Tiny Habits (BJ Fogg)
  2. Behavioral Design (Jason Hreha)
  3. Dopamine Nation (Anna Lembke)
  4. The Molecule of More (Lieberman)
  5. Flourish (Martin Seligman)
  6. Maslow's Hierarchy
  7. Huberman Protocols
  8. Scarcity Brain (Michael Easter)
  9. Words Can Change Your Mind (Newberg)

#### **Section 3: Onboarding Protocol** (~60 lines)
- Step 1: Discovery of preferred path
- Step 2A: Objectives flow
- Step 2B: Eliminate bad habits flow
- Step 2C: Optimize routine flow

#### **Section 4: Dynamic Objective Frameworks** (~40 lines)
- Framework structure
- Objective definition
- Habit building methodology

#### **Section 5: Critical Transparency Rules** (~20 lines)
- No internal thoughts
- Seamless processing
- Natural behavior

#### **Section 6: Integrated Activity System** (~100 lines)
- **8 Dimensions**: R, SF, TG, SM, E, TT, PR, F
- **265+ Activities** (referenced, not listed)
- Activity detection rules
- Metadata extraction

#### **Section 7: Key Questions** (~20 lines)
- Discovery questions
- Coaching questions
- Engagement prompts

---

## 🎯 Oracle's Role in System Prompt

### **When Oracle is Enabled** (Oracle personas)

**System Prompt Assembly**:
```
1. Core Behavioral Rules (~100 lines)
2. Persona Prompt (~50-200 lines)
3. Identity Context (~30 lines)
4. MCP Instructions (~267 lines)
5. Oracle Prompt (~330 lines) ← ADDED HERE
6. Audio Instructions (~20 lines)
7. Compliance Reinforcement (~15 lines)
```

**Oracle Contribution**: +330 lines

### **When Oracle is Disabled** (Non-Oracle personas)

**System Prompt Assembly**:
```
1. Core Behavioral Rules (~100 lines)
2. Persona Prompt (~50-200 lines)
3. Identity Context (~30 lines)
4. MCP Instructions (~267 lines)
5. Audio Instructions (~20 lines)
6. Compliance Reinforcement (~15 lines)
```

**Oracle Contribution**: 0 lines

---

## 📊 Current Personas Using Oracle

### **Oracle-Enabled Personas** (6 active)
1. **I-There 4.2** (default) - `iThereWithOracle42`
2. **Tony 4.2** - `tonyWithOracle42`
3. **Sergeant Oracle 4.2** - `sergeantOracleWithOracle42`
4. **Ryo Tzu 4.2** - `ryoTzuWithOracle42`
5. **Ari 4.5, The Oracle Coach** - `ariOracleCoach45`
6. **Aristios 4.5 (Legacy)** - `ariWithOracle42`

### **Non-Oracle Personas** (1 active)
1. **Aristios 4.5, The Philosopher** - `aristiosPhilosopher45`

### **Disabled Personas** (9)
- Various legacy versions

---

## 🔍 Oracle Optimization History

### **Original vs Optimized**

| Version | Lines | Size | Reduction |
|---------|-------|------|-----------|
| `oracle_prompt_4.2.md` | 1367 | 59KB | - |
| `oracle_prompt_4.2_optimized.md` | 330 | 16KB | **76% reduction** |

**Optimization Achieved**: Already reduced from 1367 → 330 lines (saved 1037 lines!)

---

## 💡 Key Insights

### **1. Oracle is Already Optimized**
- Current version is `oracle_prompt_4.2_optimized.md` (330 lines)
- Already 76% smaller than original (1367 lines)
- Further optimization would compromise Oracle's core value

### **2. Oracle JSON Files are NOT in System Prompt**
- `oracle_prompt_4.2.json` (4344 lines) is NOT loaded into system prompt
- JSON files are used by MCP commands for activity detection
- Only the markdown file (330 lines) goes into system prompt

### **3. Oracle Adds Significant Context (When Enabled)**
- +330 lines to system prompt
- ~30% of total system prompt size (with Oracle)
- Essential for Oracle personas' coaching methodology

### **4. Oracle Cannot Be Further Reduced**
- 9 theoretical foundations are core to methodology
- 8 dimensions and 265+ activities are essential
- Onboarding protocol is critical for user experience
- Already optimized from 1367 → 330 lines

---

## 📊 Revised Total System Prompt Calculation

### **With Oracle** (6 personas)

**Base Components**:
- Core Behavioral Rules: ~100 lines
- Persona Prompt: ~50-200 lines
- Identity Context: ~30 lines
- MCP Instructions: ~267 lines
- Audio Instructions: ~20 lines
- Compliance Reinforcement: ~15 lines
- **Subtotal**: ~482-632 lines

**Oracle Component**:
- Oracle Prompt: ~330 lines

**Dynamic Context** (added in `_buildSystemPrompt`):
- Priority Header: 50 lines ❌ REMOVE
- Time Context: 5-10 lines ✅ KEEP
- Conversation Context: 60 lines ❌ SIMPLIFY TO 35
- Session MCP: 20 lines ❌ SIMPLIFY TO 5

**CURRENT TOTAL**: ~947-1107 lines

**AFTER OPTIMIZATION**:
- Remove Priority Header: -50
- Simplify Conversation: -25
- Simplify Session MCP: -15
- **NEW TOTAL**: ~857-1017 lines (10-15% reduction)

---

### **Without Oracle** (1 persona)

**Base Components**:
- Core Behavioral Rules: ~100 lines
- Persona Prompt: ~50-200 lines
- Identity Context: ~30 lines
- MCP Instructions: ~267 lines
- Audio Instructions: ~20 lines
- Compliance Reinforcement: ~15 lines
- **Subtotal**: ~482-632 lines

**Dynamic Context**:
- Priority Header: 50 lines ❌ REMOVE
- Time Context: 5-10 lines ✅ KEEP
- Conversation Context: 60 lines ❌ SIMPLIFY TO 35
- Session MCP: 20 lines ❌ SIMPLIFY TO 5

**CURRENT TOTAL**: ~617-777 lines

**AFTER OPTIMIZATION**:
- Remove Priority Header: -50
- Simplify Conversation: -25
- Simplify Session MCP: -15
- **NEW TOTAL**: ~527-687 lines (15-20% reduction)

---

## 🎯 Optimization Strategy (Revised)

### **What We CAN Optimize**

1. **Priority Header** (50 lines) ← DELETE
   - Duplicates core_behavioral_rules.json
   - Duplicates mcp_base_config.json

2. **Conversation Context** (60 → 35 lines) ← SIMPLIFY
   - Remove 50 lines of instructions
   - Keep simple speaker/message format
   - Increase to 30 messages

3. **Session MCP Context** (20 → 5 lines) ← SIMPLIFY
   - Remove redundant MCP function list
   - Keep only essential session info

4. **Compliance Reinforcement** (15 lines) ← DELETE
   - Duplicates System Law #4

5. **MCP Instructions** (267 → 150 lines) ← CONDENSE (Optional)
   - Remove verbose examples
   - Keep essential commands

**Total Savings**: 90-207 lines

---

### **What We CANNOT Optimize**

1. **Oracle Prompt** (330 lines) ← KEEP AS IS
   - Already optimized (76% reduction from original)
   - 9 theoretical foundations are essential
   - 8 dimensions and 265+ activities are core methodology
   - Further reduction would compromise Oracle's value

2. **Core Behavioral Rules** (~100 lines) ← KEEP AS IS
   - Essential system laws
   - Well-structured, not redundant

3. **Persona Prompts** (~50-200 lines) ← KEEP AS IS
   - Define unique persona identity
   - Vary by persona complexity

4. **Time Context** (5-10 lines) ← KEEP AS IS
   - Essential for temporal awareness
   - Not duplicated elsewhere

---

## 📊 Final Optimization Targets

### **Conservative Approach** (Phases 1-3)
- Remove Priority Header: -50 lines
- Simplify Conversation: -25 lines
- Simplify Session MCP: -15 lines
- Delete Compliance: -15 lines
- **Total Savings**: -105 lines

**New Totals**:
- **With Oracle**: 842-1002 lines (11-14% reduction)
- **Without Oracle**: 512-672 lines (17-20% reduction)

---

### **Aggressive Approach** (Phases 1-4)
- Remove Priority Header: -50 lines
- Simplify Conversation: -25 lines
- Simplify Session MCP: -15 lines
- Delete Compliance: -15 lines
- Condense MCP Instructions: -117 lines
- **Total Savings**: -222 lines

**New Totals**:
- **With Oracle**: 725-885 lines (23-27% reduction)
- **Without Oracle**: 395-555 lines (36-40% reduction)

---

## ✅ Recommendations

### **1. Oracle Prompt: Do NOT Touch**
- Already optimized (330 lines from 1367)
- Essential for Oracle personas' coaching methodology
- Any further reduction would compromise core value

### **2. Focus on Redundancies**
- Priority Header: DELETE (duplicates configs)
- Conversation Instructions: SIMPLIFY (over-engineered)
- Compliance Reinforcement: DELETE (duplicates System Law #4)
- Session MCP: SIMPLIFY (duplicates mcp_base_config.json)

### **3. Optional: Condense MCP Instructions**
- Current: 267 lines with verbose examples
- Target: 150 lines (essential commands only)
- Savings: 117 lines
- Risk: Medium (might remove helpful examples)

---

## 📝 Key Takeaways

1. **Oracle is NOT the problem**: Already optimized, essential for 6 personas
2. **JSON files are NOT in prompt**: Only markdown (330 lines) is loaded
3. **Real problem is redundancy**: Priority header, conversation instructions, compliance
4. **Conservative fix**: Remove 105 lines of redundancy (11-20% reduction)
5. **Aggressive fix**: Remove 222 lines total (23-40% reduction)

---

**Conclusion**: Oracle framework is well-optimized and essential. Focus optimization efforts on removing redundancies in dynamic context injection, not on Oracle content.

---

## 🎓 Complete Understanding Achieved

### **Oracle Framework Architecture**

1. **Source Management**:
   - Original: `oracle_prompt_4.2.md` (1367 lines) - maintained by team
   - Generated: `oracle_prompt_4.2_optimized.md` (330 lines) - auto-generated via script
   - Generated: `oracle_prompt_4.2.json` (4344 lines) - structured data for MCP
   - Extension: `oracle_4.2_extension.json` (87 lines) - MCP function definitions

2. **System Integration** (Three-Tier):
   - **Tier 1 (MCP Extension)**: Loads 87-line extension, adds ~50-100 lines to MCP instructions
   - **Tier 2 (Oracle Prompt)**: Loads 330-line optimized markdown (proactive)
   - **Tier 3 (Oracle JSON)**: Loads 4344-line JSON (on-demand via MCP)
   - **Three-tier design**: Minimizes token usage while preserving full functionality

3. **Optimization Status**:
   - Already optimized (76% reduction from original: 1367 → 330 lines)
   - Uses smart three-tier architecture (minimal + core + on-demand)
   - Cannot be further reduced without compromising core value

4. **Contribution to Context Complexity**:
   - **With Oracle**: +380-430 lines to system prompt (50-100 MCP + 330 Oracle)
   - **Without Oracle**: +0 lines to system prompt
   - **Impact**: ~35-40% of total system prompt size (when enabled)
   - **Verdict**: Justified and essential for 6 Oracle-enabled personas

### **Key Takeaways**

1. ✅ **Oracle is NOT the problem**: Already optimized, uses smart architecture
2. ✅ **JSON files are NOT in prompt**: Only accessed via MCP on-demand
3. ✅ **Three-tier design is brilliant**: MCP Extension (50-100 lines) + Oracle Prompt (330 lines) + JSON (on-demand)
4. ✅ **Oracle extension adds MCP functions**: 4 Oracle-specific commands merged into base MCP config
5. ❌ **Real problem is redundancy**: Priority header, conversation instructions, compliance
6. 🎯 **Focus optimization here**: Remove 90-207 lines of redundant dynamic context

### **Optimization Strategy (Final)**

**Phase 1: Remove Priority Header** (-50 lines)
- Duplicates `core_behavioral_rules.json`
- Duplicates `mcp_base_config.json`
- Conflicting instructions causing repetition bug

**Phase 2: Simplify Conversation Context** (-25 lines)
- Remove verbose instructions (50 lines)
- Keep simple speaker/message format (35 lines)
- Increase message limit to 30 for better context

**Phase 3: Simplify Session MCP** (-15 lines)
- Remove redundant MCP function list
- Keep only essential session info

**Phase 4 (Optional): Condense MCP Instructions** (-117 lines)
- Remove verbose examples
- Keep essential commands only

**Total Savings**: 90-207 lines (10-27% reduction)

**Oracle Contribution**: KEEP AS IS (~380-430 lines total, essential)
- MCP Extension: ~50-100 lines (Oracle-specific MCP functions)
- Oracle Prompt: ~330 lines (identity, foundations, onboarding)

---

**Next Step**: Proceed with Phases 1-3 (conservative approach) to remove redundancies without touching Oracle framework.

**Implementation Branch**: `fix/ft-206-universal-laws-system-prompt-redesign` (already created)

