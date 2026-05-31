import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxPhoneE164Validator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  static final RegExp _e164 = RegExp(r'^\+[1-9]\d{7,14}$');

  @override
  String? validate(F form, E key, String value) {
    final normalized = value.replaceAll(' ', '');

    if (!_e164.hasMatch(normalized)) {
      return loc.invalidPhoneNumber;
    }

    return null;
  }
}
