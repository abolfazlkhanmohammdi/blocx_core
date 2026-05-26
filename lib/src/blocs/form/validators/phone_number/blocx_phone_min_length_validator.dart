import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxPhoneMinLengthValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  final int min;

  const BlocxPhoneMinLengthValidator(this.min);

  @override
  String? validate(F form, E key, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length < min) {
      return loc.minLengthError(min);
    }

    return null;
  }
}
