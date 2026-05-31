import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxDateTimeRangeValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, DateTime> {
  final DateTime min;
  final DateTime max;

  const BlocxDateTimeRangeValidator(this.min, this.max);

  @override
  String? validate(F form, E key, DateTime value) {
    if (value.isBefore(min) || value.isAfter(max)) {
      return loc.dateRangeError(min, max);
    }
    return null;
  }
}
