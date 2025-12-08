import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a string field has exactly [length] characters.
class BlocxExactLengthValidator extends BlocxSingleErrorFieldValidator<String> {
  final int length;

  BlocxExactLengthValidator(this.length) : assert(length >= 0, 'Length must be non-negative');

  @override
  String? validateSimple(String value) {
    final size = value.length;

    return size != length ? loc.exactLengthFieldError(length) : null;
  }
}
