import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;

class BlocxStringLengthRangeValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  final int min;
  final int max;

  const BlocxStringLengthRangeValidator(this.min, this.max);

  @override
  String? validate(F form, E key, String value) {
    if (value.length < min || value.length > max) {
      return loc.lengthRangeError(min, max);
    }
    return null;
  }
}
