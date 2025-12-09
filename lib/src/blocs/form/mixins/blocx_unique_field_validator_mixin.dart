import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart';

mixin BlocxUniqueFieldValidatorMixin<F extends BaseFormEntity<F, E>, P, E extends Enum>
    on BlocxFormBloc<F, P, E> {
  List<E> get uniqueFieldKeys;
  final Map<E, Object> _inFlightTokenByField = {};

  void initUniqueFieldChecker() {
    on<BlocxFormEventCheckUniqueValue<E>>(_checkUniqueValue, transformer: concurrent());
  }

  BlocxBaseUseCase<bool> useCaseIsUniqueValueAvailable(E key, dynamic value);

  Future<void> _checkUniqueValue(
    BlocxFormEventCheckUniqueValue<E> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    emitState(emit);
    final token = Object();
    _inFlightTokenByField[event.key] = token;
    try {
      final result = await useCaseIsUniqueValueAvailable(event.key, event.data).execute();
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
      if (_inFlightTokenByField[event.key] != token) return; // still drop stale
      handleError(BlocXErrorCode.checkingUniqueValue, emit, stacktrace: s);
    } finally {
      if (_inFlightTokenByField[event.key] == token) {
        _inFlightTokenByField.remove(event.key);
      }
    }
  }

  @override
  Set<E> get uniqueKeysBeingChecked => _inFlightTokenByField.keys.toSet();

  String unavailableFormDataMessage(E key) {
    return loc.errorCodeMessage(BlocXErrorCode.valueNotAvailable);
  }
}
