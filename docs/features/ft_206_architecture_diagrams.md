# FT-206: Architecture Diagrams - Agent System & Feature Mapping

**Analysis Date**: 2025-10-24  
**Status**: Visual Architecture Design  
**Branch**: `fix/ft-206-universal-laws-system-prompt-redesign`  
**Related Documents**: 
- Doc 3: `ft_206_agent_architecture.md`
- Doc 2: `ft_206_dart_agent_library_analysis.md`
- Doc 1: `ft_206_device_first_architecture_strategy.md`

---

## 📐 Diagram 1: Minimal Agent Library Architecture

### **Core Abstractions (~300 lines)**

```
┌─────────────────────────────────────────────────────────────────┐
│                    minimal_agent_dart                           │
│                    (Dart Package)                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│   Agent      │      │   Skill      │     │   Tool       │
│  (Interface) │      │  (Interface) │     │  (Interface) │
└──────────────┘      └──────────────┘     └──────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────────────────────────────────────────────────┐
│ • process(context) → response                            │
│ • decide(context) → decision                             │
│ • execute(decision) → response                           │
│ • reflect(response) → response                           │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│ • isRelevant(context) → bool                             │
│ • getRequiredTools(context) → List<Tool>                 │
│ • apply(context, toolResults) → string                   │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│ • isRequired(context) → bool                             │
│ • execute(context) → dynamic                             │
└──────────────────────────────────────────────────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│  Guardrail   │      │   Models     │     │   Context    │
│ (Interface)  │      │              │     │              │
└──────────────┘      └──────────────┘     └──────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────────────────────────────────────────────────┐
│ • check(response) → GuardrailResult                      │
│ • revise(response, result) → response                    │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│ • AgentContext                                           │
│ • AgentDecision                                          │
│ • AgentResponse                                          │
│ • GuardrailResult                                        │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│ • ContextBuilder                                         │
│ • DecisionEngine                                         │
│ • Providers (Persona, Time, Conversation, etc.)          │
└──────────────────────────────────────────────────────────┘
```

---

## 📐 Diagram 2: Agent Execution Flow (ReAct Pattern)

### **Three-Phase Agent Loop**

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER MESSAGE                            │
│                    "o que eu fiz hoje?"                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 1: DECIDE                              │
│                  (Minimal Context)                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. Build Minimal Context (~500-1,000 tokens)            │  │
│  │    • Persona identity (5 lines)                          │  │
│  │    • User message                                        │  │
│  │    • Last 2 messages                                     │  │
│  │    • Available tools catalog                             │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 2. Identify Relevant Skills                              │  │
│  │    • CoachingSkill.isRelevant() → false                  │  │
│  │    • ActivityTrackingSkill.isRelevant() → TRUE ✓         │  │
│  │    • ReflectionSkill.isRelevant() → false                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 3. Identify Required Tools                               │  │
│  │    • ActivityStatsTool.isRequired() → TRUE ✓             │  │
│  │    • TimeContextTool.isRequired() → TRUE ✓               │  │
│  │    • OracleDetectionTool.isRequired() → false            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ OUTPUT: AgentDecision                                    │  │
│  │  {                                                        │  │
│  │    reasoning: "User asking about today's activities",    │  │
│  │    skills: [ActivityTrackingSkill],                      │  │
│  │    tools: [ActivityStatsTool, TimeContextTool]           │  │
│  │  }                                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 2: EXECUTE                             │
│                  (Focused Context)                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. Execute Tools (Parallel)                              │  │
│  │                                                           │  │
│  │    ActivityStatsTool.execute()                           │  │
│  │    ├─→ Query Isar DB (10ms)                              │  │
│  │    └─→ Return: [water: 14:30, exercise: 16:00]          │  │
│  │                                                           │  │
│  │    TimeContextTool.execute()                             │  │
│  │    ├─→ Get current time                                  │  │
│  │    └─→ Return: "2025-10-24 18:30"                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 2. Build Focused Context (~2,000-3,000 tokens)           │  │
│  │    • Persona core identity (20 lines)                    │  │
│  │    • User message                                        │  │
│  │    • Pass 1 reasoning                                    │  │
│  │    • Tool results (activity data + time)                 │  │
│  │    • Last 5 messages                                     │  │
│  │    • Self-review checklist                               │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 3. Apply Skills (LLM Call)                               │  │
│  │    • Call Claude API with focused context                │  │
│  │    • Generate response using tool results                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ OUTPUT: Draft AgentResponse                              │  │
│  │  {                                                        │  │
│  │    content: "Registrei água às 14:30 e exercício...",    │  │
│  │    skillsUsed: [ActivityTrackingSkill],                  │  │
│  │    toolsUsed: [ActivityStatsTool, TimeContextTool]       │  │
│  │  }                                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 3: REFLECT                             │
│                  (Apply Guardrails)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. PersonaIdentityGuardrail.check()                      │  │
│  │    ✓ No brackets                                         │  │
│  │    ✓ No other persona mentions                           │  │
│  │    ✓ Matches persona style                               │  │
│  │    → PASSED                                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 2. OracleComplianceGuardrail.check()                     │  │
│  │    ✓ No activities from history                          │  │
│  │    ✓ No Oracle codes in response                         │  │
│  │    → PASSED                                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 3. ResponseQualityGuardrail.check()                      │  │
│  │    ✓ No repetition                                       │  │
│  │    ✓ Appropriate length                                  │  │
│  │    ✓ Coherent                                            │  │
│  │    → PASSED                                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ OUTPUT: Final AgentResponse                              │  │
│  │  {                                                        │  │
│  │    content: "Registrei água às 14:30 e exercício...",    │  │
│  │    skillsUsed: [ActivityTrackingSkill],                  │  │
│  │    toolsUsed: [ActivityStatsTool, TimeContextTool],      │  │
│  │    metadata: {                                           │  │
│  │      guardrails_passed: true,                            │  │
│  │      execution_time_ms: 2150                             │  │
│  │    }                                                      │  │
│  │  }                                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FINAL RESPONSE TO USER                       │
│           "Registrei água às 14:30 e exercício às 16:00"       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📐 Diagram 3: Device-First Architecture (Current State)

### **On-Device Components**

```
┌─────────────────────────────────────────────────────────────────┐
│                         DEVICE (iPhone/Android)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    UI LAYER                               │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │ ChatScreen                                          │  │ │
│  │  │  • Message input                                    │  │ │
│  │  │  • Message list                                     │  │ │
│  │  │  • Persona selector                                 │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                  AGENT LAYER                              │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │ PersonaAgent                                        │  │ │
│  │  │  • decide() → AgentDecision                         │  │ │
│  │  │  • execute() → AgentResponse                        │  │ │
│  │  │  • reflect() → AgentResponse                        │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │                              │                             │ │
│  │       ┌──────────────────────┼──────────────────────┐      │ │
│  │       │                      │                      │      │ │
│  │       ▼                      ▼                      ▼      │ │
│  │  ┌─────────┐          ┌─────────┐          ┌─────────┐   │ │
│  │  │ Skills  │          │  Tools  │          │Guardrail│   │ │
│  │  ├─────────┤          ├─────────┤          ├─────────┤   │ │
│  │  │Coaching │          │Activity │          │Persona  │   │ │
│  │  │Activity │          │Stats    │          │Identity │   │ │
│  │  │Tracking │          │Time     │          │Oracle   │   │ │
│  │  │Reflect  │          │Context  │          │Complianc│   │ │
│  │  └─────────┘          │Oracle   │          │Quality  │   │ │
│  │                       │Detection│          └─────────┘   │ │
│  │                       └─────────┘                         │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                  CONTEXT LAYER                            │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │ ContextBuilder                                      │  │ │
│  │  │  • buildDecisionContext() (minimal)                 │  │ │
│  │  │  • buildResponseContext() (focused)                 │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │                              │                             │ │
│  │       ┌──────────────────────┼──────────────────────┐      │ │
│  │       │                      │                      │      │ │
│  │       ▼                      ▼                      ▼      │ │
│  │  ┌─────────┐          ┌─────────┐          ┌─────────┐   │ │
│  │  │Providers│          │Providers│          │Providers│   │ │
│  │  ├─────────┤          ├─────────┤          ├─────────┤   │ │
│  │  │Persona  │          │Time     │          │Oracle   │   │ │
│  │  │Context  │          │Context  │          │Context  │   │ │
│  │  │Conversa │          │MCP      │          │         │   │ │
│  │  │tion     │          │Context  │          │         │   │ │
│  │  └─────────┘          └─────────┘          └─────────┘   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                   DATA LAYER                              │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │ Isar Database                                       │  │ │
│  │  │  • ChatMessages (conversation history)              │  │ │
│  │  │  • Activities (tracked activities)                  │  │ │
│  │  │  • UserSettings (preferences)                       │  │ │
│  │  │  • JournalEntries (reflections)                     │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │ Local File System                                   │  │ │
│  │  │  • Audio messages (m4a files)                       │  │ │
│  │  │  • Context logs (debug)                             │  │ │
│  │  │  • Exported data (JSON)                             │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │ Configuration Files                                 │  │ │
│  │  │  • Persona configs (JSON)                           │  │ │
│  │  │  • Oracle framework (JSON/MD)                       │  │ │
│  │  │  • MCP configs (JSON)                               │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ ONLY LLM INFERENCE
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      EXTERNAL API                               │
│                    (Claude API)                                 │
│                                                                 │
│  • Pass 1: Decision-making (~1,000 tokens)                     │
│  • Pass 2: Response generation (~2,500 tokens)                 │
│  • Activity detection (when needed)                            │
│                                                                 │
│  ✓ Stateless (no user data stored)                            │
│  ✓ Privacy-preserving (only context sent)                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📐 Diagram 4: Current Features → Agent Architecture Mapping

### **Feature Mapping**

```
┌─────────────────────────────────────────────────────────────────┐
│                    CURRENT FEATURES                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ FT-084           │  │ FT-140           │  │ FT-206           │
│ Two-Pass         │  │ Oracle Activity  │  │ Conversation     │
│ Data Integration │  │ Detection        │  │ Context Loading  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AGENT ARCHITECTURE                           │
└─────────────────────────────────────────────────────────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ AGENT            │  │ TOOLS            │  │ CONTEXT          │
│ • decide()       │  │ • ActivityStats  │  │ • ContextBuilder │
│ • execute()      │  │ • OracleDetect   │  │ • Providers      │
│ • reflect()      │  │ • TimeContext    │  │ • Strategies     │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

### **Detailed Feature Mapping**

```
┌─────────────────────────────────────────────────────────────────┐
│ FEATURE: FT-084 Two-Pass Data Integration                      │
├─────────────────────────────────────────────────────────────────┤
│ Current Implementation:                                         │
│  • ClaudeService._processDataRequiredQuery()                   │
│  • Detects MCP commands in response                            │
│  • Executes MCP, enriches context, calls LLM again             │
│                                                                 │
│ Maps To:                                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ AGENT: PersonaAgent                                      │  │
│  │  • decide() → Identifies required tools (Pass 1)         │  │
│  │  • execute() → Runs tools + LLM (Pass 2)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TOOLS: ActivityStatsTool, TimeContextTool               │  │
│  │  • isRequired() → Detect if tool needed                 │  │
│  │  • execute() → Fetch data from Isar/MCP                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CONTEXT: ContextBuilder                                  │  │
│  │  • buildDecisionContext() → Minimal (Pass 1)            │  │
│  │  • buildResponseContext() → Focused + data (Pass 2)     │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FEATURE: FT-140 Oracle Activity Detection                      │
├─────────────────────────────────────────────────────────────────┤
│ Current Implementation:                                         │
│  • SystemMCPService._oracleDetectActivities()                  │
│  • Loads Oracle 4.2 framework (265 activities)                 │
│  • Calls Claude to detect activities                           │
│                                                                 │
│ Maps To:                                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ SKILL: ActivityTrackingSkill                             │  │
│  │  • isRelevant() → Check if message has activities       │  │
│  │  • getRequiredTools() → [OracleDetectionTool]           │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TOOL: OracleDetectionTool                                │  │
│  │  • isRequired() → Check if Oracle enabled               │  │
│  │  • execute() → Load Oracle context + detect activities  │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ GUARDRAIL: OracleComplianceGuardrail                     │  │
│  │  • check() → Ensure only current message processed      │  │
│  │  • revise() → Remove Oracle codes from response         │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CONTEXT: OracleContextProvider                           │  │
│  │  • shouldInclude() → Only if Oracle needed              │  │
│  │  • buildSection() → Load Oracle framework               │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FEATURE: FT-206 Conversation Context Loading                   │
├─────────────────────────────────────────────────────────────────┤
│ Current Implementation:                                         │
│  • ClaudeService._buildRecentConversationContext()             │
│  • Loads last N messages from Isar                             │
│  • Formats as interleaved conversation                         │
│                                                                 │
│ Maps To:                                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TOOL: ConversationContextTool                            │  │
│  │  • isRequired() → Always (for continuity)               │  │
│  │  • execute() → Fetch last N messages from Isar          │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CONTEXT: ConversationContextProvider                     │  │
│  │  • shouldInclude() → Always                              │  │
│  │  • buildSection() → Format interleaved conversation     │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FEATURE: FT-060 Time Context Integration                       │
├─────────────────────────────────────────────────────────────────┤
│ Current Implementation:                                         │
│  • TimeContextService.generatePreciseTimeContext()             │
│  • Calculates time gaps (sameSession, today, yesterday, etc.)  │
│  • Provides temporal awareness                                 │
│                                                                 │
│ Maps To:                                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TOOL: TimeContextTool                                    │  │
│  │  • isRequired() → Always (for time awareness)           │  │
│  │  • execute() → Get current time + calculate time gap    │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CONTEXT: TimeContextProvider                             │  │
│  │  • shouldInclude() → Always                              │  │
│  │  • buildSection() → Format time context                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FEATURE: FT-189 Multi-Persona Awareness                        │
├─────────────────────────────────────────────────────────────────┤
│ Current Implementation:                                         │
│  • CharacterConfigManager._buildIdentityContext()              │
│  • Loads persona identity and cross-persona awareness          │
│  • Prevents persona confusion                                  │
│                                                                 │
│ Maps To:                                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CONTEXT: PersonaContextProvider                          │  │
│  │  • shouldInclude() → Always                              │  │
│  │  • buildSection() → Load persona identity + boundaries  │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ GUARDRAIL: PersonaIdentityGuardrail                      │  │
│  │  • check() → No brackets, no other persona mentions     │  │
│  │  • revise() → Remove violations                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FEATURE: FT-211 Coaching Objective Persistence                 │
├─────────────────────────────────────────────────────────────────┤
│ Current Implementation:                                         │
│  • (Proposed) Track active coaching goals                      │
│  • Maintain focus on objectives                                │
│  • Prevent topic drift                                         │
│                                                                 │
│ Maps To:                                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ SKILL: CoachingSkill                                     │  │
│  │  • isRelevant() → Check if coaching needed              │  │
│  │  • getRequiredTools() → [CoachingObjectiveTool]         │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TOOL: CoachingObjectiveTool (NEW)                        │  │
│  │  • isRequired() → Check if active objectives exist      │  │
│  │  • execute() → Fetch active coaching objectives         │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CONTEXT: CoachingContextProvider (NEW)                   │  │
│  │  • shouldInclude() → If coaching skill active           │  │
│  │  • buildSection() → Load active objectives + progress   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FEATURE: FT-103 Activity Detection Throttling                  │
├─────────────────────────────────────────────────────────────────┤
│ Current Implementation:                                         │
│  • ClaudeService._processBackgroundActivitiesWithQualification│
│  • Model-driven qualification (does message need detection?)   │
│  • Intelligent delay to prevent rate limiting                  │
│                                                                 │
│ Maps To:                                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ SKILL: ActivityTrackingSkill                             │  │
│  │  • isRelevant() → Intelligent qualification             │  │
│  │    (replaces model-driven qualification)                │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TOOL: OracleDetectionTool                                │  │
│  │  • isRequired() → Check if activities present           │  │
│  │  • execute() → Detect activities (with throttling)      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FEATURE: FT-220 Context Logging                                │
├─────────────────────────────────────────────────────────────────┤
│ Current Implementation:                                         │
│  • ContextLoggerService.logContext()                           │
│  • Logs complete context sent to LLM                           │
│  • Stores in logs/context/ for debugging                       │
│                                                                 │
│ Maps To:                                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ AGENT: PersonaAgent (Instrumentation)                    │  │
│  │  • Log before decide() → Pass 1 context                 │  │
│  │  • Log before execute() → Pass 2 context                │  │
│  │  • Log after reflect() → Final response + metadata      │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CONTEXT: ContextBuilder (Instrumentation)                │  │
│  │  • Log context size per provider                         │  │
│  │  • Log total context size                                │  │
│  │  • Log strategy used                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📐 Diagram 5: Future Architecture with Local Models

### **Hybrid Device-First + Local Tiny Models**

```
┌─────────────────────────────────────────────────────────────────┐
│                         DEVICE (iPhone/Android)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    AGENT LAYER                            │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │ HybridPersonaAgent                                  │  │ │
│  │  │  • decide() → Use local models for classification   │  │ │
│  │  │  • execute() → Use local or external LLM           │  │ │
│  │  │  • reflect() → Apply guardrails                     │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                  LOCAL MODELS                             │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │ TensorFlow Lite Models                              │  │ │
│  │  │                                                      │  │ │
│  │  │  • Activity Detection Model (~50MB)                 │  │ │
│  │  │    ├─→ Input: User message                          │  │ │
│  │  │    └─→ Output: [SF1, R3, TG5] (50ms)               │  │ │
│  │  │                                                      │  │ │
│  │  │  • Intent Classification Model (~40MB)              │  │ │
│  │  │    ├─→ Input: User message                          │  │ │
│  │  │    └─→ Output: 'coaching' | 'query' | ... (30ms)   │  │ │
│  │  │                                                      │  │ │
│  │  │  • Sentiment Analysis Model (~30MB)                 │  │ │
│  │  │    ├─→ Input: User message                          │  │ │
│  │  │    └─→ Output: {pos: 0.2, neg: 0.5} (20ms)         │  │ │
│  │  │                                                      │  │ │
│  │  │  • Basic Response Model (~100MB) (FUTURE)           │  │ │
│  │  │    ├─→ Input: User message + context               │  │ │
│  │  │    └─→ Output: Simple response (200ms)             │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                  DECISION LOGIC                           │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │ Can local models handle this?                       │  │ │
│  │  │                                                      │  │ │
│  │  │  YES → Use local models                             │  │ │
│  │  │    • Activity detection: Local model (50ms)         │  │ │
│  │  │    • Simple responses: Local model (200ms)          │  │ │
│  │  │    • Cost: $0                                       │  │ │
│  │  │    • Privacy: 100% (no external call)              │  │ │
│  │  │    • Offline: ✓ Works                               │  │ │
│  │  │                                                      │  │ │
│  │  │  NO → Use external LLM                              │  │ │
│  │  │    • Complex reasoning: Claude API (2000ms)         │  │ │
│  │  │    • Cost: $0.008                                   │  │ │
│  │  │    • Privacy: Context only                          │  │ │
│  │  │    • Offline: ✗ Requires network                    │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ ONLY FOR COMPLEX QUERIES
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      EXTERNAL API                               │
│                    (Claude API)                                 │
│                                                                 │
│  • Complex reasoning only                                      │
│  • 60% reduction in API calls                                  │
│  • $0.003 per complex query                                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      PERFORMANCE COMPARISON                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Current (External LLM Only):                                  │
│    • Latency: 2000ms                                           │
│    • Cost: $0.008 per message                                  │
│    • Offline: ✗                                                │
│    • Privacy: Context sent to API                              │
│                                                                 │
│  Future (Hybrid):                                              │
│    • Latency: 50-200ms (simple) | 2000ms (complex)            │
│    • Cost: $0 (simple) | $0.008 (complex)                     │
│    • Offline: ✓ (simple queries)                              │
│    • Privacy: 100% (simple) | Context only (complex)          │
│                                                                 │
│  Estimated Impact:                                             │
│    • 60% of messages handled locally                           │
│    • 40% of messages use external LLM                          │
│    • Average cost: $0.003 per message (62% reduction)          │
│    • Average latency: 1000ms (50% improvement)                 │
│    • Offline capability: 60% of features                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📐 Diagram 6: Complete System Architecture

### **End-to-End Flow**

```
┌─────────────────────────────────────────────────────────────────┐
│                            USER                                 │
│                    "o que eu fiz hoje?"                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                │
│  ChatScreen → ChatController → ClaudeService                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AGENT LAYER                                │
│  PersonaAgent.processMessage(context)                          │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ PHASE 1: DECIDE (Minimal Context)                        │  │
│  │  1. Build minimal context (~1,000 tokens)                │  │
│  │  2. Identify relevant skills                             │  │
│  │     • ActivityTrackingSkill.isRelevant() → TRUE          │  │
│  │  3. Identify required tools                              │  │
│  │     • ActivityStatsTool.isRequired() → TRUE              │  │
│  │     • TimeContextTool.isRequired() → TRUE                │  │
│  │  4. Return AgentDecision                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ PHASE 2: EXECUTE (Focused Context)                       │  │
│  │  1. Execute tools                                         │  │
│  │     • ActivityStatsTool.execute()                        │  │
│  │       └─→ Query Isar DB → [water: 14:30, exercise: 16:00]│ │
│  │     • TimeContextTool.execute()                          │  │
│  │       └─→ Get current time → "2025-10-24 18:30"         │  │
│  │  2. Build focused context (~2,500 tokens)                │  │
│  │  3. Apply skills (LLM call)                              │  │
│  │     • Call Claude API with focused context               │  │
│  │  4. Return draft AgentResponse                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ PHASE 3: REFLECT (Apply Guardrails)                      │  │
│  │  1. PersonaIdentityGuardrail.check() → PASSED            │  │
│  │  2. OracleComplianceGuardrail.check() → PASSED           │  │
│  │  3. ResponseQualityGuardrail.check() → PASSED            │  │
│  │  4. Return final AgentResponse                           │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      CONTEXT LAYER                              │
│  ContextBuilder                                                 │
│                                                                 │
│  Decision Context (Pass 1):                                    │
│    • PersonaContextProvider → Minimal persona (5 lines)        │
│    • ConversationContextProvider → Last 2 messages             │
│    • MCPContextProvider → Tool catalog                         │
│    Total: ~1,000 tokens                                        │
│                                                                 │
│  Response Context (Pass 2):                                    │
│    • PersonaContextProvider → Core persona (20 lines)          │
│    • TimeContextProvider → Time context                        │
│    • ConversationContextProvider → Last 5 messages             │
│    • Tool results → Activity data                              │
│    Total: ~2,500 tokens                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DATA LAYER                                │
│  Isar Database                                                  │
│    • ChatMessages → Conversation history                       │
│    • Activities → Tracked activities                           │
│    • UserSettings → Preferences                                │
│                                                                 │
│  Local File System                                             │
│    • Audio messages                                            │
│    • Context logs                                              │
│                                                                 │
│  Configuration Files                                           │
│    • Persona configs                                           │
│    • Oracle framework                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      EXTERNAL API                               │
│  Claude API                                                     │
│    • Pass 1: Decision-making (~1,000 tokens)                   │
│    • Pass 2: Response generation (~2,500 tokens)               │
│    Total: ~3,500 tokens (73% reduction from current)           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                            USER                                 │
│         "Registrei água às 14:30 e exercício às 16:00"         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Summary Tables

### **Agent Components**

| Component | Current Implementation | Agent Architecture | Benefit |
|-----------|----------------------|-------------------|---------|
| **Decision Logic** | Scattered in ClaudeService | `Agent.decide()` | ✅ Centralized |
| **Execution** | Mixed with context building | `Agent.execute()` | ✅ Clear separation |
| **Validation** | Implicit in prompts | `Agent.reflect()` + Guardrails | ✅ Explicit enforcement |
| **Skills** | Implicit in prompts | `BaseSkill` implementations | ✅ Modular, testable |
| **Tools** | MCP commands | `BaseTool` implementations | ✅ Composable |
| **Context** | Scattered methods | `ContextBuilder` + Providers | ✅ Organized |

### **Token Reduction**

| Phase | Current | Agent Architecture | Reduction |
|-------|---------|-------------------|-----------|
| **Pass 1** | 13,008 tokens | 1,000 tokens | 92% |
| **Pass 2** | N/A | 2,500 tokens | N/A |
| **Total** | 13,008 tokens | 3,500 tokens | **73%** |
| **Cost/Message** | $0.039 | $0.011 | **72%** |

---

## 📝 Conclusion

The agent architecture provides:
1. ✅ **Clear abstractions** (Agent, Skill, Tool, Guardrail)
2. ✅ **Modular design** (easy to extend and test)
3. ✅ **Device-first** (privacy, performance, cost)
4. ✅ **Future-proof** (ready for local models)
5. ✅ **Industry-standard** (ReAct, Tool Use, Guardrails)

**All current features map cleanly to the agent architecture!** 🎯

---

**Diagrams Complete** ✅

