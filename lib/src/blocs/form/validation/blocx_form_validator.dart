import 'package:blocx_core/form_bloc.dart';
import 'package:meta/meta.dart';

abstract class BlocxFormValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum> {
  List<TimedErrorMessage> validateField(F formData, E key) {
    var fieldValidators = getValidatorsByKey(formData, key);
    var value = formData.getFormattedValueByKey(key) ?? formData.getValueByKey(key);
    final errors = <TimedErrorMessage>[];
    for (var validator in fieldValidators) {
      var error = validator.validate(formData, key, value);
      if (error != null) {
        errors.add(TimedErrorMessage(error: error));
        break;
      }
    }
    return errors;
  }

  Map<E, List<TimedErrorMessage>> validateForm(F formData) {
    Map<E, List<TimedErrorMessage>> errors = {};
    for (var key in formKeys()) {
      errors[key] = validateField(formData, key);
    }
    return errors;
  }

  @visibleForOverriding
  List<BlocxFieldValidator<F, E, dynamic>> getValidatorsByKey(F formData, E key);
  @visibleForOverriding
  List<E> formKeys();
}
