import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a numeric field is less than or equal to [maxValue].
class BlocxMaxValueValidator<T extends num> extends BlocxSingleErrorFieldValidator<T> {
  /// The maximum allowed value.
  final T maxValue;

  BlocxMaxValueValidator(this.maxValue, {super.duration});

  @override
  String? validateWithSingleError(T value) {
    if (value > maxValue) {
      return loc.maxValueError(maxValue);
    }
    return null;
  }
}
