import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
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
    on BlocxBaseBloc<BlocxFormEvent, BlocxFormState<F, E>> {
  /// Current form data.
  late F formData;

  F? _initialFormData;
  bool _hasUserModifiedForm = false;

  /// Baseline form snapshot used to compute [BlocxFormState.isDirty] and
  /// restore values on [BlocxFormEventReset].
  F? get initialFormData => _initialFormData;

  /// Whether any field update has occurred since the last baseline snapshot.
  @protected
  bool get hasUserModifiedForm => _hasUserModifiedForm;

  /// Updates the baseline snapshot (e.g. after prefetch populates defaults).
  @protected
  void syncInitialFormDataBaseline(F baseline) {
    _initialFormData = baseline;
  }

  /// Clears all form errors. Overridden by [BlocxFormErrorsMixin] in [BlocxFormBloc].
  @protected
  void clearAllErrors({ErrorMutationSource? source}) {}

  /// Cancels any in-flight asynchronous unique-field checks.
  ///
  /// Overridden by [BlocxUniqueFieldValidatorMixin].
  @protected
  void cancelPendingUniqueChecks() {}

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
    _initialFormData = formData;
    _hasUserModifiedForm = false;

    on<BlocxFormEventInit<P>>(initForm, transformer: restartable());
    on<BlocxFormEventUpdateData<E>>(updateData, transformer: sequential());
    on<BlocxFormEventSubmit>(submit, transformer: droppable());
    on<BlocxFormEventReset>(resetForm, transformer: sequential());
    on<BlocxFormEventUpdateFormData<P>>(
      handleUpdateFormDataEvent,
      transformer: restartable(),
    );
    on<BlocxFormEventSyncFormData<F>>(
      handleSyncFormDataEvent,
      transformer: sequential(),
    );
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
    _hasUserModifiedForm = false;
    cancelPendingUniqueChecks();

    var updatedData = formData;
    if (_payload != null) {
      updatedData = await applyPayloadToFormData(_payload as P);
    }
    if (emit.isDone) return;
    formData = updatedData;
    _initialFormData = updatedData;

    emit(
      BlocxFormStateApplyInitialDataToForm(
        formData: formData,
        initialData: _initialFormData,
      ),
    );

    if (validateOnInit) {
      await validateForm(formData, forceFullValidation: true);
    }
    if (emit.isDone) return;

    emitState(emit);

    if (isInfoFetcher) {
      add(BlocxFormEventPrefetchRequiredInfo());
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
    _hasUserModifiedForm = true;
    var oldValue = formData.getValueByKey(event.key);
    formData = await updateFormData(event.key, event.data);
    if (isUniqueFieldValidator &&
        (this as BlocxUniqueFieldValidatorMixin<F, P, E>).uniqueFieldKeys
            .contains(event.key)) {
      add(BlocxFormEventCheckUniqueValue(key: event.key, data: event.data));
    }
    emitChangesOnUpdate(event.key, oldValue, event.data, emit);

    emitState(emit);
  }

  void emitChangesOnUpdate(
    E formKey,
    dynamic oldValue,
    dynamic newValue,
    Emitter<BlocxFormState<F, E>> emit,
  ) {
    if (shouldEmitChangesOnUpdate) {
      emit(
        BlocxFormStateFormUpdated(
          step: stepIndex,
          formData: formData,
          initialData: _initialFormData,
          errors: const {},
          fieldsFetchingInfo: const {},
          checkingUniqueFields: const {},
          updatedKey: formKey,
          oldValue: oldValue,
          newValue: newValue,
          isFormValid: checkIsFormValid(),
        ),
      );
    }
  }

  bool checkIsFormValid() {
    return true;
  }

  /// Whether every field update should emit an intermediate update state.
  bool get shouldEmitChangesOnUpdate => false;

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
          initialData: _initialFormData,
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
            initialData: _initialFormData,
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
  Future<bool> doBeforeSubmit(Emitter<BlocxFormState<F, E>> emit) async {
    return true;
  }

  /// Runs after successful form submission.
  ///
  /// Return `false` to prevent [BlocxFormStateFormSubmitted] from being emitted.
  FutureOr<bool> onFormSubmitted(
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

  Future<bool> checkIsFieldValid(F formData, E key) async {
    return true;
  }

  /// Handles replacing the full form data from a new payload.
  ///
  /// This is useful when switching between create and update modes without
  /// recreating the bloc.
  FutureOr<void> handleUpdateFormDataEvent(
    BlocxFormEventUpdateFormData<P> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    _isUpdate = event.isUpdate;
    _hasUserModifiedForm = false;
    cancelPendingUniqueChecks();
    formData = await applyPayloadToFormData(event.payload);
    _initialFormData = formData;

    emit(
      BlocxFormStateApplyInitialDataToForm(
        formData: formData,
        initialData: _initialFormData,
      ),
    );

    await validateForm(formData, forceFullValidation: true);

    emitState(emit);
  }

  /// Handles replacing the full form data from a synced [BlocxFormEventSyncFormData].
  FutureOr<void> handleSyncFormDataEvent(
    BlocxFormEventSyncFormData<F> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    formData = event.formData;

    if (event.applyToControllers) {
      emit(
        BlocxFormStateApplyInitialDataToForm(
          formData: formData,
          initialData: _initialFormData,
        ),
      );
    }

    if (event.validate) {
      await validateForm(formData, forceFullValidation: true);
    }

    emitState(emit);
  }

  /// Handles [BlocxFormEventReset], restoring [formData] back to its baseline
  /// [initialFormData], clearing errors/timers and pending unique checks, and
  /// re-emitting the clean state.
  FutureOr<void> resetForm(
    BlocxFormEventReset event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    formData = _initialFormData ?? formData;
    _hasUserModifiedForm = false;
    cancelPendingUniqueChecks();
    clearAllErrors(source: ErrorMutationSource.clearAllErrors);

    if (event.applyToControllers) {
      emit(
        BlocxFormStateApplyInitialDataToForm(
          formData: formData,
          initialData: _initialFormData,
        ),
      );
    }

    if (event.validate || validateOnInit) {
      await validateForm(formData, forceFullValidation: true);
    }
    if (emit.isDone) return;

    emitState(emit);
  }

  /// The current validation mode.
  FormValidationMode get formValidationMode => FormValidationMode.none;
}
