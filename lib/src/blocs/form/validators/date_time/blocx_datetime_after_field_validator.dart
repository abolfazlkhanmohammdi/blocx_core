import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxDateTimeAfterFieldValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, DateTime> {
  final E otherKey;
  final String otherFieldName;

  const BlocxDateTimeAfterFieldValidator(this.otherKey, this.otherFieldName);

  @override
  String? validate(F form, E key, DateTime value) {
    final otherValue = form.getValueByKey(otherKey);

    if (otherValue is! DateTime) return null;

    if (!value.isAfter(otherValue)) {
      return loc.mustBeAfterDateField(otherFieldName);
    }

    return null;
  }
}
