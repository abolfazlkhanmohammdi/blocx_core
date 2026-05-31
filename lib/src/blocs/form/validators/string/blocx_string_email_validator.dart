import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;

class BlocxStringEmailValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  static final _regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  @override
  String? validate(F form, E key, String value) {
    if (!_regex.hasMatch(value)) {
      return loc.invalidEmail;
    }
    return null;
  }
}
