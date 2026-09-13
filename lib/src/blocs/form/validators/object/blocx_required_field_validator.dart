import 'package:blocx_core/form_bloc.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';

class BlocxRequiredFieldValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, Object?> {
  @override
  String? validate(F form, E key, Object? value) {
    if (value == null) return loc.thisFieldIsRequired;
    return null;
  }
}
