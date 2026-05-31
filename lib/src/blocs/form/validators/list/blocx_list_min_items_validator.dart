import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;

class BlocxListMinItemsValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum, T>
    extends BlocxFieldValidator<F, E, List<T>> {
  final int min;

  const BlocxListMinItemsValidator(this.min);

  @override
  String? validate(F form, E key, List<T> value) {
    if (value.length < min) {
      return loc.minNumberOfItemsMustBeSelected(min);
    }
    return null;
  }
}
