import 'package:blocx_core/src/blocs/form/validators/blocx_field_validator.dart';
import 'package:meta/meta.dart';

/// A base class for field validators that produce at most a single error message.
///
/// This class is intended for simple validation scenarios where each field
/// can only produce **one error**. It wraps the result of [validateWithSingleError]
/// into a list so it is compatible with the multi-error API of [BlocxFieldValidator].
///
/// Subclasses **must implement [validateWithSingleError]** to define the actual validation logic.
/// Subclasses **should NOT override [validate]**, as it is internally used to
/// convert a single error into a list of errors.
abstract class BlocxSingleErrorFieldValidator<T> extends BlocxFieldValidator<T> {
  /// Constructs a new instance of [BlocxSingleErrorFieldValidator].
  BlocxSingleErrorFieldValidator({super.duration});

  /// Internal implementation that converts the result of [validateWithSingleError]
  /// into a list of errors.
  ///
  /// Returns a single-element list if [validateWithSingleError] returns a non-null error,
  /// or an empty list if the value is valid.
  ///
  /// ⚠️ Do **not** override this method in subclasses.
  @internal
  @override
  List<String> validate(T value) {
    final error = validateWithSingleError(value);
    return error != null ? [error] : [];
  }

  /// Validates the given [value] and returns a single error message if invalid.
  ///
  /// Returns `null` if the value is valid.
  ///
  /// This method **must** be implemented by subclasses to define custom validation logic.
  String? validateWithSingleError(T value);
}
