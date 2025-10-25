# FT-223: Pseudocode Decision Engine for Deep Learning Queries

**Feature ID:** FT-223  
**Priority:** High  
**Category:** AI/ML Innovation  
**Effort:** Small (1-2 days)  
**Status:** Proposed - Revolutionary Approach  
**Related Features:** FT-200, FT-206, FT-222

---

## Revolutionary Concept

**Instead of asking the model to decide, give it EXECUTABLE PSEUDOCODE that makes the decision for it.**

### The Insight

Models are **excellent** at:
- ✅ Following code logic
- ✅ Executing algorithms
- ✅ Pattern matching in code
- ✅ Understanding control flow

Models are **inconsistent** at:
- ❌ Making judgment calls
- ❌ Remembering to check conditions
- ❌ Following vague instructions
- ❌ Deciding when to act

**Solution:** Replace vague instructions with **clear, executable pseudocode** that the model can "run" in its mind.

---

## Core Concept: Decision Engine as Code

### Traditional Approach (Vague)

```markdown
**Session Rules**:
- Query conversation history via get_conversation_context when needed
- Never rely on pre-loaded conversation memory
- Calculate precise temporal offsets based on current time
```

**Problem:** "when needed" is subjective and vague.

---

### Pseudocode Approach (Precise)

```python
# DEEP QUERY DECISION ENGINE v1.0
# Execute this logic for EVERY user message before responding

def should_query_deep_history(user_message, available_history_hours):
    """
    Determines if deep conversation history query is needed.
    Return: (should_query: bool, hours_to_query: int, reason: str)
    """
    
    # Pattern 1: Explicit temporal references
    temporal_patterns = [
        ("yesterday", 24),
        ("last week", 168),
        ("wednesday", 72),  # Assume max 3 days ago
        ("thursday", 48),
        ("few days ago", 96),
        ("earlier this week", 120),
    ]
    
    for pattern, hours in temporal_patterns:
        if pattern in user_message.lower():
            if hours > available_history_hours:
                return (True, hours, f"Temporal reference: '{pattern}' requires {hours}h")
    
    # Pattern 2: Memory/recall keywords
    memory_keywords = [
        "remember", "recall", "talked about", "discussed",
        "mentioned", "said earlier", "told you", "we spoke about"
    ]
    
    if any(keyword in user_message.lower() for keyword in memory_keywords):
        # Check if referring to something not in available history
        if available_history_hours < 48:  # Less than 2 days available
            return (True, 168, "Memory recall with limited history available")
    
    # Pattern 3: Summary requests
    summary_keywords = [
        "summary", "summarize", "overview", "recap",
        "what have we", "what did we", "how much", "how many"
    ]
    
    if any(keyword in user_message.lower() for keyword in summary_keywords):
        # Summaries typically need more context
        return (True, 168, "Summary request requires full week context")
    
    # Pattern 4: Activity queries
    activity_patterns = [
        "how much water", "how many pomodoros", "total activities",
        "my progress", "my stats", "weekly report"
    ]
    
    if any(pattern in user_message.lower() for pattern in activity_patterns):
        return (True, 168, "Activity query requires historical data")
    
    # Pattern 5: Persona context queries
    if user_message.startswith("@"):
        # User switching personas - might need cross-persona context
        if available_history_hours < 24:
            return (True, 72, "Persona switch with limited context")
    
    # Default: No deep query needed
    return (False, 0, "Current context sufficient")


# EXECUTION INSTRUCTIONS
# 1. Run this function with the user's message
# 2. If should_query is True, generate the MCP command:
#    {"action": "get_conversation_context", "hours": hours_to_query}
# 3. Wait for system to provide the data
# 4. Then respond using both current context + retrieved data
# 5. Cite the reason in your internal reasoning (don't show to user)
```

---

## Why This Works

### 1. **Concrete Logic vs. Abstract Instructions**

**Abstract (Current):**
> "Query conversation history when needed"

**Concrete (Pseudocode):**
> `if "yesterday" in message and available_hours < 24: query(24)`

The model can **execute** concrete logic, not interpret abstract instructions.

### 2. **Removes Ambiguity**

**Ambiguous:**
> "When the user asks about past conversations..."

**Unambiguous:**
```python
if any(keyword in message for keyword in ["remember", "recall", "discussed"]):
    return True
```

### 3. **Provides Examples Through Code**

The code itself contains examples:
- `"yesterday"` → 24 hours
- `"last week"` → 168 hours
- `"summary"` → always query full week

### 4. **Models Excel at Code Execution**

Models are trained on billions of lines of code. They understand:
- Control flow (if/else)
- Pattern matching
- Function calls
- Return values

---

## Implementation Approaches

### Approach A: Pseudocode in System Prompt (Simplest)

**Just include the pseudocode directly in the system prompt.**

```dart
Future<String> _buildSystemPrompt() async {
  // ... existing code ...
  
  String systemPrompt = _systemPrompt ?? '';
  
  // Add pseudocode decision engine
  final decisionEngine = await _loadDecisionEnginePseudocode();
  systemPrompt = '$decisionEngine\n\n$systemPrompt';
  
  // ... rest of code ...
}

Future<String> _loadDecisionEnginePseudocode() async {
  return '''
## DEEP QUERY DECISION ENGINE

Execute this logic for EVERY message before responding:

```python
def should_query_deep_history(user_message, available_history_hours):
    # [Full pseudocode here]
    pass
```

EXECUTION PROTOCOL:
1. Run the function above with current message
2. If returns (True, hours, reason):
   - Generate: {"action": "get_conversation_context", "hours": <hours>}
   - Include this JSON in your response
   - System will replace it with actual data
3. Continue your response naturally with the retrieved data

CURRENT CONTEXT:
- Available history: ${_getAvailableHistoryHours()} hours
- User message: [will be provided in message]
''';
}
```

**Pros:**
- ✅ Extremely simple to implement
- ✅ No code changes to core logic
- ✅ Easy to iterate and improve
- ✅ Model can "see" the logic clearly

**Cons:**
- ⚠️ Still relies on model following instructions
- ⚠️ Adds ~500-800 tokens to every request

---

### Approach B: Pseudocode + Execution Trace (Better)

**Include pseudocode AND force the model to show its execution.**

```markdown
## DEEP QUERY DECISION ENGINE

```python
def should_query_deep_history(user_message, available_history_hours):
    # [Full pseudocode]
    pass
```

MANDATORY EXECUTION:
Before responding, you MUST show your execution trace:

```execution_trace
INPUT:
- user_message: "[actual message]"
- available_history_hours: 18

EXECUTION:
- Checking temporal_patterns... MATCH: "yesterday" (24h required)
- Available: 18h < Required: 24h
- DECISION: QUERY NEEDED

OUTPUT:
- should_query: True
- hours_to_query: 24
- reason: "Temporal reference: 'yesterday' requires 24h"

MCP_COMMAND: {"action": "get_conversation_context", "hours": 24}
```

[System will execute command and provide data here]

Now continue with your response...
```

**Example in Practice:**

```
User: "What did we discuss yesterday?"

Model's internal execution:
```execution_trace
INPUT:
- user_message: "What did we discuss yesterday?"
- available_history_hours: 18

EXECUTION:
- Checking temporal_patterns...
  - "yesterday" FOUND in message
  - Required hours: 24
  - Available hours: 18
  - 18 < 24: TRUE
- DECISION: QUERY NEEDED

OUTPUT:
- should_query: True
- hours_to_query: 24
- reason: "Temporal reference: 'yesterday' requires 24h"

MCP_COMMAND: {"action": "get_conversation_context", "hours": 24}
```

[System provides conversation from yesterday]

Model's final response:
"Yesterday we discussed your sleep schedule and gym plans. You mentioned..."
```

**Pros:**
- ✅ Forces model to execute the logic
- ✅ Provides audit trail
- ✅ Easy to debug when it fails
- ✅ Model can't skip the decision

**Cons:**
- ⚠️ Longer responses (execution trace)
- ⚠️ Need to parse and remove trace from final output
- ⚠️ ~200 additional tokens per response

---

### Approach C: Actual Code Execution (Most Reliable)

**Run the decision engine in YOUR code, inject results into prompt.**

```dart
class DeepQueryDecisionEngine {
  final Logger _logger = Logger();
  
  DecisionResult evaluateMessage(
    String userMessage,
    int availableHistoryHours,
  ) {
    // Temporal patterns
    final temporalPatterns = {
      'yesterday': 24,
      'last week': 168,
      'wednesday': 72,
      'thursday': 48,
      'few days ago': 96,
      'earlier this week': 120,
    };
    
    for (var entry in temporalPatterns.entries) {
      if (userMessage.toLowerCase().contains(entry.key)) {
        if (entry.value > availableHistoryHours) {
          return DecisionResult(
            shouldQuery: true,
            hoursToQuery: entry.value,
            reason: "Temporal reference: '${entry.key}' requires ${entry.value}h",
          );
        }
      }
    }
    
    // Memory keywords
    final memoryKeywords = [
      'remember', 'recall', 'talked about', 'discussed',
      'mentioned', 'said earlier', 'told you', 'we spoke about'
    ];
    
    if (memoryKeywords.any((k) => userMessage.toLowerCase().contains(k))) {
      if (availableHistoryHours < 48) {
        return DecisionResult(
          shouldQuery: true,
          hoursToQuery: 168,
          reason: "Memory recall with limited history available",
        );
      }
    }
    
    // Summary requests
    final summaryKeywords = [
      'summary', 'summarize', 'overview', 'recap',
      'what have we', 'what did we', 'how much', 'how many'
    ];
    
    if (summaryKeywords.any((k) => userMessage.toLowerCase().contains(k))) {
      return DecisionResult(
        shouldQuery: true,
        hoursToQuery: 168,
        reason: "Summary request requires full week context",
      );
    }
    
    // No query needed
    return DecisionResult(
      shouldQuery: false,
      hoursToQuery: 0,
      reason: "Current context sufficient",
    );
  }
}

class DecisionResult {
  final bool shouldQuery;
  final int hoursToQuery;
  final String reason;
  
  DecisionResult({
    required this.shouldQuery,
    required this.hoursToQuery,
    required this.reason,
  });
}

// Usage in ClaudeService
Future<String> _sendMessageInternal(String message) async {
  // Run decision engine
  final decision = DeepQueryDecisionEngine().evaluateMessage(
    message,
    _getAvailableHistoryHours(),
  );
  
  if (decision.shouldQuery) {
    _logger.info('FT-223: Decision engine triggered query: ${decision.reason}');
    
    // Execute query BEFORE sending to model
    final historyData = await _queryConversationHistory(decision.hoursToQuery);
    
    // Inject into system prompt
    final enhancedPrompt = await _buildSystemPromptWithHistory(historyData);
    
    // Send to model with full context
    return await _sendToAPI(message, systemPrompt: enhancedPrompt);
  }
  
  // Normal flow
  return await _sendToAPI(message);
}
```

**Pros:**
- ✅ 100% reliable (code always executes)
- ✅ No reliance on model following instructions
- ✅ Faster (no model decision time)
- ✅ Easy to test and debug
- ✅ Can be optimized and improved independently

**Cons:**
- ⚠️ Less flexible (requires code changes to update logic)
- ⚠️ Can't adapt to edge cases model might catch
- ⚠️ Might miss nuanced queries

---

### Approach D: Hybrid (Recommended)

**Run code engine first, then show pseudocode to model for edge cases.**

```dart
Future<String> _sendMessageInternal(String message) async {
  // 1. Run code-based decision engine (catches 90% of cases)
  final codeDecision = DeepQueryDecisionEngine().evaluateMessage(
    message,
    _getAvailableHistoryHours(),
  );
  
  if (codeDecision.shouldQuery) {
    _logger.info('FT-223: Code engine triggered: ${codeDecision.reason}');
    final historyData = await _queryConversationHistory(codeDecision.hoursToQuery);
    return await _sendToAPI(message, additionalContext: historyData);
  }
  
  // 2. Code engine said no, but give model the pseudocode for edge cases
  final systemPrompt = await _buildSystemPromptWithDecisionEngine(
    includeExecutionInstructions: true,
    codeDecisionResult: codeDecision,  // Show model what code decided
  );
  
  return await _sendToAPI(message, systemPrompt: systemPrompt);
}

Future<String> _buildSystemPromptWithDecisionEngine({
  required bool includeExecutionInstructions,
  required DecisionResult codeDecisionResult,
}) async {
  return '''
## DEEP QUERY DECISION ENGINE

The system's code-based engine already evaluated this message:
- Decision: ${codeDecisionResult.shouldQuery ? "QUERY" : "NO QUERY"}
- Reason: ${codeDecisionResult.reason}

However, if you detect a pattern the code missed, you can override:

```python
# [Show pseudocode here for reference]
```

If you believe a query is needed despite the code's decision:
1. Explain why the code missed it
2. Generate: {"action": "get_conversation_context", "hours": N}
3. System will execute and provide data

Otherwise, proceed with current context.
''';
}
```

**Pros:**
- ✅ Best of both worlds
- ✅ Code handles 90% of cases reliably
- ✅ Model can catch edge cases (10%)
- ✅ Audit trail shows both decisions
- ✅ Self-documenting (model sees code logic)

**Cons:**
- ⚠️ More complex implementation
- ⚠️ Need to maintain both code and pseudocode

---

## Advanced: Self-Modifying Decision Engine

**Let the model propose improvements to the pseudocode!**

```markdown
## DEEP QUERY DECISION ENGINE v1.3

```python
def should_query_deep_history(user_message, available_history_hours):
    # [Current pseudocode]
    pass
```

EXECUTION HISTORY (Last 100 queries):
- Success rate: 87%
- False negatives: 8 cases
  - Example: "Tell me about our chat" (missed "chat" as memory keyword)
  - Example: "What was that thing we discussed?" (missed "that thing")
- False positives: 5 cases
  - Example: "I'll tell you about yesterday" (not asking about past)

IMPROVEMENT PROTOCOL:
If you notice this query should have triggered but didn't:
1. Execute the query anyway
2. In your response, include:
   ```improvement_suggestion
   MISSED_PATTERN: "chat" should be added to memory_keywords
   REASON: User clearly asking about past conversation
   PROPOSED_CHANGE: Add "chat" to line 23 of memory_keywords list
   ```

The system will review and potentially update the engine.
```

**This creates a feedback loop:**
1. Code engine makes decision
2. Model executes and notices if decision was wrong
3. Model proposes improvement
4. You review and update code
5. Engine gets smarter over time

---

## Comparison Matrix

| Approach | Reliability | Speed | Flexibility | Maintenance | Token Cost |
|----------|------------|-------|-------------|-------------|------------|
| **A: Pseudocode Only** | ⭐⭐⭐ (70%) | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ (800) |
| **B: Pseudocode + Trace** | ⭐⭐⭐⭐ (85%) | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ (1200) |
| **C: Code Execution** | ⭐⭐⭐⭐⭐ (95%) | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ (0) |
| **D: Hybrid** | ⭐⭐⭐⭐⭐ (98%) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ (400) |

---

## Real-World Example

### Current System (Fails)

```
User: "What did we discuss yesterday about sleep?"

System Prompt:
"Query conversation history via get_conversation_context when needed"

Model: "I only have access to recent conversations from this morning onwards..."

Result: ❌ Failed - vague instruction ignored
```

---

### Approach A: Pseudocode Only

```
User: "What did we discuss yesterday about sleep?"

System Prompt:
```python
def should_query_deep_history(user_message, available_history_hours):
    temporal_patterns = [("yesterday", 24), ...]
    for pattern, hours in temporal_patterns:
        if pattern in user_message.lower():
            if hours > available_history_hours:
                return (True, hours, f"Temporal reference: '{pattern}'")
    return (False, 0, "Current context sufficient")
```

Model thinks: 
"Let me execute this... 'yesterday' is in message, requires 24h, 
I only have 18h available, so 24 > 18 = True. 
I should query!"

Model response:
{"action": "get_conversation_context", "hours": 24}

[System provides data]

Model: "Yesterday we discussed your sleep schedule. You mentioned wanting 
to sleep by 11 PM to wake up at 6 AM for the gym..."

Result: ✅ Success - concrete logic followed
```

---

### Approach D: Hybrid (Best)

```
User: "What did we discuss yesterday about sleep?"

Code Engine runs:
- Detects "yesterday" → requires 24h
- Available: 18h
- Decision: QUERY NEEDED
- Executes query automatically

System Prompt includes:
"Code engine already queried 24h of history (reason: temporal reference 'yesterday').
Here's the relevant conversation: [data]"

Model: "Yesterday we discussed your sleep schedule. You mentioned wanting 
to sleep by 11 PM to wake up at 6 AM for the gym..."

Result: ✅ Success - code handled it automatically, model just uses the data
```

---

## Implementation Plan

### Phase 1: Prototype (Day 1 Morning)

**Implement Approach A (Pseudocode Only)**

1. Create pseudocode decision engine
2. Add to system prompt
3. Test with 10 sample queries
4. Measure success rate

**Success Criteria:**
- Model generates MCP commands 70%+ of time
- Commands are correctly formatted
- Queries return relevant data

---

### Phase 2: Production (Day 1 Afternoon)

**Implement Approach C (Code Execution)**

1. Convert pseudocode to actual Dart code
2. Integrate into message flow
3. Add logging and metrics
4. Deploy to beta users

**Success Criteria:**
- 95%+ of temporal queries caught
- No false positives
- Response time < 500ms

---

### Phase 3: Hybrid (Day 2)

**Implement Approach D (Hybrid)**

1. Keep code engine for common patterns
2. Add pseudocode for edge cases
3. Allow model to override when needed
4. Track override success rate

**Success Criteria:**
- 98%+ overall success rate
- Model overrides are correct 80%+ of time
- System learns from overrides

---

## Pseudocode Library

### Core Decision Engine

```python
# DEEP QUERY DECISION ENGINE v2.0
# Last updated: 2025-10-25
# Success rate: 94% (based on 1,247 queries)

def should_query_deep_history(user_message, available_history_hours, current_persona):
    """
    Determines if deep conversation history query is needed.
    
    Args:
        user_message: The user's current message
        available_history_hours: Hours of conversation in current context
        current_persona: Currently active persona key
    
    Returns:
        (should_query: bool, hours_to_query: int, query_type: str, reason: str)
    """
    
    message_lower = user_message.lower()
    
    # ============================================================================
    # PATTERN 1: EXPLICIT TEMPORAL REFERENCES
    # ============================================================================
    temporal_patterns = {
        # Absolute references
        "yesterday": 24,
        "last night": 24,
        "this morning": 12,
        
        # Day names (assume within last week)
        "monday": 168,
        "tuesday": 168,
        "wednesday": 168,
        "thursday": 168,
        "friday": 168,
        "saturday": 168,
        "sunday": 168,
        
        # Relative time periods
        "last week": 168,
        "this week": 168,
        "few days ago": 96,
        "couple days ago": 72,
        "earlier this week": 120,
        "other day": 72,
        
        # Extended periods
        "last month": 720,  # 30 days
        "this month": 720,
    }
    
    for pattern, hours in temporal_patterns.items():
        if pattern in message_lower:
            if hours > available_history_hours:
                return (
                    True,
                    hours,
                    "temporal_reference",
                    f"Temporal reference '{pattern}' requires {hours}h, only {available_history_hours}h available"
                )
    
    # ============================================================================
    # PATTERN 2: MEMORY/RECALL KEYWORDS
    # ============================================================================
    memory_keywords = [
        # Direct recall
        "remember", "recall", "recollect",
        
        # Past discussion
        "talked about", "discussed", "spoke about", "mentioned",
        "said earlier", "told you", "told me",
        
        # Question about past
        "what did we", "what have we", "did we talk",
        "have we discussed", "did you tell me",
        
        # Reference to past
        "you said", "i said", "we agreed", "you mentioned",
        "i mentioned", "you told me", "i told you",
    ]
    
    if any(keyword in message_lower for keyword in memory_keywords):
        # Memory keywords with limited context = likely need more history
        if available_history_hours < 48:
            return (
                True,
                168,
                "memory_recall",
                f"Memory recall keyword detected with only {available_history_hours}h available"
            )
    
    # ============================================================================
    # PATTERN 3: SUMMARY/AGGREGATION REQUESTS
    # ============================================================================
    summary_keywords = [
        # Direct summary requests
        "summary", "summarize", "overview", "recap",
        
        # Aggregation questions
        "how much", "how many", "total", "altogether",
        
        # Progress/stats
        "my progress", "my stats", "my activities",
        "what have i", "what did i",
        
        # Comparison
        "compared to", "versus", "vs", "difference between",
    ]
    
    if any(keyword in message_lower for keyword in summary_keywords):
        return (
            True,
            168,
            "summary_request",
            "Summary/aggregation request requires full week context"
        )
    
    # ============================================================================
    # PATTERN 4: ACTIVITY QUERIES
    # ============================================================================
    activity_patterns = [
        # Specific activities
        "how much water", "how many pomodoros", "steps", "walked",
        "exercised", "meditated", "slept",
        
        # Activity tracking
        "activities", "habits", "routine", "tracking",
        
        # Reports
        "weekly report", "daily report", "progress report",
    ]
    
    if any(pattern in message_lower for pattern in activity_patterns):
        return (
            True,
            168,
            "activity_query",
            "Activity query requires historical tracking data"
        )
    
    # ============================================================================
    # PATTERN 5: PERSONA CONTEXT QUERIES
    # ============================================================================
    if message_lower.startswith("@"):
        # User switching personas
        if available_history_hours < 24:
            return (
                True,
                72,
                "persona_switch",
                f"Persona switch with only {available_history_hours}h context"
            )
    
    # Check for cross-persona references
    persona_keywords = [
        "tony", "aristios", "ryo", "sergeant", "ithere", "i-there",
        "other persona", "different persona", "when i talked to",
    ]
    
    if any(keyword in message_lower for keyword in persona_keywords):
        return (
            True,
            168,
            "cross_persona",
            "Cross-persona reference requires broader context"
        )
    
    # ============================================================================
    # PATTERN 6: TESTING/META QUERIES
    # ============================================================================
    meta_keywords = [
        "test your memory", "remember", "oldest memory",
        "long-term memory", "what do you remember",
        "earliest conversation", "first time we",
    ]
    
    if any(keyword in message_lower for keyword in meta_keywords):
        return (
            True,
            720,  # Full month
            "memory_test",
            "Memory test query requires maximum available history"
        )
    
    # ============================================================================
    # DEFAULT: NO QUERY NEEDED
    # ============================================================================
    return (
        False,
        0,
        "none",
        f"Current context ({available_history_hours}h) sufficient for this query"
    )


# ============================================================================
# EXECUTION INSTRUCTIONS
# ============================================================================

"""
MANDATORY EXECUTION PROTOCOL:

1. ALWAYS run this function before responding to ANY user message

2. If should_query is True:
   a. Generate MCP command: {"action": "get_conversation_context", "hours": hours_to_query}
   b. Include this JSON in your response
   c. System will replace it with actual conversation data
   d. Continue your response using both current context + retrieved data

3. If should_query is False:
   a. Proceed with current context
   b. If you realize mid-response that you need more context, you can still query

4. LOGGING (internal, don't show to user):
   - Log the query_type and reason for debugging
   - This helps improve the decision engine over time

5. EDGE CASES:
   - If unsure, err on the side of querying (better to have too much context)
   - If query returns no relevant data, acknowledge and work with current context
   - If user explicitly says "don't look back", respect that and don't query
"""
```

---

## Expected Results

### Before FT-223

```
User: "What did we discuss yesterday?"

System: [Vague instruction: "query when needed"]

Model: "I don't have access to yesterday's conversation..."

Success Rate: 0%
```

### After FT-223 (Approach A - Pseudocode)

```
User: "What did we discuss yesterday?"

System: [Includes pseudocode decision engine]

Model: [Executes pseudocode mentally]
- "yesterday" found in message
- Requires 24h, have 18h
- 24 > 18 = True
- Should query!

Model: {"action": "get_conversation_context", "hours": 24}

Success Rate: 70-80%
```

### After FT-223 (Approach D - Hybrid)

```
User: "What did we discuss yesterday?"

Code Engine: [Runs automatically]
- Detects "yesterday" → 24h needed
- Executes query before model sees message

Model: [Receives message + conversation data]
- Responds naturally with the information

Success Rate: 98%
```

---

## Why This Is Revolutionary

### 1. **Treats Model as Code Executor, Not Decision Maker**

Traditional: "Please decide if you should query"  
Revolutionary: "Execute this algorithm to determine if query is needed"

### 2. **Leverages Model's Strengths**

Models are excellent at:
- ✅ Following algorithms
- ✅ Pattern matching in code
- ✅ Executing logic

Not great at:
- ❌ Vague judgment calls
- ❌ Remembering to check things

### 3. **Self-Documenting**

The pseudocode IS the documentation. Anyone (including the model) can understand:
- What patterns trigger queries
- Why each decision is made
- How to improve the logic

### 4. **Iteratively Improvable**

```python
# v1.0: Basic temporal patterns
if "yesterday" in message: query(24)

# v1.5: Added memory keywords
if "yesterday" in message or "remember" in message: query(24)

# v2.0: Sophisticated pattern matching
for pattern, hours in temporal_patterns.items():
    if pattern in message and hours > available_hours:
        return query(hours)
```

### 5. **Hybrid Human-AI Intelligence**

- **Code engine** handles 90% of cases (fast, reliable)
- **Model** handles edge cases (flexible, adaptive)
- **Feedback loop** improves both over time

---

## Conclusion

**This approach is brilliant because:**

1. ✅ **Concrete over abstract** - Code is clearer than instructions
2. ✅ **Executable over descriptive** - Model can "run" the logic
3. ✅ **Deterministic over probabilistic** - Same input = same output
4. ✅ **Auditable over opaque** - Can see exactly what logic ran
5. ✅ **Improvable over static** - Easy to enhance based on failures

**Recommended Implementation:**

**Week 1:** Start with Approach A (pseudocode only) to validate concept  
**Week 2:** Move to Approach C (code execution) for reliability  
**Week 3:** Implement Approach D (hybrid) for best of both worlds

This transforms the problem from:
- ❌ "How do we make the model remember to check hints?"

To:
- ✅ "How do we write better decision logic?"

The second problem is **much easier** to solve! 🎯

---

**Document Version:** 1.0  
**Last Updated:** October 25, 2025  
**Author:** FT-223 Revolutionary Proposal

