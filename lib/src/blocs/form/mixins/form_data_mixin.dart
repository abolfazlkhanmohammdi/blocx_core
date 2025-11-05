import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:meta/meta.dart';

mixin FormDataMixin<F, P, E extends Enum> on BaseBloc<FormEvent, FormBlocState<F, E>> {
  late F formData;
  P? _payload;
  bool _isUpdate = false;
  @mustCallSuper
  void initData(F formData) {
    this.formData = formData;
    on<FormEventInit<P>>(initForm);
    on<FormEventUpdateData<E>>(updateData);
    on<FormEventSubmit>(submit);
    on<FormEventUpdateFormData<P>>(handleUpdateFormDataEvent);
  }

  FutureOr<void> initForm(FormEventInit<P> event, Emitter<FormBlocState<F, E>> emit) async {
    _payload = event.payload;
    _isUpdate = event.payload != null;
    if (_payload != null) formData = await applyPayloadToFormData(_payload as P);
    emit(FormStateApplyInitialDataToForm(formData: formData));
    if (validateOnInit) validateForm(formData);
    emitState(emit);
    if (isInfoFetcher) add(FormEventFetchRequiredInfo());
  }

  Future<F> applyPayloadToFormData(P payload) async {
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
    if (emitChangesOnUpdate) {
      emit(
        FormStateFormUpdated(
          step: stepIndex,
          formData: formData,
          errors: {},
          fieldsFetchingInfo: {},
          checkingUniqueFields: {},
        ),
      );
    }
    validateForm(formData);
    emitState(emit);
  }

  bool get emitChangesOnUpdate => false;

  bool get isUniqueFieldValidator;

  bool get isInfoFetcher;

  BaseUseCase get submitUseCase;

  F updateFormData(E key, data);

  void emitState(Emitter<FormBlocState<F, E>> emit);

  Future<void> submit(FormEventSubmit event, Emitter<FormBlocState<F, E>> emit) async {
    try {
      bool proceed = await doBeforeSubmit(emit);
      if (!proceed) {
        emitState(emit);
        return;
      }
      emit(FormStateSubmittingForm(formData: formData, step: stepIndex));
      var result = await submitUseCase.execute();
      if (result.isFailure) {
        handleError(result.error!, emit);
        emitState(emit);
        return;
      }
      bool shouldEmitSubmittedState = await onFormSubmitted(emit, result);
      if (shouldEmitSubmittedState) {
        emit(FormStateFormSubmitted(submittedData: result.data, formData: formData));
      }
      emitState(emit);
    } catch (e, s) {
      emitState(emit);
      handleError(e, emit, stacktrace: s);
    }
  }

  Future<bool> doBeforeSubmit(Emitter<FormBlocState<F, E>> emit) async {
    return true;
  }

  Future<bool> onFormSubmitted(Emitter<FormBlocState<F, E>> emit, UseCaseResult result) async {
    return true;
  }

  bool get isUpdate => _isUpdate;
  P? get payload => _payload;

  @override
  ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.snackBar;

  bool get validateOnInit => false;

  void validateForm(F formData) {}

  FutureOr<void> handleUpdateFormDataEvent(
    FormEventUpdateFormData<P> event,
    Emitter<FormBlocState<F, E>> emit,
  ) async {
    _isUpdate = event.isUpdate;
    formData = await applyPayloadToFormData(event.payload);
    emit(FormStateApplyInitialDataToForm(formData: formData));
    validateForm(formData);
    emitState(emit);
  }
}
