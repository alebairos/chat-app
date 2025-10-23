# FT-210 Quick Test Script

**5-Minute Test to Verify Bug Fix**

---

## The Bug (Before Fix)

**Problem:** AI repeats the same question multiple times, ignoring user's answer

**Example:**
```
User: quarta
AI: Qual seria o dia mais tranquilo?

User: já respondi
AI: Qual seria o dia mais tranquilo? [REPEAT]
```

---

## Quick Test Script

### Test 1: Tony Life Coach (Most Critical)

**Run this exact conversation:**

```
1. You: @tony fala

2. You: tudo

3. You: dormir mais cedo

4. You: durmo tarde, por causa do trabalho. preciso acordar cedo pelo menos 1 dia durante a semana pra ir pra academia cedo

5. You: quarta

🚨 CRITICAL CHECKPOINT:
   ✅ If Tony says: "Perfeito! Quarta-feira..." or similar plan
      → BUG IS FIXED ✅
   
   ❌ If Tony repeats: "Qual seria o dia mais tranquilo?"
      → BUG STILL PRESENT ❌

6. You: já respondi

🚨 SECOND CHECKPOINT:
   ✅ If Tony acknowledges and continues
      → BUG IS FIXED ✅
   
   ❌ If Tony repeats the question AGAIN
      → BUG STILL PRESENT ❌
```

---

## Test 2: Activity Tracking (Quick)

**Run this exact conversation:**

```
1. You: marca que bebi água

2. You: sim, acabei de beber

🚨 CHECKPOINT:
   ✅ If AI acknowledges naturally without repeating
      → BUG IS FIXED ✅
   
   ❌ If AI repeats: "Vou registrar isso" or similar
      → BUG STILL PRESENT ❌
```

---

## Expected Results

### ✅ Bug Fixed (What You Should See)

**Message 5 (after "quarta"):**
```
Tony: Perfeito! Quarta-feira é um ótimo dia para começar. 
Vamos planejar sua rotina...
```

**Message 6 (after "já respondi"):**
```
Tony: Desculpe! Vamos continuar com o plano...
```

### ❌ Bug Still Present (What You Should NOT See)

**Message 5 (after "quarta"):**
```
Tony: Entendo. O desafio é equilibrar trabalho noturno com exercício matinal. 
Qual seria o dia mais tranquilo da sua semana para começar acordando mais cedo?
```

**Message 6 (after "já respondi"):**
```
Tony: Entendo. O desafio é equilibrar trabalho noturno com exercício matinal. 
Qual seria o dia mais tranquilo da sua semana para começar acordando mais cedo?
[EXACT SAME REPEAT]
```

---

## How to Run the Test

### Option 1: In Simulator/Emulator

```bash
# Start the app
flutter run

# Follow the test script above
# Type each message exactly as shown
# Observe Tony's responses
```

### Option 2: On Physical Device

```bash
# Deploy to device
flutter run -d <device-id>

# Follow the test script above
# Type each message exactly as shown
# Observe Tony's responses
```

---

## Recording Results

### If Bug is Fixed ✅

**Document:**
- [x] Test 1 passed (Tony responded correctly to "quarta")
- [x] Test 2 passed (Activity tracking worked smoothly)
- [x] No repeated responses observed
- [x] Conversation flowed naturally

**Action:** Approve for merge ✅

### If Bug Still Present ❌

**Document:**
- [ ] Which message triggered the repeat
- [ ] Exact text of repeated response
- [ ] Screenshot or screen recording
- [ ] Export conversation using chat export feature

**Action:** Report to development team ❌

---

## Alternative Quick Tests

### Test A: Different Persona (Ari)

```
You: @ari oi
You: quero melhorar minha produtividade
You: me distraio com redes sociais
You: Instagram principalmente
You: o que você sugere?

✅ Ari should provide suggestions (not repeat question)
```

### Test B: Sergeant Oracle

```
You: @sergeant opa
You: marca que fiz 10 flexões
You: e 20 polichinelos
You: o que eu fiz hoje?

✅ Sergeant should list both activities (no duplicates)
```

---

## Troubleshooting

### If You're Unsure

**Question:** Is this a repeat or just similar?

**Check:**
1. Is the text **word-for-word identical**?
   - If YES → It's a repeat (bug present)
   - If NO → It's just similar (probably OK)

2. Does the AI **ignore your previous answer**?
   - If YES → Bug present
   - If NO → Probably OK

3. Does it happen **multiple times** in one conversation?
   - If YES → Bug present
   - If NO → Might be coincidence

### Still Unsure?

Run the full test from `ft_210_manual_testing_guide.md`

---

## Quick Reference

| Symptom | Bug Status |
|---------|------------|
| AI repeats exact same question after you answered | ❌ Bug present |
| AI ignores your answer and asks again | ❌ Bug present |
| AI says something similar but different | ✅ Probably OK |
| AI acknowledges your answer and continues | ✅ Bug fixed |
| Conversation flows naturally | ✅ Bug fixed |

---

## Time Required

- **Quick Test:** 5 minutes
- **Full Test:** 30 minutes
- **Stress Test:** 15-20 minutes

**Recommendation:** Start with Quick Test, run Full Test if you have time

---

## Contact

**Questions?** Reference FT-210 documentation:
- `ft_210_manual_testing_guide.md` (detailed guide)
- `ft_210_fix_duplicate_conversation_history_bug.md` (bug specification)
- `ft_210_fix_duplicate_conversation_history_impl_summary.md` (implementation)

