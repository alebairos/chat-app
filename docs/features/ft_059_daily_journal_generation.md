# Feature Specification: Daily Journal Generation

## Overview

This feature specification outlines the implementation of an automated daily journal generation system that transforms daily chat conversations into beautiful, web-based journal entries authored by the I-There 2.1 persona.

## Feature Summary

**Feature ID:** FT-059  
**Priority:** High  
**Category:** AI Content Generation  
**Estimated Effort:** 7-10 days  

### User Story
> As a user, I want to receive automatically generated daily journals based on my conversations so that I can reflect on my growth, insights, and personality discoveries in a beautiful, shareable format.

## Target Users

### Primary Users
- **Active chat app users** seeking daily reflection and personal growth tracking
- **Users engaged with I-There 2.1** who value personality insights and clone observations
- **Users interested in journaling** but lacking time or motivation for manual writing

### Secondary Users  
- **Mental health enthusiasts** using conversation data for self-reflection
- **Productivity users** wanting daily progress and growth summaries
- **Content creators** seeking shareable personal development content

## Architecture Overview

### System Components
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │ Firebase Func   │    │ Firebase Host   │
│  (Local Isar)   │───▶│ (Python FastAPI)│───▶│   (Static Web)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
   Trigger + Data          Generation API           Web Journals
```

**Data Flow:**
1. **End-of-Day Detection** → Flutter app detects new day rollover
2. **Data Extraction** → App sends previous day's messages to Firebase Function
3. **Content Generation** → FastAPI processes data using configurable prompts + Claude API
4. **Static Deployment** → Generated HTML/CSS deployed to Firebase Hosting  
5. **User Notification** → I-There 2.1 sends chat message with journal URL

## Requirements

### Functional Requirements

#### FR-001: Automated Daily Trigger
- **Trigger Method:** Periodic checks every hour via Flutter Timer
- **Detection Logic:** Detect when current date > last journal generation date
- **No Messages Handling:** If no messages exist for a day, no journal is generated
- **Minimum Threshold:** Require minimum 3 meaningful messages for journal generation
- **Time Zone Support:** Use user's local timezone for day boundaries
- **Graceful Degradation:** Handle offline scenarios with retry logic

#### FR-002: Data Extraction & API Communication
- **Source:** Extract messages from local Isar database
- **Date Range:** Previous day (00:00 to 23:59 user local time)
- **Message Filtering:** Include all message types (text, audio) with metadata
- **Payload Format:**
```json
{
  "date": "2025-01-20T00:00:00Z",
  "messages": [
    {
      "timestamp": "2025-01-20T14:30:00Z",
      "text": "message content",
      "isUser": true,
      "personaKey": "iThereWithOracle21",
      "personaDisplayName": "I-There 2.1"
    }
  ],
  "userTimezone": -3
}
```
- **API Endpoint:** Firebase Function at `/generateJournal`
- **Error Handling:** Retry failed requests with exponential backoff

#### FR-003: Configurable Prompt System (Server-Side)
**Configuration Structure:**
```python
JOURNAL_PROMPTS = {
    "iThereWithOracle21": {
        "voice": {
            "greeting": "hey, your clone here from clone earth 🌎",
            "signature": "- your clone on clone earth",
            "style": "casual_observational"
        },
        "system_prompt": "You are I-There 2.1, the user's AI clone...",
        "journal_template": "Write a daily journal entry for {date}...",
        "analysis_prompts": {
            "themes": "Analyze conversations and identify main themes: {messages}",
            "insights": "What personality traits can you observe: {messages}",
            "summary": "Provide a brief summary of conversations: {messages}"
        },
        "fallbacks": {
            "no_messages": "quiet day today - no conversations to observe...",
            "few_messages": "just a few exchanges today..."
        }
    }
}
```

#### FR-004: Content Generation Pipeline
**Analysis Phase:**
1. **Theme Extraction** → Identify 2-3 main conversation themes using Claude API
2. **Personality Insights** → Extract authentic personality observations
3. **Growth Moments** → Identify learning or development moments
4. **Conversation Summary** → Create brief, natural conversation overview

**Content Generation:**
1. **Template Processing** → Use configurable prompts with extracted variables
2. **Claude API Integration** → Generate journal content in I-There 2.1 voice
3. **Content Validation** → Ensure 2-3 paragraph length, appropriate tone
4. **Fallback Handling** → Use configured fallback messages for edge cases

#### FR-005: Per-User Isolated Web Journal Generation
**User Isolation Architecture:**
- **Complete User Isolation:** Each user has dedicated path structure
- **URL Pattern:** `yourapp.com/u/{user_hash}/j/{date}/index.html`
- **No Shared Assets:** Each journal is completely self-contained
- **Independent Deployment:** Users cannot access other users' journals

**Self-Contained HTML Structure:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Journal - January 20, 2025</title>
    <style>
        /* All CSS inlined - no external dependencies */
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; }
        .journal-container { max-width: 600px; margin: 0 auto; }
        /* Complete styling inlined here */
    </style>
</head>
<body class="persona-ithere">
    <div class="journal-container">
        <header class="journal-header">
            <div class="date">January 20, 2025</div>
            <div class="author">your clone from clone earth 🌎</div>
        </header>
        <main class="journal-content">
            <!-- AI-generated content -->
        </main>
        <footer class="journal-footer">
            <div class="signature">- your clone on clone earth</div>
        </footer>
    </div>
</body>
</html>
```

**Generation Strategy:**
- **Full Rebuild Approach:** Regenerate all content (static + dynamic) for each journal
- **Inline Everything:** CSS, fonts, and all assets embedded in single HTML file
- **Self-Contained:** Each journal file is completely independent
- **No External Dependencies:** Zero external CSS/JS requests for maximum reliability

**Styling Requirements:**
- **Mobile-first responsive design** with max-width 600px
- **I-There 2.1 color scheme:** Purple gradient (#667eea to #764ba2)
- **Clean typography:** System fonts, 1.1rem body text, 1.7 line height
- **Card-based layout:** Rounded corners, subtle shadow, white background
- **Accessibility:** Proper contrast ratios, semantic HTML structure
- **File Size Optimization:** Target ~15KB per complete journal file

#### FR-006: Secure Per-User URL Generation
- **User-Specific Paths:** Each user gets isolated path structure
- **Pattern:** `https://your-project.web.app/u/{user_hash}/j/{date}/`
- **User Hash Generation:** `{user_id}-salt` → SHA256 → first 16 chars
- **Date Format:** `YYYY-MM-DD` for journal date paths
- **Complete URL:** `yourapp.com/u/a7f8d9e2b1c4f6a8/j/2025-01-20/index.html`
- **Privacy:** User hashes not guessable but deterministic per user
- **Isolation:** Complete path separation prevents cross-user access

#### FR-007: In-Chat Notification System
**Notification Trigger:**
- **Status Polling:** Flutter app polls `/journalStatus` endpoint every 30 minutes
- **Ready Detection:** API returns `{"ready": true, "journalUrl": "..."}` when complete
- **Message Generation:** Create chat message from I-There 2.1 persona

**Notification Message Template:**
```
hey! just finished writing about yesterday ({date}) 📓

captured some interesting observations about your personality and growth moments. wanna check it out?

{journal_url}

curious what you think about my perspective from clone earth 🌎
```

#### FR-008: Firebase Hosting Integration
- **Deployment Target:** Firebase Hosting static file serving
- **Automated Server Deployment:** All deployment handled automatically by Firebase Function
- **Per-User Directory Structure:**
```
public/
├── u/
│   ├── a7f8d9e2b1c4f6a8/  # Hashed user ID
│   │   └── j/
│   │       ├── 2025-01-20/
│   │       │   └── index.html  # Self-contained journal
│   │       ├── 2025-01-21/
│   │       │   └── index.html
│   │       └── 2025-01-22/
│   │           └── index.html
│   └── b2c9e4f7a1d8c5b6/  # Another user
│       └── j/
│           └── 2025-01-20/
│               └── index.html
```
- **File Management:** Single HTML file per journal (no separate CSS files)
- **Performance:** Global CDN distribution, aggressive caching
- **SSL:** Automatic HTTPS for all journal URLs

### Non-Functional Requirements

#### NFR-001: Performance
- **Journal Generation Time:** Complete generation within 60 seconds
- **Web Page Load Time:** Journal pages load in <2 seconds globally
- **Mobile Performance:** Optimized for 3G connections and older devices
- **API Response Time:** Status checks return within 5 seconds

#### NFR-002: Cost Optimization
- **Claude API Usage:** ~$0.01 per journal generation (estimated 5K tokens)
- **Firebase Free Tier Usage:**
  - Functions: <100 daily invocations (well within 2M/month limit)
  - Hosting: <10MB storage per month, <1GB transfer
  - Firestore: <1K reads/writes per day for status tracking
- **Target Monthly Cost:** <$0.50 for daily journal generation

#### NFR-003: Reliability
- **Uptime:** 99.9% availability for journal generation
- **Error Recovery:** Graceful handling of Claude API rate limits
- **Data Integrity:** No message data stored on server after processing
- **Retry Logic:** Exponential backoff for failed generations

#### NFR-004: Security & Privacy
- **Data Transit:** Messages sent to API only for processing, not stored
- **Journal Privacy:** URLs obscured but not authenticated (acceptable for MVP)
- **API Security:** Firebase Functions with proper CORS configuration
- **Content Safety:** No personally identifiable information in URLs

#### NFR-005: Maintainability
- **Configuration-Driven:** All prompts and styling configurable server-side
- **Prompt Iteration:** Update journal voice without app releases
- **A/B Testing:** Support for multiple prompt variants
- **Monitoring:** Firebase Functions logging for debugging and optimization

## Technical Specifications

### Flutter App Components

#### Trigger Service Configuration
```json
// assets/config/journal_trigger_config.json
{
  "dailyJournalTrigger": {
    "enabled": true,
    "checkIntervalHours": 1,
    "generationTimeHour": 1,
    "minimumMessages": 3,
    "apiEndpoint": "https://your-region-your-project.cloudfunctions.net/generateJournal",
    "statusEndpoint": "https://your-region-your-project.cloudfunctions.net/journalStatus"
  },
  "notificationSettings": {
    "authorPersona": "iThereWithOracle21",
    "messageTemplate": "hey! just finished writing about yesterday ({date}) 📓..."
  }
}
```

#### Core Service Implementation
```dart
class JournalTriggerService {
  static Timer? _periodicTimer;
  
  static Future<void> initialize() async {
    final config = await _loadTriggerConfig();
    if (config['enabled'] == true) {
      _startPeriodicChecks(config);
    }
  }
  
  static Future<void> _sendDataToAPI(DateTime date, config) async {
    final messages = await _getMessagesForDate(date);
    
    // No messages = no journal generation
    if (messages.isEmpty) {
      Logger().info('No messages for ${date.toIso8601String()}, skipping journal');
      return;
    }
    
    if (messages.length < config['minimumMessages']) {
      Logger().info('Only ${messages.length} messages, below threshold');
      return;
    }
    
    final payload = {
      'date': date.toIso8601String(),
      'messages': _formatMessagesForAPI(messages),
      'userTimezone': DateTime.now().timeZoneOffset.inHours,
      'userId': _getUserId(), // For per-user isolation
    };
    
    await http.post(Uri.parse(config['apiEndpoint']), 
      body: jsonEncode(payload),
      headers: {'Content-Type': 'application/json'});
    
    _startPollingForJournal(date, config);
  }
}
```

### Firebase Function Architecture

#### FastAPI Application Structure
```python
# main.py
from firebase_functions import https_fn
from fastapi import FastAPI
from journal_configs import JOURNAL_PROMPTS, JOURNAL_STYLES

app = FastAPI()

@app.post("/generateJournal")
async def generate_journal(request_data: dict):
    date = datetime.fromisoformat(request_data['date'])
    messages = request_data['messages']
    user_id = request_data['userId']
    
    # No messages = no journal
    if not messages or len(messages) == 0:
        return {
            "status": "skipped", 
            "reason": "no_messages",
            "date": date.isoformat()
        }
    
    # Use I-There 2.1 as default journal author
    author_key = "iThereWithOracle21"
    prompt_config = JOURNAL_PROMPTS[author_key]
    
    # Generate analysis and content
    analysis = await generate_analysis(messages, prompt_config)
    journal_content = await generate_journal_content(date, analysis, prompt_config)
    
    # Create complete self-contained HTML file
    html_content = await generate_complete_html(journal_content, date, user_id)
    
    # Deploy single file to Firebase Hosting with user isolation
    file_path = f"u/{hash_user_id(user_id)}/j/{date.strftime('%Y-%m-%d')}/index.html"
    await deploy_to_firebase_hosting(file_path, html_content)
    
    # Generate final URL
    journal_url = f"https://yourapp.com/{file_path}"
    
    # Store status for polling
    await store_journal_status(date, journal_url, user_id)
    
    return {"status": "success", "url": journal_url}

@app.get("/journalStatus")
async def journal_status(date: str, user_id: str):
    status = await get_journal_status(date, user_id)
    return {"ready": status.get("ready", False), "journalUrl": status.get("url")}

async def generate_complete_html(content: str, date: datetime, user_id: str) -> str:
    """Generate completely self-contained HTML file with inlined CSS"""
    css = generate_ithere_css()  # Inline all styling
    
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Journal - {date.strftime('%B %d, %Y')}</title>
    <style>{css}</style>
</head>
<body class="persona-ithere">
    <div class="journal-container">
        <header class="journal-header">
            <div class="date">{date.strftime('%B %d, %Y')}</div>
            <div class="author">your clone from clone earth 🌎</div>
        </header>
        <main class="journal-content">{content}</main>
        <footer class="journal-footer">
            <div class="signature">- your clone on clone earth</div>
        </footer>
    </div>
</body>
</html>"""
    
    return html
```

## Implementation Phases

### Phase 1: Core Infrastructure (Days 1-3)
1. **Firebase Project Setup** with Functions and Hosting
2. **Basic FastAPI Function** with health check endpoint
3. **Flutter Trigger Service** with periodic checking
4. **Configuration Loading** for journal trigger settings

### Phase 2: Content Generation (Days 4-6)
1. **Prompt Configuration System** with I-There 2.1 templates
2. **Claude API Integration** for analysis and content generation
3. **Self-Contained HTML Generation** with inlined CSS
4. **No Messages Handling** and fallback logic
5. **Error Handling & Fallbacks** for edge cases

### Phase 3: Deployment & Notification (Days 7-8)
1. **Firebase Hosting Integration** with automated single-file deployment
2. **Per-User URL Generation** with isolated directory structure
3. **Status Polling System** in Flutter app with user context
4. **In-Chat Notification** with I-There 2.1 messages

### Phase 4: Testing & Polish (Days 9-10)
1. **End-to-End Testing** of complete flow
2. **Performance Optimization** for mobile and web
3. **Error Scenario Testing** and recovery mechanisms
4. **Documentation & Monitoring** setup

## Success Criteria

### Primary Success Metrics
1. ✅ **Automated Generation**: Daily journals generated without user intervention
2. ✅ **Beautiful Presentation**: Web-based journals match Daymi aesthetic benchmark
3. ✅ **I-There 2.1 Voice**: Authentic clone persona voice in journal content
4. ✅ **Mobile Optimization**: Fast loading on mobile devices globally
5. ✅ **Cost Efficiency**: Operation within $0.50/month budget for daily journals

### Secondary Success Metrics
1. ✅ **User Engagement**: Users clicking journal links >80% of the time
2. ✅ **Content Quality**: Journals provide meaningful personality insights
3. ✅ **System Reliability**: <5% failed generations due to technical issues
4. ✅ **Configuration Flexibility**: Prompt updates possible without app releases
5. ✅ **Privacy Compliance**: No conversation data stored on servers after processing

## Risk Assessment

### Technical Risks
- **Claude API Rate Limits**: Mitigation through exponential backoff and usage monitoring
- **Firebase Free Tier Limits**: Monitoring usage and upgrade planning if needed
- **Mobile Network Reliability**: Offline queueing and retry mechanisms

### Product Risks
- **Content Quality Variability**: Extensive prompt testing and fallback content
- **User Privacy Concerns**: Clear communication about data processing and non-storage
- **Journal URL Discovery**: Acceptable risk for MVP with obscured URLs

### Operational Risks
- **Prompt Configuration Management**: Version control and rollback procedures
- **Cost Scaling**: Usage monitoring and automatic cost alerts
- **Content Moderation**: Basic content filtering for inappropriate generation

## Future Enhancements

### Phase 2 Features (Post-MVP)
- **Image Generation**: AI-generated images combining user avatar with daily themes
- **Multiple Journal Authors**: Support for Ari, Sergeant Oracle journal styles
- **Journal Collections**: Weekly and monthly compilation journals
- **Sharing Features**: Social sharing capabilities for journal entries
- **Analytics Dashboard**: User reflection patterns and growth tracking

### Advanced Features
- **Journal Search**: Full-text search across historical journals
- **Mood Tracking**: Emotional tone analysis and trend visualization
- **Goal Integration**: Journal entries tied to Oracle system objectives
- **Export Features**: PDF generation and backup capabilities
- **Personalization**: Custom journal themes and formatting options

---

**Note**: This feature builds upon the existing chat export functionality (FT-048) and persona configuration system (FT-003), leveraging proven patterns while introducing AI-powered content generation and web-based presentation.
