/// Represents the different states of audio playback.
///
/// This enum is used to track the current state of audio playback
/// throughout the application, enabling consistent state management
/// and UI updates based on the playback state.
enum PlaybackState {
  /// Initial state before any playback has started
  initial,

  /// Loading state when preparing audio for playback
  loading,

  /// Active playback is in progress
  playing,

  /// Playback has been temporarily paused
  paused,

  /// Playback has been stopped completely
  stopped
}
