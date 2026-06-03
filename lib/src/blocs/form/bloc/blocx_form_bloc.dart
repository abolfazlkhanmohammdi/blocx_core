import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart'
    show
        BlocxFormErrorsMixin,
        BlocxFormInfoFetcherMixin,
        BlocxFormSteppedMixin,
        BlocxUniqueFieldValidatorMixin;
import 'package:blocx_core/src/blocs/form/mixins/blocx_form_core_mixin.dart';
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart';

part 'blocx_form_event.dart';
part 'blocx_form_state.dart';

/// Base class for all form blocs in the blocx ecosystem.
///
/// Manages the full lifecycle of an immutable form backed by a
/// [BlocxBaseFormEntity] subclass. Wires up validation, submission,
/// optional stepped navigation, unique-field checking, and initial
/// info-fetching automatically based on which mixins are applied.
///
/// ## Minimal setup
///
/// 1. Define a field enum [E] and a [BlocxBaseFormEntity] subclass [F].
/// 2. Extend [BlocxFormBloc] with those types plus a payload type [P].
///    Use `void` when there is no initial payload.
/// 3. Provide [submitUseCaseTask], the required submit task.
///
/// ```dart
/// class CreatePostBloc extends BlocxFormBloc<PostForm, void, PostField> {
///   CreatePostBloc() : super(PostForm.empty());
///
///   @override
///   BlocxUseCaseTask<CreatePostInput, PostResponse> get submitUseCaseTask {
///     return BlocxUseCaseTask<CreatePostInput, PostResponse>(
///       useCase: _createPostUseCase,
///       inputBuilder: () => CreatePostInput(title: formData.title),
///     );
///   }
/// }
/// ```
///
/// ## Optional features
///
/// | Mixin | Behaviour unlocked |
/// |---|---|
/// | [BlocxFormSteppedMixin] | Multi-step form navigation |
/// | [BlocxUniqueFieldValidatorMixin] | Async per-field uniqueness checks |
/// | [BlocxFormInfoFetcherMixin] | Fetches remote data before the form renders |
///
/// ## Update / edit forms
///
/// When editing an existing entity, pass the entity as the payload [P] and
/// override [applyPayloadToFormData] to hydrate [F] from it. Dispatch
/// [BlocxFormEventInit] with the payload to trigger hydration.
///
/// ## Type parameters
///
/// - [F]: The immutable form entity. Must extend [BlocxBaseFormEntity].
/// - [P]: The optional payload type used for edit-mode hydration. Use `void`
///   for create-only forms.
/// - [E]: The enum identifying each field. Used as the key for updates,
///   validation errors, and info-fetching.
abstract class BlocxFormBloc<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    extends BaseBloc<BlocxFormEvent, BlocxFormState<F, E>>
    with BlocxFormCoreMixin<F, P, E>, BlocxFormErrorsMixin<F, P, E> {
  /// Creates the bloc with the blank [formData] as the initial state.
  ///
  /// No [ScreenManagerCubit] is needed. It is managed by [BaseBloc].
  BlocxFormBloc(F formData) : super(BlocxFormStateInitial(formData: formData)) {
    initData(formData);
    initErrors();

    if (isStepped) {
      (this as BlocxFormSteppedMixin<F, P, E>).initStepped();
    }

    if (isUniqueFieldValidator) {
      (this as BlocxUniqueFieldValidatorMixin<F, P, E>).initUniqueFieldChecker();
    }

    if (isInfoFetcher) {
      (this as BlocxFormInfoFetcherMixin<F, P, E>).initInfoFetcher();
    }
  }

  /// Whether this bloc has [BlocxFormSteppedMixin] applied.
  bool get isStepped => this is BlocxFormSteppedMixin<F, P, E>;

  /// Whether this bloc has [BlocxUniqueFieldValidatorMixin] applied.
  @override
  bool get isUniqueFieldValidator => this is BlocxUniqueFieldValidatorMixin<F, P, E>;

  /// Whether this bloc has [BlocxFormInfoFetcherMixin] applied.
  @override
  bool get isInfoFetcher => this is BlocxFormInfoFetcherMixin<F, P, E>;

  /// The set of fields currently waiting on a remote info fetch.
  ///
  /// Override when using [BlocxFormInfoFetcherMixin] to track per-field loading
  /// indicators.
  Set<E> get fieldsFetchingInfo => <E>{};

  /// The set of fields whose uniqueness is currently being checked remotely.
  ///
  /// Override when using [BlocxUniqueFieldValidatorMixin].
  Set<E> get uniqueKeysBeingChecked => <E>{};

  /// Whether the current form can execute the submit use case.
  ///
  /// Submission is blocked when validation errors exist, required field info is
  /// still loading, or unique-field validation is still running.
  @override
  bool get isFormSubmittable {
    return errors.isEmpty && fieldsFetchingInfo.isEmpty && uniqueKeysBeingChecked.isEmpty;
  }

  @override
  void emitState(Emitter<BlocxFormState<F, E>> emit) {
    emit(
      BlocxFormStateLoaded(
        formData: formData,
        step: stepIndex,
        errors: errors,
        fieldsFetchingInfo: fieldsFetchingInfo,
        checkingUniqueFields: uniqueKeysBeingChecked,
        comesFromPreviousStep: comesFromPreviousStep,
      ),
    );
  }

  /// Whether the current step was reached by going backward.
  ///
  /// Override to return `true` when handling [BlocxFormEventPreviousStep] so
  /// the UI can animate in the correct direction.
  bool get comesFromPreviousStep => false;

  /// Closes the bloc and cancels all pending timed-error timers.
  @override
  Future<void> close() async {
    clearTimers();
    return super.close();
  }
}
