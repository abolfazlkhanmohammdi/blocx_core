import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxIntegerGreaterThanFieldValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, int> {
  final E otherKey;

  const BlocxIntegerGreaterThanFieldValidator(this.otherKey);

  @override
  String? validate(F form, E key, int value) {
    final otherValue = form.getValueByKey(otherKey);

    if (otherValue is! int) return null;

    if (value <= otherValue) {
      return loc.greaterThanFieldError(otherValue);
    }

    return null;
  }
}
