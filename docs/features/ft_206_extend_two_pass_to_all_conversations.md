# FT-206: Extend Two-Pass Architecture to All Conversations

**Analysis Date**: 2025-10-24  
**Status**: Architectural Enhancement Proposal  
**Branch**: `fix/ft-206-universal-laws-system-prompt-redesign`  
**Based On**: FT-220 Context Log Analysis  
**Related Features**: FT-084 (Existing Two-Pass for Data Queries)

---

## 🎯 Executive Summary

**CRITICAL DISCOVERY**: The two-pass architecture **already exists** (FT-084) but is currently:
1. **Limited to data queries only** (~30% of messages)
2. **Uses FULL CONTEXT in both passes** (13,008 tokens × 2 = 26,016 tokens!)

**Proposal**: Extend FT-084 to **all conversations** with **minimal context in Pass 1**, achieving:
- **80% token reduction** (13,008 → 2,600 avg tokens)
- **$312 savings per 10K messages**
- **Better AI focus** (only relevant context)
- **Leverage existing infrastructure** (FT-084 already works!)

---

## 🔍 Current State: FT-084 Two-Pass Architecture

### **Existing Implementation** (Since FT-084)

The system **already uses two-pass processing** for data-requiring queries:

**Location**: `lib/services/claude_service.dart` (lines 552-562)

```dart
// Check if Claude requested data using intelligent two-pass approach
if (_containsMCPCommand(assistantMessage)) {
  _logger.info('🧠 FT-084: Detected data request, switching to two-pass processing');
  final dataInformedResponse = await _processDataRequiredQuery(
      message, assistantMessage, messageId);
  return dataInformedResponse;
}

// Regular conversation flow (no data required)
_logger.debug('Regular conversation - no data required');
```

### **Current FT-084 Flow** (Data Queries Only)

```
User: "o que eu fiz hoje?"
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PASS 1: Claude with FULL CONTEXT (13,008 tokens)            │
├─────────────────────────────────────────────────────────────┤
│ Input:                                                       │
│ - Full system prompt (909 lines)                            │
│ - Full Oracle framework (400 lines)                         │
│ - All MCP functions (100 lines)                             │
│ - All persona details (150 lines)                           │
│ - Core behavioral rules (50 lines)                          │
│ - Priority hierarchy (70 lines)                             │
│ - Audio formatting (50 lines)                               │
│                                                             │
│ Output: {"action": "get_activity_stats", "days": 0}         │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ DATA FETCH: Execute MCP Commands (200ms)                    │
├─────────────────────────────────────────────────────────────┤
│ - get_activity_stats(days=0)                                │
│ - Returns: [water: 14:30, exercise: 16:00]                  │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PASS 2: Claude with FULL CONTEXT + Data (15,000 tokens)     │
├─────────────────────────────────────────────────────────────┤
│ Input:                                                       │
│ - Same full system prompt (909 lines)                       │
│ - Fetched activity data                                     │
│ - Enriched prompt with qualification                        │
│                                                             │
│ Output: "Registrei água às 14:30 e exercício às 16:00"      │
└─────────────────────────────────────────────────────────────┘
```

**Total Tokens**: 13,008 (Pass 1) + 15,000 (Pass 2) = **28,008 tokens**  
**Cost**: ~$0.084 per data query message  
**Problem**: **Both passes use full context** - massive waste!

---

## 🧠 Proposed Architecture: Minimal Context Two-Pass

### **Enhanced FT-084 Flow** (All Conversations)

```
User: "o que eu fiz hoje?"
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PASS 1: Decision Engine (MINIMAL - 500-1,000 tokens)        │
├─────────────────────────────────────────────────────────────┤
│ Input:                                                       │
│ - Persona identifier (5 lines)                              │
│ - User message                                              │
│ - Last 2 messages (for context)                             │
│ - MCP function catalog (20 lines)                           │
│ - Decision rules (10 lines)                                 │
│                                                             │
│ Output: {                                                    │
│   "reasoning": "User asking about today's activities",      │
│   "mcp_calls": [{"action": "get_activity_stats", "days": 0}],│
│   "response_type": "data_informed",                         │
│   "needs_oracle": false,                                    │
│   "needs_coaching": false                                   │
│ }                                                            │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ DATA FETCH: Execute MCP Commands (200ms)                    │
├─────────────────────────────────────────────────────────────┤
│ - get_activity_stats(days=0)                                │
│ - Returns: [water: 14:30, exercise: 16:00]                  │
│ - Oracle framework NOT loaded (not needed)                  │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PASS 2: Response Generation (FOCUSED - 2,000-3,000 tokens)  │
├─────────────────────────────────────────────────────────────┤
│ Input:                                                       │
│ - Persona core identity (20 lines)                          │
│ - User message                                              │
│ - Pass 1 reasoning                                          │
│ - Fetched activity data                                     │
│ - Last 5 messages (for continuity)                          │
│ - Self-review checklist                                     │
│                                                             │
│ Output: "Registrei água às 14:30 e exercício às 16:00"      │
└─────────────────────────────────────────────────────────────┘
```

**Total Tokens**: 1,000 (Pass 1) + 2,500 (Pass 2) = **3,500 tokens**  
**Cost**: ~$0.011 per message  
**Savings**: **87% reduction!** ($0.084 → $0.011)

---

## 💡 Key Benefits

### **1. Massive Token Reduction**

| Message Type | Current (Single Pass) | Current (FT-084 Two-Pass) | Proposed (Minimal Two-Pass) | Reduction |
|--------------|----------------------|---------------------------|----------------------------|-----------|
| **Simple Greeting** | 13,008 | N/A (single pass) | 1,500 | 88% |
| **Data Query** | 13,008 | 28,008 | 3,500 | 87% |
| **Coaching Session** | 13,008 | N/A (single pass) | 5,000 | 62% |
| **Average** | 13,008 | ~18,000 | 2,600 | **80%** |

### **2. Cost Savings**

| Metric | Current | Proposed | Savings |
|--------|---------|----------|---------|
| **Per Message** | $0.039 | $0.008 | 79% |
| **Per 10K** | $390 | $78 | **$312** |
| **Per 100K** | $3,900 | $780 | **$3,120** |

### **3. Better AI Focus**

**Pass 1**: Pure decision-making
- No noise from unused context
- Clear task: analyze and decide
- Faster, more accurate decisions

**Pass 2**: Focused execution
- Only relevant data present
- Clear task: respond using provided data
- Better quality responses

### **4. Leverage Existing Infrastructure**

✅ FT-084 two-pass flow already works  
✅ MCP command detection already implemented  
✅ Data fetch orchestration already tested  
✅ Conversation history integrity already maintained  
✅ Graceful fallback already in place

**We just need to**:
1. Add minimal context mode for Pass 1
2. Add dynamic context loading for Pass 2
3. Extend to all conversations (not just data queries)

---

## 📋 Detailed Implementation Plan

### **Phase 1: Minimal Context Mode** (4-6 hours)

#### **1.1 Create Decision Engine Prompt Builder** (2 hours)

**Location**: `lib/services/claude_service.dart`

```dart
/// FT-206: Build minimal decision engine prompt for Pass 1
String _buildDecisionEnginePrompt(String userMessage) {
  final lastMessages = _getLastNMessages(2); // For context
  
  return '''
# DECISION ENGINE

## Persona
- Name: ${_activePersonaName}
- Role: ${_activePersonaRole}
- Style: ${_activePersonaStyle}

## User Message
$userMessage

## Last 2 Messages (for context)
$lastMessages

## Available Functions
- get_current_time: Current date/time
- get_activity_stats: Activity data (days parameter)
- get_conversation_context: Conversation history
- oracle_detect_activities: Detect Oracle activities
- get_interleaved_conversation: Recent conversation thread

## Decision Rules
1. If user asks about time → call get_current_time
2. If user asks about activities/data → call get_activity_stats
3. If user references past conversation → call get_conversation_context
4. If message contains activities → call oracle_detect_activities
5. If simple greeting/conversation → no data needed

## Your Task
Analyze the user message and decide:
1. What data is needed?
2. Which MCP functions to call?
3. What type of response is appropriate?

Output format:
{
  "reasoning": "...",
  "mcp_calls": [...],
  "response_type": "conversational|data_informed|coaching",
  "needs_oracle": true/false,
  "needs_coaching": true/false
}
''';
}
```

#### **1.2 Create Dynamic Context Loader** (2 hours)

```dart
/// FT-206: Build dynamic context for Pass 2 based on Pass 1 decision
Future<String> _buildDynamicContext(
  String userMessage,
  Map<String, dynamic> pass1Decision,
  String mcpData,
) async {
  final StringBuffer context = StringBuffer();
  
  // 1. Minimal persona core (always included)
  context.writeln(_buildMinimalPersonaCore());
  
  // 2. User message
  context.writeln('\n## User Message\n$userMessage');
  
  // 3. Pass 1 reasoning
  context.writeln('\n## Analysis\n${pass1Decision['reasoning']}');
  
  // 4. Fetched data (if any)
  if (mcpData.isNotEmpty) {
    context.writeln('\n## Fetched Data\n$mcpData');
  }
  
  // 5. Oracle framework (only if needed)
  if (pass1Decision['needs_oracle'] == true) {
    context.writeln('\n${await _loadOracleFrameworkSummary()}');
  }
  
  // 6. Coaching methodology (only if needed)
  if (pass1Decision['needs_coaching'] == true) {
    context.writeln('\n${await _loadCoachingMethodology()}');
  }
  
  // 7. Recent conversation (last 5 messages)
  context.writeln('\n${await _getLastNMessages(5)}');
  
  // 8. Self-review checklist
  context.writeln(_buildSelfReviewChecklist());
  
  return context.toString();
}
```

#### **1.3 Modify `_sendMessageInternal()` to Use Minimal Context** (1 hour)

```dart
Future<String> _sendMessageInternal(String message) async {
  // ... existing initialization ...
  
  // FT-206: Use minimal context for Pass 1
  final decisionPrompt = _buildDecisionEnginePrompt(message);
  
  // Pass 1: Decision engine with minimal context
  final pass1Response = await _callClaudeWithPrompt(decisionPrompt);
  
  // Parse Pass 1 decision
  final pass1Decision = _parsePass1Decision(pass1Response);
  
  // Execute MCP calls if needed
  String mcpData = '';
  if (pass1Decision['mcp_calls'].isNotEmpty) {
    mcpData = await _executeMCPCalls(pass1Decision['mcp_calls']);
  }
  
  // FT-206: Build dynamic context for Pass 2
  final dynamicContext = await _buildDynamicContext(
    message,
    pass1Decision,
    mcpData,
  );
  
  // Pass 2: Response generation with focused context
  final pass2Response = await _callClaudeWithPrompt(dynamicContext);
  
  // ... existing history management ...
  
  return _cleanResponseForUser(pass2Response);
}
```

#### **1.4 Testing** (1 hour)

- Test simple greetings (minimal context)
- Test data queries (focused context + data)
- Test coaching sessions (focused context + Oracle)
- Verify token counts in logs
- Validate AI quality maintained

---

### **Phase 2: Hybrid Routing** (2-3 hours)

#### **2.1 Add Local Message Classification** (1 hour)

```dart
/// FT-206: Classify message type locally (no API call)
String _classifyMessageLocally(String message) {
  final lowerMessage = message.toLowerCase();
  
  // Simple conversational
  final simplePatterns = [
    r'^(opa|oi|olá|hey|hi)\b',
    r'^(valeu|obrigado|thanks)\b',
    r'^(bom dia|boa tarde|boa noite)\b',
    r'^(tudo certo|tudo bem|beleza)\b',
  ];
  if (simplePatterns.any((p) => RegExp(p).hasMatch(lowerMessage))) {
    return 'simple_conversational';
  }
  
  // Data query
  final dataPatterns = [
    r'\b(o que|what).*(fiz|fez|did)\b',
    r'\b(quantas|quantos|how many)\b',
    r'\b(resumo|summary)\b',
    r'\b(semana|week|mês|month)\b',
  ];
  if (dataPatterns.any((p) => RegExp(p).hasMatch(lowerMessage))) {
    return 'data_query';
  }
  
  // Coaching (default for longer messages)
  if (message.split().length > 5) {
    return 'coaching_session';
  }
  
  return 'simple_conversational';
}
```

#### **2.2 Implement Conditional Routing** (1 hour)

```dart
Future<String> _sendMessageInternal(String message) async {
  // ... existing initialization ...
  
  // FT-206: Classify message locally
  final messageType = _classifyMessageLocally(message);
  
  if (messageType == 'simple_conversational') {
    // Single pass with minimal context
    return await _processSinglePassMinimal(message);
  } else {
    // Two-pass with dynamic context
    return await _processTwoPassDynamic(message, messageType);
  }
}
```

#### **2.3 Testing** (1 hour)

- Test routing logic with various message types
- Verify token counts per message type
- Validate latency for simple messages
- Ensure AI quality across all types

---

### **Phase 3: Optimization & Monitoring** (2-3 hours)

#### **3.1 Add Token Tracking** (1 hour)

```dart
/// FT-206: Track token usage per pass
void _logTokenUsage(String pass, int tokens) {
  _logger.info('FT-206: $pass token usage: $tokens');
  // Store in analytics for monitoring
}
```

#### **3.2 Add Performance Metrics** (1 hour)

```dart
/// FT-206: Track latency per pass
void _logLatency(String pass, Duration duration) {
  _logger.info('FT-206: $pass latency: ${duration.inMilliseconds}ms');
  // Store in analytics for monitoring
}
```

#### **3.3 A/B Testing Setup** (1 hour)

```dart
/// FT-206: Feature flag for gradual rollout
bool _isFT206Enabled() {
  return _featureFlags['ft_206_minimal_two_pass'] ?? false;
}
```

---

## 📊 Expected Results

### **Token Distribution** (Based on 40/40/20 message type split)

| Message Type | % of Messages | Current Tokens | Proposed Tokens | Savings |
|--------------|---------------|----------------|-----------------|---------|
| Simple Conversational | 40% | 13,008 | 1,000 | 92% |
| Data Queries | 40% | 13,008 | 3,000 | 77% |
| Coaching Sessions | 20% | 13,008 | 5,000 | 62% |
| **Weighted Average** | 100% | **13,008** | **2,600** | **80%** |

### **Cost Analysis**

| Metric | Current | Proposed | Savings |
|--------|---------|----------|---------|
| **Per Message** | $0.039 | $0.008 | $0.031 (79%) |
| **Per 10K** | $390 | $78 | **$312 (80%)** |
| **Per 100K** | $3,900 | $780 | **$3,120 (80%)** |
| **Per 1M** | $39,000 | $7,800 | **$31,200 (80%)** |

### **Latency Impact**

| Message Type | Current | Proposed | Change |
|--------------|---------|----------|--------|
| Simple Conversational | 2-3s | 1-2s | **Faster!** |
| Data Queries | 2-3s | 3-4s | +1s |
| Coaching Sessions | 2-3s | 4-5s | +2s |
| **Average** | 2-3s | 2.5-3.5s | +0.5s |

---

## 🎯 Implementation Roadmap

### **Option 1: Incremental (RECOMMENDED)** ⭐

#### **Sprint 1: Minimal Context Mode** (4-6 hours)
- Build decision engine prompt
- Create dynamic context loader
- Modify `_sendMessageInternal()`
- Test with all message types

**Deliverable**: Two-pass with minimal context for all conversations  
**Expected Savings**: 70-80% token reduction

#### **Sprint 2: Hybrid Routing** (2-3 hours)
- Add local message classification
- Implement conditional routing
- Test routing logic

**Deliverable**: Smart routing (single-pass for simple, two-pass for complex)  
**Expected Savings**: 80% token reduction

#### **Sprint 3: Optimization** (2-3 hours)
- Add token tracking
- Add performance metrics
- Setup A/B testing

**Deliverable**: Production-ready system with monitoring  
**Expected Savings**: 80% token reduction

**Total Effort**: 8-12 hours  
**Total Savings**: $312 per 10K messages (80%)

---

### **Option 2: Direct Implementation** (Higher Risk)

#### **Week 1: Core Implementation** (8-10 hours)
- All Phase 1 + Phase 2 work
- Comprehensive testing

#### **Week 2: Optimization & Rollout** (4-6 hours)
- Phase 3 work
- Gradual rollout with monitoring

**Total Effort**: 12-16 hours  
**Total Savings**: $312 per 10K messages (80%)

---

## 🚀 Recommendation

### **Start with Option 1 (Incremental)**

**Rationale**:
1. ✅ Lower risk (validate each phase)
2. ✅ Faster time to value (70-80% savings in Sprint 1)
3. ✅ Learn from real usage before full rollout
4. ✅ Easier to debug and optimize incrementally

**Timeline**:
- **Week 1**: Sprint 1 (Minimal Context Mode)
- **Week 2**: Sprint 2 (Hybrid Routing)
- **Week 3**: Sprint 3 (Optimization & Monitoring)

**Expected Outcome**:
- **80% token reduction** by end of Week 2
- **$312 savings per 10K messages**
- **Production-ready system** by end of Week 3

---

## ❓ Key Questions

1. **Is 0.5-1s average latency increase acceptable** for 80% cost savings?
   - Simple messages are actually **faster** (1-2s vs 2-3s)
   - Complex messages are slower (4-5s vs 2-3s)
   - Average is only +0.5s

2. **Should we implement hybrid routing or always use two-pass?**
   - Hybrid is more complex but optimizes latency
   - Always two-pass is simpler but slower for simple messages
   - **Recommendation**: Start with always two-pass, add hybrid in Sprint 2

3. **How to handle A/B testing?**
   - Feature flag in config
   - Gradual rollout (10% → 50% → 100%)
   - Monitor token usage and AI quality

---

## 📝 Conclusion

The two-pass architecture **already exists** (FT-084) and **already works**. We just need to:

1. **Add minimal context mode** for Pass 1 (decision engine)
2. **Add dynamic context loading** for Pass 2 (response generation)
3. **Extend to all conversations** (not just data queries)

This will achieve:
- **80% token reduction** (13,008 → 2,600 avg tokens)
- **$312 savings per 10K messages**
- **Better AI focus** (only relevant context)
- **Leverage existing infrastructure** (FT-084 already works!)

**Let's extend FT-084 and unlock massive savings!** 🚀

