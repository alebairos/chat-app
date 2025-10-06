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

  // FT-181: Goal-aware activity detection features
  static const bool goalAwareActivityDetection =
      false; // Enhanced activity detection with goal context
  static const bool goalActivityBoard =
      false; // Activity board with goal sections
  static const bool activityGoalLabels =
      false; // Visual goal labels on activity cards

  // Composite flags for common feature combinations
  static bool get isGoalsTabEnabled => goalAwarePersonas && goalsTab;
  static bool get isGoalCreationEnabled =>
      goalAwarePersonas && goalCreation && goalModel;
  static bool get isGoalTrackingEnabled => goalAwarePersonas && goalModel;
  static bool get isPersonaGoalAware =>
      goalAwarePersonas && personaGoalAwareness;
  static bool get isGoalActivityTrackingEnabled =>
      goalAwarePersonas && goalActivityAssociation;

  // FT-181: Goal-aware activity detection composite flags
  static bool get isGoalAwareActivityDetectionEnabled =>
      goalAwarePersonas && goalAwareActivityDetection && goalModel;
  static bool get isGoalActivityBoardEnabled =>
      goalAwarePersonas && goalActivityBoard && goalModel;
  static bool get isActivityGoalLabelsEnabled =>
      goalAwarePersonas && activityGoalLabels && goalModel;

  // Development and testing flags
  static const bool debugGoalFeatures =
      false; // Enable debug logging for goal features

  /// Check if any goal-related features are enabled
  static bool get hasAnyGoalFeatures =>
      goalsTab ||
      goalCreation ||
      goalModel ||
      personaGoalAwareness ||
      goalActivityAssociation ||
      goalAwareActivityDetection ||
      goalActivityBoard ||
      activityGoalLabels;

  /// Get enabled feature list for debugging
  static List<String> get enabledGoalFeatures {
    final enabled = <String>[];
    if (goalAwarePersonas) enabled.add('goalAwarePersonas');
    if (goalsTab) enabled.add('goalsTab');
    if (goalCreation) enabled.add('goalCreation');
    if (goalModel) enabled.add('goalModel');
    if (personaGoalAwareness) enabled.add('personaGoalAwareness');
    if (goalActivityAssociation) enabled.add('goalActivityAssociation');
    if (goalAwareActivityDetection) enabled.add('goalAwareActivityDetection');
    if (goalActivityBoard) enabled.add('goalActivityBoard');
    if (activityGoalLabels) enabled.add('activityGoalLabels');
    if (debugGoalFeatures) enabled.add('debugGoalFeatures');
    return enabled;
  }
}
