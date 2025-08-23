# FT-061 Activity Memory Testing Guide

## Quick Testing Steps

### 1. Launch App & Switch to Oracle Persona
- Open the app in iOS simulator
- **Switch to "Ari 2.1"** (Oracle-compatible persona)
- Watch logs for Oracle parsing messages

### 2. Check Oracle Parsing (Fixed T→TG Mapping)
**Look for in logs:**
```
✅ GOOD: "Successfully parsed Oracle: X dimensions, Y total activities"
❌ BAD: "Could not find dimension for activity code: T1, T8, etc."
```

### 3. Test Activity Detection with Enhanced Prompts
**Send these test messages:**

**Test 1 - Single Activity:**
```
"Acabei de beber água"
```
**Expected:** 
- Log: `extract_activities` MCP call
- Log: Activity detection processing
- AI response celebrating SF1 completion

**Test 2 - Multiple Activities:**
```
"Fiz 2 pomodoros e bebi água"
```
**Expected:**
- Log: `extract_activities` MCP call  
- Log: Detection of T8 (pomodoros) and SF1 (água)
- AI response celebrating both activities

**Test 3 - Oracle Framework Activities:**
```
"Acabei de fazer minha rotina da manhã e meditar"
```
**Expected:**
- Log: `extract_activities` MCP call
- Log: Detection of T1 (rotina manhã) and SM1 (meditar)
- AI response using Oracle terminology

### 4. Verify Database Storage
- Open Isar Inspector: `https://inspect.isar.dev/3.1.0+1/#/...` (from logs)
- Check `ActivityModel` collection
- Verify activities are stored with correct:
  - Activity codes (T1, SF1, SM1, etc.)
  - Timestamps
  - Dimensions (TG, SF, SM, etc.)

## What Each Fix Should Do

### Oracle Parsing Fix (T→TG Mapping)
- **Before:** Hundreds of warnings "Could not find dimension for T1, T8"
- **After:** Clean parsing "Successfully parsed Oracle: 5 dimensions, X activities"

### Enhanced Persona Prompts
- **Before:** AI claims to register but doesn't call function
- **After:** AI consistently calls `extract_activities` when activities mentioned

### Expected Log Flow
```
1. Oracle parsing: "Successfully parsed Oracle: 5 dimensions, X activities"
2. User message: "Acabei de beber água"
3. AI calls: extract_activities MCP function
4. Activity detection: "Detected 1 activity: SF1 - Beber água"
5. Database storage: "Logged 1 activity to database"
6. AI response: Celebrates the completion
```

## Troubleshooting

**If Oracle parsing still fails:**
- Check if persona switched to "Ari 2.1"
- Look for file loading errors in logs

**If AI doesn't call extract_activities:**
- Verify persona prompt was updated
- Try more explicit messages like "Please register that I completed SF1"

**If activities aren't stored:**
- Check Isar schema updates
- Verify ActivityMemoryService initialization

## Success Criteria

✅ **Oracle Parsing:** Clean logs, no dimension warnings
✅ **AI Behavior:** Consistent MCP calls for activity mentions  
✅ **Database Storage:** Activities visible in Isar Inspector
✅ **User Experience:** AI celebrates and tracks progress appropriately
