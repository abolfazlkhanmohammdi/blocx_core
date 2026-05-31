import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;

class BlocxStringMatchValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxFieldValidator<F, E, String> {
  final E otherKey;
  final String? errorMessage;

  const BlocxStringMatchValidator(this.otherKey, {this.errorMessage});

  @override
  String? validate(F form, E key, String value) {
    final otherValue = form.getValueByKey(otherKey) as String?;

    if (value != otherValue) {
      return errorMessage ?? loc.valuesDoNotMatch;
    }

    return null;
  }
}
