import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxDoubleRangeValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, double> {
  final double min;
  final double max;

  const BlocxDoubleRangeValidator(this.min, this.max);

  @override
  String? validate(F form, E key, double value) {
    if (value < min || value > max) {
      return loc.numberRangeError(min, max);
    }
    return null;
  }
}
