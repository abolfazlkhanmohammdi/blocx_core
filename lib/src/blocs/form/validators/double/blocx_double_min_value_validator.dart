import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxDoubleMinValueValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, double> {
  final double min;

  const BlocxDoubleMinValueValidator(this.min);

  @override
  String? validate(F form, E key, double value) {
    if (value < min) {
      return loc.minValueError(min);
    }
    return null;
  }
}
