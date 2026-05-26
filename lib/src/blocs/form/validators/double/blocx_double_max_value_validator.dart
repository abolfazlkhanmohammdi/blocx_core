import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxDoubleMaxValueValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, double> {
  final double max;

  const BlocxDoubleMaxValueValidator(this.max);

  @override
  String? validate(F form, E key, double value) {
    if (value > max) {
      return loc.maxValueError(max);
    }
    return null;
  }
}
