import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;

class BlocxIntegerRequiredValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, int?> {
  @override
  String? validate(F form, E key, int? value) {
    if (value == null) {
      return loc.thisFieldIsRequired;
    }
    return null;
  }
}
