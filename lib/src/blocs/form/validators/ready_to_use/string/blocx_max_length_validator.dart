import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a string field does not exceed [maxLength] characters.
class BlocxMaxLengthValidator extends BlocxSingleErrorFieldValidator<String> {
  final int maxLength;

  BlocxMaxLengthValidator(this.maxLength, {super.duration})
    : assert(maxLength >= 0, 'maxLength must be non-negative');

  @override
  String? validateWithSingleError(String value) {
    return value.length > maxLength ? loc.maxLengthError(maxLength) : null;
  }
}
