import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a numeric field is within the inclusive range [minValue, maxValue].
class BlocxRangeValueValidator extends BlocxSingleErrorFieldValidator<num> {
  final num minValue;
  final num maxValue;

  BlocxRangeValueValidator({required this.minValue, required this.maxValue})
    : assert(maxValue >= minValue, 'maxValue must be >= minValue');

  @override
  String? validateSimple(num value) {
    if (value < minValue || value > maxValue) {
      return loc.numberRangeError(minValue, maxValue);
    }
    return null;
  }
}
