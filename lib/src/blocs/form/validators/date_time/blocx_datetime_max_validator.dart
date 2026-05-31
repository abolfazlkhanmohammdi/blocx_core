import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxDateTimeMaxValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, DateTime> {
  final DateTime max;

  const BlocxDateTimeMaxValidator(this.max);

  @override
  String? validate(F form, E key, DateTime value) {
    if (value.isAfter(max)) {
      return loc.maxDateError(max);
    }
    return null;
  }
}
