import 'dart:async';
import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/base/readable_error.dart';
import 'package:blocx_core/src/blocs/screen_manager/screen_manager_cubit.dart';
import 'package:blocx_core/src/core/enum_error_codes.dart';
import 'package:meta/meta.dart';

part 'base_bloc_event.dart';
part 'base_bloc_state.dart';

abstract class BaseBloc<E extends BaseEvent, S extends BaseState> extends Bloc<E, S> {
  final ScreenManagerCubit _screenManagerCubit;
  BaseBloc(super.initialState, this._screenManagerCubit);

  void pop() => _screenManagerCubit.pop();
  void displayErrorWidget(ReadableError error) => _screenManagerCubit.displayErrorWidget(error);

  void displayErrorWidgetByErrorCode(BlocXErrorCode errorCode, {Object? error, StackTrace? stackTrace}) =>
      _screenManagerCubit.displayErrorWidgetByErrorCode(errorCode, error: error, st: stackTrace);

  void displayWarningSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(message, BlocXSnackbarType.warning, title: title);

  void displayErrorSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(message, BlocXSnackbarType.error, title: title);

  void displayInfoSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(message, BlocXSnackbarType.info, title: title);

  FutureOr<void> handleError(Object error, Emitter<BaseState> emit, {StackTrace? stacktrace}) {
    dev.log(error.toString());
    if (stacktrace != null) dev.log(stacktrace.toString());
    ReadableError readableError = makeErrorReadable(error, stackTrace: stacktrace);
    if (errorDisplayPolicy == ErrorDisplayPolicy.snackBar) {
      displayErrorSnackbar(readableError.message, title: readableError.title);
    } else {
      displayErrorWidget(readableError);
    }
  }

  ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.snackBar;

  @override
  Future<void> close() async {
    await _screenManagerCubit.close();
    return super.close();
  }

  ScreenManagerCubit get screenManagerCubit => _screenManagerCubit;

  ReadableError makeErrorReadable(Object error, {StackTrace? stackTrace});
}

enum ErrorDisplayPolicy { snackBar, page }
