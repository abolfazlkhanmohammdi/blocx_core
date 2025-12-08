import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a numeric field is greater than or equal to [minValue].
class BlocxMinValueValidator<T extends num> extends BlocxSingleErrorFieldValidator<T> {
  /// The minimum allowed value.
  final T minValue;

  /// Optional error message. Defaults to a localized message if not provided.
  final String? message;

  BlocxMinValueValidator(this.minValue, {this.message});

  @override
  String? validateSimple(T value) {
    if (value < minValue) {
      return message ?? loc.minValueError(minValue);
    }
    return null;
  }
}
