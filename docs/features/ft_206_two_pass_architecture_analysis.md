# FT-206: Two-Pass Architecture Analysis - Radical Context Optimization

**Analysis Date**: 2025-10-24  
**Status**: Architectural Enhancement Proposal  
**Branch**: `fix/ft-206-universal-laws-system-prompt-redesign`  
**Based On**: FT-220 Context Log Analysis  
**Related Features**: FT-084 (Existing Two-Pass for Data Queries)

---

## 🎯 Proposal Overview

**CRITICAL DISCOVERY**: The two-pass architecture **already exists** (FT-084) but is currently **limited to data queries only**. This analysis proposes **extending the existing two-pass system** to **all conversations** with minimal context in Pass 1 (decision engine) and dynamic context loading in Pass 2 (response generation), potentially achieving **80% token reduction** compared to current implementation.

---

## 🔍 Current State: FT-084 Two-Pass Architecture

### **Existing Implementation** (Since FT-084)

The system **already uses two-pass processing** for data-requiring queries:

**Current Flow** (from `lib/services/claude_service.dart`):
```dart
// Line 552-562: Check if Claude requested data
if (_containsMCPCommand(assistantMessage)) {
  _logger.info('🧠 FT-084: Detected data request, switching to two-pass processing');
  final dataInformedResponse = await _processDataRequiredQuery(
      message, assistantMessage, messageId);
  return dataInformedResponse;
}

// Regular conversation flow (no data required)
_logger.debug('Regular conversation - no data required');
```

**Pass 1** (Initial Response):
- User message → Claude API
- Claude analyzes and decides if data is needed
- If yes: Claude generates MCP commands like `{"action": "get_activity_stats", "days": 7}`

**Data Fetch**:
- System executes MCP commands
- Retrieves real data from database

**Pass 2** (Data-Informed Response):
- User message + fetched data → Claude API
- Claude generates final response with real data
- Response stored in conversation history

### **What's Already Working**

✅ Two-pass flow for data queries (activity stats, time context)  
✅ MCP command detection and execution  
✅ Data-informed response generation  
✅ Conversation history integrity  
✅ Graceful fallback if MCP fails  
✅ Background activity detection with qualification (FT-103)

### **What's Missing**

❌ Two-pass is **only used for data queries** (~30% of messages)  
❌ Regular conversations use **full context** (13,008 tokens)  
❌ Oracle framework **always loaded** (400 lines) even when not needed  
❌ No dynamic context loading based on conversation type  
❌ No minimal context for simple conversational messages

---

## 🧠 Proposed Architecture

### **Current Flow** (Single Pass)
```
User Message → [Full Context + System Prompt] → API Call → Response
                     13,008 tokens
                     ~2-3 seconds
```

### **Proposed Flow** (Two-Pass)
```
User Message → [Pass 1: Decision Engine] → API Call 1 → MCP Calls → 
                    ~500-1,000 tokens
                    
               [Pass 2: Response Generation] → API Call 2 → Response
                    ~2,000-3,000 tokens
                    
Total: ~2,500-4,000 tokens
Total Time: ~4-6 seconds
```

---

## 📋 Detailed Flow Design

### **Pass 1: Decision Engine** (Minimal Context)

**Purpose**: Analyze user message and decide what data is needed

**Context Structure** (~500-1,000 tokens):
```markdown
# DECISION ENGINE

## Persona
- Name: I-There 4.2
- Role: Mirror Realm reflection, life coach
- Style: Casual, curious, lowercase

## User Message
{user_message}

## Last 2 Messages (for context)
{last_2_messages}

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
  "reasoning": "User is asking about today's activities",
  "mcp_calls": [
    {"action": "get_current_time"},
    {"action": "get_activity_stats", "days": 0}
  ],
  "response_type": "data_informed",
  "needs_oracle": true,
  "needs_coaching": false
}
```

**Output**: JSON with reasoning and required MCP calls

---

### **Data Fetch Phase** (Between Passes)

**Purpose**: Execute MCP commands identified in Pass 1

**Process**:
1. Parse Pass 1 JSON output
2. Execute MCP calls in parallel (where possible)
3. Collect all results
4. Prepare for Pass 2

**Example**:
```python
pass1_output = {
  "mcp_calls": [
    {"action": "get_current_time"},
    {"action": "get_activity_stats", "days": 0}
  ],
  "needs_oracle": true
}

# Execute in parallel
results = await asyncio.gather(
  mcp.get_current_time(),
  mcp.get_activity_stats(days=0),
  load_oracle_context() if pass1_output["needs_oracle"] else None
)
```

---

### **Pass 2: Response Generation** (Dynamic Context)

**Purpose**: Generate final response with only relevant data

**Context Structure** (~2,000-3,000 tokens):
```markdown
# RESPONSE GENERATION

## Persona Core (20 lines)
- Name: I-There 4.2
- Identity: Mirror Realm reflection
- Style: Casual, curious, lowercase
- Critical Rules:
  * NEVER use brackets or internal thoughts
  * ALWAYS use fetched data (don't approximate)
  * Maintain conversation continuity
  * Avoid repetition

## User Message
{user_message}

## Pass 1 Analysis
Reasoning: {pass1_reasoning}
Response Type: {response_type}

## Fetched Data
### Current Time
{time_data}

### Activity Data
{activity_data}

### Oracle Context (if needed)
{oracle_context_minimal}

## Recent Conversation (5 messages)
{last_5_messages}

## Response Guidelines
- Maintain persona voice
- Use fetched data (don't approximate)
- Build on conversation context
- Avoid repetition from history

## Self-Review Checklist
Before finalizing, verify:
1. ✓ Answers user's question
2. ✓ Consistent with persona
3. ✓ Uses fetched data correctly
4. ✓ No repetition from history
5. ✓ Appropriate tone

Generate your response.
```

**Output**: Final response to user

---

## 💡 Key Benefits

### **1. Massive Token Reduction**

| Metric | Current | Two-Pass | Reduction |
|--------|---------|----------|-----------|
| Pass 1 Tokens | - | 500-1,000 | - |
| Pass 2 Tokens | - | 2,000-3,000 | - |
| Total Tokens | 13,008 | 2,500-4,000 | 69-81% |
| Cost/Message | $0.039 | $0.008-0.012 | 69-81% |
| Cost/10K | $390 | $75-120 | $270-315 savings |

### **2. Intelligent Data Loading**

**Current Approach**: Load everything "just in case"
- Full Oracle framework (400 lines) in every message
- Complete MCP catalog (100 lines) always present
- All persona details (150 lines) regardless of need

**Two-Pass Approach**: Load only what's needed
- Oracle framework: Only if activities detected (30% of messages)
- MCP functions: Only descriptions for called functions
- Persona details: Minimal core + relevant sections

**Example Savings**:
```
Simple greeting: "opa, tudo certo?"
- Current: 13,008 tokens (full context)
- Two-Pass: 1,500 tokens (minimal context, no data fetch)
- Savings: 88%

Data query: "o que eu fiz hoje?"
- Current: 13,008 tokens (full context)
- Two-Pass: 3,500 tokens (minimal + activity data)
- Savings: 73%

Coaching session: "quero melhorar meu sono"
- Current: 13,008 tokens (full context)
- Two-Pass: 5,000 tokens (minimal + Oracle + coaching)
- Savings: 62%
```

### **3. Better AI Focus**

**Pass 1**: Pure decision-making
- No noise from unused context
- Clear task: analyze and decide
- Faster, more accurate decisions

**Pass 2**: Focused execution
- Only relevant data present
- Clear task: respond using provided data
- Better quality responses

### **4. Scalability**

**Current**: Linear growth
- Add new persona → +150 lines to every message
- Add new feature → +50-100 lines to every message
- Add new MCP function → +10-20 lines to every message

**Two-Pass**: Sub-linear growth
- Add new persona → +20 lines to Pass 1, +150 lines only when needed
- Add new feature → +5-10 lines to Pass 1, full context only when used
- Add new MCP function → +1 line to Pass 1, details only when called

---

## ⚠️ Challenges & Mitigations

### **Challenge 1: Latency (2x Increase)**

**Problem**: Two API calls = 2x latency

**Current**:
```
User message → API call → Response
Total: ~2-3 seconds
```

**Two-Pass**:
```
User message → Pass 1 API → MCP calls → Pass 2 API → Response
Total: ~4-6 seconds
```

**Mitigations**:
1. **Parallel MCP Execution**: Execute multiple MCP calls simultaneously
2. **MCP Caching**: Cache frequently accessed data (current time, user profile)
3. **Streaming Pass 2**: Start streaming response as soon as first tokens arrive
4. **Optimized MCP**: Ensure MCP calls are <100ms each
5. **Smart Batching**: Combine related MCP calls when possible

**Estimated Latency**:
- Pass 1: 800ms (smaller context = faster)
- MCP Fetch: 200ms (parallel execution)
- Pass 2: 1,200ms (focused context = faster)
- **Total**: ~2.2 seconds (comparable to current!)

**Verdict**: ✅ **Acceptable** with optimizations

---

### **Challenge 2: Pass 1 Decision Quality**

**Problem**: Can the model make good decisions with minimal context?

**Test Scenarios**:

#### **Scenario A: Simple Greeting** ✅
```
User: "opa, tudo certo?"
Pass 1 Decision: 
- Reasoning: "Simple greeting, conversational response"
- MCP calls: []
- Response type: "conversational"
Result: ✅ Perfect - no data needed
```

#### **Scenario B: Data Query** ✅
```
User: "o que eu fiz hoje?"
Pass 1 Decision:
- Reasoning: "User asking about today's activities"
- MCP calls: [get_current_time, get_activity_stats(days=0)]
- Response type: "data_informed"
Result: ✅ Perfect - clear data need
```

#### **Scenario C: Temporal Query** ✅
```
User: "resumo da semana"
Pass 1 Decision:
- Reasoning: "User wants weekly summary"
- MCP calls: [get_activity_stats(days=7)]
- Response type: "data_informed"
Result: ✅ Perfect - clear timeframe
```

#### **Scenario D: Ambiguous Reference** ⚠️
```
User: "e sobre aquilo que conversamos?"
Pass 1 Decision:
- Reasoning: "User referencing past conversation, unclear topic"
- MCP calls: [get_conversation_context(hours=24)]
- Response type: "conversational"
Result: ⚠️ May need more context to identify specific topic
```

**Mitigation for Ambiguous Cases**:
1. Include last 2-3 messages in Pass 1 (adds ~200 tokens)
2. Use conservative data fetching (fetch more rather than less)
3. Pass 2 can acknowledge if more context is needed

**Verdict**: ✅ **Works for 90%+ of cases**, acceptable for rest

---

### **Challenge 3: Oracle Framework Integration**

**Problem**: Oracle has 265+ activities and complex detection logic

**Current Approach**:
- Full Oracle framework (400 lines) in every message
- Always present, even when not needed
- 70% of messages don't involve activities

**Two-Pass Solution**:

**Pass 1**: Minimal Oracle trigger
```markdown
## Oracle Activity Detection
If user message mentions:
- Physical activities (exercise, sleep, water, food)
- Mental activities (meditation, reading, learning)
- Work activities (pomodoro, focus, tasks)
- Relationships (family, friends, communication)
- Spirituality (gratitude, prayer, reflection)

Then: needs_oracle = true
```

**Pass 2** (only if needs_oracle = true):
```markdown
## Oracle 4.2 Framework
- 8 Dimensions: R, SF, TG, SM, E, TT, PR, F
- 265+ Activities
- Theoretical Foundations (condensed)
- Detection Rules
```

**Estimated Savings**:
- 70% of messages: Skip 400 lines = 280 lines average savings
- 30% of messages: Include 200 lines (condensed) = 60 lines average cost
- **Net savings**: 220 lines average (24% of total prompt)

**Verdict**: ✅ **Huge win** - Oracle only when needed

---

### **Challenge 4: Persona Identity Consistency**

**Problem**: Persona needs consistent voice across both passes

**Solution**: Minimal Persona Core (20 lines)

**Pass 1 Core**:
```markdown
## Persona: I-There 4.2
- Identity: Mirror Realm reflection, life coach
- Style: Casual, curious, lowercase "i"
- Role: Learn about user, provide insights
- Critical: No brackets, no internal thoughts
```

**Pass 2 Core** (same + relevant additions):
```markdown
## Persona: I-There 4.2
- Identity: Mirror Realm reflection, life coach
- Style: Casual, curious, lowercase "i"
- Role: Learn about user, provide insights
- Critical: No brackets, no internal thoughts

[If coaching needed]
- Coaching Approach: Tiny Habits, Behavioral Design
- Focus: Sustainable change, micro-habits

[If Oracle needed]
- Oracle Framework: 8 dimensions, 265+ activities
- Detection: Only from current message
```

**Verdict**: ✅ **Maintains consistency** with dynamic loading

---

### **Challenge 5: Self-Review Implementation**

**Problem**: How to ensure quality in Pass 2?

**Option A: Explicit Review Prompt** (Simpler)
```markdown
## Self-Review Checklist
Before finalizing your response, review:
1. Does it answer the user's question?
2. Is it consistent with previous messages?
3. Does it avoid repetition?
4. Is the tone appropriate?
5. Does it use fetched data correctly?

If any issues, revise your response.
```

**Option B: Structured Output** (More Reliable)
```json
{
  "draft_response": "...",
  "review": {
    "answers_question": true,
    "consistent": true,
    "no_repetition": true,
    "tone_appropriate": true,
    "uses_data": true
  },
  "revisions_needed": false,
  "final_response": "..."
}
```

**Recommendation**: Start with **Option A** (simpler), upgrade to **Option B** if quality issues arise

**Verdict**: ✅ **Option A sufficient** for MVP

---

## 🚀 Hybrid Approach: Best of Both Worlds

### **Smart Conditional Two-Pass**

Instead of always using two passes, intelligently decide based on message type:

```python
def process_message(user_message, persona):
    # Quick classification (local, no API call)
    message_type = classify_message_locally(user_message)
    
    if message_type == "simple_conversational":
        # Single pass with minimal context
        # Examples: "opa", "valeu", "bom dia"
        return single_pass_response(
            user_message, 
            context_size="minimal"  # ~1,000 tokens
        )
    
    elif message_type == "data_query":
        # Two-pass with data fetching
        # Examples: "o que fiz hoje?", "resumo da semana"
        pass1 = decision_engine(user_message)
        data = fetch_mcp_data(pass1.mcp_calls)
        return response_generation(
            user_message, 
            data,
            context_size="focused"  # ~3,000 tokens
        )
    
    elif message_type == "coaching_session":
        # Two-pass with full Oracle context
        # Examples: "quero melhorar meu sono", "me ajuda com..."
        pass1 = decision_engine(user_message)
        data = fetch_mcp_data(pass1.mcp_calls)
        oracle_context = load_oracle_framework()
        return response_generation(
            user_message, 
            data, 
            oracle_context,
            context_size="full"  # ~5,000 tokens
        )
```

### **Message Classification** (Local, No API)

```python
def classify_message_locally(message: str) -> str:
    """
    Classify message type using simple pattern matching.
    No API call needed - fast and cheap.
    """
    message_lower = message.lower()
    
    # Simple conversational
    simple_patterns = [
        r'^(opa|oi|olá|hey|hi)\b',
        r'^(valeu|obrigado|thanks)\b',
        r'^(bom dia|boa tarde|boa noite)\b',
        r'^(tudo certo|tudo bem|beleza)\b',
    ]
    if any(re.match(p, message_lower) for p in simple_patterns):
        return "simple_conversational"
    
    # Data query
    data_patterns = [
        r'\b(o que|what).*(fiz|fez|did)\b',
        r'\b(quantas|quantos|how many)\b',
        r'\b(resumo|summary)\b',
        r'\b(semana|week|mês|month)\b',
    ]
    if any(re.search(p, message_lower) for p in data_patterns):
        return "data_query"
    
    # Coaching (default for longer messages)
    if len(message.split()) > 5:
        return "coaching_session"
    
    # Default to conversational
    return "simple_conversational"
```

### **Estimated Token Distribution**

Assuming message type distribution:
- **40% Simple Conversational**: 1,000 tokens avg
- **40% Data Queries**: 3,000 tokens avg
- **20% Coaching Sessions**: 5,000 tokens avg

**Average Tokens per Message**:
```
(0.40 × 1,000) + (0.40 × 3,000) + (0.20 × 5,000) = 2,600 tokens
```

**Compared to Current**: 13,008 tokens  
**Reduction**: **80%**  
**Cost Savings**: **$312 per 10K messages**

---

## 📊 Comprehensive Comparison

### **Token Usage**

| Scenario | Current | Scenario B | Two-Pass | Hybrid |
|----------|---------|------------|----------|--------|
| **Simple Message** | 13,008 | 6,900 | 2,500 | 1,000 |
| **Data Query** | 13,008 | 6,900 | 3,500 | 3,000 |
| **Coaching** | 13,008 | 6,900 | 5,000 | 5,000 |
| **Average** | 13,008 | 6,900 | 3,500 | 2,600 |
| **Reduction** | - | 47% | 73% | 80% |

### **Cost Analysis**

| Metric | Current | Scenario B | Two-Pass | Hybrid |
|--------|---------|------------|----------|--------|
| **Per Message** | $0.039 | $0.021 | $0.011 | $0.008 |
| **Per 10K** | $390 | $207 | $105 | $78 |
| **Savings** | - | $183 (47%) | $285 (73%) | $312 (80%) |

### **Latency**

| Metric | Current | Scenario B | Two-Pass | Hybrid |
|--------|---------|------------|----------|--------|
| **Simple Message** | 2-3s | 2-3s | 2-3s | 1-2s |
| **Data Query** | 2-3s | 2-3s | 4-6s | 3-4s |
| **Coaching** | 2-3s | 2-3s | 4-6s | 4-5s |
| **Average** | 2-3s | 2-3s | 3-4s | 2.5-3.5s |

### **Complexity**

| Aspect | Current | Scenario B | Two-Pass | Hybrid |
|--------|---------|------------|----------|--------|
| **Implementation** | Low | Low | High | High |
| **Maintenance** | Medium | Medium | High | High |
| **Testing** | Simple | Simple | Complex | Complex |
| **Debugging** | Easy | Easy | Moderate | Moderate |

---

## 🎯 Implementation Roadmap

### **Option 1: Incremental Approach** ⭐ RECOMMENDED

#### **Phase 1: Scenario B** (4-6 hours)
- Implement 47% reduction via prompt optimization
- Validate AI quality maintained
- Get immediate $183/10K savings
- **Deliverable**: Optimized single-pass system

#### **Phase 2: Simple Two-Pass for Data Queries** (6-8 hours)
- Implement two-pass only for data queries (40% of messages)
- Keep single-pass for conversational messages
- Validate latency acceptable
- **Deliverable**: Hybrid system with selective two-pass

#### **Phase 3: Full Hybrid System** (6-8 hours)
- Add coaching session two-pass
- Implement local message classification
- Optimize MCP execution
- **Deliverable**: Complete hybrid system (80% reduction)

**Total Effort**: 16-22 hours  
**Total Savings**: $312 per 10K messages (80%)  
**Risk**: Low (incremental validation)

---

### **Option 2: Direct to Hybrid** (Higher Risk)

#### **Phase 1: Build Decision Engine** (8-10 hours)
- Design Pass 1 prompt structure
- Implement JSON output parsing
- Test decision quality

#### **Phase 2: Implement Two-Pass Flow** (8-10 hours)
- Build data fetch orchestration
- Design Pass 2 prompt structure
- Implement response generation

#### **Phase 3: Add Message Classification** (4-6 hours)
- Build local classifier
- Implement conditional routing
- Optimize performance

**Total Effort**: 20-26 hours  
**Total Savings**: $312 per 10K messages (80%)  
**Risk**: Medium (big architectural change)

---

## 💭 Assessment & Recommendation

### **The Two-Pass Architecture is EXCELLENT Because**:

✅ **Massive Cost Savings**: 80% reduction ($312/10K messages)  
✅ **Better AI Focus**: Only relevant context in each pass  
✅ **Scalability**: Sub-linear growth as features added  
✅ **Intelligent Loading**: Oracle/coaching only when needed  
✅ **Future-Proof**: Architecture supports growth

### **But It Requires**:

⚠️ **Higher Complexity**: Two passes to maintain and debug  
⚠️ **More Development Time**: 20-26 hours vs 4-6 hours  
⚠️ **Latency Trade-off**: 2x API calls (mitigated with hybrid)  
⚠️ **More Testing**: Both passes need validation

---

## 🎯 Final Recommendation

### **For Immediate Value**: Start with **Scenario B** (Incremental Approach)
- **4-6 hours** to 47% reduction
- **$183/10K savings** immediately
- **Low risk**, proven approach
- **Then evaluate** if two-pass is worth additional effort

### **For Long-Term Optimization**: Go with **Hybrid Two-Pass** (Incremental)
- **16-22 hours** to 80% reduction
- **$312/10K savings** (70% more than Scenario B)
- **Incremental validation** reduces risk
- **Best architecture** for future growth

### **My Personal Recommendation**: **Incremental Approach (Option 1)**

**Rationale**:
1. Get **47% savings in 4-6 hours** (quick win)
2. Validate AI quality maintained
3. Gather real usage data
4. **Then decide** if additional 33% savings worth 12-16 more hours
5. Lower risk, faster time to value

---

## 📝 Next Steps

### **If Choosing Incremental Approach**:
1. ✅ Implement Scenario B (47% reduction)
2. ✅ Deploy and monitor for 1-2 weeks
3. ✅ Analyze real usage patterns
4. ✅ Decide on two-pass based on data

### **If Choosing Direct Hybrid**:
1. ✅ Design Pass 1 prompt structure
2. ✅ Build decision engine
3. ✅ Implement data fetch orchestration
4. ✅ Design Pass 2 prompt structure
5. ✅ Add message classification
6. ✅ Test and validate

---

## ❓ Decision Questions

1. **Is 2x latency acceptable** for 80% cost savings?
   - Mitigated to ~1.5x with optimizations
   - Hybrid approach keeps simple messages fast

2. **Immediate value or maximum optimization**?
   - Scenario B: 4-6 hours, 47% savings
   - Hybrid: 16-22 hours, 80% savings

3. **Comfortable with higher complexity**?
   - Two-pass requires more maintenance
   - But better architecture long-term

4. **Priority**: Cost, latency, or simplicity?
   - Cost → Hybrid Two-Pass
   - Latency → Scenario B
   - Simplicity → Scenario B

---

**Analysis Complete** ✅

**Recommendation**: Start with Scenario B, then evaluate two-pass based on real data.

