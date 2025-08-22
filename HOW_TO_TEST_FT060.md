# How to Test FT-060: Enhanced Time Awareness

## 🚀 **Quick Testing Guide**

### **Method 1: App Testing (Easiest)**

1. **Launch the app:**
   ```bash
   flutter run
   ```

2. **Test Short Gaps (Should NOT show enhanced context):**
   - Send a message
   - Wait 10-15 minutes
   - Send another message
   - **Expected:** Basic context like "Current context: It is Thursday afternoon."

3. **Test Long Gaps (Should show enhanced context):**
   - Send a message
   - Close the app and wait 6+ hours (or continue to Method 2 for artificial testing)
   - Reopen app and send another message
   - **Expected:** Enhanced context like "Note: Conversation resuming later today (6 hours and 23 minutes ago). Current context: It is Thursday at 2:47 PM."

### **Method 2: Database Time Manipulation (Advanced)**

You can artificially create time gaps by modifying the database:

1. **Install database browser:**
   ```bash
   # For Android
   flutter run
   # Navigate to app data and find the Isar database file
   
   # For iOS Simulator
   # Database is in ~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/
   ```

2. **Modify last message timestamp:**
   - Find the most recent message in the database
   - Change its timestamp to 6+ hours ago
   - Restart the app and send a new message

### **Method 3: Direct Context Testing**

Test the time context service directly through debug console:

```dart
// In your app, add this to any widget's onPressed:
final lastMessage = DateTime.now().subtract(Duration(hours: 6));
final basicContext = TimeContextService.generateTimeContext(lastMessage);
final enhancedContext = TimeContextService.generatePreciseTimeContext(lastMessage);

print('Basic: $basicContext');
print('Enhanced: $enhancedContext');
```

### **Method 4: Manual Testing Scenarios**

#### **Scenario A: 6-Hour Gap**
- **Before:** "Note: Conversation resuming later today."
- **After FT-060:** "Note: Conversation resuming later today (6 hours and 15 minutes ago). Current context: It is Thursday at 8:30 PM."

#### **Scenario B: Yesterday (24+ hours)**
- **Before:** "Note: Conversation resuming from yesterday."
- **After FT-060:** "Note: Conversation resuming from yesterday (1 day and 3 hours ago). Current context: It is Friday at 10:15 AM."

#### **Scenario C: This Week (3 days)**
- **Before:** "Note: Conversation resuming from earlier this week."
- **After FT-060:** "Note: Conversation resuming from earlier this week (3 days ago). Current context: It is Sunday at 4:20 PM."

### **Method 5: Console Verification**

Add debug prints to see the time context in action:

1. **Add to `lib/services/claude_service.dart`:**
   ```dart
   // In sendMessage method, after line 177:
   print('🕒 Time Context Generated: $timeContext');
   ```

2. **Run the app with console output:**
   ```bash
   flutter run --verbose
   ```

3. **Look for console output showing the enhanced context.**

## 🔍 **What to Look For**

### **Enhanced Context Features:**

1. **Precise Duration:** "6 hours and 23 minutes ago" instead of just "later today"
2. **Exact Time:** "at 2:47 PM" instead of just "afternoon"
3. **Smart Triggering:** Only for gaps >= 4 hours
4. **Graceful Fallback:** Falls back to basic context if SystemMCP fails

### **Expected Behaviors:**

- **Short gaps (< 30 min):** No enhancement, identical to before
- **Medium gaps (30 min - 4 hours):** Still basic context for performance
- **Long gaps (4+ hours):** Enhanced with precise calculations
- **Very long gaps (days/weeks):** Precise day counts and current time

## 🎯 **Success Indicators**

✅ **Working correctly if you see:**
- Precise durations like "6 hours and 15 minutes ago"
- Exact times like "at 2:47 PM" instead of just "afternoon"
- Enhanced context only for longer gaps (4+ hours)
- Graceful fallback to basic context if something fails

❌ **Issues if you see:**
- No enhancement for any time gaps
- Error messages in context strings
- App crashes when generating time context
- Same basic context for all gap sizes

## 🛠 **Troubleshooting**

If enhanced context isn't working:

1. **Check SystemMCP:** Ensure `get_current_time` function works
2. **Verify Time Gaps:** Make sure gaps are actually >= 4 hours
3. **Console Logs:** Look for error messages in debug output
4. **Fallback Behavior:** Basic context should still work

The feature is designed to fail gracefully, so conversations should never break even if the enhancement fails.
