import 'package:blocx_core/form_bloc.dart' show BlocxFieldValidator;
import 'package:blocx_core/src/core/localizations/loc_provider.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart' show BaseFormEntity;

class BlocxListMaxItemsValidator<F extends BaseFormEntity<F, E>, E extends Enum, T>
    extends BlocxFieldValidator<F, E, List<T>> {
  final int max;

  const BlocxListMaxItemsValidator(this.max);

  @override
  String? validate(F form, E key, List<T> value) {
    if (value.length > max) {
      return loc.maxNumberOfItemsCanBeSelected(max);
    }
    return null;
  }
}
