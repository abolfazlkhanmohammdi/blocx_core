import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

/// Validator that ensures a [DateTime] value is within the inclusive range [minDate, maxDate].
class BlocxDateRangeValidator extends BlocxSingleErrorFieldValidator<DateTime> {
  final DateTime minDate;
  final DateTime maxDate;

  /// Creates a validator that enforces the date to be within [minDate] and [maxDate].
  BlocxDateRangeValidator({required this.minDate, required this.maxDate, super.duration})
    : assert(
        maxDate.isAfter(minDate) || maxDate.isAtSameMomentAs(minDate),
        'maxDate must be after or equal to minDate',
      );

  @override
  String? validateWithSingleError(DateTime value) {
    if (value.isBefore(minDate) || value.isAfter(maxDate)) {
      return loc.dateRangeError(minDate, maxDate); // localized error message
    }
    return null;
  }
}
