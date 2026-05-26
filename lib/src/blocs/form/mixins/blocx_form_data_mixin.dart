import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:blocx_core/src/core/use_cases/blocx_use_case_result.dart' show BlocxUseCaseResult;
import 'package:blocx_core/src/core/use_cases/blocx_use_case_task.dart';
import 'package:meta/meta.dart';

/// Core mixin providing full lifecycle form state management for [BlocxFormBloc].
///
/// This mixin orchestrates:
/// - form initialization
/// - payload hydration
/// - field updates
/// - validation lifecycle
/// - submission execution via use cases
///
/// It is designed for immutable [BaseFormEntity]-based forms.
///
/// ## Key Responsibilities
/// - Maintain form state (`formData`)
/// - Apply payload transformations
/// - Handle field updates and validation
/// - Execute submission via [BlocxUseCaseTask]
/// - Provide lifecycle hooks for customization
///
/// ## Execution Model
/// Form submission is executed via:
/// `BlocxUseCaseTask -> useCase.execute(input)`
mixin BlocxFormDataMixin<F extends BaseFormEntity<F, E>, P, E extends Enum>
    on BaseBloc<BlocxFormEvent, BlocxFormState<F, E>> {
  /// Current form state instance.
  late F formData;

  /// Optional payload used for initialization or updates.
  P? _payload;

  /// Whether form is in update mode.
  bool _isUpdate = false;

  /// Use case task responsible for submitting the form.
  ///
  /// This replaces direct use-case execution and ensures:
  /// - input is built at runtime
  /// - execution is always type-consistent
  BlocxUseCaseTask get submitUseCaseTask;

  /// Initializes mixin and registers event handlers.
  ///
  /// Must be called inside bloc constructor.
  @mustCallSuper
  void initData(F formData) {
    this.formData = formData;

    on<BlocxFormEventInit<P>>(initForm);
    on<BlocxFormEventUpdateData<E>>(updateData);
    on<BlocxFormEventSubmit>(submit);
    on<BlocxFormEventUpdateFormData<P>>(handleUpdateFormDataEvent);
  }

  /// Handles form initialization.
  ///
  /// Flow:
  /// - stores payload
  /// - sets update mode
  /// - optionally transforms payload into form model
  /// - emits initial state
  /// - triggers validation (if enabled)
  /// - optionally triggers info fetching
  @mustCallSuper
  FutureOr<void> initForm(BlocxFormEventInit<P> event, Emitter<BlocxFormState<F, E>> emit) async {
    _payload = event.payload;
    _isUpdate = event.payload != null;

    if (_payload != null) {
      formData = await applyPayloadToFormData(_payload as P);
    }

    emit(BlocxFormStateApplyInitialDataToForm(formData: formData));

    if (validateOnInit) {
      validateForm(formData);
    }

    emitState(emit);

    if (isInfoFetcher) {
      add(BlocxFormEventFetchRequiredInfo());
    }
  }

  /// Converts payload into form model.
  ///
  /// Must be overridden by implementations that support payload hydration.
  Future<F> applyPayloadToFormData(P payload) async {
    throw UnimplementedError();
  }

  /// Current step index for multi-step forms.
  int get stepIndex => 0;

  /// Handles field-level updates.
  ///
  /// Flow:
  /// - optional unique-field validation check
  /// - updates form model
  /// - optionally emits intermediate state
  FutureOr<void> updateData(BlocxFormEventUpdateData<E> event, Emitter<BlocxFormState<F, E>> emit) async {
    if (isUniqueFieldValidator &&
        (this as BlocxUniqueFieldValidatorMixin<F, P, E>).uniqueFieldKeys.contains(event.key)) {
      add(BlocxFormEventCheckUniqueValue(key: event.key, data: event.data));
      return;
    }

    formData = updateFormData(event.key, event.data);

    if (emitChangesOnUpdate) {
      emit(
        BlocxFormStateFormUpdated(
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

  /// Whether field updates emit intermediate UI states.
  bool get emitChangesOnUpdate => false;

  /// Whether unique field validation is enabled.
  bool get isUniqueFieldValidator;

  /// Whether form fetches additional info on init.
  bool get isInfoFetcher;

  /// Updates form field and triggers validation.
  F updateFormData(E key, dynamic data) {
    final result = formData.updateByKeySafe(key, data);
    validateForm(result, key: key);
    return result;
  }

  /// Emits current state (implemented by bloc).
  void emitState(Emitter<BlocxFormState<F, E>> emit);

  /// Handles form submission.
  ///
  /// FIXED:
  /// Uses BlocxUseCaseTask instead of raw execute()
  Future<void> submit(BlocxFormEventSubmit event, Emitter<BlocxFormState<F, E>> emit) async {
    try {
      final proceed = await doBeforeSubmit(emit);
      if (!proceed) {
        emitState(emit);
        return;
      }

      emit(BlocxFormStateSubmittingForm(formData: formData, step: stepIndex));

      final task = submitUseCaseTask;

      final result = await task.useCase.execute(task.inputBuilder());

      if (result.isFailure) {
        handleError(result.error!, emit);
        emitState(emit);
        return;
      }

      final shouldEmit = await onFormSubmitted(emit, result);

      if (shouldEmit) {
        emit(BlocxFormStateFormSubmitted(submittedData: result.data, formData: formData));
      }

      emitState(emit);
    } catch (e, s) {
      emitState(emit);
      handleError(e, emit, stacktrace: s);
    }
  }

  /// Pre-submit hook.
  Future<bool> doBeforeSubmit(Emitter<BlocxFormState<F, E>> emit) async => true;

  /// Post-submit hook.
  Future<bool> onFormSubmitted(Emitter<BlocxFormState<F, E>> emit, BlocxUseCaseResult result) async => true;

  /// Whether form is currently in update mode.
  bool get isUpdate => _isUpdate;

  /// Current payload (if any).
  P? get payload => _payload;

  /// Error presentation strategy.
  @override
  ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.snackBar;

  /// Whether validation runs on init.
  bool get validateOnInit => false;

  /// Validation hook.
  void validateForm(F formData, {E? key}) {}

  /// Handles external full-form replacement.
  FutureOr<void> handleUpdateFormDataEvent(
    BlocxFormEventUpdateFormData<P> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    _isUpdate = event.isUpdate;
    formData = await applyPayloadToFormData(event.payload);

    emit(BlocxFormStateApplyInitialDataToForm(formData: formData));

    validateForm(formData);
    emitState(emit);
  }

  /// Validation mode strategy.
  FormValidationMode get formValidationMode => FormValidationMode.none;
}
