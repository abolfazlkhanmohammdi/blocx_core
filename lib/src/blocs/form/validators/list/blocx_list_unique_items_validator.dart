import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart' show loc;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart' show BlocxBaseFormEntity;

class BlocxListUniqueItemsValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum, T>
    extends BlocxFieldValidator<F, E, List<T>> {
  const BlocxListUniqueItemsValidator();

  @override
  String? validate(F form, E key, List<T> value) {
    final set = value.toSet();

    if (set.length != value.length) {
      return loc.selectedItemsMustBeUnique;
    }

    return null;
  }
}
