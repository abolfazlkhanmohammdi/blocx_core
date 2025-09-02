import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';

mixin FormDataMixin<F, P, E extends Enum> on BaseBloc<FormEvent, FormBlocState<F, E>> {
  late F formData;
  P? _payload;
  initData(F formData) {
    this.formData = formData;
    on<FormEventInit<P>>(initForm);
    on<FormEventUpdateData<E>>(updateData);
    on<FormEventSubmit>(submit);
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

  BaseUseCase get submitUseCase;

  F updateFormData(E key, data);

  void emitState(Emitter<FormBlocState<F, E>> emit);

  Future<void> submit(FormEventSubmit event, Emitter<FormBlocState<F, E>> emit) async {
    try {
      emit(FormStateSubmittingForm(formData: formData));
      var result = await submitUseCase.execute();
      if (result.isFailure) {
        displayErrorWidget(StateError("an error occurred in data register check your submit"));
        return;
      }
      await onFormSubmitted(result);
      emit(FormStateFormSubmitted(submittedData: result.data, formData: formData));
      emitState(emit);
    } catch (e, s) {
      displayErrorWidget(e, stackTrace: s);
    }
  }

  Future<void> onFormSubmitted(UseCaseResult result) async {}
  bool get isUpdate => _payload != null;
  P? get payload => _payload;
}
