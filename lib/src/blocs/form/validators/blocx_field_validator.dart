import 'package:blocx_core/src/blocs/form/validators/timed_error_message.dart';

/// Base class for field validators used in form validation.
///
/// Subclasses should implement [validate] to provide custom validation logic
/// for a specific field type [T]. The [validate] method returns a list of
/// error messages for the given value. An empty list indicates the value is valid.
///
/// The optional [duration] getter can be overridden to specify a duration
/// for timed errors when used with [TimedErrorMessage].
///
/// Example usage:
/// ```dart
/// class NonEmptyValidator extends BlocxFieldValidator<String> {
///   @override
///   List<String> validate(String value) {
///     return value.isEmpty ? ['Field cannot be empty'] : [];
///   }
///
///   @override
///   Duration get duration => Duration(seconds: 3);
/// }
/// ```
abstract class BlocxFieldValidator<T> {
  /// Optional duration associated with the error messages.
  ///
  /// Can be used by form systems that display timed errors.
  /// Defaults to `null`.
  final Duration? duration;
  BlocxFieldValidator({this.duration});

  /// Validates the given [value] and returns a list of error messages.
  ///
  /// Returns an empty list if the value is valid.
  List<String> validate(T value);
}
