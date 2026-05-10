import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;

class BlocxStringMaxLengthValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  final int max;

  const BlocxStringMaxLengthValidator(this.max);

  @override
  String? validate(F form, E key, String value) {
    if (value.length > max) {
      return loc.maxLengthError(max);
    }
    return null;
  }
}
