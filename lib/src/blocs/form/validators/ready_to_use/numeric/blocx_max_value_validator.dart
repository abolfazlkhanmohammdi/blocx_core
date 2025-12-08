import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a numeric field is less than or equal to [maxValue].
class BlocxMaxValueValidator<T extends num> extends BlocxSingleErrorFieldValidator<T> {
  /// The maximum allowed value.
  final T maxValue;

  /// Optional error message. Defaults to a localized message if not provided.
  final String? message;

  BlocxMaxValueValidator(this.maxValue, {this.message});

  @override
  String? validateSimple(T value) {
    if (value > maxValue) {
      return message ?? loc.maxValueError(maxValue);
    }
    return null;
  }
}
