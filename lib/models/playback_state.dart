/// States for audio playback in the application
enum PlaybackState {
  /// Audio is not currently playing
  stopped,

  /// Audio is currently playing
  playing,

  /// Audio is paused in the middle of playback
  paused,

  /// Audio is currently loading/buffering
  loading,

  /// An error occurred during playback
  error,
}
