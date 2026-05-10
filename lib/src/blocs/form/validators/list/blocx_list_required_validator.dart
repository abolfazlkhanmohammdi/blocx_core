import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxListRequiredValidator<F extends BaseFormEntity<F, E>, E extends Enum, T>
    extends BlocxFieldValidator<F, E, List<T>?> {
  @override
  String? validate(F form, E key, List<T>? value) {
    if (value == null || value.isEmpty) {
      return loc.thisFieldIsRequired;
    }
    return null;
  }
}
