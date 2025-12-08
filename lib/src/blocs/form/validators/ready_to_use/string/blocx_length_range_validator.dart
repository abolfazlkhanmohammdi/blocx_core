import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a string field is within the inclusive range [minLength, maxLength].
class BlocxLengthRangeValidator extends BlocxSingleErrorFieldValidator<String> {
  final int minLength;
  final int maxLength;

  BlocxLengthRangeValidator({required this.minLength, required this.maxLength})
    : assert(maxLength >= minLength, 'maxLength must be >= minLength');

  @override
  String? validateSimple(String value) {
    final length = value.trim().length;

    if (length < minLength || length > maxLength) {
      return loc.lengthRangeError(minLength, maxLength);
    }

    return null;
  }
}
