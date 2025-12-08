/// Represents an error message that can optionally be displayed for a limited duration.
///
/// This is useful for form validation scenarios where some errors
/// should disappear automatically after a certain period.
class TimedErrorMessage {
  /// The error message text.
  final String error;

  /// Optional duration for which the error should be displayed.
  ///
  /// If `null`, the error is considered persistent until cleared manually.
  final Duration? duration;

  /// Creates a new [TimedErrorMessage] with the given [error] and optional [duration].
  TimedErrorMessage({required this.error, required this.duration});
}
