import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxDoublePositiveValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, double> {
  const BlocxDoublePositiveValidator();

  @override
  String? validate(F form, E key, double value) {
    if (value <= 0) {
      return loc.minValueError(0);
    }
    return null;
  }
}
