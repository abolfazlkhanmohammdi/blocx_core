import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/base/base_bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/form_bloc.dart';
import 'package:blocx_core/src/blocs/form/mixins/unique_field_validator_mixin.dart';

mixin FormDataMixin<F, P, E extends Enum> on BaseBloc<FormEvent, FormBlocState<F, E>> {
  late F formData;
  P? _payload;
  initData(F formData) {
    this.formData = formData;
    on<FormEventInit<P>>(initForm);
    on<FormEventUpdateData<E>>(updateData);
  }

  FutureOr<void> initForm(FormEventInit<P> event, Emitter<FormBlocState<F, E>> emit) {
    _payload = event.payload;
    if (_payload != null) formData = applyPayloadToFormData(_payload as P);
    emit(FormStateApplyInitialDataToForm(formData: formData));
    emitState(emit);
    if (isInfoFetcher) add(FormEventFetchRequiredInfo());
  }

  F applyPayloadToFormData(P payload) {
    throw UnimplementedError();
  }

  int get stepIndex => 0;

  FutureOr<void> updateData(FormEventUpdateData<E> event, Emitter<FormBlocState<F, E>> emit) async {
    if (isUniqueFieldValidator &&
        (this as UniqueFieldValidatorMixin<F, P, E>).uniqueFieldKeys.contains(event.key)) {
      add(FormEventCheckUniqueValue(key: event.key, data: event.data));
      return;
    }
    formData = updateFormData(event.key, event.data);
    emitState(emit);
  }

  bool get isUniqueFieldValidator;

  bool get isInfoFetcher;

  F updateFormData(E key, data);

  void emitState(Emitter<FormBlocState<F, E>> emit);
}
