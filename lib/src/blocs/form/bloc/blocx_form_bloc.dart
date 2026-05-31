import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart'
    show
        BlocxFormSteppedMixin,
        BlocxUniqueFieldValidatorMixin,
        BlocxFormErrorsMixin,
        BlocxFormInfoFetcherMixin;
import 'package:blocx_core/src/blocs/form/mixins/blocx_form_data_mixin.dart';
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
/// 2. Extend [BlocxFormBloc] with those types plus a payload type [P]
///    (use `void` when there is no initial payload).
/// 3. Provide [submitUseCaseTask] — the only required override.
///
/// ```dart
/// class CreatePostBloc extends BlocxFormBloc<PostForm, void, PostField> {
///   CreatePostBloc() : super(PostForm.empty());
///
///   @override
///   BlocxUseCaseTask get submitUseCaseTask => BlocxUseCaseTask(
///     useCase: _createPostUseCase,
///     inputBuilder: () => CreatePostInput(title: formData.title),
///   );
/// }
/// ```
///
/// ## Optional features (applied via mixins)
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
    with BlocxFormDataMixin<F, P, E>, BlocxFormErrorsMixin<F, P, E> {
  /// Creates the bloc with the blank [formData] as the initial state.
  ///
  /// No [ScreenManagerCubit] needed — it is managed by [BaseBloc].
  BlocxFormBloc(F formData) : super(BlocxFormStateInitial(formData: formData)) {
    initData(formData);
    initErrors();
    if (isStepped) (this as BlocxFormSteppedMixin<F, P, E>).initStepped();
    if (isUniqueFieldValidator) (this as BlocxUniqueFieldValidatorMixin<F, P, E>).initUniqueFieldChecker();
    if (isInfoFetcher) (this as BlocxFormInfoFetcherMixin<F, P, E>).initInfoFetcher();
  }

  /// Whether this bloc has [BlocxFormSteppedMixin] applied.
  bool get isStepped => this is BlocxFormSteppedMixin<F, P, E>;

  @override
  bool get isUniqueFieldValidator => this is BlocxUniqueFieldValidatorMixin<F, P, E>;

  @override
  bool get isInfoFetcher => this is BlocxFormInfoFetcherMixin<F, P, E>;

  /// The set of fields currently waiting on a remote info fetch.
  ///
  /// Override when using [BlocxFormInfoFetcherMixin] to track
  /// per-field loading indicators.
  Set<E> get fieldsFetchingInfo => {};

  /// The set of fields whose uniqueness is currently being checked remotely.
  ///
  /// Override when using [BlocxUniqueFieldValidatorMixin].
  Set<E> get uniqueKeysBeingChecked => {};

  @override
  void emitState(Emitter<BlocxFormState<F, E>> emit) {
    emit(BlocxFormStateLoaded(
      formData: formData,
      step: stepIndex,
      errors: errors,
      fieldsFetchingInfo: fieldsFetchingInfo,
      checkingUniqueFields: uniqueKeysBeingChecked,
      comesFromPreviousStep: comesFromPreviousStep,
    ));
  }

  /// Whether the current step was reached by going backward.
  ///
  /// Override to return `true` when handling [BlocxFormEventPreviousStep]
  /// so the UI can animate in the correct direction.
  bool get comesFromPreviousStep => false;
}
