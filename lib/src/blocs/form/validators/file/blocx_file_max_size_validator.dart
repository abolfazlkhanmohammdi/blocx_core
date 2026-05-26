import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/blocs/form/validators/file/blocx_file.dart' show BlocxFile;
import 'package:blocx_core/src/core/localizations/loc_provider.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;

class BlocxFileMaxSizeValidator<F extends BaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, BlocxFile> {
  final int maxBytes;

  const BlocxFileMaxSizeValidator(this.maxBytes);

  @override
  String? validate(F form, E key, BlocxFile value) {
    if (value.sizeBytes > maxBytes) {
      return loc.fileSizeMustBeSmallerThan(_format(maxBytes));
    }
    return null;
  }

  String _format(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;

    if (bytes >= mb) return "${(bytes / mb).toStringAsFixed(1)} MB";
    if (bytes >= kb) return "${(bytes / kb).toStringAsFixed(1)} KB";
    return "$bytes bytes";
  }
}
