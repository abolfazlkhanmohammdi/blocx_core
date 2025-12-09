import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a string field has at least [minLength] characters.
class BlocxMinLengthValidator extends BlocxSingleErrorFieldValidator<String> {
  final int minLength;

  BlocxMinLengthValidator(this.minLength, {super.duration})
    : assert(minLength >= 0, 'minLength must be non-negative');

  @override
  String? validateWithSingleError(String value) {
    return value.trim().length < minLength ? loc.minLengthError(minLength) : null;
  }
}
