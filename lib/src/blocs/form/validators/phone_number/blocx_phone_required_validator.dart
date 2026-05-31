import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxPhoneRequiredValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String?> {
  @override
  String? validate(F form, E key, String? value) {
    if (value == null || value.trim().isEmpty) {
      return loc.thisFieldIsRequired;
    }
    return null;
  }
}
