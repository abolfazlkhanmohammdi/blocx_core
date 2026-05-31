import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;

class BlocxStringUrlValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  @override
  String? validate(F form, E key, String value) {
    final uri = Uri.tryParse(value);

    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return loc.invalidUrl;
    }

    return null;
  }
}
