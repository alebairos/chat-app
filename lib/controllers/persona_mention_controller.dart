/// FT-207: Persona Mention Autocomplete
/// Controller for orchestrating persona mention detection and autocomplete
import 'dart:async';
import '../models/persona_option.dart';
import '../services/persona_mention_parser.dart';
import '../services/persona_autocomplete_service.dart';

class PersonaMentionController {
  final PersonaAutocompleteService _service = PersonaAutocompleteService();
  List<PersonaOption> _availablePersonas = [];
  bool _isInitialized = false;
  Timer? _debounceTimer;

  // Debounce delay to prevent excessive filtering
  static const Duration _debounceDelay = Duration(milliseconds: 150);

  // Callbacks for UI integration
  Function(List<PersonaOption>)? onPersonasFiltered;
  Function(String personaKey)? onPersonaSelected;
  Function(String newText, int newCursorPosition)? onTextReplaced;

  /// Initialize the controller by loading available personas
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if feature is enabled
      final isEnabled = await _service.isFeatureEnabled();
      if (!isEnabled) {
        print('FT-207: Persona mention feature is disabled');
        return;
      }

      // Load available personas
      _availablePersonas = await _service.getAvailablePersonas();
      _isInitialized = true;

      print('FT-207: Initialized with ${_availablePersonas.length} personas');
    } catch (e) {
      print('FT-207: Error initializing persona mention controller: $e');
    }
  }

  /// Handle text change in input field with debouncing
  void onTextChanged(String text, int cursorPosition) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Debounce the text change to avoid excessive processing
    _debounceTimer = Timer(_debounceDelay, () {
      _processTextChange(text, cursorPosition);
    });
  }

  /// Process text change immediately (for testing or special cases)
  void onTextChangedImmediate(String text, int cursorPosition) {
    _debounceTimer?.cancel();
    _processTextChange(text, cursorPosition);
  }

  /// Internal method to process text changes
  void _processTextChange(String text, int cursorPosition) {
    // Check if controller is initialized and feature is enabled
    if (!_isInitialized) {
      _hideAutocomplete();
      return;
    }

    // Extract mention from current cursor position
    final mention = PersonaMentionParser.extractMention(text, cursorPosition);

    if (mention == null) {
      // No mention found - hide autocomplete
      _hideAutocomplete();
      return;
    }

    // Filter personas based on partial name
    final filteredPersonas =
        _service.filterPersonas(_availablePersonas, mention.partialName);

    // Notify UI with filtered results
    _showAutocomplete(filteredPersonas);
  }

  /// Handle persona selection from autocomplete
  void selectPersona(
      PersonaOption persona, String currentText, int cursorPosition) {
    try {
      // Extract current mention
      final mention =
          PersonaMentionParser.extractMention(currentText, cursorPosition);
      if (mention == null) {
        print('FT-207: No mention found for persona selection');
        return;
      }

      // Replace @mention with selected persona short name
      final replacementText = '@${persona.shortName}';
      final newText = PersonaMentionParser.replaceMention(
        currentText,
        mention,
        replacementText,
        addSpace: true,
      );

      // Calculate new cursor position
      final newCursorPosition = PersonaMentionParser.getCursorAfterReplacement(
        mention,
        replacementText,
        addSpace: true,
      );

      // Notify UI about text replacement
      onTextReplaced?.call(newText, newCursorPosition);

      // Trigger persona switch using existing infrastructure
      onPersonaSelected?.call(persona.key);

      // Hide autocomplete
      _hideAutocomplete();

      print('FT-207: Selected persona ${persona.displayName} (${persona.key})');
    } catch (e) {
      print('FT-207: Error selecting persona: $e');
    }
  }

  /// Show autocomplete with filtered personas
  void _showAutocomplete(List<PersonaOption> personas) {
    onPersonasFiltered?.call(personas);
  }

  /// Hide autocomplete suggestions
  void _hideAutocomplete() {
    onPersonasFiltered?.call([]);
  }

  /// Check if feature is enabled (for UI state management)
  Future<bool> isFeatureEnabled() async {
    return await _service.isFeatureEnabled();
  }

  /// Get all available personas (for debugging or advanced UI)
  List<PersonaOption> get availablePersonas =>
      List.unmodifiable(_availablePersonas);

  /// Check if controller is ready to use
  bool get isInitialized => _isInitialized;

  /// Manually refresh persona list (useful after config changes)
  Future<void> refresh() async {
    _service.clearCache();
    _isInitialized = false;
    await initialize();
  }

  /// Validate a persona key against available personas
  Future<bool> isValidPersonaKey(String key) async {
    return await _service.isValidPersonaKey(key);
  }

  /// Get persona option by key
  PersonaOption? getPersonaByKey(String key) {
    try {
      return _availablePersonas.firstWhere((persona) => persona.key == key);
    } catch (e) {
      return null;
    }
  }

  /// Dispose of resources
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    onPersonasFiltered = null;
    onPersonaSelected = null;
    onTextReplaced = null;
  }

  /// Force hide autocomplete (useful for external events)
  void hideAutocomplete() {
    _hideAutocomplete();
  }

  /// Check if text contains mentions (utility method)
  bool containsMentions(String text) {
    return PersonaMentionParser.containsMentions(text);
  }

  /// Get all mentions in text (utility method)
  List<PersonaMention> getAllMentions(String text) {
    return PersonaMentionParser.extractAllMentions(text);
  }
}
