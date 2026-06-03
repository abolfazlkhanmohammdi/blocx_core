import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart' show BlocxFormBloc, BlocxFormEventCheckUniqueValue, BlocxFormState;
import 'package:blocx_core/src/core/localizations/loc_provider.dart';
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart';

/// Adds async unique-field validation support to a [BlocxFormBloc].
///
/// This mixin validates configured fields through use cases that return
/// `true` when the value is available and `false` when it is already taken.
///
/// It uses per-field request tokens to ignore stale async responses.
mixin BlocxUniqueFieldValidatorMixin<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    on BlocxFormBloc<F, P, E> {
  /// Fields that require uniqueness validation.
  List<E> get uniqueFieldKeys;

  /// Tracks active validation requests per field.
  final Map<E, Object> _inFlightTokenByField = <E, Object>{};

  /// Returns the use case task responsible for checking uniqueness.
  ///
  /// The returned use case must output `true` when the value is available and
  /// `false` when it is unavailable.
  BlocxUseCaseTask<dynamic, bool>? useCaseIsUniqueValueAvailable(
    E key,
    dynamic value,
  );

  /// Registers the unique-field validation event handler.
  void initUniqueFieldChecker() {
    on<BlocxFormEventCheckUniqueValue<E>>(
      _checkUniqueValue,
      transformer: concurrent(),
    );
  }

  /// Handles async uniqueness validation for one field.
  ///
  /// Stale responses are ignored by comparing the request token stored for the
  /// field with the token created for this request.
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

      final result = await task.execute();

      if (_inFlightTokenByField[event.key] != token) return;

      _inFlightTokenByField.remove(event.key);

      emitState(emit);

      if (result.isFailure) {
        handleError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }

      final isAvailable = result.data ?? false;
      final unavailableMessage = unavailableFormDataMessage(event.key);

      final bool stateChanged;

      if (isAvailable) {
        formData = await updateFormData(event.key, event.data);
        stateChanged = clearFieldError(
          event.key,
          errorMessage: unavailableMessage,
        );
      } else {
        stateChanged = setFieldError(event.key, unavailableMessage);
      }

      if (stateChanged) {
        emitState(emit);
      }
    } catch (e, s) {
      if (_inFlightTokenByField[event.key] != token) return;

      handleError(BlocXErrorCode.checkingUniqueValue, emit, stacktrace: s);
    } finally {
      if (_inFlightTokenByField[event.key] == token) {
        _inFlightTokenByField.remove(event.key);
      }
    }
  }

  /// Fields currently being validated for uniqueness.
  @override
  Set<E> get uniqueKeysBeingChecked => _inFlightTokenByField.keys.toSet();

  /// Default error message for unavailable values.
  ///
  /// Override this for field-specific or domain-specific messages.
  String unavailableFormDataMessage(E key) {
    return loc.errorCodeMessage(BlocXErrorCode.valueNotAvailable);
  }
}
