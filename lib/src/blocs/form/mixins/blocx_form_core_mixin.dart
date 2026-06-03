import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:meta/meta.dart';

/// Core mixin providing full lifecycle form state management for [BlocxFormBloc].
///
/// Orchestrates form initialisation, payload hydration, field updates,
/// validation, and submission via [BlocxUseCaseTask].
///
/// The mixin is designed for immutable [BlocxBaseFormEntity] implementations,
/// where every field update returns a new form entity instance.
mixin BlocxFormCoreMixin<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    on BaseBloc<BlocxFormEvent, BlocxFormState<F, E>> {
  /// Current form data.
  late F formData;

  P? _payload;
  bool _isUpdate = false;

  /// The use case task executed when the form is submitted.
  ///
  /// Concrete form blocs can override this with a more specific task type.
  ///
  /// Example:
  ///
  /// ```dart
  /// @override
  /// BlocxUseCaseTask<CreateCategoryInput, CategoryResponse>
  ///     get submitUseCaseTask {
  ///   return BlocxUseCaseTask<CreateCategoryInput, CategoryResponse>(
  ///     useCase: createCategoryUseCase,
  ///     inputBuilder: () => CreateCategoryInput(
  ///       code: formData.code,
  ///       name: formData.name,
  ///     ),
  ///   );
  /// }
  /// ```
  BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask;

  /// Initialises form data and registers form data event handlers.
  ///
  /// This method is called by [BlocxFormBloc].
  @mustCallSuper
  void initData(F formData) {
    this.formData = formData;

    on<BlocxFormEventInit<P>>(initForm);
    on<BlocxFormEventUpdateData<E>>(updateData);
    on<BlocxFormEventSubmit>(submit);
    on<BlocxFormEventUpdateFormData<P>>(handleUpdateFormDataEvent);
  }

  /// Handles the initial form event.
  ///
  /// Stores the optional payload, applies it to [formData] when present,
  /// emits the initial form data to the UI, optionally validates the form,
  /// and starts required info fetching when supported.
  @mustCallSuper
  FutureOr<void> initForm(
    BlocxFormEventInit<P> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    _payload = event.payload;
    _isUpdate = event.payload != null;

    if (_payload != null) {
      formData = await applyPayloadToFormData(_payload as P);
    }

    emit(BlocxFormStateApplyInitialDataToForm(formData: formData));

    if (validateOnInit) {
      await validateForm(formData, forceFullValidation: true);
    }

    emitState(emit);

    if (isInfoFetcher) {
      add(BlocxFormEventFetchRequiredInfo());
    }
  }

  /// Converts an update payload into form data.
  ///
  /// Override this for edit/update forms.
  FutureOr<F> applyPayloadToFormData(P payload) => formData;

  /// Current form step index.
  ///
  /// Defaults to `0` for non-stepped forms.
  int get stepIndex => 0;

  /// Handles a single field update event.
  ///
  /// If the updated field is configured as a unique field, the update is
  /// delegated to [BlocxUniqueFieldValidatorMixin]. Otherwise, [formData] is
  /// updated and validation is run.
  FutureOr<void> updateData(
    BlocxFormEventUpdateData<E> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    if (isUniqueFieldValidator &&
        (this as BlocxUniqueFieldValidatorMixin<F, P, E>).uniqueFieldKeys.contains(event.key)) {
      add(
        BlocxFormEventCheckUniqueValue(
          key: event.key,
          data: event.data,
        ),
      );
      return;
    }

    formData = await updateFormData(event.key, event.data);

    if (emitChangesOnUpdate) {
      emit(
        BlocxFormStateFormUpdated(
          step: stepIndex,
          formData: formData,
          errors: const {},
          fieldsFetchingInfo: const {},
          checkingUniqueFields: const {},
        ),
      );
    }

    emitState(emit);
  }

  /// Whether every field update should emit an intermediate update state.
  bool get emitChangesOnUpdate => false;

  /// Whether this bloc uses [BlocxUniqueFieldValidatorMixin].
  bool get isUniqueFieldValidator;

  /// Whether this bloc uses [BlocxFormInfoFetcherMixin].
  bool get isInfoFetcher;

  /// Updates the form data by field key and runs validation.
  ///
  /// Returns the updated form data after validation has completed.
  Future<F> updateFormData(E key, dynamic data) async {
    final result = formData.updateByKeySafe(key, data);
    await validateForm(result, key: key);
    return result;
  }

  /// Emits the current loaded form state.
  void emitState(Emitter<BlocxFormState<F, E>> emit);

  /// Handles form submission.
  ///
  /// The form is fully validated before any submit hook or use case is run.
  /// If validation fails, or if any required async field work is still pending,
  /// submission is blocked.
  Future<void> submit(
    BlocxFormEventSubmit event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    try {
      await validateForm(formData, forceFullValidation: true);

      if (!isFormSubmittable) {
        emitState(emit);
        return;
      }

      final proceed = await doBeforeSubmit(emit);
      if (!proceed) {
        emitState(emit);
        return;
      }

      emit(
        BlocxFormStateSubmittingForm(
          formData: formData,
          step: stepIndex,
        ),
      );

      final result = await submitUseCaseTask.execute();

      if (result.isFailure) {
        handleError(result.error!, emit);
        emitState(emit);
        return;
      }

      final shouldEmit = await onFormSubmitted(emit, result);
      if (shouldEmit) {
        emit(
          BlocxFormStateFormSubmitted(
            submittedData: result.data,
            formData: formData,
          ),
        );
      }

      emitState(emit);
    } catch (e, s) {
      emitState(emit);
      handleError(e, emit, stacktrace: s);
    }
  }

  /// Whether the form can currently be submitted.
  ///
  /// The base implementation allows submission. [BlocxFormBloc] should override
  /// this to block submission when validation errors exist, field info is still
  /// loading, or unique-field checks are still running.
  bool get isFormSubmittable => true;

  /// Runs before the submit use case.
  ///
  /// Return `false` to stop submission.
  Future<bool> doBeforeSubmit(
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    return true;
  }

  /// Runs after successful form submission.
  ///
  /// Return `false` to prevent [BlocxFormStateFormSubmitted] from being emitted.
  Future<bool> onFormSubmitted(
    Emitter<BlocxFormState<F, E>> emit,
    BlocxUseCaseResult<Object?> result,
  ) async {
    return true;
  }

  /// Whether the form is currently in update/edit mode.
  bool get isUpdate => _isUpdate;

  /// The current update payload, if any.
  P? get payload => _payload;

  /// The default error display policy for this form bloc.
  @override
  ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.snackBar;

  /// Whether the form should validate immediately after initialisation.
  bool get validateOnInit => false;

  /// Validates the form.
  ///
  /// [key] is provided when a single field changed.
  ///
  /// When [forceFullValidation] is `true`, implementations should validate the
  /// whole form according to [formValidationMode].
  FutureOr<void> validateForm(
    F formData, {
    E? key,
    bool forceFullValidation = false,
  }) {}

  /// Handles replacing the full form data from a new payload.
  ///
  /// This is useful when switching between create and update modes without
  /// recreating the bloc.
  FutureOr<void> handleUpdateFormDataEvent(
    BlocxFormEventUpdateFormData<P> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    _isUpdate = event.isUpdate;
    formData = await applyPayloadToFormData(event.payload);

    emit(BlocxFormStateApplyInitialDataToForm(formData: formData));

    await validateForm(formData, forceFullValidation: true);

    emitState(emit);
  }

  /// The current validation mode.
  FormValidationMode get formValidationMode => FormValidationMode.none;
}
