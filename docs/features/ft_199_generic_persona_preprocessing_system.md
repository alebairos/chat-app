# FT-199: Generic Persona Preprocessing System

**Feature ID:** FT-199  
**Priority:** High  
**Category:** Architecture Enhancement  
**Effort:** 4-6 hours  
**Date:** October 18, 2025

## Overview

Create a generic persona preprocessing system that transforms any persona configuration into a structured database, enabling reliable content verification and eliminating AI hallucination across all personas. This system applies the proven Oracle framework approach universally to any persona's structured content.

---

## **Problem Statement**

### **Current Issues**
- **Persona-specific compliance failures**: AI fabricates content instead of using exact persona configuration (e.g., 6-point vs 14-point manifesto)
- **Training data interference**: AI defaults to training patterns instead of persona-specific content
- **Inconsistent verification**: Each persona requires custom compliance checking
- **Token inefficiency**: Large persona configurations in system prompts
- **Scalability limitations**: Adding new personas requires custom implementation

### **Evidence from Logs**
```
User: "me fala sobre seu manifesto"
Expected: 14-point exact manifesto from aristios_base_config_4.5.json
Actual: 6-point fabricated manifesto from training data
Root Cause: AI ignores 16,175 characters of persona configuration
```

---

## **Solution: Generic Persona Preprocessing**

### **Core Concept**
Apply the Oracle framework's successful structured database approach to **any persona configuration**, creating:
- **Structured JSON databases** for all persona content
- **Universal MCP commands** for reliable content access
- **Generic verification system** for compliance checking
- **Optimized prompts** with database references

### **Architecture Overview**
```
Persona Config (JSON/MD) → Generic Preprocessor → Structured Database → MCP Commands → Reliable AI Responses
```

---

## **Technical Implementation**

### **1. Generic Persona Structure**

```python
class GenericPersonaStructure:
    """Universal structure that any persona can be parsed into"""
    
    def __init__(self):
        self.identity = {}          # Name, role, mission
        self.personality = {}       # Traits, voice, tone
        self.values = {}           # Core values and beliefs
        self.knowledge_base = {}   # Structured content (manifestos, principles, etc.)
        self.interaction_style = {} # Communication patterns
        self.examples = {}         # Interaction examples
        self.metadata = {}         # Processing info
```

### **2. Universal Parsing Patterns**

```python
class PersonaPreprocessor:
    """Generic preprocessor for any persona configuration"""
    
    def __init__(self):
        self.parsing_patterns = {
            'identity': [
                r'(?i)papel\s+e\s+missão',
                r'(?i)role\s+and\s+mission', 
                r'(?i)você\s+é\s+(\w+)',
                r'(?i)i\s+am\s+(\w+)'
            ],
            'structured_content': [
                r'(?i)manifesto',
                r'(?i)princípios',
                r'(?i)principles',
                r'(?i)framework',
                r'(?i)metodologia'
            ]
            # ... additional patterns
        }
    
    def parse_persona_file(self, file_path: str) -> Dict:
        """Parse any persona file into structured database"""
        # Generic parsing logic that works for any persona
        pass
```

### **3. Universal Database Schema**

```json
{
  "version": "1.0",
  "persona_key": "aristiosPhilosopher45",
  "source_file": "aristios_base_config_4.5.json",
  "generated_at": "2025-10-18T12:00:00Z",
  "identity": {
    "name": "Aristios",
    "role": "Oráculo do LyfeOS",
    "mission": "maximizar a probabilidade de que cada usuário melhore de vida"
  },
  "knowledge_base": {
    "manifesto": {
      "type": "numbered_list",
      "total_items": 14,
      "items": [
        {
          "number": 1,
          "title": "A jornada da alma", 
          "content": "Estamos neste mundo por uma fração de milésimo no tempo..."
        }
        // ... exact content from configuration
      ]
    }
  },
  "metadata": {
    "total_structured_items": 20,
    "parsing_status": "success",
    "token_estimate": 4200,
    "optimization_potential": "60%"
  }
}
```

### **4. Universal MCP Commands**

```dart
// Generic MCP commands that work for any persona
case 'get_persona_identity':
  return await _getPersonaIdentity(parsedCommand['persona'] as String?);

case 'get_persona_knowledge':
  final section = parsedCommand['section'] as String? ?? 'all';
  return await _getPersonaKnowledge(parsedCommand['persona'] as String?, section);

Future<String> _getPersonaKnowledge(String? personaKey, String section) async {
  final personaDb = await _loadPersonaDatabase(personaKey ?? _currentPersonaKey);
  final knowledgeBase = personaDb['knowledge_base'] ?? {};
  
  return json.encode({
    'status': 'success',
    'data': knowledgeBase[section] ?? knowledgeBase,
    'source': 'persona_database'
  });
}
```

### **5. Generic Verification System**

```dart
Future<String> _processPersonaVerification(String userMessage, String initialResponse, String messageId) async {
  
  // Detect what type of persona content is needed (universal)
  final contentNeeds = _analyzePersonaContentNeeds(userMessage);
  
  // Load appropriate persona database sections (universal)
  final personaData = await _loadRequiredPersonaContent(contentNeeds);
  
  // Build verification prompt with exact database content (universal)
  final verificationPrompt = _buildGenericVerificationPrompt(
    userMessage, 
    initialResponse, 
    personaData
  );
  
  // Same verification flow for all personas
  return await _callClaudeWithPrompt(verificationPrompt);
}
```

---

## **Benefits Analysis**

### **1. Universal Compliance**
- **Eliminates hallucination**: Structured database prevents fabricated content
- **Guarantees accuracy**: Exact content from persona configurations
- **Works for all personas**: Same reliability as Oracle framework

### **2. Scalability**
```python
# Adding new persona is trivial
python3 scripts/preprocess_persona.py assets/config/new_persona_config.json
# Automatically gets database, MCP commands, verification
```

### **3. Token Optimization**
```
Current: 16,175 chars persona config in system prompt
Optimized: 4,200 chars summary + database reference
Savings: ~60% token reduction while maintaining 100% accuracy
```

### **4. Consistency**
- **Same structure** for all persona databases
- **Same MCP commands** for all personas  
- **Same verification patterns** across personas
- **Unified testing** approach

### **5. Maintainability**
- **Single codebase** to maintain and improve
- **Consistent documentation** and patterns
- **Easy debugging** with unified approach

---

## **Implementation Plan**

### **Phase 1: Create Generic Preprocessor (2 hours)**
- Adapt `preprocess_oracle.py` for generic persona processing
- Create `PersonaPreprocessor` class with universal parsing patterns
- Support for numbered lists, bullet points, key-value pairs
- Generate structured JSON databases

### **Phase 2: Universal MCP Integration (1 hour)**
- Add generic persona database commands to `SystemMCPService`
- `get_persona_identity`, `get_persona_knowledge`, `get_persona_examples`
- Universal database loading and caching

### **Phase 3: Generic Verification System (1.5 hours)**
- Extend two-pass flow with generic persona verification
- Universal content needs analysis
- Database-backed verification prompts

### **Phase 4: Optimization & Testing (1.5 hours)**
- Create optimized persona configurations
- Generate test databases for all existing personas
- Validate compliance improvements

**Total Effort: 6 hours**

---

## **Usage Examples**

### **Processing All Personas**
```bash
# Process all persona configurations
python3 scripts/preprocess_persona.py --all

# Process specific persona
python3 scripts/preprocess_persona.py assets/config/aristios_base_config_4.5.json

# Create optimized versions
python3 scripts/preprocess_persona.py --all --optimize
```

### **Expected Results**
```
Before: User asks about manifesto → AI fabricates 6 points
After:  User asks about manifesto → System loads database → AI uses exact 14 points
```

---

## **Success Metrics**

### **Compliance Metrics**
- **Manifesto accuracy**: 100% exact point count and titles
- **Content authenticity**: 0% fabricated content from training data
- **Verification success rate**: >95% compliance correction

### **Performance Metrics**
- **Token reduction**: 40-60% across all personas
- **Response accuracy**: 100% for structured content queries
- **Processing time**: <100ms for database queries

### **Scalability Metrics**
- **New persona onboarding**: <30 minutes from config to database
- **Maintenance overhead**: Single codebase for all personas
- **Test coverage**: Unified testing for all persona types

---

## **Risk Mitigation**

### **Implementation Risks**
- **Parsing complexity**: Start with simple patterns, expand iteratively
- **Database size**: Monitor token usage, optimize as needed
- **Performance impact**: Cache databases, lazy loading

### **Content Quality Risks**
- **Parsing accuracy**: Extensive validation and testing
- **Database completeness**: Fallback to original config if needed
- **Verification reliability**: Multiple validation layers

---

## **Future Enhancements**

### **Advanced Features**
- **Multi-language support**: Parse personas in different languages
- **Dynamic content updates**: Hot-reload persona databases
- **Content versioning**: Track persona configuration changes
- **Analytics dashboard**: Monitor persona compliance and usage

### **Integration Opportunities**
- **Persona editor**: Visual tool for creating/editing persona databases
- **Content validation**: Automated testing for persona compliance
- **Performance monitoring**: Real-time compliance metrics

---

## **Conclusion**

The Generic Persona Preprocessing System transforms persona compliance from a specific problem into a solved architectural pattern. By applying the proven Oracle framework approach universally, we achieve:

1. **Universal compliance**: Every persona gets reliable content verification
2. **Scalable architecture**: Easy to add new personas without custom code
3. **Token optimization**: Significant reduction in system prompt size
4. **Consistent quality**: Same reliability across all persona types
5. **Maintainable codebase**: Single system instead of persona-specific solutions

**This system eliminates AI hallucination for persona-specific content while providing a scalable foundation for future persona development.**

---

## **Dependencies**

- Existing Oracle preprocessing infrastructure (`preprocess_oracle.py`)
- Two-pass verification system (FT-199 persona verification)
- SystemMCPService singleton pattern (FT-195)
- Claude API integration and rate limiting

## **Related Features**

- FT-193: Persona Configuration Compliance Enforcement
- FT-194: Fix Activity Detection Bypass for Philosopher
- FT-195: Fix SystemMCP Singleton Pattern
- FT-196: Fix Persona Prefix in Responses
- FT-197: Complete Prompt Chain Analysis
