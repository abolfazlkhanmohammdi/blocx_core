import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart';
import 'package:meta/meta.dart';

/// A mixin that provides form data management for a [FormBloc].
///
/// This mixin handles initializing form data, updating fields, applying
/// payloads, submission, and triggering validation. It is intended to be
/// used with `FormBloc` subclasses that manage forms backed by
/// immutable `BaseFormEntity`s.
mixin FormDataMixin<F extends BaseFormEntity<F, E>, P, E extends Enum>
    on BaseBloc<FormEvent, FormBlocState<F, E>> {
  /// The current state of the form data.
  late F formData;

  /// Optional payload used for initializing or updating the form.
  P? _payload;

  /// Indicates whether the form is in update mode (vs create mode).
  bool _isUpdate = false;

  /// Initializes the mixin with [formData] and sets up event handlers.
  ///
  /// Must be called in the bloc constructor.
  @mustCallSuper
  void initData(F formData) {
    this.formData = formData;

    on<FormEventInit<P>>(initForm);
    on<FormEventUpdateData<E>>(updateData);
    on<FormEventSubmit>(submit);
    on<FormEventUpdateFormData<P>>(handleUpdateFormDataEvent);
  }

  /// Handles form initialization when receiving a [FormEventInit] event.
  ///
  /// - Applies an optional payload.
  /// - Emits an initial state with the form data.
  /// - Optionally triggers validation on init if [validateOnInit] is true.
  /// - Triggers fetching of required info if the bloc is an info fetcher.
  FutureOr<void> initForm(FormEventInit<P> event, Emitter<FormBlocState<F, E>> emit) async {
    _payload = event.payload;
    _isUpdate = event.payload != null;

    if (_payload != null) {
      formData = await applyPayloadToFormData(_payload as P);
    }

    emit(FormStateApplyInitialDataToForm(formData: formData));

    if (validateOnInit) validateForm(formData);

    emitState(emit);

    if (isInfoFetcher) add(FormEventFetchRequiredInfo());
  }

  /// Applies a payload to the form data.
  ///
  /// Subclasses should override this method to transform [payload] into
  /// a new [formData] instance.
  ///
  /// Throws [UnimplementedError] by default.
  Future<F> applyPayloadToFormData(P payload) async {
    throw UnimplementedError();
  }

  /// The current step index of a stepped form.
  int get stepIndex => 0;

  /// Handles updates to individual fields when receiving a [FormEventUpdateData] event.
  ///
  /// - Checks for unique field validation if applicable.
  /// - Updates the form data via [updateFormData].
  /// - Emits an intermediate state if [emitChangesOnUpdate] is true.
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

    emitState(emit);
  }

  /// Whether to emit intermediate states when updating a field.
  bool get emitChangesOnUpdate => false;

  /// Whether the form implements unique field validation.
  bool get isUniqueFieldValidator;

  /// Whether the form fetches additional info on init.
  bool get isInfoFetcher;

  /// The use case responsible for submitting the form.
  BaseUseCase get submitUseCase;

  /// Updates the form data for a single field.
  ///
  /// Validates the field before updating.
  F updateFormData(E key, data) {
    validateForm(formData, key: key);
    return formData.updateByKeySafe(key, data);
  }

  /// Emits the current form state. Subclasses must implement this to
  /// define how state is emitted.
  void emitState(Emitter<FormBlocState<F, E>> emit);

  /// Handles form submission when receiving a [FormEventSubmit] event.
  ///
  /// - Runs [doBeforeSubmit] to check if submission should proceed.
  /// - Executes [submitUseCase].
  /// - Emits success or error states accordingly.
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

  /// Hook called before form submission.
  ///
  /// Return `false` to cancel submission.
  Future<bool> doBeforeSubmit(Emitter<FormBlocState<F, E>> emit) async => true;

  /// Hook called after form submission.
  ///
  /// Return `true` to emit a submitted state, or `false` to skip it.
  Future<bool> onFormSubmitted(Emitter<FormBlocState<F, E>> emit, UseCaseResult result) async => true;

  /// Whether the form is in update mode.
  bool get isUpdate => _isUpdate;

  /// Optional payload used to initialize or update the form.
  P? get payload => _payload;

  /// Defines how validation errors should be displayed.
  @override
  ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.snackBar;

  /// Whether to validate the form on init.
  bool get validateOnInit => false;

  /// Validates the form or a single field.
  ///
  /// Override this method to implement custom validation logic.
  /// - [formData] is the current form data.
  /// - [key] is optional; if provided, only the corresponding field is validated.
  void validateForm(F formData, {E? key}) {}

  /// Handles updates when receiving a [FormEventUpdateFormData] event.
  ///
  /// - Applies the payload to the form data.
  /// - Updates `_isUpdate` flag.
  /// - Emits an initial state with the updated data.
  /// - Triggers validation.
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
