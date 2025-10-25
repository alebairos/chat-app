# FT-206: Dart Agent Library Analysis - Build vs Buy

**Analysis Date**: 2025-10-24  
**Status**: Research & Recommendation  
**Branch**: `fix/ft-206-universal-laws-system-prompt-redesign`  
**Related Features**: FT-206 Agent Architecture

---

## 🎯 Research Question

**Is there a neat, concise, efficient agent library for Dart?**

Requirements:
- ✅ Neat and concise (not overengineered like LangChain)
- ✅ Efficient (minimal overhead)
- ✅ Supports agent patterns (Skills, Tools, Guardrails)
- ✅ Dart/Flutter compatible

---

## 🔍 Research Findings

### **TL;DR**: No suitable library exists. Build your own (it's simple!).

---

## 📦 Available Dart Libraries

### **1. LangChain Dart** ❌

**Package**: `langchain_dart` on pub.dev  
**Status**: Available  
**Last Updated**: 2024

**What It Is**:
- Full LangChain port to Dart
- Comprehensive framework with chains, agents, memory, embeddings, vector stores
- Part of the LangChain ecosystem

**Why It Doesn't Fit**:
- ❌ **Overengineered**: Exactly what we want to avoid
- ❌ **Heavy abstractions**: Too many layers
- ❌ **Bloated**: Includes features we don't need (vector stores, embeddings, etc.)
- ❌ **Complex**: Steep learning curve
- ❌ **Breaking changes**: External dependency risk

**Verdict**: Too heavy for our needs

---

### **2. agent_dart** ❌

**Package**: `agent_dart` on pub.dev  
**Status**: Available  
**Last Updated**: 2024

**What It Is**:
- Agent library for Dfinity's Internet Computer blockchain
- Designed for decentralized app development
- Handles blockchain interactions and canister calls

**Why It Doesn't Fit**:
- ❌ **Wrong domain**: Blockchain agents, not LLM agents
- ❌ **Different patterns**: Not ReAct, Tool Use, or Guardrails
- ❌ **Specialized**: Tailored for Internet Computer protocol

**Verdict**: Different problem space

---

### **3. Isolate Agents** ❌

**Package**: `isolate_agents` on pub.dev  
**Status**: Available  
**Last Updated**: 2024

**What It Is**:
- Simplifies Dart Isolates for concurrent programming
- Provides standardized protocol for Isolate communication
- Reduces overhead of managing Isolates

**Why It Doesn't Fit**:
- ❌ **Wrong domain**: Concurrency, not AI agents
- ❌ **Different patterns**: Multi-threading, not agent patterns
- ❌ **Not AI-focused**: No LLM integration

**Verdict**: Different problem space

---

### **4. agent_dart_base** ❌

**Package**: `agent_dart_base` on pub.dev  
**Status**: Available  
**Last Updated**: 2024

**What It Is**:
- Base library for Internet Computer agents
- Foundation for building IC agents in Dart/Flutter
- Part of the agent_dart ecosystem

**Why It Doesn't Fit**:
- ❌ **Same as agent_dart**: Blockchain-focused
- ❌ **Not general-purpose**: Specialized for IC protocol

**Verdict**: Different problem space

---

## 💡 Recommendation: Build Your Own

### **Why Build Instead of Buy?**

1. ✅ **Simple patterns**: Agent abstractions are straightforward (~500 lines total)
2. ✅ **No dependencies**: No external library to maintain
3. ✅ **Tailored**: Exactly what you need, nothing more
4. ✅ **Full control**: No breaking changes from external libraries
5. ✅ **Easy to understand**: You own the code
6. ✅ **No bloat**: Only the features you use

### **What You Actually Need**

The agent patterns we designed in `ft_206_agent_architecture.md` are minimal:

```dart
// Core abstractions (~100 lines)
abstract class BaseAgent {
  Future<AgentResponse> processMessage({...});
  Future<AgentDecision> decide({...});
  Future<AgentResponse> execute({...});
  Future<AgentResponse> reflect({...});
}

abstract class BaseSkill {
  String get name;
  Future<bool> isRelevant(String userMessage, AgentContext context);
  Future<List<BaseTool>> getRequiredTools(...);
}

abstract class BaseTool {
  String get name;
  Future<bool> isRequired(String userMessage, AgentContext context);
  Future<dynamic> execute(AgentContext context);
}

abstract class BaseGuardrail {
  String get name;
  Future<GuardrailResult> check(AgentResponse response, AgentContext context);
  Future<AgentResponse> revise(...);
}

// Models (~50 lines)
class AgentContext { ... }
class AgentDecision { ... }
class AgentResponse { ... }
class GuardrailResult { ... }

// Implementation (~350 lines)
class PersonaAgent extends BaseAgent { ... }
```

**Total**: ~500 lines of clean, focused code.

---

## 🎯 Implementation Options

### **Option 1: Implement in Your App** ⭐ RECOMMENDED

**Approach**: Implement agent architecture directly in your app

**Pros**:
- ✅ No external dependencies
- ✅ Tailored to your exact needs
- ✅ Full control over implementation
- ✅ Easy to test and debug
- ✅ No library overhead
- ✅ Fast iteration

**Cons**:
- ⚠️ You maintain the code (but it's simple!)
- ⚠️ Not reusable across projects (unless extracted later)

**Effort**: 22-32 hours (as outlined in `ft_206_agent_architecture.md`)

**Timeline**:
- **Week 1**: Agent core + Skills (10-14 hours)
- **Week 2**: Tools + Guardrails (8-12 hours)
- **Week 3**: Integration + Testing (4-6 hours)

---

### **Option 2: Build a Minimal Library First**

**Approach**: Create a minimal agent library, then use it in your app

**Pros**:
- ✅ Reusable across projects
- ✅ Clean separation of concerns
- ✅ Could publish to pub.dev
- ✅ Help the Dart community

**Cons**:
- ⚠️ More upfront work
- ⚠️ Need to maintain a separate package
- ⚠️ Slower iteration (library + app)

**Effort**: 30-40 hours (library + integration)

**Timeline**:
- **Week 1-2**: Build minimal library (20-26 hours)
- **Week 3**: Integrate with app (6-8 hours)
- **Week 4**: Test and refine (4-6 hours)

---

### **Option 3: Hybrid Approach** (Best Long-Term)

**Approach**: Implement in app first, extract library later

**Phase 1** (Weeks 1-3): Implement in app
- Build agent architecture directly in app
- Iterate quickly based on real needs
- Validate patterns work for your use case

**Phase 2** (Week 4+): Extract library
- Extract core abstractions into separate package
- Publish to pub.dev as `minimal_agent_dart`
- Keep app-specific implementations in app

**Pros**:
- ✅ Fast initial iteration
- ✅ Validated patterns before extraction
- ✅ Eventually reusable
- ✅ Help the Dart community

**Cons**:
- ⚠️ Refactoring work later
- ⚠️ Need to maintain library eventually

**Effort**: 22-32 hours (Phase 1) + 8-12 hours (Phase 2)

---

## 📋 Minimal Agent Library Spec

If you decide to create a library (Option 2 or 3), here's what it should include:

### **Package Structure**

```
minimal_agent_dart/
├── lib/
│   ├── minimal_agent.dart (Main export)
│   │
│   ├── src/
│   │   ├── agent.dart (BaseAgent interface)
│   │   ├── skill.dart (BaseSkill interface)
│   │   ├── tool.dart (BaseTool interface)
│   │   ├── guardrail.dart (BaseGuardrail interface)
│   │   │
│   │   └── models/
│   │       ├── agent_context.dart
│   │       ├── agent_decision.dart
│   │       ├── agent_response.dart
│   │       └── guardrail_result.dart
│   │
│   └── test/
│       ├── agent_test.dart
│       ├── skill_test.dart
│       ├── tool_test.dart
│       └── guardrail_test.dart
│
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### **Core Abstractions** (~200 lines)

**File**: `lib/src/agent.dart`

```dart
/// Base interface for all agents.
/// 
/// Implements the ReAct pattern: Reasoning + Acting
/// - decide(): Analyze situation and plan actions
/// - execute(): Perform actions using skills and tools
/// - reflect(): Self-review and apply guardrails
abstract class Agent {
  /// Agent identity
  String get name;
  String get role;
  
  /// Agent capabilities
  List<Skill> get skills;
  List<Tool> get tools;
  List<Guardrail> get guardrails;
  
  /// Core agent loop: Decide → Execute → Reflect
  Future<AgentResponse> process(AgentContext context);
  
  /// PHASE 1: Decision-making
  Future<AgentDecision> decide(AgentContext context);
  
  /// PHASE 2: Execution
  Future<AgentResponse> execute(AgentDecision decision, AgentContext context);
  
  /// PHASE 3: Self-reflection
  Future<AgentResponse> reflect(AgentResponse draft, AgentContext context);
}
```

**File**: `lib/src/skill.dart`

```dart
/// A skill is a capability the agent can perform.
/// 
/// Skills represent high-level competencies like coaching,
/// data analysis, content generation, etc.
abstract class Skill {
  /// Skill identity
  String get name;
  String get description;
  
  /// Is this skill relevant for the current context?
  Future<bool> isRelevant(AgentContext context);
  
  /// What tools does this skill need?
  Future<List<Tool>> getRequiredTools(AgentContext context);
  
  /// Apply this skill (optional - can be handled by agent's LLM)
  Future<String> apply({
    required AgentContext context,
    required Map<String, dynamic> toolResults,
  }) async {
    return ''; // Default: handled by agent
  }
}
```

**File**: `lib/src/tool.dart`

```dart
/// A tool is an external capability the agent can invoke.
/// 
/// Tools represent concrete functions like API calls,
/// database queries, file operations, etc.
abstract class Tool {
  /// Tool identity
  String get name;
  String get description;
  
  /// Is this tool required for the current context?
  Future<bool> isRequired(AgentContext context);
  
  /// Execute the tool
  Future<dynamic> execute(AgentContext context);
}
```

**File**: `lib/src/guardrail.dart`

```dart
/// A guardrail is a constraint or rule the agent must follow.
/// 
/// Guardrails are applied after response generation to ensure
/// compliance with rules, constraints, and quality standards.
abstract class Guardrail {
  /// Guardrail identity
  String get name;
  String get description;
  
  /// Check if response passes this guardrail
  Future<GuardrailResult> check(
    AgentResponse response,
    AgentContext context,
  );
  
  /// Revise response to pass this guardrail
  Future<AgentResponse> revise(
    AgentResponse response,
    AgentContext context,
    GuardrailResult checkResult,
  );
}
```

### **Models** (~100 lines)

**File**: `lib/src/models/agent_context.dart`

```dart
/// Context provided to the agent for processing.
class AgentContext {
  final String userMessage;
  final Map<String, dynamic> metadata;
  
  AgentContext({
    required this.userMessage,
    this.metadata = const {},
  });
}
```

**File**: `lib/src/models/agent_decision.dart`

```dart
/// Result of agent's decision phase.
class AgentDecision {
  final String reasoning;
  final List<Skill> skills;
  final List<Tool> tools;
  final Map<String, dynamic> metadata;
  
  AgentDecision({
    required this.reasoning,
    required this.skills,
    required this.tools,
    this.metadata = const {},
  });
}
```

**File**: `lib/src/models/agent_response.dart`

```dart
/// Final response from the agent.
class AgentResponse {
  final String content;
  final List<Skill> skillsUsed;
  final List<Tool> toolsUsed;
  final Map<String, dynamic> metadata;
  
  AgentResponse({
    required this.content,
    required this.skillsUsed,
    required this.toolsUsed,
    this.metadata = const {},
  });
  
  AgentResponse copyWith({
    String? content,
    List<Skill>? skillsUsed,
    List<Tool>? toolsUsed,
    Map<String, dynamic>? metadata,
  }) {
    return AgentResponse(
      content: content ?? this.content,
      skillsUsed: skillsUsed ?? this.skillsUsed,
      toolsUsed: toolsUsed ?? this.toolsUsed,
      metadata: metadata ?? this.metadata,
    );
  }
}
```

**File**: `lib/src/models/guardrail_result.dart`

```dart
/// Result of a guardrail check.
class GuardrailResult {
  final bool passed;
  final String? reason;
  final Map<String, dynamic>? metadata;
  
  GuardrailResult({
    required this.passed,
    this.reason,
    this.metadata,
  });
}
```

### **Main Export** (~10 lines)

**File**: `lib/minimal_agent.dart`

```dart
/// A minimal, concise, efficient agent framework for Dart.
/// 
/// Provides core abstractions for building AI agents with:
/// - Skills: Capabilities the agent can perform
/// - Tools: External functions the agent can invoke
/// - Guardrails: Rules and constraints the agent must follow
/// 
/// Implements the ReAct pattern: Reasoning + Acting
library minimal_agent;

export 'src/agent.dart';
export 'src/skill.dart';
export 'src/tool.dart';
export 'src/guardrail.dart';
export 'src/models/agent_context.dart';
export 'src/models/agent_decision.dart';
export 'src/models/agent_response.dart';
export 'src/models/guardrail_result.dart';
```

### **Total Library Size**: ~300 lines

---

## 📊 Comparison: Build vs Buy

| Aspect | LangChain Dart | agent_dart | Build Your Own |
|--------|----------------|------------|----------------|
| **Size** | ~10,000+ lines | ~5,000+ lines | ~500 lines |
| **Complexity** | High | Medium | Low |
| **Dependencies** | Many | Medium | None |
| **Learning Curve** | Steep | Medium | Minimal |
| **Flexibility** | Limited | Limited | Full |
| **Maintenance** | External | External | You |
| **Breaking Changes** | Risk | Risk | None |
| **Tailored** | ❌ | ❌ | ✅ |
| **Overhead** | High | Medium | Minimal |
| **Fits Your Needs** | ❌ | ❌ | ✅ |

**Winner**: Build Your Own ✅

---

## 🚀 Recommendation

### **Implement Agent Architecture Directly in Your App** ⭐

**Why**:
1. ✅ **Simple**: Only ~500 lines of code
2. ✅ **No dependencies**: No external libraries to maintain
3. ✅ **Tailored**: Exactly what you need
4. ✅ **Full control**: No breaking changes
5. ✅ **Fast iteration**: Change anything anytime
6. ✅ **Easy to understand**: You own the code

**Timeline**:
- **Week 1-2**: Implement agent architecture (22-32 hours)
- **Week 3**: Optimize and test
- **Week 4**: (Optional) Extract library and publish to pub.dev

**Result**: A clean, efficient agent system that's exactly what you need.

---

## 📝 Future: Minimal Agent Library for Dart

If you extract a library later, it could be:

**Package Name**: `minimal_agent_dart`

**Description**: A minimal, concise, efficient agent framework for Dart. Provides core abstractions for building AI agents with Skills, Tools, and Guardrails. Implements the ReAct pattern (Reasoning + Acting).

**Features**:
- ✅ Minimal abstractions (~300 lines)
- ✅ Zero dependencies
- ✅ Full type safety
- ✅ Easy to extend
- ✅ Well documented
- ✅ 100% test coverage

**Target Audience**: Developers who want agent patterns without LangChain's complexity.

**This would be the library the Dart community needs!** 🎯

---

## 🎯 Next Steps

### **Immediate Actions**

1. ✅ **Decision**: Build your own (don't wait for a library)
2. ⏭️ **Implement**: Follow `ft_206_agent_architecture.md`
3. ⏭️ **Iterate**: Refine based on real usage
4. ⏭️ **Extract** (Optional): Create `minimal_agent_dart` library later

### **Long-Term Vision**

1. Implement agent architecture in your app
2. Validate patterns work for your use case
3. Extract core abstractions into library
4. Publish to pub.dev
5. Help the Dart community!

---

## 📚 References

### **Research Sources**
- pub.dev: `langchain_dart`
- pub.dev: `agent_dart`
- pub.dev: `agent_dart_base`
- pub.dev: `isolate_agents`

### **Related Documentation**
- `ft_206_agent_architecture.md` - Complete agent architecture design
- `ft_206_context_builder_architecture.md` - Context management design
- `ft_206_extend_two_pass_to_all_conversations.md` - Two-pass optimization

### **Agent Patterns**
- ReAct (Reasoning + Acting)
- Tool Use
- Guardrails
- Skills-based architecture

---

## 📝 Conclusion

**There is no neat, concise agent library for Dart** - but that's actually **good news** because:

1. ✅ The patterns are simple enough to implement yourself (~500 lines)
2. ✅ You get exactly what you need (no bloat)
3. ✅ You maintain full control (no external dependencies)
4. ✅ You could create the library the Dart community needs!

**Recommendation**: Implement the agent architecture we designed. It's clean, focused, and exactly what you're looking for.

**Future Opportunity**: Extract `minimal_agent_dart` library and help the Dart community!

---

**Research Complete** ✅  
**Recommendation**: Build Your Own ⭐

