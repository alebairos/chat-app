# FT-206: Agent-Based Architecture - Skills, Tools, and Guardrails

**Analysis Date**: 2025-10-24  
**Status**: Architectural Design  
**Branch**: `fix/ft-206-universal-laws-system-prompt-redesign`  
**Related Features**: FT-084 (Two-Pass), FT-220 (Context Logging)

---

## 🎯 Executive Summary

**Problem**: The current system is architected as a monolithic chat service, making it hard to reason about, extend, and maintain.

**Solution**: Reframe as an **agent-based system** using proven AI agent patterns:
- **Agent**: The AI persona (I-There, Tony, Ari, etc.)
- **Skills**: Capabilities the agent can perform (coaching, activity tracking, reflection)
- **Tools**: External functions the agent can invoke (MCP commands)
- **Guardrails**: Rules and constraints the agent must follow (persona identity, Oracle compliance)

**Benefits**:
- ✅ Industry-standard patterns (ReAct, Tool Use, Guardrails)
- ✅ Clear mental model (agent with skills, tools, guardrails)
- ✅ Composable capabilities (add skills/tools/guardrails independently)
- ✅ Testable in isolation (each component tested separately)
- ✅ Observable & debuggable (full visibility into agent behavior)
- ✅ Future-proof (ready for Garmin, goal planning, etc.)

---

## 🤖 Current System as an Agent

Your chat app is actually a **multi-agent system**, but it's not architected as one:

### **What It Really Is**

- **Agent**: The AI persona (I-There, Tony, Ari, Sergeant Oracle, etc.)
- **Skills**: Coaching, activity tracking, reflection, goal setting
- **Tools**: MCP functions (get_activity_stats, oracle_detect_activities, get_current_time)
- **Guardrails**: Oracle framework, persona identity rules, behavioral constraints

### **How It's Currently Architected**

- **Monolithic ClaudeService** (1,772 lines)
- **Scattered context building** across multiple methods
- **Implicit skills** (no clear abstraction)
- **Tools as MCP commands** (not modeled as agent tools)
- **Guardrails as config** (not enforced programmatically)

---

## 🏗️ Proposed: Agent-Based Architecture

### **Directory Structure**

```
lib/agents/
├── base_agent.dart (Abstract agent interface)
├── persona_agent.dart (Concrete persona implementation)
│
├── skills/
│   ├── base_skill.dart (Abstract skill interface)
│   ├── coaching_skill.dart
│   ├── activity_tracking_skill.dart
│   ├── reflection_skill.dart
│   ├── goal_planning_skill.dart (future)
│   └── health_monitoring_skill.dart (future - Garmin)
│
├── tools/
│   ├── base_tool.dart (Abstract tool interface)
│   ├── activity_stats_tool.dart
│   ├── conversation_context_tool.dart
│   ├── oracle_detection_tool.dart
│   ├── time_context_tool.dart
│   └── (future) garmin_data_tool.dart
│
├── guardrails/
│   ├── base_guardrail.dart (Abstract guardrail interface)
│   ├── persona_identity_guardrail.dart
│   ├── oracle_compliance_guardrail.dart
│   ├── response_quality_guardrail.dart
│   └── safety_guardrail.dart
│
├── models/
│   ├── agent_context.dart
│   ├── agent_decision.dart
│   └── agent_response.dart
│
└── context/
    ├── context_builder.dart (From previous analysis)
    ├── decision_engine.dart
    └── providers/ (From previous analysis)
```

---

## 📋 Detailed Design

### **1. Base Agent Interface**

**File**: `lib/agents/base_agent.dart`

```dart
/// Core agent abstraction following proven agent patterns.
/// 
/// Implements the ReAct pattern: Reasoning + Acting
/// - Decide: Analyze situation and plan actions
/// - Execute: Perform actions using skills and tools
/// - Reflect: Self-review and apply guardrails
abstract class BaseAgent {
  /// Agent identity
  String get name;
  String get role;
  String get personality;
  
  /// Agent capabilities
  List<BaseSkill> get skills;
  List<BaseTool> get tools;
  List<BaseGuardrail> get guardrails;
  
  /// Core agent loop: Decide → Execute → Reflect
  Future<AgentResponse> processMessage({
    required String userMessage,
    required AgentContext context,
  });
  
  /// PHASE 1: Decision-making (which skills/tools to use)
  Future<AgentDecision> decide({
    required String userMessage,
    required AgentContext context,
  });
  
  /// PHASE 2: Execution (use tools and skills to generate response)
  Future<AgentResponse> execute({
    required AgentDecision decision,
    required AgentContext context,
  });
  
  /// PHASE 3: Self-reflection (apply guardrails and revise if needed)
  Future<AgentResponse> reflect({
    required AgentResponse draft,
    required AgentContext context,
  });
}
```

---

### **2. Persona Agent Implementation**

**File**: `lib/agents/persona_agent.dart`

```dart
/// Concrete implementation of a persona agent.
/// 
/// Each persona (I-There, Tony, Ari, etc.) is an instance of this agent
/// with different configurations (skills, tools, guardrails).
class PersonaAgent extends BaseAgent {
  final String _personaKey;
  final ConfigLoader _configLoader;
  final ContextBuilder _contextBuilder;
  final List<BaseSkill> _skills = [];
  final List<BaseTool> _tools = [];
  final List<BaseGuardrail> _guardrails = [];
  final Logger _logger = Logger();
  
  PersonaAgent({
    required String personaKey,
    required ConfigLoader configLoader,
    required ContextBuilder contextBuilder,
  })  : _personaKey = personaKey,
        _configLoader = configLoader,
        _contextBuilder = contextBuilder {
    _initializeCapabilities();
  }
  
  void _initializeCapabilities() {
    _logger.info('Initializing agent capabilities for $_personaKey');
    
    // Register skills
    _skills.add(CoachingSkill());
    _skills.add(ActivityTrackingSkill());
    _skills.add(ReflectionSkill());
    
    // Register tools
    _tools.add(ActivityStatsTool());
    _tools.add(ConversationContextTool());
    _tools.add(OracleDetectionTool());
    _tools.add(TimeContextTool());
    
    // Register guardrails
    _guardrails.add(PersonaIdentityGuardrail(_personaKey));
    _guardrails.add(OracleComplianceGuardrail());
    _guardrails.add(ResponseQualityGuardrail());
    
    _logger.info(
      'Agent initialized: ${_skills.length} skills, '
      '${_tools.length} tools, ${_guardrails.length} guardrails',
    );
  }
  
  @override
  String get name => _configLoader.activePersonaDisplayName;
  
  @override
  String get role => 'Life coach and companion';
  
  @override
  String get personality => _configLoader.activePersonaStyle;
  
  @override
  List<BaseSkill> get skills => List.unmodifiable(_skills);
  
  @override
  List<BaseTool> get tools => List.unmodifiable(_tools);
  
  @override
  List<BaseGuardrail> get guardrails => List.unmodifiable(_guardrails);
  
  /// Core agent loop: Decide → Execute → Reflect
  @override
  Future<AgentResponse> processMessage({
    required String userMessage,
    required AgentContext context,
  }) async {
    _logger.info('Agent processing message: ${userMessage.substring(0, 50)}...');
    
    // PHASE 1: DECIDE (minimal context)
    _logger.debug('PHASE 1: Decision-making');
    final decision = await decide(
      userMessage: userMessage,
      context: context,
    );
    
    _logger.info(
      'Decision: ${decision.skills.length} skills, '
      '${decision.tools.length} tools',
    );
    
    // PHASE 2: EXECUTE (focused context + tools)
    _logger.debug('PHASE 2: Execution');
    final draft = await execute(
      decision: decision,
      context: context,
    );
    
    // PHASE 3: REFLECT (self-review + guardrails)
    _logger.debug('PHASE 3: Reflection');
    final finalResponse = await reflect(
      draft: draft,
      context: context,
    );
    
    _logger.info('Agent response complete');
    return finalResponse;
  }
  
  /// PHASE 1: Decision-making (which skills/tools to use)
  @override
  Future<AgentDecision> decide({
    required String userMessage,
    required AgentContext context,
  }) async {
    // Build minimal context for decision
    final decisionContext = await _contextBuilder.buildDecisionContext(
      userMessage: userMessage,
      recentMessages: context.recentMessages,
    );
    
    // Identify relevant skills
    final relevantSkills = await _identifyRelevantSkills(
      userMessage,
      context,
    );
    
    _logger.debug(
      'Relevant skills: ${relevantSkills.map((s) => s.name).join(", ")}',
    );
    
    // Identify required tools
    final requiredTools = await _identifyRequiredTools(
      userMessage,
      context,
      relevantSkills,
    );
    
    _logger.debug(
      'Required tools: ${requiredTools.map((t) => t.name).join(", ")}',
    );
    
    return AgentDecision(
      reasoning: 'User needs ${relevantSkills.map((s) => s.name).join(", ")}',
      skills: relevantSkills,
      tools: requiredTools,
      context: decisionContext,
    );
  }
  
  /// PHASE 2: Execution (use tools and skills)
  @override
  Future<AgentResponse> execute({
    required AgentDecision decision,
    required AgentContext context,
  }) async {
    // Execute tools to gather data
    final toolResults = await _executeTools(decision.tools, context);
    
    _logger.debug(
      'Tool results: ${toolResults.keys.join(", ")}',
    );
    
    // Build focused context with tool results
    final executionContext = await _contextBuilder.buildResponseContext(
      userMessage: context.userMessage,
      decision: decision,
      mcpData: toolResults,
    );
    
    _logger.debug(
      'Execution context: ${executionContext.length} chars',
    );
    
    // Apply skills to generate response
    final response = await _applySkills(
      decision.skills,
      context,
      toolResults,
      executionContext,
    );
    
    return AgentResponse(
      content: response,
      skillsUsed: decision.skills,
      toolsUsed: decision.tools,
      metadata: {'phase': 'execution'},
    );
  }
  
  /// PHASE 3: Self-reflection (apply guardrails)
  @override
  Future<AgentResponse> reflect({
    required AgentResponse draft,
    required AgentContext context,
  }) async {
    var currentResponse = draft;
    final guardrailResults = <String, GuardrailResult>{};
    
    // Apply all guardrails
    for (final guardrail in _guardrails) {
      final result = await guardrail.check(currentResponse, context);
      guardrailResults[guardrail.name] = result;
      
      if (!result.passed) {
        _logger.warning(
          'Guardrail failed: ${guardrail.name} - ${result.reason}',
        );
        
        // Guardrail failed - revise response
        currentResponse = await guardrail.revise(
          currentResponse,
          context,
          result,
        );
        
        _logger.info('Response revised by ${guardrail.name}');
      }
    }
    
    final allPassed = guardrailResults.values.every((r) => r.passed);
    _logger.info('Guardrails: ${allPassed ? "All passed" : "Some failed and revised"}');
    
    return currentResponse.copyWith(
      metadata: {
        ...currentResponse.metadata,
        'phase': 'reflection',
        'guardrails_passed': allPassed,
        'guardrail_results': guardrailResults,
      },
    );
  }
  
  Future<List<BaseSkill>> _identifyRelevantSkills(
    String userMessage,
    AgentContext context,
  ) async {
    final relevant = <BaseSkill>[];
    
    for (final skill in _skills) {
      if (await skill.isRelevant(userMessage, context)) {
        relevant.add(skill);
      }
    }
    
    return relevant;
  }
  
  Future<List<BaseTool>> _identifyRequiredTools(
    String userMessage,
    AgentContext context,
    List<BaseSkill> skills,
  ) async {
    final required = <BaseTool>[];
    
    // Tools required by skills
    for (final skill in skills) {
      required.addAll(await skill.getRequiredTools(userMessage, context));
    }
    
    // Tools required by message patterns
    for (final tool in _tools) {
      if (await tool.isRequired(userMessage, context)) {
        required.add(tool);
      }
    }
    
    return required.toSet().toList(); // Remove duplicates
  }
  
  Future<Map<String, dynamic>> _executeTools(
    List<BaseTool> tools,
    AgentContext context,
  ) async {
    final results = <String, dynamic>{};
    
    for (final tool in tools) {
      try {
        _logger.debug('Executing tool: ${tool.name}');
        results[tool.name] = await tool.execute(context);
      } catch (e) {
        _logger.error('Tool execution failed: ${tool.name} - $e');
        results[tool.name] = {'error': e.toString()};
      }
    }
    
    return results;
  }
  
  Future<String> _applySkills(
    List<BaseSkill> skills,
    AgentContext context,
    Map<String, dynamic> toolResults,
    String executionContext,
  ) async {
    // For now, use LLM with execution context
    // In future, skills could have specific logic
    final apiClient = ClaudeAPIClient(context.apiKey);
    
    return await apiClient.sendMessage(
      messages: [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': context.userMessage}
          ]
        }
      ],
      systemPrompt: executionContext,
    );
  }
}
```

---

### **3. Skills Interface**

**File**: `lib/agents/skills/base_skill.dart`

```dart
/// A skill is a capability the agent can perform.
/// 
/// Skills represent high-level competencies like coaching, activity tracking,
/// reflection, etc. Each skill can determine if it's relevant for a given
/// message and what tools it needs to perform its function.
abstract class BaseSkill {
  /// Skill identity
  String get name;
  String get description;
  
  /// Is this skill relevant for the current message?
  Future<bool> isRelevant(String userMessage, AgentContext context);
  
  /// What tools does this skill need?
  Future<List<BaseTool>> getRequiredTools(
    String userMessage,
    AgentContext context,
  );
  
  /// Apply this skill to generate response
  /// (Optional - can be handled by agent's LLM call)
  Future<String> apply({
    required String userMessage,
    required AgentContext context,
    required Map<String, dynamic> toolResults,
  }) async {
    // Default: No specific logic, handled by agent's LLM call
    return '';
  }
}
```

**Example: CoachingSkill**

**File**: `lib/agents/skills/coaching_skill.dart`

```dart
/// Coaching skill: Provide life coaching guidance and support.
/// 
/// This skill is relevant when users ask for help with goals, habits,
/// behavior change, or personal development.
class CoachingSkill extends BaseSkill {
  @override
  String get name => 'Coaching';
  
  @override
  String get description => 'Provide life coaching guidance and support';
  
  @override
  Future<bool> isRelevant(String userMessage, AgentContext context) async {
    // Coaching is relevant for goal-setting, habit formation, behavior change
    final patterns = [
      r'\b(quero|want|preciso|need)\b',
      r'\b(ajuda|help|apoio|support)\b',
      r'\b(como|how)\b.*(melhorar|improve|mudar|change)\b',
      r'\b(objetivo|goal|meta|target)\b',
      r'\b(hábito|habit|rotina|routine)\b',
    ];
    
    return patterns.any(
      (p) => RegExp(p, caseSensitive: false).hasMatch(userMessage),
    );
  }
  
  @override
  Future<List<BaseTool>> getRequiredTools(
    String userMessage,
    AgentContext context,
  ) async {
    // Coaching often needs activity history and Oracle framework
    return [
      ActivityStatsTool(),
      OracleDetectionTool(),
    ];
  }
}
```

**Example: ActivityTrackingSkill**

**File**: `lib/agents/skills/activity_tracking_skill.dart`

```dart
/// Activity tracking skill: Track and analyze user activities.
/// 
/// This skill is relevant when users ask about their past activities,
/// progress, or statistics.
class ActivityTrackingSkill extends BaseSkill {
  @override
  String get name => 'Activity Tracking';
  
  @override
  String get description => 'Track and analyze user activities';
  
  @override
  Future<bool> isRelevant(String userMessage, AgentContext context) async {
    // Activity tracking is relevant for queries about past activities
    final patterns = [
      r'\b(o que|what).*(fiz|fez|did)\b',
      r'\b(quantas|quantos|how many)\b',
      r'\b(resumo|summary)\b',
      r'\b(semana|week|mês|month|dia|day)\b',
      r'\b(progresso|progress)\b',
    ];
    
    return patterns.any(
      (p) => RegExp(p, caseSensitive: false).hasMatch(userMessage),
    );
  }
  
  @override
  Future<List<BaseTool>> getRequiredTools(
    String userMessage,
    AgentContext context,
  ) async {
    return [
      ActivityStatsTool(),
      TimeContextTool(),
    ];
  }
}
```

**Example: ReflectionSkill**

**File**: `lib/agents/skills/reflection_skill.dart`

```dart
/// Reflection skill: Help users reflect on experiences and insights.
/// 
/// This skill is relevant when users want to process experiences,
/// gain insights, or explore their thoughts and feelings.
class ReflectionSkill extends BaseSkill {
  @override
  String get name => 'Reflection';
  
  @override
  String get description => 'Help users reflect on experiences and insights';
  
  @override
  Future<bool> isRelevant(String userMessage, AgentContext context) async {
    // Reflection is relevant for processing experiences
    final patterns = [
      r'\b(sinto|feel|penso|think)\b',
      r'\b(percebi|noticed|aprendi|learned)\b',
      r'\b(refletir|reflect|considerar|consider)\b',
      r'\b(insight|percepção|awareness)\b',
    ];
    
    return patterns.any(
      (p) => RegExp(p, caseSensitive: false).hasMatch(userMessage),
    );
  }
  
  @override
  Future<List<BaseTool>> getRequiredTools(
    String userMessage,
    AgentContext context,
  ) async {
    return [
      ConversationContextTool(),
    ];
  }
}
```

**Future: HealthMonitoringSkill (Garmin)**

**File**: `lib/agents/skills/health_monitoring_skill.dart`

```dart
/// Health monitoring skill: Track and analyze health metrics.
/// 
/// This skill is relevant when users ask about health data from
/// connected devices like Garmin.
class HealthMonitoringSkill extends BaseSkill {
  @override
  String get name => 'Health Monitoring';
  
  @override
  String get description => 'Track and analyze health metrics from devices';
  
  @override
  Future<bool> isRelevant(String userMessage, AgentContext context) async {
    // Health monitoring is relevant for health metric queries
    final patterns = [
      r'\b(heart rate|frequência cardíaca)\b',
      r'\b(sleep|sono)\b',
      r'\b(stress|estresse)\b',
      r'\b(steps|passos)\b',
      r'\b(vo2|cardio)\b',
    ];
    
    return patterns.any(
      (p) => RegExp(p, caseSensitive: false).hasMatch(userMessage),
    );
  }
  
  @override
  Future<List<BaseTool>> getRequiredTools(
    String userMessage,
    AgentContext context,
  ) async {
    return [
      GarminDataTool(),
      TimeContextTool(),
    ];
  }
}
```

---

### **4. Tools Interface**

**File**: `lib/agents/tools/base_tool.dart`

```dart
/// A tool is an external capability the agent can invoke.
/// 
/// Tools represent concrete functions like fetching activity stats,
/// getting conversation history, detecting Oracle activities, etc.
/// They are the agent's interface to external systems and data.
abstract class BaseTool {
  /// Tool identity
  String get name;
  String get description;
  
  /// Is this tool required for the current message?
  Future<bool> isRequired(String userMessage, AgentContext context);
  
  /// Execute the tool
  Future<dynamic> execute(AgentContext context);
}
```

**Example: ActivityStatsTool**

**File**: `lib/agents/tools/activity_stats_tool.dart`

```dart
/// Tool for retrieving user activity statistics.
/// 
/// Wraps the get_activity_stats MCP command.
class ActivityStatsTool extends BaseTool {
  final SystemMCPService _mcpService;
  
  ActivityStatsTool(this._mcpService);
  
  @override
  String get name => 'get_activity_stats';
  
  @override
  String get description => 'Retrieve user activity statistics for a time period';
  
  @override
  Future<bool> isRequired(String userMessage, AgentContext context) async {
    // Check if message asks about activities
    final patterns = [
      r'\b(o que|what).*(fiz|fez|did)\b',
      r'\b(quantas|quantos|how many)\b',
      r'\b(atividades|activities)\b',
      r'\b(resumo|summary)\b',
    ];
    
    return patterns.any(
      (p) => RegExp(p, caseSensitive: false).hasMatch(userMessage),
    );
  }
  
  @override
  Future<dynamic> execute(AgentContext context) async {
    // Determine time period from message
    final days = _extractDaysFromMessage(context.userMessage);
    
    // Execute MCP command
    final command = jsonEncode({
      'action': 'get_activity_stats',
      'days': days,
    });
    
    return await _mcpService.processCommand(command);
  }
  
  int _extractDaysFromMessage(String message) {
    if (message.contains('hoje') || message.contains('today')) return 0;
    if (message.contains('semana') || message.contains('week')) return 7;
    if (message.contains('mês') || message.contains('month')) return 30;
    return 1; // Default to yesterday
  }
}
```

**Example: TimeContextTool**

**File**: `lib/agents/tools/time_context_tool.dart`

```dart
/// Tool for retrieving time context.
/// 
/// Wraps the get_current_time MCP command and TimeContextService.
class TimeContextTool extends BaseTool {
  final TimeContextService _timeService;
  
  TimeContextTool(this._timeService);
  
  @override
  String get name => 'get_time_context';
  
  @override
  String get description => 'Get current time and time gap context';
  
  @override
  Future<bool> isRequired(String userMessage, AgentContext context) async {
    // Time context is always required
    return true;
  }
  
  @override
  Future<dynamic> execute(AgentContext context) async {
    // Get last message timestamp
    final lastMessageTime = await _getLastMessageTimestamp(context);
    
    // Generate time context
    return await _timeService.generatePreciseTimeContext(lastMessageTime);
  }
  
  Future<DateTime?> _getLastMessageTimestamp(AgentContext context) async {
    if (context.recentMessages.length > 1) {
      return context.recentMessages[1].timestamp;
    }
    return null;
  }
}
```

**Future: GarminDataTool**

**File**: `lib/agents/tools/garmin_data_tool.dart`

```dart
/// Tool for retrieving health data from Garmin.
/// 
/// Integrates with Garmin Connect API to fetch health metrics.
class GarminDataTool extends BaseTool {
  final GarminService _garminService;
  
  GarminDataTool(this._garminService);
  
  @override
  String get name => 'get_garmin_data';
  
  @override
  String get description => 'Retrieve health data from Garmin device';
  
  @override
  Future<bool> isRequired(String userMessage, AgentContext context) async {
    // Check if Garmin is connected
    if (!await _garminService.isConnected()) return false;
    
    // Check if message asks about health metrics
    final patterns = [
      r'\b(heart rate|frequência cardíaca)\b',
      r'\b(sleep|sono)\b',
      r'\b(stress|estresse)\b',
      r'\b(steps|passos)\b',
    ];
    
    return patterns.any(
      (p) => RegExp(p, caseSensitive: false).hasMatch(userMessage),
    );
  }
  
  @override
  Future<dynamic> execute(AgentContext context) async {
    return await _garminService.getHealthData(
      startDate: DateTime.now().subtract(Duration(days: 1)),
      endDate: DateTime.now(),
    );
  }
}
```

---

### **5. Guardrails Interface**

**File**: `lib/agents/guardrails/base_guardrail.dart`

```dart
/// A guardrail is a constraint or rule the agent must follow.
/// 
/// Guardrails are applied after response generation to ensure
/// compliance with rules, constraints, and quality standards.
abstract class BaseGuardrail {
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

/// Result of a guardrail check
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

**Example: PersonaIdentityGuardrail**

**File**: `lib/agents/guardrails/persona_identity_guardrail.dart`

```dart
/// Guardrail to ensure response maintains persona identity.
/// 
/// Checks for:
/// - No brackets or internal thoughts
/// - No mention of other personas (unless handoff)
/// - Maintains persona style
class PersonaIdentityGuardrail extends BaseGuardrail {
  final String _personaKey;
  
  PersonaIdentityGuardrail(this._personaKey);
  
  @override
  String get name => 'Persona Identity';
  
  @override
  String get description => 'Ensure response maintains persona identity';
  
  @override
  Future<GuardrailResult> check(
    AgentResponse response,
    AgentContext context,
  ) async {
    final violations = <String>[];
    
    // Check 1: No brackets or internal thoughts
    if (response.content.contains('[') || response.content.contains(']')) {
      violations.add('Contains brackets (internal thoughts)');
    }
    
    // Check 2: No mention of other personas (unless handoff)
    final otherPersonas = ['I-There', 'Tony', 'Ari', 'Sergeant Oracle', 'Aristios', 'Ryo Tzu'];
    final currentPersona = await _getPersonaName();
    otherPersonas.remove(currentPersona);
    
    for (final persona in otherPersonas) {
      if (response.content.contains(persona) && !context.isHandoff) {
        violations.add('Mentions other persona: $persona');
      }
    }
    
    // Check 3: Maintains persona style
    if (!await _matchesPersonaStyle(response.content)) {
      violations.add('Does not match persona style');
    }
    
    return GuardrailResult(
      passed: violations.isEmpty,
      reason: violations.isEmpty ? null : violations.join('; '),
      metadata: {'violations': violations},
    );
  }
  
  @override
  Future<AgentResponse> revise(
    AgentResponse response,
    AgentContext context,
    GuardrailResult checkResult,
  ) async {
    String revised = response.content;
    
    // Remove brackets
    revised = revised.replaceAll(RegExp(r'\[.*?\]'), '');
    
    // Remove other persona mentions (simple approach)
    final otherPersonas = ['I-There', 'Tony', 'Ari', 'Sergeant Oracle', 'Aristios', 'Ryo Tzu'];
    final currentPersona = await _getPersonaName();
    otherPersonas.remove(currentPersona);
    
    for (final persona in otherPersonas) {
      revised = revised.replaceAll(persona, '');
    }
    
    return response.copyWith(
      content: revised.trim(),
      metadata: {
        ...response.metadata,
        'revised': true,
        'guardrail': name,
      },
    );
  }
  
  Future<String> _getPersonaName() async {
    final config = CharacterConfigManager();
    return await config.activePersonaDisplayName;
  }
  
  Future<bool> _matchesPersonaStyle(String content) async {
    // Check if content matches persona style
    // (simplified - real implementation would be more sophisticated)
    return true;
  }
}
```

**Example: OracleComplianceGuardrail**

**File**: `lib/agents/guardrails/oracle_compliance_guardrail.dart`

```dart
/// Guardrail to ensure Oracle 4.2 framework compliance.
/// 
/// Checks for:
/// - Activity detection only from current message
/// - No Oracle codes in response (unless explaining)
/// - Follows 8 dimensions and 265+ activities
class OracleComplianceGuardrail extends BaseGuardrail {
  @override
  String get name => 'Oracle Compliance';
  
  @override
  String get description => 'Ensure response follows Oracle 4.2 framework';
  
  @override
  Future<GuardrailResult> check(
    AgentResponse response,
    AgentContext context,
  ) async {
    // Only check if Oracle is enabled
    final config = CharacterConfigManager();
    if (!await config.isOracleEnabled()) {
      return GuardrailResult(passed: true);
    }
    
    final violations = <String>[];
    
    // Check 1: Activity detection only from current message
    if (response.metadata['activities_from_history'] == true) {
      violations.add('Detected activities from conversation history');
    }
    
    // Check 2: No Oracle codes in response (unless explaining)
    final oracleCodePattern = RegExp(
      r'\b(R\d+|SF\d+|TG\d+|SM\d+|E\d+|TT\d+|PR\d+|F\d+)\b',
    );
    if (oracleCodePattern.hasMatch(response.content)) {
      // Allow if explaining Oracle framework
      if (!response.content.toLowerCase().contains('oracle') &&
          !response.content.toLowerCase().contains('framework')) {
        violations.add('Contains Oracle activity codes in response');
      }
    }
    
    return GuardrailResult(
      passed: violations.isEmpty,
      reason: violations.isEmpty ? null : violations.join('; '),
      metadata: {'violations': violations},
    );
  }
  
  @override
  Future<AgentResponse> revise(
    AgentResponse response,
    AgentContext context,
    GuardrailResult checkResult,
  ) async {
    String revised = response.content;
    
    // Remove Oracle codes
    revised = revised.replaceAll(
      RegExp(r'\b(R\d+|SF\d+|TG\d+|SM\d+|E\d+|TT\d+|PR\d+|F\d+)\b'),
      '',
    );
    
    return response.copyWith(
      content: revised.trim(),
      metadata: {
        ...response.metadata,
        'revised': true,
        'guardrail': name,
      },
    );
  }
}
```

**Example: ResponseQualityGuardrail**

**File**: `lib/agents/guardrails/response_quality_guardrail.dart`

```dart
/// Guardrail to ensure response quality.
/// 
/// Checks for:
/// - No repetition from recent conversation
/// - Appropriate length
/// - Coherent and relevant
class ResponseQualityGuardrail extends BaseGuardrail {
  @override
  String get name => 'Response Quality';
  
  @override
  String get description => 'Ensure response quality and coherence';
  
  @override
  Future<GuardrailResult> check(
    AgentResponse response,
    AgentContext context,
  ) async {
    final violations = <String>[];
    
    // Check 1: No exact repetition from recent messages
    for (final msg in context.recentMessages) {
      if (!msg.isUser && msg.text == response.content) {
        violations.add('Exact repetition of previous response');
      }
    }
    
    // Check 2: Appropriate length (not too short, not too long)
    if (response.content.length < 20) {
      violations.add('Response too short');
    }
    if (response.content.length > 2000) {
      violations.add('Response too long');
    }
    
    // Check 3: Not empty
    if (response.content.trim().isEmpty) {
      violations.add('Empty response');
    }
    
    return GuardrailResult(
      passed: violations.isEmpty,
      reason: violations.isEmpty ? null : violations.join('; '),
      metadata: {'violations': violations},
    );
  }
  
  @override
  Future<AgentResponse> revise(
    AgentResponse response,
    AgentContext context,
    GuardrailResult checkResult,
  ) async {
    // For quality issues, we can't easily revise automatically
    // Return original response with warning
    return response.copyWith(
      metadata: {
        ...response.metadata,
        'quality_warning': checkResult.reason,
      },
    );
  }
}
```

---

### **6. Agent Models**

**File**: `lib/agents/models/agent_context.dart`

```dart
/// Context provided to the agent for processing a message.
class AgentContext {
  final String userMessage;
  final List<ChatMessage> recentMessages;
  final String apiKey;
  final bool isHandoff;
  final Map<String, dynamic> metadata;
  
  AgentContext({
    required this.userMessage,
    required this.recentMessages,
    required this.apiKey,
    this.isHandoff = false,
    this.metadata = const {},
  });
}
```

**File**: `lib/agents/models/agent_decision.dart`

```dart
/// Result of agent's decision phase.
class AgentDecision {
  final String reasoning;
  final List<BaseSkill> skills;
  final List<BaseTool> tools;
  final String context;
  
  AgentDecision({
    required this.reasoning,
    required this.skills,
    required this.tools,
    required this.context,
  });
}
```

**File**: `lib/agents/models/agent_response.dart`

```dart
/// Final response from the agent.
class AgentResponse {
  final String content;
  final List<BaseSkill> skillsUsed;
  final List<BaseTool> toolsUsed;
  final Map<String, dynamic> metadata;
  
  AgentResponse({
    required this.content,
    required this.skillsUsed,
    required this.toolsUsed,
    required this.metadata,
  });
  
  AgentResponse copyWith({
    String? content,
    List<BaseSkill>? skillsUsed,
    List<BaseTool>? toolsUsed,
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

---

### **7. Simplified ClaudeService (Agent Orchestrator)**

**File**: `lib/services/claude_service.dart`

```dart
/// Now just an orchestrator for the agent system.
/// 
/// Responsibilities:
/// - Build agent context
/// - Invoke agent to process message
/// - Store conversation history
class ClaudeService {
  final PersonaAgent _agent;
  final ChatStorageService _storageService;
  final Logger _logger = Logger();
  
  ClaudeService({
    required String apiKey,
    required SystemMCPService mcpService,
    required String personaKey,
  })  : _agent = PersonaAgent(
          personaKey: personaKey,
          configLoader: ConfigLoader(),
          contextBuilder: ContextBuilder(),
        ),
        _storageService = ChatStorageService();
  
  /// Send message using agent system
  Future<String> sendMessage(String message) async {
    _logger.info('Processing message via agent: ${message.substring(0, 50)}...');
    
    // Build agent context
    final context = await _buildAgentContext(message);
    
    // Let agent process message (Decide → Execute → Reflect)
    final response = await _agent.processMessage(
      userMessage: message,
      context: context,
    );
    
    // Store in history
    await _storeInHistory(message, response.content);
    
    _logger.info(
      'Agent response complete: '
      'Skills=${response.skillsUsed.map((s) => s.name).join(", ")}, '
      'Tools=${response.toolsUsed.map((t) => t.name).join(", ")}',
    );
    
    return response.content;
  }
  
  Future<AgentContext> _buildAgentContext(String message) async {
    final recentMessages = await _storageService.getMessages(limit: 10);
    
    return AgentContext(
      userMessage: message,
      recentMessages: recentMessages,
      apiKey: _apiKey,
      isHandoff: _detectHandoff(message, recentMessages),
    );
  }
  
  bool _detectHandoff(String message, List<ChatMessage> recentMessages) {
    // Detect if this is a persona handoff
    // (simplified - real implementation would be more sophisticated)
    return message.toLowerCase().contains('falar com') ||
        message.toLowerCase().contains('talk to');
  }
  
  Future<void> _storeInHistory(String userMessage, String response) async {
    // Store user message
    await _storageService.saveMessage(
      ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    
    // Store assistant response
    await _storageService.saveMessage(
      ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }
}
```

---

## 📊 Benefits of Agent Architecture

### **1. Industry-Standard Patterns** ✅

This architecture follows **proven agent patterns**:
- **ReAct** (Reasoning + Acting): Decide → Execute → Reflect
- **Tool Use**: Agents invoke tools to gather information
- **Guardrails**: Constraints applied before final output
- **Skills**: Modular capabilities that can be composed

**References**:
- LangChain Agents
- AutoGPT
- OpenAI Assistants
- Anthropic Claude Tool Use

### **2. Clear Mental Model** ✅

**Before**: "It's a chat service with context building and MCP commands"  
**After**: "It's an agent with skills, tools, and guardrails"

This makes it easier to:
- Explain the system to new developers
- Reason about behavior
- Debug issues
- Add new capabilities

### **3. Composable Capabilities** ✅

```dart
// Add new skill (2-4 hours)
class HealthMonitoringSkill extends BaseSkill {
  // ... implementation ...
}
_skills.add(HealthMonitoringSkill());

// Add new tool (2-4 hours)
class GarminDataTool extends BaseTool {
  // ... implementation ...
}
_tools.add(GarminDataTool());

// Add new guardrail (2-4 hours)
class SafetyGuardrail extends BaseGuardrail {
  // ... implementation ...
}
_guardrails.add(SafetyGuardrail());
```

### **4. Testable in Isolation** ✅

```dart
// Test skill
test('CoachingSkill identifies coaching queries', () async {
  final skill = CoachingSkill();
  final isRelevant = await skill.isRelevant(
    'quero melhorar meu sono',
    mockContext,
  );
  expect(isRelevant, true);
});

// Test tool
test('ActivityStatsTool executes correctly', () async {
  final tool = ActivityStatsTool(mockMCPService);
  final result = await tool.execute(mockContext);
  expect(result, isNotNull);
});

// Test guardrail
test('PersonaIdentityGuardrail catches bracket violations', () async {
  final guardrail = PersonaIdentityGuardrail('ariLifeCoach');
  final response = AgentResponse(
    content: '[thinking] hmm...',
    skillsUsed: [],
    toolsUsed: [],
    metadata: {},
  );
  final result = await guardrail.check(response, mockContext);
  expect(result.passed, false);
});
```

### **5. Observable & Debuggable** ✅

```dart
// Agent execution is fully observable
final response = await agent.processMessage(...);

print('Skills used: ${response.skillsUsed.map((s) => s.name)}');
print('Tools used: ${response.toolsUsed.map((t) => t.name)}');
print('Guardrails passed: ${response.metadata['guardrails_passed']}');
print('Guardrail results: ${response.metadata['guardrail_results']}');
```

### **6. Aligns with Industry Standards** ✅

This architecture aligns with:
- **LangChain Agents**: skills = chains, tools = tools
- **AutoGPT**: agent loop (think → act → observe)
- **OpenAI Assistants**: tools, function calling
- **Anthropic Claude**: tool use, system prompts
- **LangGraph**: agent state machines

---

## 🎯 Migration Strategy

### **Phase 1: Agent Core** (6-8 hours)

**Goal**: Implement base agent framework

**Tasks**:
1. Create `lib/agents/` directory structure
2. Implement `BaseAgent` interface
3. Implement `PersonaAgent` class
4. Implement models: `AgentContext`, `AgentDecision`, `AgentResponse`
5. Test agent loop (Decide → Execute → Reflect)

**Deliverable**: Working agent framework

---

### **Phase 2: Skills** (4-6 hours)

**Goal**: Extract capabilities into skills

**Tasks**:
1. Implement `BaseSkill` interface
2. Extract existing capabilities into skills:
   - `CoachingSkill`
   - `ActivityTrackingSkill`
   - `ReflectionSkill`
3. Test each skill in isolation

**Deliverable**: 3 working skills

---

### **Phase 3: Tools** (4-6 hours)

**Goal**: Wrap MCP commands as tools

**Tasks**:
1. Implement `BaseTool` interface
2. Wrap existing MCP commands as tools:
   - `ActivityStatsTool`
   - `ConversationContextTool`
   - `OracleDetectionTool`
   - `TimeContextTool`
3. Test each tool in isolation

**Deliverable**: 4 working tools

---

### **Phase 4: Guardrails** (4-6 hours)

**Goal**: Extract rules as guardrails

**Tasks**:
1. Implement `BaseGuardrail` interface
2. Extract existing rules as guardrails:
   - `PersonaIdentityGuardrail`
   - `OracleComplianceGuardrail`
   - `ResponseQualityGuardrail`
3. Test each guardrail in isolation

**Deliverable**: 3 working guardrails

---

### **Phase 5: Integration** (4-6 hours)

**Goal**: Integrate agent system with existing app

**Tasks**:
1. Simplify `ClaudeService` to agent orchestrator
2. Integrate agent system with existing UI
3. End-to-end testing
4. Migration complete!

**Deliverable**: Fully integrated agent system

---

**Total Effort**: 22-32 hours

---

## 🚀 Recommendation

### **Implement Agent Architecture First**

**Why**:
1. ✅ **Industry-standard patterns** (proven, well-understood)
2. ✅ **Clear mental model** (agent with skills, tools, guardrails)
3. ✅ **Composable** (add skills/tools/guardrails independently)
4. ✅ **Testable** (each component tested in isolation)
5. ✅ **Observable** (full visibility into agent behavior)
6. ✅ **Future-proof** (ready for Garmin, goal planning, etc.)

**Then**:
- FT-206 optimization becomes trivial (just optimize context building in `decide()` phase)
- Adding Garmin is just adding `GarminDataTool` and `HealthMonitoringSkill`
- Adding goal planning is just adding `GoalPlanningSkill`

---

## 📝 Conclusion

**Agent architecture is the right foundation** because:
- ✅ Aligns with industry standards (ReAct, Tool Use, Guardrails)
- ✅ Clear mental model (easier to understand and explain)
- ✅ Composable capabilities (add skills/tools/guardrails independently)
- ✅ Testable in isolation (each component tested separately)
- ✅ Observable & debuggable (full visibility into agent behavior)
- ✅ Future-proof (ready for Garmin, goal planning, calendar, weather, etc.)

**This is the foundation for a scalable, maintainable AI agent system.** 🤖

---

**Architecture Design Complete** ✅

