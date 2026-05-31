import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:meta/meta.dart';

/// Shorthand for the [BlocxUseCaseTask] type used by [BlocxFormDataMixin.submitUseCaseTask].
///
/// Saves consumers from spelling out the full generic each time:
/// ```dart
/// @override
/// FormSubmitTask get submitUseCaseTask => BlocxUseCaseTask(
///   useCase: _createPostUseCase,
///   inputBuilder: () => CreatePostInput(title: formData.title),
/// );
/// ```
typedef FormSubmitTask = BlocxUseCaseTask;

/// Core mixin providing full lifecycle form state management for [BlocxFormBloc].
///
/// Orchestrates form initialisation, payload hydration, field updates,
/// validation, and submission via [BlocxUseCaseTask]. Designed for use with
/// immutable [BlocxBaseFormEntity] subclasses.
///
/// ## Required overrides
///
/// - [submitUseCaseTask]: wires up the use case and input for form submission.
///
/// ## Optional overrides
///
/// | Override | When to use |
/// |---|---|
/// | [applyPayloadToFormData] | Edit/update forms that hydrate fields from a payload |
/// | [validateForm] | Inline field or cross-field validation |
/// | [doBeforeSubmit] | Pre-submit guards (e.g. show confirmation dialog) |
/// | [onFormSubmitted] | Post-submit side-effects (e.g. analytics, navigation) |
/// | [validateOnInit] | Run validation immediately after [BlocxFormEventInit] |
/// | [emitChangesOnUpdate] | Emit an intermediate state on every field change |
///
/// ## Submission flow
///
/// 1. [BlocxFormEventSubmit] dispatched
/// 2. [doBeforeSubmit] called — return `false` to abort
/// 3. [BlocxFormStateSubmittingForm] emitted
/// 4. `submitUseCaseTask.useCase.execute(inputBuilder())` called
/// 5. On failure: [handleError] called, state restored
/// 6. On success: [onFormSubmitted] called, [BlocxFormStateFormSubmitted] emitted
mixin BlocxFormDataMixin<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    on BaseBloc<BlocxFormEvent, BlocxFormState<F, E>> {
  /// Current form state instance.
  late F formData;

  P? _payload;
  bool _isUpdate = false;

  /// The use case task executed on form submission.
  ///
  /// Use the [FormSubmitTask] typedef for brevity:
  /// ```dart
  /// @override
  /// FormSubmitTask get submitUseCaseTask => BlocxUseCaseTask(
  ///   useCase: _createPostUseCase,
  ///   inputBuilder: () => CreatePostInput(title: formData.title),
  /// );
  /// ```
  FormSubmitTask get submitUseCaseTask;

  /// Initialises the mixin and registers event handlers.
  ///
  /// Called automatically by [BlocxFormBloc]. Do not call manually.
  @mustCallSuper
  void initData(F formData) {
    this.formData = formData;
    on<BlocxFormEventInit<P>>(initForm);
    on<BlocxFormEventUpdateData<E>>(updateData);
    on<BlocxFormEventSubmit>(submit);
    on<BlocxFormEventUpdateFormData<P>>(handleUpdateFormDataEvent);
  }

  /// Handles [BlocxFormEventInit].
  ///
  /// Stores the payload, optionally hydrates [formData] via
  /// [applyPayloadToFormData], runs optional validation, and triggers
  /// info-fetching if [isInfoFetcher] is true.
  @mustCallSuper
  FutureOr<void> initForm(BlocxFormEventInit<P> event, Emitter<BlocxFormState<F, E>> emit) async {
    _payload = event.payload;
    _isUpdate = event.payload != null;

    if (_payload != null) {
      formData = await applyPayloadToFormData(_payload as P);
    }

    emit(BlocxFormStateApplyInitialDataToForm(formData: formData));

    if (validateOnInit) validateForm(formData);

    emitState(emit);

    if (isInfoFetcher) add(BlocxFormEventFetchRequiredInfo());
  }

  /// Hydrates [formData] from [payload] for edit/update forms.
  ///
  /// Only called when [BlocxFormEventInit] is dispatched with a non-null
  /// payload. For create-only forms (`P = void`) this is never invoked —
  /// no need to override it.
  ///
  /// ```dart
  /// @override
  /// FutureOr<ProfileForm> applyPayloadToFormData(User payload) =>
  ///     ProfileForm(name: payload.name, bio: payload.bio);
  /// ```
  FutureOr<F> applyPayloadToFormData(P payload) => formData;

  /// Current step index for multi-step forms. Defaults to `0`.
  int get stepIndex => 0;

  /// Handles [BlocxFormEventUpdateData].
  ///
  /// Delegates unique-field checks to [BlocxUniqueFieldValidatorMixin] when
  /// applicable, then updates [formData] via [updateFormData].
  FutureOr<void> updateData(
    BlocxFormEventUpdateData<E> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    if (isUniqueFieldValidator &&
        (this as BlocxUniqueFieldValidatorMixin<F, P, E>).uniqueFieldKeys.contains(event.key)) {
      add(BlocxFormEventCheckUniqueValue(key: event.key, data: event.data));
      return;
    }

    formData = updateFormData(event.key, event.data);

    if (emitChangesOnUpdate) {
      emit(BlocxFormStateFormUpdated(
        step: stepIndex,
        formData: formData,
        errors: {},
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
      ));
    }

    emitState(emit);
  }

  /// Whether field updates emit [BlocxFormStateFormUpdated] before the full state.
  ///
  /// Useful when the UI needs to react to individual keystrokes.
  bool get emitChangesOnUpdate => false;

  /// Whether [BlocxUniqueFieldValidatorMixin] is applied to this bloc.
  bool get isUniqueFieldValidator;

  /// Whether [BlocxFormInfoFetcherMixin] is applied to this bloc.
  bool get isInfoFetcher;

  /// Applies a field update and runs validation.
  ///
  /// Returns the updated [F] instance.
  F updateFormData(E key, dynamic data) {
    final result = formData.updateByKeySafe(key, data);
    validateForm(result, key: key);
    return result;
  }

  /// Emits the current form state. Implemented by [BlocxFormBloc].
  void emitState(Emitter<BlocxFormState<F, E>> emit);

  /// Handles [BlocxFormEventSubmit].
  ///
  /// Runs [doBeforeSubmit], emits [BlocxFormStateSubmittingForm], executes the
  /// use case, then calls [onFormSubmitted] or [handleError] based on the result.
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

  /// Called before submission. Return `false` to abort.
  ///
  /// Use for confirmation dialogs, final validation gates, or any async
  /// pre-flight check.
  Future<bool> doBeforeSubmit(Emitter<BlocxFormState<F, E>> emit) async => true;

  /// Called after a successful submission.
  ///
  /// Return `false` to suppress [BlocxFormStateFormSubmitted] emission
  /// (e.g. when you handle navigation directly here).
  Future<bool> onFormSubmitted(
    Emitter<BlocxFormState<F, E>> emit,
    BlocxUseCaseResult result,
  ) async =>
      true;

  /// Whether the form is in update/edit mode.
  bool get isUpdate => _isUpdate;

  /// The current payload, if any.
  P? get payload => _payload;

  /// Error display strategy. Defaults to snackbar.
  @override
  ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.snackBar;

  /// Whether validation runs immediately after [BlocxFormEventInit].
  bool get validateOnInit => false;

  /// Validation hook. Override to add field or cross-field validation.
  ///
  /// [key] is set when a single field changed; `null` on full-form validation.
  void validateForm(F formData, {E? key}) {}

  /// Handles [BlocxFormEventUpdateFormData] — replaces the entire form.
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
