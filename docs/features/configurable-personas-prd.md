# Configurable Personas - Product Requirements Document

## Executive Summary

The Configurable Personas system extends the existing persona framework to provide dynamic configuration capabilities. This allows administrators and advanced users to enable/disable personas, modify prompts, and update data sources without code changes, while maintaining the simplicity and robustness of the current system.

## Problem Statement

The current persona system, while well-architected, requires code changes and app rebuilds to modify character configurations. Users need the ability to:
- Enable or disable specific personas based on use case
- Modify persona prompts for customization
- Update persona data sources (CSV files) without development intervention
- Dynamically configure which personas are available in the UI

## Goals and Objectives

### Primary Goals
1. **Dynamic Configuration**: Enable runtime configuration of personas without code changes
2. **Data Flexibility**: Support CSV-based data sources for persona knowledge
3. **Selective Enablement**: Allow enabling/disabling of specific personas
4. **Context Preservation**: Maintain chat history context for the active persona
5. **Operational Simplicity**: Minimize complexity while maximizing configurability

### Success Metrics
- Configuration changes take effect without app restart
- Zero code changes required for persona modifications
- Reduced development overhead for persona customization
- Maintained or improved app performance
- Preserved chat context integrity

## User Stories

### As an Administrator
- I want to enable/disable personas based on deployment requirements
- I want to modify persona prompts to customize behavior
- I want to update CSV data sources to refresh persona knowledge
- I want to configure which personas appear in the user interface

### As a User
- I want to see only enabled personas in the selection interface
- I want seamless persona switching with preserved context
- I want consistent behavior from configured personas
- I want the active persona to remember our conversation history

### As a Developer
- I want simple configuration management without complex abstractions
- I want robust testing capabilities without extensive mocking
- I want defensive code that handles configuration errors gracefully
- I want maintainable code that follows existing architectural patterns

## Technical Requirements

### 1. Configuration Management

#### 1.1 Persona Configuration Schema
```json
{
  "personas": {
    "personalDevelopmentAssistant": {
      "enabled": true,
      "displayName": "Personal Development Assistant",
      "description": "Empathetic guide focused on practical solutions",
      "systemPrompt": "path/to/system_prompt.txt",
      "explorationPrompts": {
        "physical": "path/to/physical_prompt.txt",
        "mental": "path/to/mental_prompt.txt",
        "relationships": "path/to/relationships_prompt.txt",
        "spirituality": "path/to/spirituality_prompt.txt",
        "work": "path/to/work_prompt.txt"
      },
      "dataSources": [
        "data/personal_development.csv",
        "data/habits.csv"
      ],
      "voiceConfig": {
        "voiceId": "voice_id_here",
        "stability": 0.7,
        "similarityBoost": 0.8,
        "style": 0.1
      }
    },
    "sergeantOracle": {
      "enabled": true,
      "displayName": "Sergeant Oracle",
      "description": "Roman time-traveler with military precision",
      "systemPrompt": "path/to/sergeant_system_prompt.txt",
      "explorationPrompts": { /* ... */ },
      "dataSources": [
        "data/military_wisdom.csv",
        "data/historical_facts.csv"
      ],
      "voiceConfig": { /* ... */ }
    },
    "zenMaster": {
      "enabled": false,
      "displayName": "The Zen Master",
      "description": "Enlightened sage with ancient wisdom",
      "systemPrompt": "path/to/zen_system_prompt.txt",
      "explorationPrompts": { /* ... */ },
      "dataSources": [
        "data/zen_teachings.csv",
        "data/meditation_practices.csv"
      ],
      "voiceConfig": { /* ... */ }
    }
  },
  "defaultPersona": "personalDevelopmentAssistant",
  "chatHistoryRetention": true,
  "configVersion": "1.0.0"
}
```

#### 1.2 File Structure
```
assets/
├── config/
│   ├── personas_config.json
│   └── prompts/
│       ├── personal_development_system.txt
│       ├── sergeant_oracle_system.txt
│       ├── zen_master_system.txt
│       └── exploration/
│           ├── physical.txt
│           ├── mental.txt
│           ├── relationships.txt
│           ├── spirituality.txt
│           └── work.txt
├── data/
│   ├── personal_development.csv
│   ├── habits.csv
│   ├── military_wisdom.csv
│   ├── historical_facts.csv
│   ├── zen_teachings.csv
│   └── meditation_practices.csv
```

### 2. Architecture Design

#### 2.1 Configuration Manager Enhancement
```dart
class ConfigurablePersonaManager {
  static final ConfigurablePersonaManager _instance = ConfigurablePersonaManager._internal();
  
  PersonaConfiguration? _configuration;
  Map<String, PersonaData> _personaData = {};
  String? _activePersonaId;
  
  // Core methods
  Future<bool> loadConfiguration();
  Future<void> reloadConfiguration();
  List<PersonaConfig> getEnabledPersonas();
  Future<bool> setActivePersona(String personaId);
  Future<String> getSystemPrompt(String personaId);
  Future<Map<String, String>> getExplorationPrompts(String personaId);
  Map<String, dynamic> getPersonaData(String personaId);
  
  // Configuration methods
  Future<bool> enablePersona(String personaId);
  Future<bool> disablePersona(String personaId);
  Future<bool> updatePersonaPrompt(String personaId, String promptType, String content);
  Future<bool> updatePersonaData(String personaId, String csvPath);
}
```

#### 2.2 CSV Data Integration
```dart
class PersonaDataManager {
  static Future<Map<String, dynamic>> loadCsvData(String csvPath) async;
  static Future<bool> validateCsvStructure(String csvPath) async;
  static Map<String, dynamic> parseCsvToMap(String csvContent);
  static Future<void> reloadDataSources(List<String> csvPaths) async;
}
```

#### 2.3 Configuration Validation
```dart
class ConfigurationValidator {
  static bool validatePersonaConfig(PersonaConfiguration config);
  static bool validatePromptFile(String promptPath);
  static bool validateCsvFile(String csvPath);
  static List<String> getConfigurationErrors(PersonaConfiguration config);
}
```

### 3. Data Management

#### 3.1 CSV Structure Requirements
- **Headers Required**: All CSV files must have proper headers
- **Encoding**: UTF-8 encoding for international character support
- **Size Limits**: Maximum 10MB per CSV file
- **Validation**: Automatic validation on load with error reporting

#### 3.2 CSV Processing Pipeline
```dart
class CsvProcessor {
  Future<ValidationResult> validateCsv(String csvPath);
  Future<Map<String, dynamic>> processCsv(String csvPath);
  Future<void> cacheProcessedData(String personaId, Map<String, dynamic> data);
  Map<String, dynamic>? getCachedData(String personaId);
}
```

### 4. User Interface Requirements

#### 4.1 Settings Menu Integration
- **Persona Management Section**: New section in settings for persona configuration
- **Enable/Disable Toggles**: Simple toggle switches for each persona
- **Active Persona Selection**: Radio button or dropdown for active persona selection
- **Configuration Status**: Visual indicators for configuration health

#### 4.2 Character Selection Enhancement
```dart
class EnhancedCharacterSelectionScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PersonaConfig>>(
      stream: ConfigurablePersonaManager().enabledPersonasStream,
      builder: (context, snapshot) {
        final enabledPersonas = snapshot.data ?? [];
        
        if (enabledPersonas.length == 1) {
          // Auto-select single persona, skip selection screen
          return ChatScreen();
        }
        
        return PersonaSelectionWidget(personas: enabledPersonas);
      },
    );
  }
}
```

#### 4.3 Single Persona Use Case
When only one persona is enabled:
- Skip character selection screen entirely
- Auto-activate the single enabled persona
- Hide persona-related UI elements in settings
- Show simplified interface focused on the single character

## Implementation Strategy

### Phase 1: Configuration Foundation
**Duration**: 2-3 weeks

**Deliverables**:
- `ConfigurablePersonaManager` implementation
- JSON configuration schema
- Basic CSV data loading
- Configuration validation

**Key Components**:
```dart
// Core configuration classes
class PersonaConfiguration {
  final Map<String, PersonaConfig> personas;
  final String defaultPersona;
  final bool chatHistoryRetention;
  final String configVersion;
}

class PersonaConfig {
  final bool enabled;
  final String displayName;
  final String description;
  final String systemPromptPath;
  final Map<String, String> explorationPromptPaths;
  final List<String> dataSources;
  final VoiceConfig voiceConfig;
}
```

### Phase 2: Data Integration
**Duration**: 1-2 weeks

**Deliverables**:
- CSV processing pipeline
- Data caching system
- Validation framework
- Error handling

**Key Components**:
```dart
// Data processing pipeline
class DataPipeline {
  Future<ProcessingResult> processPersonaData(PersonaConfig config);
  Future<void> cachePersonaData(String personaId, ProcessedData data);
  Future<ProcessedData?> getCachedData(String personaId);
  Future<void> invalidateCache(String personaId);
}
```

### Phase 3: UI Integration
**Duration**: 1-2 weeks

**Deliverables**:
- Enhanced settings menu
- Dynamic character selection
- Single persona mode
- Configuration status indicators

**Key Components**:
```dart
// UI components
class PersonaConfigurationWidget extends StatefulWidget;
class EnabledPersonasList extends StatelessWidget;
class PersonaDataStatus extends StatelessWidget;
class SinglePersonaMode extends StatelessWidget;
```

### Phase 4: Testing & Polish
**Duration**: 1-2 weeks

**Deliverables**:
- Comprehensive test suite
- Performance optimization
- Documentation
- Error recovery mechanisms

## Testing Strategy

### 1. Defensive Testing Approach
Following the requirement to "do less, test more, avoid mocks, apply defensive testing":

```dart
// Integration tests with real data
class PersonaConfigurationIntegrationTest {
  testRealConfigurationLoading() async {
    // Use actual configuration files
    final manager = ConfigurablePersonaManager();
    final result = await manager.loadConfiguration();
    expect(result, isTrue);
    expect(manager.getEnabledPersonas(), isNotEmpty);
  }
  
  testCsvDataProcessing() async {
    // Use real CSV files
    final processor = CsvProcessor();
    final result = await processor.processCsv('test_data/sample.csv');
    expect(result, isNotNull);
    expect(result.containsKey('headers'), isTrue);
  }
  
  testConfigurationValidation() async {
    // Test with various real configuration scenarios
    final validator = ConfigurationValidator();
    final validConfig = await loadTestConfig('valid_config.json');
    expect(validator.validatePersonaConfig(validConfig), isTrue);
    
    final invalidConfig = await loadTestConfig('invalid_config.json');
    expect(validator.validatePersonaConfig(invalidConfig), isFalse);
  }
}
```

### 2. Error Handling Tests
```dart
class ErrorHandlingTest {
  testMissingConfigurationFile() async {
    // Test graceful degradation when config file is missing
    final manager = ConfigurablePersonaManager();
    final result = await manager.loadConfiguration();
    expect(result, isFalse);
    expect(manager.getEnabledPersonas(), equals(getDefaultPersonas()));
  }
  
  testCorruptedCsvData() async {
    // Test handling of corrupted CSV files
    final processor = CsvProcessor();
    final result = await processor.validateCsv('test_data/corrupted.csv');
    expect(result.isValid, isFalse);
    expect(result.errors, isNotEmpty);
  }
  
  testPartialConfiguration() async {
    // Test behavior with incomplete configuration
    final manager = ConfigurablePersonaManager();
    await manager.loadPartialConfiguration('test_configs/partial.json');
    expect(manager.getEnabledPersonas(), isNotEmpty);
  }
}
```

### 3. Performance Tests
```dart
class PerformanceTest {
  testLargeCsvProcessing() async {
    // Test with realistic CSV file sizes
    final processor = CsvProcessor();
    final stopwatch = Stopwatch()..start();
    
    await processor.processCsv('test_data/large_dataset.csv');
    stopwatch.stop();
    
    expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 second limit
  }
  
  testConfigurationReload() async {
    // Test configuration reload performance
    final manager = ConfigurablePersonaManager();
    await manager.loadConfiguration();
    
    final stopwatch = Stopwatch()..start();
    await manager.reloadConfiguration();
    stopwatch.stop();
    
    expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1 second limit
  }
}
```

## Technical Specifications

### 1. Configuration File Format
- **Format**: JSON for human readability and easy parsing
- **Location**: `assets/config/personas_config.json`
- **Validation**: JSON Schema validation on load
- **Versioning**: Configuration version tracking for migration support

### 2. CSV Data Requirements
- **Encoding**: UTF-8
- **Format**: Standard CSV with header row
- **Size Limit**: 10MB per file
- **Validation**: Header validation, data type checking
- **Caching**: Processed data cached for performance

### 3. Prompt File Format
- **Format**: Plain text files (.txt)
- **Location**: `assets/config/prompts/`
- **Variables**: Support for template variables (e.g., `{{persona_name}}`)
- **Validation**: Content validation and variable substitution testing

### 4. Error Handling Strategy
```dart
class ConfigurationError extends Exception {
  final String message;
  final String? filePath;
  final ErrorSeverity severity;
  
  ConfigurationError(this.message, {this.filePath, this.severity = ErrorSeverity.error});
}

enum ErrorSeverity { warning, error, critical }

class ErrorRecovery {
  static PersonaConfiguration createFallbackConfiguration();
  static Future<void> logConfigurationError(ConfigurationError error);
  static bool canRecoverFromError(ConfigurationError error);
}
```

## Non-Functional Requirements

### 1. Simplicity & Maintainability
- **Minimal Abstractions**: Use simple, direct implementations over complex patterns
- **Clear Interfaces**: Well-defined contracts between components
- **Documentation**: Inline documentation for all public APIs
- **Code Review**: All changes require peer review for maintainability

### 2. Configuration Ease
- **Hot Reload**: Configuration changes apply without app restart
- **Validation**: Immediate feedback on configuration errors
- **Defaults**: Sensible defaults for all configuration options
- **Migration**: Automatic migration support for configuration updates

### 3. Defensive Programming
- **Input Validation**: All inputs validated at boundaries
- **Graceful Degradation**: System continues to function with partial configuration
- **Error Recovery**: Automatic recovery from non-critical errors
- **Logging**: Comprehensive logging for debugging and monitoring

### 4. Performance Requirements
- **Configuration Load**: < 2 seconds for initial configuration load
- **CSV Processing**: < 5 seconds for files up to 10MB
- **Memory Usage**: < 50MB additional memory for configuration data
- **Response Time**: < 100ms for persona switching

## Risk Assessment & Mitigation

### High Risks
1. **Configuration Corruption**
   - *Risk*: Invalid configuration breaks the application
   - *Mitigation*: Validation framework with fallback configuration

2. **Large CSV Performance**
   - *Risk*: Large CSV files cause performance issues
   - *Mitigation*: File size limits, streaming processing, caching

3. **Context Loss**
   - *Risk*: Chat history lost during persona switching
   - *Mitigation*: Robust context preservation system

### Medium Risks
1. **Configuration Complexity**
   - *Risk*: Configuration becomes too complex for users
   - *Mitigation*: Simple UI, good defaults, documentation

2. **Data Consistency**
   - *Risk*: Inconsistent data across CSV files
   - *Mitigation*: Validation rules, data integrity checks

### Low Risks
1. **File System Access**
   - *Risk*: File access permissions issues
   - *Mitigation*: Proper error handling, fallback mechanisms

## Success Criteria

### Functional Success
- [ ] Enable/disable personas without code changes
- [ ] Modify prompts through configuration files
- [ ] Update CSV data sources dynamically
- [ ] Single persona mode works seamlessly
- [ ] Multi-persona selection preserved
- [ ] Chat history maintained across persona switches

### Technical Success
- [ ] Configuration loads in < 2 seconds
- [ ] CSV processing completes in < 5 seconds for 10MB files
- [ ] Memory usage stays within 50MB overhead
- [ ] Zero crashes due to configuration errors
- [ ] 100% test coverage for critical paths

### Operational Success
- [ ] No development intervention required for persona updates
- [ ] Non-technical users can modify configurations
- [ ] Error messages are clear and actionable
- [ ] System recovers gracefully from errors
- [ ] Performance remains consistent with current system

## Future Enhancements

### Phase 2 Features
- **Dynamic Prompt Templates**: Template engine for prompt customization
- **Multi-language Support**: Localized prompts and data
- **Persona Analytics**: Usage tracking and performance metrics
- **A/B Testing**: Framework for testing different persona configurations

### Phase 3 Features
- **Cloud Configuration**: Remote configuration management
- **User Customization**: Per-user persona preferences
- **Advanced Data Sources**: Database integration, API data sources
- **Persona Learning**: Adaptive behavior based on user interactions

## Conclusion

The Configurable Personas system provides a robust, maintainable solution for dynamic persona management while preserving the simplicity and elegance of the existing architecture. By focusing on configuration-driven design, defensive programming, and comprehensive testing, this system enables flexible persona management without sacrificing reliability or performance.

The implementation follows the principle of "do less, test more" by providing focused functionality with extensive real-world testing, ensuring the system remains maintainable and reliable in production environments. 