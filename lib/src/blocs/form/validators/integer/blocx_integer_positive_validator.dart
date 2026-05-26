import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;

class BlocxIntegerPositiveValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, int> {
  const BlocxIntegerPositiveValidator();

  @override
  String? validate(F form, E key, int value) {
    if (value < 0) {
      return loc.minValueError(0);
    }
    return null;
  }
}
