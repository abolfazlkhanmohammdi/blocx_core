import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a [DateTime] value is not after [maxDate].
class BlocxMaxDateValidator extends BlocxSingleErrorFieldValidator<DateTime> {
  final DateTime maxDate;

  /// Creates a validator that enforces the maximum allowed date.
  BlocxMaxDateValidator(this.maxDate, {super.duration});

  @override
  String? validateWithSingleError(DateTime value) {
    if (value.isAfter(maxDate)) {
      return loc.maxDateError(maxDate); // localized error message
    }
    return null;
  }
}
