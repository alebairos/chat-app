# FT-210 Manual Testing Guide

**Feature:** Fix Duplicate Conversation History Bug  
**Branch:** `fix/ft-210-duplicate-conversation-history`  
**Testing Date:** October 22, 2025

---

## Testing Objective

Verify that AI personas:
1. ✅ Respond appropriately to each user message (no repeats)
2. ✅ Understand context from previous messages
3. ✅ Don't get confused by sequential questions
4. ✅ Handle activity tracking commands correctly

---

## Pre-Testing Setup

### 1. Deploy the Fix
```bash
# Make sure you're on the fix branch
git checkout fix/ft-210-duplicate-conversation-history

# Run the app
flutter run
```

### 2. Choose a Persona to Test
Recommended order:
1. **Tony** (Life Coach) - Simple, direct responses
2. **Ari** (Life Coach) - More conversational
3. **Aristios** (Philosopher) - Complex responses
4. **Sergeant Oracle** (Activity tracking) - MCP commands

---

## Test Scenario 1: Sequential Question-Answer Flow

**Persona:** Tony Life Coach  
**Objective:** Verify no repeated questions  
**Expected Behavior:** Each response should be unique and relevant

### Conversation Script

```
You: @tony fala
Expected: Tony greets and asks opening question
✅ PASS / ❌ FAIL: ___________

You: tudo
Expected: Tony acknowledges and asks specific area to improve
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________

You: dormir mais cedo
Expected: Tony asks about current sleep routine
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________

You: durmo tarde, por causa do trabalho. preciso acordar cedo pelo menos 1 dia durante a semana pra ir pra academia cedo
Expected: Tony asks which day would be easiest
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________

You: quarta
Expected: Tony responds with plan for Wednesday (NOT repeating previous question)
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________

🚨 CRITICAL CHECK: Did Tony repeat the question about which day?
If YES → Bug still present
If NO → Bug fixed! ✅

You: já respondi
Expected: Tony acknowledges and continues conversation (NOT repeating again)
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________
```

### What to Look For

**✅ GOOD (Bug Fixed):**
- Each response is unique
- Tony acknowledges "quarta" and provides specific advice
- Tony understands "já respondi" and moves forward

**❌ BAD (Bug Still Present):**
- Tony repeats: "Qual seria o dia mais tranquilo?"
- Tony ignores "quarta" and asks again
- Tony doesn't understand "já respondi"

---

## Test Scenario 2: Activity Tracking with MCP Commands

**Persona:** Sergeant Oracle or Ari  
**Objective:** Verify activity tracking doesn't cause duplicates  
**Expected Behavior:** Smooth confirmation without confusion

### Conversation Script

```
You: opa
Expected: Persona greets warmly
✅ PASS / ❌ FAIL: ___________

You: marca que bebi 500ml de água
Expected: Persona confirms water logged, possibly asks follow-up
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________

You: sim, acabei de beber agora
Expected: Persona acknowledges naturally (NOT repeating confirmation)
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________

You: o que eu fiz hoje?
Expected: Persona lists activities including the water
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________

You: marca que fiz 10 flexões
Expected: Persona confirms exercise logged
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________

You: e agora?
Expected: Persona responds contextually (NOT repeating previous question)
✅ PASS / ❌ FAIL: ___________
Notes: _________________________________
```

### What to Look For

**✅ GOOD (Bug Fixed):**
- Each activity confirmation is unique
- Persona understands follow-up responses
- No repeated confirmations

**❌ BAD (Bug Still Present):**
- Persona repeats: "Vou registrar isso"
- Persona asks same question twice
- Persona seems confused by follow-ups

---

## Test Scenario 3: Multi-Turn Conversation (Extended)

**Persona:** Ari or Aristios  
**Objective:** Verify conversation maintains context over many turns  
**Expected Behavior:** Natural, flowing conversation

### Conversation Script

```
You: opa! bom dia
Expected: Warm greeting
✅ PASS / ❌ FAIL: ___________

You: como está seu dia?
Expected: Persona responds and asks about you
✅ PASS / ❌ FAIL: ___________

You: tudo bem. quero melhorar minha produtividade
Expected: Persona asks about current productivity challenges
✅ PASS / ❌ FAIL: ___________

You: me distraio muito com redes sociais
Expected: Persona acknowledges and explores the issue
✅ PASS / ❌ FAIL: ___________

You: especialmente Instagram e Twitter
Expected: Persona responds specifically to these platforms
✅ PASS / ❌ FAIL: ___________

You: o que você sugere?
Expected: Persona provides specific suggestions (NOT repeating previous question)
✅ PASS / ❌ FAIL: ___________

You: gostei da primeira sugestão
Expected: Persona acknowledges which suggestion and elaborates
✅ PASS / ❌ FAIL: ___________

You: como implemento isso?
Expected: Persona provides implementation steps (NOT repeating)
✅ PASS / ❌ FAIL: ___________
```

### What to Look For

**✅ GOOD (Bug Fixed):**
- Persona remembers: social media, Instagram, Twitter
- Responses build on previous context
- No repeated questions or suggestions
- Natural conversation flow

**❌ BAD (Bug Still Present):**
- Persona asks same question multiple times
- Persona doesn't remember previous context
- Responses feel disconnected

---

## Test Scenario 4: Edge Case - Rapid Sequential Messages

**Persona:** Any  
**Objective:** Verify fix works with quick back-to-back messages  
**Expected Behavior:** Each message processed correctly

### Conversation Script

```
You: oi
[Wait for response]
Expected: Greeting
✅ PASS / ❌ FAIL: ___________

You: tudo bem?
[Wait for response]
Expected: Response to "tudo bem"
✅ PASS / ❌ FAIL: ___________

You: e você?
[Wait for response]
Expected: Response about persona's state (NOT repeating previous)
✅ PASS / ❌ FAIL: ___________

You: legal
[Wait for response]
Expected: Acknowledgment and continuation (NOT repeating)
✅ PASS / ❌ FAIL: ___________
```

### What to Look For

**✅ GOOD (Bug Fixed):**
- Each response is unique
- Persona tracks conversation flow
- No confusion with quick messages

**❌ BAD (Bug Still Present):**
- Persona repeats responses
- Persona loses track of conversation

---

## Test Scenario 5: Persona Switching

**Personas:** Multiple  
**Objective:** Verify fix works across persona switches  
**Expected Behavior:** Clean conversation with each persona

### Conversation Script

```
You: @tony oi
Expected: Tony greets
✅ PASS / ❌ FAIL: ___________

You: quero melhorar meu sono
Expected: Tony asks about sleep
✅ PASS / ❌ FAIL: ___________

You: @ari oi
Expected: Ari greets (different from Tony)
✅ PASS / ❌ FAIL: ___________

You: também quero melhorar meu sono
Expected: Ari asks about sleep (NOT repeating Tony's question)
✅ PASS / ❌ FAIL: ___________

You: @tony voltei
Expected: Tony continues previous conversation context
✅ PASS / ❌ FAIL: ___________
```

### What to Look For

**✅ GOOD (Bug Fixed):**
- Each persona has unique voice
- No cross-contamination of responses
- Context maintained per persona

**❌ BAD (Bug Still Present):**
- Personas repeat each other's questions
- Confusion about conversation context

---

## Test Scenario 6: Stress Test - Long Conversation

**Persona:** Any  
**Objective:** Verify fix holds up over extended conversation  
**Duration:** 15-20 message exchanges

### Conversation Guidelines

Have a natural conversation about any topic for 15-20 exchanges. Focus on:

1. **Variety:** Ask different types of questions
2. **Follow-ups:** Respond to persona's questions
3. **Context:** Reference previous messages
4. **Interruptions:** Change topics mid-conversation

### Success Criteria

After 15-20 exchanges, the persona should:
- ✅ Still respond uniquely to each message
- ✅ Remember conversation context
- ✅ Not repeat any questions or responses
- ✅ Maintain coherent conversation flow

**Overall Result:**
✅ PASS / ❌ FAIL: ___________

**Notes:**
_________________________________
_________________________________
_________________________________

---

## Debugging Tips

### If You See Repeated Responses

1. **Check the exact text:**
   - Is it word-for-word identical?
   - Or just similar in meaning?

2. **Note when it happens:**
   - After which message number?
   - With which persona?
   - What type of message triggered it?

3. **Check logs:**
   ```bash
   # In terminal where app is running
   # Look for: "FT-210" in logs
   # Check _conversationHistory length
   ```

4. **Export conversation:**
   - Use chat export feature
   - Share with developer for analysis

### If Persona Seems Confused

1. **Check if it's the duplicate bug:**
   - Does persona ignore your last message?
   - Does persona ask the same question twice?

2. **Or is it a different issue:**
   - Persona gives wrong information?
   - Persona doesn't understand command?
   - Persona loses context after many turns?

---

## Test Results Summary

### Overall Assessment

**Date Tested:** ___________  
**Tester:** ___________  
**Device:** ___________  
**Flutter Version:** ___________

### Scenario Results

| Scenario | Status | Notes |
|----------|--------|-------|
| 1. Sequential Q&A | ✅ / ❌ | |
| 2. Activity Tracking | ✅ / ❌ | |
| 3. Multi-Turn | ✅ / ❌ | |
| 4. Rapid Messages | ✅ / ❌ | |
| 5. Persona Switching | ✅ / ❌ | |
| 6. Stress Test | ✅ / ❌ | |

### Critical Bug Check

**Did you observe ANY of these issues?**
- [ ] AI repeated the same response word-for-word
- [ ] AI ignored user's answer and asked again
- [ ] AI seemed confused by follow-up messages
- [ ] AI lost context after a few exchanges

**If you checked ANY box above:** Bug may still be present - investigate further

**If you checked NO boxes:** Bug appears to be fixed! ✅

### Additional Observations

**Positive findings:**
_________________________________
_________________________________
_________________________________

**Issues found:**
_________________________________
_________________________________
_________________________________

**Suggestions:**
_________________________________
_________________________________
_________________________________

---

## Quick Test (5 Minutes)

If you're short on time, run this quick test:

```
1. Open app
2. Say: "@tony fala"
3. Say: "tudo"
4. Say: "dormir mais cedo"
5. Say: "durmo tarde"
6. Say: "quarta"
7. Say: "já respondi"

✅ If Tony provides plan for Wednesday at step 6 → BUG FIXED
❌ If Tony repeats "Qual seria o dia?" at step 6 → BUG STILL PRESENT
```

---

## Reporting Results

### If Bug is Fixed ✅

Great! Document:
1. Which scenarios you tested
2. Any edge cases you found
3. Overall conversation quality

### If Bug Still Present ❌

Please provide:
1. **Exact conversation:** Copy/paste the messages
2. **Which persona:** Name of persona tested
3. **When it happened:** After which message
4. **Screenshots:** If possible
5. **Logs:** Check terminal output

**Report to:** Development team with FT-210 reference

---

## Next Steps After Testing

### If All Tests Pass ✅

1. Document results in this file
2. Commit results to branch
3. Approve pull request
4. Merge to develop
5. Deploy to production
6. Monitor user feedback

### If Any Tests Fail ❌

1. Document failure details
2. Export problematic conversation
3. Share with development team
4. Do NOT merge to develop
5. Wait for additional fix

---

## Notes Section

Use this space for any additional observations:

_________________________________
_________________________________
_________________________________
_________________________________
_________________________________
_________________________________
_________________________________
_________________________________
_________________________________
_________________________________

