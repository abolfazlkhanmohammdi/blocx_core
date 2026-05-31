import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxPhoneMaxLengthValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  final int max;

  const BlocxPhoneMaxLengthValidator(this.max);

  @override
  String? validate(F form, E key, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > max) {
      return loc.maxLengthError(max);
    }

    return null;
  }
}
