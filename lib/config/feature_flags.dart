/// FT-178: Feature flags for goal-aware personas functionality
///
/// Provides granular control over goal-related features with safe defaults.
/// All flags default to false for safe incremental rollout.
class FeatureFlags {
  // FT-178: Master flag for goal-aware personas functionality
  static const bool goalAwarePersonas = true;

  // Individual feature components (for granular control)
  static const bool goalsTab = true; // Goals tab visibility in navigation
  static const bool goalCreation =
      true; // Goal creation via persona conversation
  static const bool goalModel = true; // Goal storage and database operations
  static const bool personaGoalAwareness =
      false; // Persona system prompt goal context
  static const bool goalActivityAssociation =
      false; // Activity-goal linking and tracking

  // Composite flags for common feature combinations
  static bool get isGoalsTabEnabled => goalAwarePersonas && goalsTab;
  static bool get isGoalCreationEnabled =>
      goalAwarePersonas && goalCreation && goalModel;
  static bool get isGoalTrackingEnabled => goalAwarePersonas && goalModel;
  static bool get isPersonaGoalAware =>
      goalAwarePersonas && personaGoalAwareness;
  static bool get isGoalActivityTrackingEnabled =>
      goalAwarePersonas && goalActivityAssociation;

  // Development and testing flags
  static const bool debugGoalFeatures =
      false; // Enable debug logging for goal features

  /// Check if any goal-related features are enabled
  static bool get hasAnyGoalFeatures =>
      goalsTab ||
      goalCreation ||
      goalModel ||
      personaGoalAwareness ||
      goalActivityAssociation;

  /// Get enabled feature list for debugging
  static List<String> get enabledGoalFeatures {
    final enabled = <String>[];
    if (goalAwarePersonas) enabled.add('goalAwarePersonas');
    if (goalsTab) enabled.add('goalsTab');
    if (goalCreation) enabled.add('goalCreation');
    if (goalModel) enabled.add('goalModel');
    if (personaGoalAwareness) enabled.add('personaGoalAwareness');
    if (goalActivityAssociation) enabled.add('goalActivityAssociation');
    if (debugGoalFeatures) enabled.add('debugGoalFeatures');
    return enabled;
  }
}
