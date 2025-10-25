# FT-206: Context Builder Architecture - Modular Context Management

**Analysis Date**: 2025-10-24  
**Status**: Architectural Design  
**Branch**: `fix/ft-206-universal-laws-system-prompt-redesign`  
**Related Features**: FT-084 (Two-Pass), FT-220 (Context Logging)

---

## 🎯 Executive Summary

**Problem**: Context building logic is tightly coupled to `ClaudeService` (1,772 lines), making it hard to test, extend, and maintain.

**Solution**: Extract context building into a dedicated module with:
- **Provider-based architecture** (each context aspect is independent)
- **Strategy pattern** (minimal, focused, or full context)
- **Open for extension** (Garmin, goal planning, etc. are trivial to add)
- **Easy to test** (each provider tested in isolation)

**Benefits**:
- ✅ Clean separation of concerns
- ✅ Easy to extend (add new providers without touching core)
- ✅ Easy to test (unit tests for each provider)
- ✅ Not over-engineered (simple interfaces, clear responsibilities)
- ✅ Future-proof (ready for Garmin, goal planning, etc.)

---

## 🔍 Current Architecture Problem

### **Current State: Tightly Coupled**

```
ClaudeService (1,772 lines!)
├── Message handling
├── Conversation history
├── API communication
├── Context building (scattered across methods)
│   ├── _buildSystemPrompt()
│   ├── _buildRecentConversationContext()
│   ├── _formatInterleavedConversation()
│   ├── _buildEnrichedPromptWithQualification()
│   └── _detectDataQueryPattern()
├── Time context integration
├── MCP command processing
├── Activity detection
├── Two-pass orchestration
└── Error handling
```

**Problems**:
- ❌ **Massive god class** (1,772 lines)
- ❌ **Context logic scattered** across multiple methods
- ❌ **Hard to test** context building in isolation
- ❌ **Hard to extend** (adding Garmin data requires modifying ClaudeService)
- ❌ **Violates Single Responsibility Principle**
- ❌ **Tight coupling** between API communication and context assembly

---

## 🏗️ Proposed Architecture: Context Builder Module

### **Clean Separation of Concerns**

```
lib/services/
├── claude_service.dart (300-400 lines)
│   ├── API communication
│   ├── Message orchestration
│   └── Error handling
│
├── context/
│   ├── context_builder.dart (Core orchestrator)
│   ├── decision_engine.dart (Pass 1: Minimal context)
│   ├── context_loader.dart (Pass 2: Dynamic loading)
│   │
│   ├── providers/
│   │   ├── base_context_provider.dart (Abstract interface)
│   │   ├── persona_context_provider.dart
│   │   ├── time_context_provider.dart
│   │   ├── conversation_context_provider.dart
│   │   ├── oracle_context_provider.dart
│   │   ├── mcp_context_provider.dart
│   │   └── (future) garmin_context_provider.dart
│   │   └── (future) goal_planning_context_provider.dart
│   │
│   ├── strategies/
│   │   ├── base_context_strategy.dart (Abstract interface)
│   │   ├── minimal_context_strategy.dart (Pass 1)
│   │   ├── focused_context_strategy.dart (Pass 2)
│   │   └── full_context_strategy.dart (Legacy/fallback)
│   │
│   └── models/
│       ├── decision_result.dart
│       └── context_metadata.dart
```

---

## 📋 Detailed Design

### **1. Core: ContextBuilder** (Orchestrator)

**File**: `lib/services/context/context_builder.dart`

```dart
/// Central orchestrator for building AI context.
/// Coordinates multiple context providers and applies strategies.
class ContextBuilder {
  final List<BaseContextProvider> _providers = [];
  final Logger _logger = Logger();
  
  ContextBuilder() {
    _registerProviders();
  }
  
  void _registerProviders() {
    // Core providers (always registered)
    _providers.add(PersonaContextProvider());
    _providers.add(TimeContextProvider());
    _providers.add(ConversationContextProvider());
    _providers.add(MCPContextProvider());
    
    // Optional providers (registered based on config)
    if (_isOracleEnabled()) {
      _providers.add(OracleContextProvider());
    }
    
    // Future providers (easy to add)
    // _providers.add(GarminContextProvider());
    // _providers.add(GoalPlanningContextProvider());
  }
  
  /// Build context for Pass 1 (Decision Engine)
  Future<String> buildDecisionContext({
    required String userMessage,
    required List<ChatMessage> recentMessages,
  }) async {
    final strategy = MinimalContextStrategy();
    return await _buildContext(
      strategy: strategy,
      userMessage: userMessage,
      recentMessages: recentMessages,
    );
  }
  
  /// Build context for Pass 2 (Response Generation)
  Future<String> buildResponseContext({
    required String userMessage,
    required DecisionResult decision,
    required Map<String, dynamic> mcpData,
  }) async {
    final strategy = FocusedContextStrategy(decision);
    return await _buildContext(
      strategy: strategy,
      userMessage: userMessage,
      decision: decision,
      mcpData: mcpData,
    );
  }
  
  /// Core context building logic
  Future<String> _buildContext({
    required ContextStrategy strategy,
    required String userMessage,
    List<ChatMessage>? recentMessages,
    DecisionResult? decision,
    Map<String, dynamic>? mcpData,
  }) async {
    final context = StringBuffer();
    
    // Strategy determines which providers to use and in what order
    final activeProviders = strategy.selectProviders(_providers);
    
    for (final provider in activeProviders) {
      if (await provider.shouldInclude(strategy, decision)) {
        final section = await provider.buildSection(
          userMessage: userMessage,
          recentMessages: recentMessages,
          decision: decision,
          mcpData: mcpData,
        );
        
        if (section.isNotEmpty) {
          context.writeln(section);
          context.writeln(); // Spacing
          
          _logger.debug(
            'Context: Added ${provider.name} '
            '(${section.length} chars)',
          );
        }
      }
    }
    
    final totalSize = context.length;
    _logger.info(
      'Context built: ${activeProviders.length} providers, '
      '$totalSize chars (~${(totalSize / 4).round()} tokens)',
    );
    
    return context.toString();
  }
}
```

---

### **2. Abstract Provider Interface**

**File**: `lib/services/context/providers/base_context_provider.dart`

```dart
/// Base interface for all context providers.
/// Each provider is responsible for one aspect of context.
abstract class BaseContextProvider {
  /// Priority order (lower = higher priority)
  int get priority;
  
  /// Provider name (for logging)
  String get name;
  
  /// Should this provider be included in the current context?
  Future<bool> shouldInclude(
    ContextStrategy strategy,
    DecisionResult? decision,
  );
  
  /// Build this provider's context section
  Future<String> buildSection({
    required String userMessage,
    List<ChatMessage>? recentMessages,
    DecisionResult? decision,
    Map<String, dynamic>? mcpData,
  });
}
```

---

### **3. Example Provider: PersonaContextProvider**

**File**: `lib/services/context/providers/persona_context_provider.dart`

```dart
/// Provides persona identity and configuration context.
class PersonaContextProvider extends BaseContextProvider {
  final ConfigLoader _configLoader = ConfigLoader();
  
  @override
  int get priority => 1; // Highest priority
  
  @override
  String get name => 'Persona';
  
  @override
  Future<bool> shouldInclude(
    ContextStrategy strategy,
    DecisionResult? decision,
  ) async {
    // Always include persona (but strategy controls how much)
    return true;
  }
  
  @override
  Future<String> buildSection({
    required String userMessage,
    List<ChatMessage>? recentMessages,
    DecisionResult? decision,
    Map<String, dynamic>? mcpData,
  }) async {
    // Minimal context for Pass 1
    if (decision == null) {
      return await _buildMinimalPersona();
    }
    
    // Full context for Pass 2 (if needed)
    if (decision.needsFullPersona) {
      return await _configLoader.loadSystemPrompt();
    }
    
    // Default: Core persona only
    return await _buildCorePersona();
  }
  
  Future<String> _buildMinimalPersona() async {
    final name = await _configLoader.activePersonaDisplayName;
    final config = CharacterConfigManager();
    
    return '''
## Persona
- Name: $name
- Role: Life coach and companion
- Style: Conversational, supportive, authentic
''';
  }
  
  Future<String> _buildCorePersona() async {
    // 20-30 lines of core identity
    // (extracted from full persona config)
    final systemPrompt = await _configLoader.loadSystemPrompt();
    
    // Extract core identity section (first 500 chars as example)
    // In reality, this would parse the config and extract key sections
    return systemPrompt.substring(0, 500);
  }
}
```

---

### **4. Example Provider: OracleContextProvider**

**File**: `lib/services/context/providers/oracle_context_provider.dart`

```dart
/// Provides Oracle 4.2 framework context (on-demand).
class OracleContextProvider extends BaseContextProvider {
  @override
  int get priority => 4; // Lower priority (loaded on-demand)
  
  @override
  String get name => 'Oracle Framework';
  
  @override
  Future<bool> shouldInclude(
    ContextStrategy strategy,
    DecisionResult? decision,
  ) async {
    // Only include if Oracle is enabled AND decision says it's needed
    final config = CharacterConfigManager();
    if (!await config.isOracleEnabled()) return false;
    
    // Pass 1: Never include (too large)
    if (decision == null) return false;
    
    // Pass 2: Only if decision says Oracle is needed
    return decision.needsOracle;
  }
  
  @override
  Future<String> buildSection({
    required String userMessage,
    List<ChatMessage>? recentMessages,
    DecisionResult? decision,
    Map<String, dynamic>? mcpData,
  }) async {
    // Load Oracle framework from config
    return await rootBundle.loadString(
      'assets/config/oracle/oracle_prompt_4.2_optimized.md',
    );
  }
}
```

---

### **5. Example Provider: TimeContextProvider**

**File**: `lib/services/context/providers/time_context_provider.dart`

```dart
/// Provides time awareness context (current time, time gaps, etc.).
class TimeContextProvider extends BaseContextProvider {
  final TimeContextService _timeService = TimeContextService();
  
  @override
  int get priority => 2; // High priority (always needed)
  
  @override
  String get name => 'Time Context';
  
  @override
  Future<bool> shouldInclude(
    ContextStrategy strategy,
    DecisionResult? decision,
  ) async {
    // Always include time context (critical for awareness)
    return true;
  }
  
  @override
  Future<String> buildSection({
    required String userMessage,
    List<ChatMessage>? recentMessages,
    DecisionResult? decision,
    Map<String, dynamic>? mcpData,
  }) async {
    // Get last message timestamp
    final lastMessageTime = await _getLastMessageTimestamp();
    
    // Generate time context
    return await _timeService.generatePreciseTimeContext(lastMessageTime);
  }
  
  Future<DateTime?> _getLastMessageTimestamp() async {
    final storageService = ChatStorageService();
    final messages = await storageService.getMessages(limit: 2);
    return messages.length > 1 ? messages[1].timestamp : null;
  }
}
```

---

### **6. Example Provider: ConversationContextProvider**

**File**: `lib/services/context/providers/conversation_context_provider.dart`

```dart
/// Provides recent conversation history context.
class ConversationContextProvider extends BaseContextProvider {
  final ChatStorageService _storageService = ChatStorageService();
  
  @override
  int get priority => 3; // Medium priority
  
  @override
  String get name => 'Conversation History';
  
  @override
  Future<bool> shouldInclude(
    ContextStrategy strategy,
    DecisionResult? decision,
  ) async {
    // Include in both Pass 1 (minimal) and Pass 2 (full)
    return true;
  }
  
  @override
  Future<String> buildSection({
    required String userMessage,
    List<ChatMessage>? recentMessages,
    DecisionResult? decision,
    Map<String, dynamic>? mcpData,
  }) async {
    // Pass 1: Last 2 messages only
    if (decision == null) {
      return await _buildMinimalHistory(2);
    }
    
    // Pass 2: Last 5-10 messages
    final limit = decision.needsFullHistory ? 10 : 5;
    return await _buildFullHistory(limit);
  }
  
  Future<String> _buildMinimalHistory(int limit) async {
    final messages = await _storageService.getMessages(limit: limit);
    final buffer = StringBuffer();
    
    buffer.writeln('## Recent Messages');
    for (final msg in messages) {
      final speaker = msg.isUser ? 'User' : msg.personaDisplayName;
      buffer.writeln('- **$speaker**: ${msg.text.substring(0, 50)}...');
    }
    
    return buffer.toString();
  }
  
  Future<String> _buildFullHistory(int limit) async {
    // Use existing _formatInterleavedConversation logic
    // (extracted from ClaudeService)
    return await _formatInterleavedConversation(limit);
  }
}
```

---

### **7. Future Provider: GarminContextProvider**

**File**: `lib/services/context/providers/garmin_context_provider.dart`

```dart
/// Provides Garmin health data context (future feature).
class GarminContextProvider extends BaseContextProvider {
  @override
  int get priority => 5;
  
  @override
  String get name => 'Garmin Health Data';
  
  @override
  Future<bool> shouldInclude(
    ContextStrategy strategy,
    DecisionResult? decision,
  ) async {
    // Only include if Garmin is connected AND decision needs health data
    if (!await _isGarminConnected()) return false;
    return decision?.needsHealthData ?? false;
  }
  
  @override
  Future<String> buildSection({
    required String userMessage,
    List<ChatMessage>? recentMessages,
    DecisionResult? decision,
    Map<String, dynamic>? mcpData,
  }) async {
    final garminData = await _fetchGarminData(decision!.healthDataQuery);
    
    return '''
## Garmin Health Data (Last 24h)
- Heart Rate: ${garminData.avgHeartRate} bpm (avg), ${garminData.restingHeartRate} bpm (resting)
- Sleep Score: ${garminData.sleepScore}/100 (${garminData.sleepDuration}h)
- Steps: ${garminData.steps} (${garminData.distance}km)
- Stress Level: ${garminData.stressLevel}/100
- Body Battery: ${garminData.bodyBattery}/100
- VO2 Max: ${garminData.vo2Max}
''';
  }
  
  Future<GarminData> _fetchGarminData(HealthDataQuery query) async {
    // Fetch from Garmin API or local cache
    final garminService = GarminService();
    return await garminService.getHealthData(query);
  }
  
  Future<bool> _isGarminConnected() async {
    final garminService = GarminService();
    return await garminService.isConnected();
  }
}
```

---

### **8. Future Provider: GoalPlanningContextProvider**

**File**: `lib/services/context/providers/goal_planning_context_provider.dart`

```dart
/// Provides goal planning and OKR context (future feature).
class GoalPlanningContextProvider extends BaseContextProvider {
  @override
  int get priority => 6;
  
  @override
  String get name => 'Goal Planning';
  
  @override
  Future<bool> shouldInclude(
    ContextStrategy strategy,
    DecisionResult? decision,
  ) async {
    // Only include if user has active goals AND decision needs goal context
    final hasActiveGoals = await _hasActiveGoals();
    if (!hasActiveGoals) return false;
    
    return decision?.needsGoalContext ?? false;
  }
  
  @override
  Future<String> buildSection({
    required String userMessage,
    List<ChatMessage>? recentMessages,
    DecisionResult? decision,
    Map<String, dynamic>? mcpData,
  }) async {
    final goals = await _fetchActiveGoals();
    final buffer = StringBuffer();
    
    buffer.writeln('## Active Goals & OKRs');
    for (final goal in goals) {
      buffer.writeln('### ${goal.title}');
      buffer.writeln('- Status: ${goal.progress}% complete');
      buffer.writeln('- Deadline: ${goal.deadline}');
      buffer.writeln('- Key Results:');
      for (final kr in goal.keyResults) {
        buffer.writeln('  * ${kr.description}: ${kr.progress}%');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  Future<List<Goal>> _fetchActiveGoals() async {
    final goalService = GoalPlanningService();
    return await goalService.getActiveGoals();
  }
  
  Future<bool> _hasActiveGoals() async {
    final goals = await _fetchActiveGoals();
    return goals.isNotEmpty;
  }
}
```

---

### **9. Context Strategies**

**File**: `lib/services/context/strategies/base_context_strategy.dart`

```dart
/// Base interface for context strategies.
abstract class ContextStrategy {
  /// Strategy name (for logging)
  String get name;
  
  /// Select which providers to use for this strategy
  List<BaseContextProvider> selectProviders(
    List<BaseContextProvider> allProviders,
  );
}
```

**File**: `lib/services/context/strategies/minimal_context_strategy.dart`

```dart
/// Strategy for Pass 1: Decision Engine (minimal context)
class MinimalContextStrategy extends ContextStrategy {
  @override
  String get name => 'Minimal (Decision Engine)';
  
  @override
  List<BaseContextProvider> selectProviders(
    List<BaseContextProvider> allProviders,
  ) {
    // Only include essential providers for decision-making
    return allProviders
        .where((p) =>
            p is PersonaContextProvider ||
            p is MCPContextProvider ||
            p is ConversationContextProvider ||
            p is TimeContextProvider)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }
}
```

**File**: `lib/services/context/strategies/focused_context_strategy.dart`

```dart
/// Strategy for Pass 2: Response Generation (focused context)
class FocusedContextStrategy extends ContextStrategy {
  final DecisionResult decision;
  
  FocusedContextStrategy(this.decision);
  
  @override
  String get name => 'Focused (Response Generation)';
  
  @override
  List<BaseContextProvider> selectProviders(
    List<BaseContextProvider> allProviders,
  ) {
    // Include all providers, but let them decide based on decision
    return allProviders..sort((a, b) => a.priority.compareTo(b.priority));
  }
}
```

---

### **10. DecisionEngine** (Pass 1 Orchestrator)

**File**: `lib/services/context/decision_engine.dart`

```dart
/// Orchestrates Pass 1: Analyzes user message and decides what's needed.
class DecisionEngine {
  final ContextBuilder _contextBuilder = ContextBuilder();
  final ClaudeAPIClient _apiClient;
  final Logger _logger = Logger();
  
  DecisionEngine(this._apiClient);
  
  /// Analyze user message and decide what context/data is needed
  Future<DecisionResult> analyze({
    required String userMessage,
    required List<ChatMessage> recentMessages,
  }) async {
    // Build minimal context for decision-making
    final context = await _contextBuilder.buildDecisionContext(
      userMessage: userMessage,
      recentMessages: recentMessages,
    );
    
    _logger.debug('Decision Engine: Context size = ${context.length} chars');
    
    // Call Claude with minimal context
    final response = await _apiClient.sendMessage(
      messages: [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userMessage}
          ]
        }
      ],
      systemPrompt: context,
    );
    
    // Parse decision from response
    return _parseDecision(response);
  }
  
  DecisionResult _parseDecision(String response) {
    try {
      final json = jsonDecode(response);
      return DecisionResult.fromJson(json);
    } catch (e) {
      _logger.warning('Failed to parse decision: $e');
      return DecisionResult.fallback();
    }
  }
}
```

---

### **11. DecisionResult Model**

**File**: `lib/services/context/models/decision_result.dart`

```dart
/// Result of Pass 1 decision engine analysis.
class DecisionResult {
  final String reasoning;
  final List<MCPCommand> mcpCalls;
  final String responseType; // conversational, data_informed, coaching
  final bool needsOracle;
  final bool needsCoaching;
  final bool needsFullPersona;
  final bool needsFullHistory;
  final bool needsHealthData;
  final bool needsGoalContext;
  final HealthDataQuery? healthDataQuery;
  
  DecisionResult({
    required this.reasoning,
    required this.mcpCalls,
    required this.responseType,
    this.needsOracle = false,
    this.needsCoaching = false,
    this.needsFullPersona = false,
    this.needsFullHistory = false,
    this.needsHealthData = false,
    this.needsGoalContext = false,
    this.healthDataQuery,
  });
  
  factory DecisionResult.fromJson(Map<String, dynamic> json) {
    return DecisionResult(
      reasoning: json['reasoning'] as String,
      mcpCalls: (json['mcp_calls'] as List)
          .map((cmd) => MCPCommand.fromJson(cmd))
          .toList(),
      responseType: json['response_type'] as String,
      needsOracle: json['needs_oracle'] as bool? ?? false,
      needsCoaching: json['needs_coaching'] as bool? ?? false,
      needsFullPersona: json['needs_full_persona'] as bool? ?? false,
      needsFullHistory: json['needs_full_history'] as bool? ?? false,
      needsHealthData: json['needs_health_data'] as bool? ?? false,
      needsGoalContext: json['needs_goal_context'] as bool? ?? false,
    );
  }
  
  /// Fallback decision when parsing fails
  factory DecisionResult.fallback() {
    return DecisionResult(
      reasoning: 'Fallback: Unable to parse decision',
      mcpCalls: [],
      responseType: 'conversational',
    );
  }
}
```

---

### **12. Simplified ClaudeService**

**File**: `lib/services/claude_service.dart` (SIMPLIFIED!)

```dart
/// Now focused ONLY on API communication and orchestration.
class ClaudeService {
  final ClaudeAPIClient _apiClient;
  final DecisionEngine _decisionEngine;
  final ContextBuilder _contextBuilder;
  final SystemMCPService _mcpService;
  final ChatStorageService _storageService;
  final Logger _logger = Logger();
  
  ClaudeService({
    required String apiKey,
    required SystemMCPService mcpService,
  })  : _apiClient = ClaudeAPIClient(apiKey),
        _decisionEngine = DecisionEngine(ClaudeAPIClient(apiKey)),
        _contextBuilder = ContextBuilder(),
        _mcpService = mcpService,
        _storageService = ChatStorageService();
  
  /// Send message with intelligent two-pass processing
  Future<String> sendMessage(String message) async {
    _logger.info('Processing message: ${message.substring(0, 50)}...');
    
    // PASS 1: Decision Engine (minimal context)
    final decision = await _decisionEngine.analyze(
      userMessage: message,
      recentMessages: await _getRecentMessages(2),
    );
    
    _logger.info(
      'Decision: ${decision.responseType}, '
      'MCP calls: ${decision.mcpCalls.length}',
    );
    
    // DATA FETCH: Execute MCP commands (if needed)
    final mcpData = await _executeMCPCalls(decision.mcpCalls);
    
    // PASS 2: Response Generation (focused context)
    final context = await _contextBuilder.buildResponseContext(
      userMessage: message,
      decision: decision,
      mcpData: mcpData,
    );
    
    _logger.debug('Response Context: ${context.length} chars');
    
    // Call Claude with focused context
    final response = await _apiClient.sendMessage(
      messages: [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': message}
          ]
        }
      ],
      systemPrompt: context,
    );
    
    // Store in history and return
    await _storeInHistory(message, response);
    return response;
  }
  
  Future<Map<String, dynamic>> _executeMCPCalls(
    List<MCPCommand> commands,
  ) async {
    final results = <String, dynamic>{};
    
    for (final cmd in commands) {
      try {
        final result = await _mcpService.processCommand(cmd.toJson());
        results[cmd.action] = result;
      } catch (e) {
        _logger.warning('MCP command failed: ${cmd.action} - $e');
      }
    }
    
    return results;
  }
  
  Future<List<ChatMessage>> _getRecentMessages(int limit) async {
    return await _storageService.getMessages(limit: limit);
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

## 📊 Benefits of This Architecture

### **1. Single Responsibility Principle** ✅

Each class has one clear responsibility:
- `ClaudeService`: API communication & orchestration
- `ContextBuilder`: Context assembly
- `DecisionEngine`: Pass 1 decision logic
- `PersonaContextProvider`: Persona context only
- `OracleContextProvider`: Oracle context only
- `GarminContextProvider`: Garmin data only

### **2. Open/Closed Principle** ✅

- **Open for extension**: Add new providers without modifying existing code
- **Closed for modification**: Core logic doesn't change

**Example**: Adding Garmin support
```dart
// Create new provider (50 lines)
class GarminContextProvider extends BaseContextProvider {
  // ... implementation ...
}

// Register in ContextBuilder (1 line)
_providers.add(GarminContextProvider());

// Done! No changes to ClaudeService or other providers
```

### **3. Dependency Inversion** ✅

- All providers implement `BaseContextProvider` interface
- `ContextBuilder` depends on abstraction, not concrete classes
- Easy to mock for testing

### **4. Easy to Test** ✅

```dart
// Test context building in isolation
test('PersonaContextProvider builds minimal context', () async {
  final provider = PersonaContextProvider();
  final context = await provider.buildSection(
    userMessage: 'Hello',
    recentMessages: [],
    decision: null, // Pass 1
    mcpData: {},
  );
  
  expect(context, contains('## Persona'));
  expect(context.length, lessThan(500)); // Minimal!
});

// Test strategy selection
test('MinimalContextStrategy selects only essential providers', () {
  final strategy = MinimalContextStrategy();
  final allProviders = [
    PersonaContextProvider(),
    OracleContextProvider(),
    GarminContextProvider(),
  ];
  
  final selected = strategy.selectProviders(allProviders);
  
  expect(selected, contains(isA<PersonaContextProvider>()));
  expect(selected, isNot(contains(isA<OracleContextProvider>())));
  expect(selected, isNot(contains(isA<GarminContextProvider>())));
});

// Test DecisionEngine
test('DecisionEngine identifies data queries', () async {
  final engine = DecisionEngine(mockApiClient);
  final decision = await engine.analyze(
    userMessage: 'o que eu fiz hoje?',
    recentMessages: [],
  );
  
  expect(decision.responseType, 'data_informed');
  expect(decision.mcpCalls, isNotEmpty);
  expect(decision.mcpCalls.first.action, 'get_activity_stats');
});
```

### **5. Easy to Extend** ✅

**Adding Garmin Support** (2-4 hours):
1. Create `GarminContextProvider` (50 lines)
2. Register in `ContextBuilder` (1 line)
3. Add `needsHealthData` to `DecisionResult` (1 line)
4. Update decision prompt to mention Garmin (5 lines)
5. Test (1 hour)

**No changes needed to**:
- `ClaudeService`
- Other providers
- Core context building logic

### **6. Easy to Configure** ✅

```json
// assets/config/context_providers_config.json
{
  "providers": {
    "persona": {
      "enabled": true,
      "priority": 1,
      "minimal_size_chars": 200,
      "core_size_chars": 500
    },
    "time": {
      "enabled": true,
      "priority": 2
    },
    "conversation": {
      "enabled": true,
      "priority": 3,
      "minimal_messages": 2,
      "full_messages": 10
    },
    "oracle": {
      "enabled": true,
      "priority": 4,
      "load_on_demand": true
    },
    "garmin": {
      "enabled": false,
      "priority": 5,
      "cache_duration_minutes": 15
    },
    "goal_planning": {
      "enabled": false,
      "priority": 6
    }
  }
}
```

---

## 🎯 Migration Strategy

### **Phase 1: Extract Context Building** (4-6 hours)

**Goal**: Move context logic out of `ClaudeService`

**Tasks**:
1. Create `lib/services/context/` directory structure
2. Create `BaseContextProvider` interface
3. Extract existing context logic into providers:
   - `PersonaContextProvider` (from `_buildSystemPrompt`)
   - `TimeContextProvider` (from `TimeContextService` integration)
   - `ConversationContextProvider` (from `_buildRecentConversationContext`)
   - `OracleContextProvider` (from Oracle loading logic)
   - `MCPContextProvider` (from MCP documentation)
4. Create `ContextBuilder` orchestrator
5. **Test in isolation** (unit tests for each provider)

**Deliverable**: Context building logic extracted and tested

---

### **Phase 2: Implement Strategies** (2-3 hours)

**Goal**: Add strategy pattern for different context modes

**Tasks**:
1. Create `BaseContextStrategy` interface
2. Create `MinimalContextStrategy` (Pass 1)
3. Create `FocusedContextStrategy` (Pass 2)
4. Create `FullContextStrategy` (legacy fallback)
5. **Test strategies** (integration tests)

**Deliverable**: Strategy pattern implemented and tested

---

### **Phase 3: Create DecisionEngine** (2-3 hours)

**Goal**: Extract Pass 1 logic into dedicated module

**Tasks**:
1. Create `DecisionEngine` class
2. Create `DecisionResult` model
3. Extract Pass 1 logic from `ClaudeService`
4. Integrate with `ContextBuilder`
5. **Test decision-making** (unit tests)

**Deliverable**: DecisionEngine implemented and tested

---

### **Phase 4: Simplify ClaudeService** (2-3 hours)

**Goal**: Refactor `ClaudeService` to use new modules

**Tasks**:
1. Remove context building logic from `ClaudeService`
2. Integrate `DecisionEngine` and `ContextBuilder`
3. Simplify `_sendMessageInternal()` to orchestration only
4. **Test end-to-end** (integration tests)

**Deliverable**: Simplified `ClaudeService` (300-400 lines)

---

### **Phase 5: Add Future Providers** (as needed)

**Goal**: Extend with new context sources

**Tasks** (per provider):
1. Create provider class (50-100 lines)
2. Register in `ContextBuilder` (1 line)
3. Update `DecisionResult` if needed (1-2 lines)
4. Update decision prompt if needed (5-10 lines)
5. Test (1 hour)

**Effort per provider**: 2-4 hours

**Examples**:
- `GarminContextProvider` (when Garmin integration ready)
- `GoalPlanningContextProvider` (when goal planning ready)
- `CalendarContextProvider` (for scheduling awareness)
- `WeatherContextProvider` (for context-aware coaching)

---

## 📈 Expected Outcomes

### **Code Quality**

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| `ClaudeService` lines | 1,772 | 300-400 | 77% reduction |
| Testability | Low | High | ✅ Unit testable |
| Extensibility | Hard | Easy | ✅ Add providers |
| Maintainability | Hard | Easy | ✅ Clear structure |
| Coupling | High | Low | ✅ Loose coupling |

### **Development Velocity**

| Task | Before | After | Improvement |
|------|--------|-------|-------------|
| Add new context source | 4-8 hours | 2-4 hours | 50% faster |
| Test context logic | Hard | Easy | ✅ Isolated tests |
| Debug context issues | Hard | Easy | ✅ Clear boundaries |
| Modify existing context | Risky | Safe | ✅ No side effects |

### **Architecture Quality**

- ✅ **Single Responsibility**: Each class has one job
- ✅ **Open/Closed**: Open for extension, closed for modification
- ✅ **Liskov Substitution**: All providers are interchangeable
- ✅ **Interface Segregation**: Minimal interfaces
- ✅ **Dependency Inversion**: Depend on abstractions

---

## 🚀 Recommendation

### **Implement This Architecture Before FT-206 Optimization**

**Why**:
1. ✅ **Clean foundation** for FT-206 minimal context
2. ✅ **Easy to add** Garmin, goal planning, etc.
3. ✅ **Testable** in isolation
4. ✅ **Maintainable** (each provider is ~50-100 lines)
5. ✅ **Future-proof** (open for extension)

**Timeline**:
- **Week 1**: Phases 1-2 (Extract providers, create strategies)
- **Week 2**: Phases 3-4 (DecisionEngine, simplify ClaudeService)
- **Week 3**: FT-206 optimization (now much easier!)

**Total Effort**: 10-15 hours (one-time refactoring)  
**Future Extensions**: 2-4 hours per new provider

**Result**: Clean, extensible architecture + ready for 80% token reduction

---

## 📝 Conclusion

This architecture:
- ✅ **Separates concerns** (context building is independent)
- ✅ **Easy to extend** (add providers without touching core)
- ✅ **Easy to test** (each provider tested in isolation)
- ✅ **Not over-engineered** (simple interfaces, clear responsibilities)
- ✅ **Future-proof** (Garmin, goal planning, etc. are trivial to add)
- ✅ **Follows SOLID principles** (clean, maintainable code)

**This is the foundation for scalable, maintainable AI context management.** 🚀

---

**Architecture Design Complete** ✅

