import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/form/bloc/form_bloc.dart';
import 'package:blocx_core/src/core/enum_error_codes.dart';

mixin UniqueFieldValidatorMixin<F, P, E extends Enum> on FormBloc<F, P, E> {
  List<E> get uniqueFieldKeys;
  final Map<E, Object> _inFlightTokenByField = {};

  void initUniqueFieldChecker() {
    on<FormEventCheckUniqueValue<E>>(_checkUniqueValue, transformer: concurrent());
  }

  BaseUseCase<bool> useCaseIsUniqueValueAvailable(E key, dynamic value);

  void handleError(BlocXErrorCode errorCode, Object? error, StackTrace? stackTrace) {}

  Future<void> _checkUniqueValue(
    FormEventCheckUniqueValue<E> event,
    Emitter<FormBlocState<F, E>> emit,
  ) async {
    final token = Object();
    _inFlightTokenByField[event.key] = token;

    try {
      final result = await useCaseIsUniqueValueAvailable(event.key, event.data).execute();
      if (_inFlightTokenByField[event.key] != token) return;
      if (result.isFailure) {
        handleError(BlocXErrorCode.checkingUniqueValue, result.error, result.stackTrace);
        return;
      }

      final isAvailable = result.data ?? false;
      bool stateChanged;
      if (isAvailable) {
        formData = updateFormData(event.key, event.data);
        stateChanged = clearFieldError(event.key,errorCode: BlocXErrorCode.valueNotAvailable);
      } else {
        stateChanged = setFieldError(event.key, BlocXErrorCode.valueNotAvailable);
      }
      if(stateChanged)emitState(emit);
    } catch (e, s) {
      if (_inFlightTokenByField[event.key] != token) return; // still drop stale
      handleError(BlocXErrorCode.checkingUniqueValue, e, s);
    } finally {
      if (_inFlightTokenByField[event.key] == token) {
        _inFlightTokenByField.remove(event.key);
      }
    }
  }
}
