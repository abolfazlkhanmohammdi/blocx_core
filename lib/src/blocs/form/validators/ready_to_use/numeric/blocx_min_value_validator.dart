import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a numeric field is greater than or equal to [minValue].
class BlocxMinValueValidator<T extends num> extends BlocxSingleErrorFieldValidator<T> {
  /// The minimum allowed value.
  final T minValue;

  BlocxMinValueValidator(this.minValue, {super.duration});

  @override
  String? validateWithSingleError(T value) {
    if (value < minValue) {
      return loc.minValueError(minValue);
    }
    return null;
  }
}
