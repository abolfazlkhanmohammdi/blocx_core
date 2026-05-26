import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxDateTimeBeforeFieldValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, DateTime> {
  final E otherKey;
  final String otherFieldName;
  const BlocxDateTimeBeforeFieldValidator(this.otherKey, this.otherFieldName);

  @override
  String? validate(F form, E key, DateTime value) {
    final otherValue = form.getValueByKey(otherKey);

    if (otherValue is! DateTime) return null;

    if (!value.isBefore(otherValue)) {
      return loc.mustBeBeforeDateField(otherFieldName);
    }

    return null;
  }
}
