import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;

class BlocxStringExactLengthValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  final int length;

  const BlocxStringExactLengthValidator(this.length);

  @override
  String? validate(F form, E key, String value) {
    if (value.length != length) {
      return loc.exactLengthFieldError(length);
    }
    return null;
  }
}
