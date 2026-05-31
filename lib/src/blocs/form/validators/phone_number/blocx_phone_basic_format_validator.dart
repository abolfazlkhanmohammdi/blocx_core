import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxPhoneBasicFormatValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  @override
  String? validate(F form, E key, String value) {
    final normalized = value.replaceAll(' ', '');

    if (!_phoneRegex.hasMatch(normalized)) {
      return loc.invalidPhoneNumber;
    }

    return null;
  }

  RegExp get _phoneRegex => RegExp(r'^\+?[0-9]{7,15}$');
}
