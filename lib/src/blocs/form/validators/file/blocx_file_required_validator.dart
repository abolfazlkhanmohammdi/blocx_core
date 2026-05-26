import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/blocs/form/validators/file/blocx_file.dart' show BlocxFile;
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxFileRequiredValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, BlocxFile?> {
  @override
  String? validate(F form, E key, BlocxFile? value) {
    if (value == null || value.path.isEmpty) {
      return loc.thisFieldIsRequired;
    }
    return null;
  }
}
