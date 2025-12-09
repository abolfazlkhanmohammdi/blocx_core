import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a field is not empty or null.
class BlocxRequiredValidator extends BlocxSingleErrorFieldValidator<dynamic> {
  BlocxRequiredValidator({super.duration});

  @override
  String? validateWithSingleError(value) {
    if (value == null) return loc.thisFieldIsRequired;

    bool isEmpty = false;
    if (value is String) {
      isEmpty = value.trim().isEmpty;
    } else if (value is Map) {
      isEmpty = value.isEmpty;
    }

    return isEmpty ? loc.thisFieldIsRequired : null;
  }
}
