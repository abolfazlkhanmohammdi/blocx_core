import 'dart:async';

import 'package:blocx_core/form_bloc.dart';
import 'package:meta/meta.dart';

abstract class BlocxFormValidator<F extends BaseFormEntity<F, E>, E extends Enum> {
  FutureOr<List<TimedErrorMessage>> validateField(F formData, E key);

  Future<Map<E, List<TimedErrorMessage>>> validateForm(F formData) async {
    Map<E, List<TimedErrorMessage>> errors = {};
    for (var key in formKeys()) {
      errors[key] = await validateField(formData, key);
    }
    return errors;
  }

  @visibleForOverriding
  List<BlocxFieldValidator> getValidatorsByKey(F formData, E key);
  @visibleForOverriding
  List<E> formKeys();
}
