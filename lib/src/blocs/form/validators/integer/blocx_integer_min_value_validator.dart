import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;

class BlocxIntegerMinValueValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, int> {
  final int min;

  const BlocxIntegerMinValueValidator(this.min);

  @override
  String? validate(F form, E key, int value) {
    if (value < min) {
      return loc.minValueError(min);
    }
    return null;
  }
}
