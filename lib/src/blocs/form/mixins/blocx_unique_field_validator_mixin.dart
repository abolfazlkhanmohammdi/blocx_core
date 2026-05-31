import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart' show BlocxFormEventCheckUniqueValue, BlocxFormBloc, BlocxFormState;
import 'package:blocx_core/src/core/localizations/loc_provider.dart';
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart';
import 'package:blocx_core/src/core/use_cases/blocx_use_case_task.dart';

/// Mixin that adds **unique field validation support** to a [BlocxFormBloc].
///
/// This mixin is responsible for:
/// - validating field uniqueness via async use cases
/// - preventing race conditions via per-field in-flight tokens
/// - updating form state based on validation result
/// - managing concurrent validation requests safely
///
/// ## Concurrency model
/// Uses `bloc_concurrency.concurrent()` so multiple field validations
/// can run in parallel without blocking each other.
///
/// Stale responses are ignored using a per-field token system.
///
/// ## Use case contract
/// Each field validation must be provided as a [BlocxUseCaseTask],
/// ensuring that input is built at execution time.
///
/// Type parameters:
/// - [F]: form entity type
/// - [P]: payload type
/// - [E]: enum field key type
mixin BlocxUniqueFieldValidatorMixin<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    on BlocxFormBloc<F, P, E> {
  /// Fields that require uniqueness validation.
  List<E> get uniqueFieldKeys;

  /// Tracks active validation requests per field.
  /// Used to prevent race conditions and stale updates.
  final Map<E, Object> _inFlightTokenByField = {};

  /// Use case task responsible for checking uniqueness.
  ///
  /// Must return a boolean indicating whether the value is available.
  BlocxUseCaseTask<BlocxBaseUseCase<dynamic, bool>, dynamic>? useCaseIsUniqueValueAvailable(
    E key,
    dynamic value,
  );

  /// Initializes event handler for unique field validation.
  ///
  /// Uses `concurrent()` transformer to allow parallel validation.
  void initUniqueFieldChecker() {
    on<BlocxFormEventCheckUniqueValue<E>>(_checkUniqueValue, transformer: concurrent());
  }

  /// Handles async uniqueness validation for a field.
  ///
  /// Execution flow:
  /// 1. Emit intermediate state
  /// 2. Register request token
  /// 3. Execute use case
  /// 4. Ignore stale responses
  /// 5. Apply validation result to form state
  Future<void> _checkUniqueValue(
    BlocxFormEventCheckUniqueValue<E> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    emitState(emit);

    final token = Object();
    _inFlightTokenByField[event.key] = token;

    try {
      final task = useCaseIsUniqueValueAvailable(event.key, event.data);
      if (task == null) return;
      final result = await task.useCase.execute(task.inputBuilder());

      if (_inFlightTokenByField[event.key] != token) return;

      _inFlightTokenByField.remove(event.key);

      emitState(emit);

      if (result.isFailure) {
        handleError(result.error!, emit, stacktrace: StackTrace.current);
        return;
      }

      final isAvailable = result.data ?? false;

      bool stateChanged;

      if (isAvailable) {
        formData = updateFormData(event.key, event.data);

        stateChanged = clearFieldError(event.key, errorMessage: unavailableFormDataMessage(event.key));
      } else {
        stateChanged = setFieldError(event.key, unavailableFormDataMessage(event.key));
      }

      if (stateChanged) emitState(emit);
    } catch (e, s) {
      if (_inFlightTokenByField[event.key] != token) return;

      handleError(BlocXErrorCode.checkingUniqueValue, emit, stacktrace: s);
    } finally {
      if (_inFlightTokenByField[event.key] == token) {
        _inFlightTokenByField.remove(event.key);
      }
    }
  }

  /// Currently validating fields (used by UI for loading indicators).
  @override
  Set<E> get uniqueKeysBeingChecked => _inFlightTokenByField.keys.toSet();

  /// Default error message for unavailable values.
  ///
  /// Can be overridden for domain-specific localization.
  String unavailableFormDataMessage(E key) {
    return loc.errorCodeMessage(BlocXErrorCode.valueNotAvailable);
  }
}
