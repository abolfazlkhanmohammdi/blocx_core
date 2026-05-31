import 'dart:async' show FutureOr;

import 'package:blocx_core/form_bloc.dart' show BlocxBaseFormEntity;

abstract class BlocxFieldValidator<F extends BlocxBaseFormEntity<F, E>, E extends Enum, T> {
  const BlocxFieldValidator();
  FutureOr<String?> validate(F form, E key, T value);
}
