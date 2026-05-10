import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxIntegerLessThanFieldValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, int> {
  final E otherKey;
  final String otherFieldName;
  const BlocxIntegerLessThanFieldValidator(this.otherKey, this.otherFieldName);

  @override
  String? validate(F form, E key, int value) {
    final otherValue = form.getValueByKey(otherKey);

    if (otherValue is! int) return null;

    if (value >= otherValue) {
      return loc.lessThanFieldError(otherValue);
    }

    return null;
  }
}
