import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;

class BlocxStringAlphanumericValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  static final _regex = RegExp(r'^[a-zA-Z0-9]+$');

  @override
  String? validate(F form, E key, String value) {
    if (!_regex.hasMatch(value)) {
      return loc.onlyAlphanumericAllowed;
    }
    return null;
  }
}
