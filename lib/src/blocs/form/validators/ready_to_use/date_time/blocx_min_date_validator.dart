import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a [DateTime] value is not before [minDate].
class BlocxMinDateValidator extends BlocxSingleErrorFieldValidator<DateTime> {
  final DateTime minDate;

  /// Creates a validator that enforces the minimum allowed date.
  BlocxMinDateValidator(this.minDate);

  @override
  String? validateSimple(DateTime value) {
    if (value.isBefore(minDate)) {
      return loc.minDateError(minDate); // localized error message
    }
    return null;
  }
}
