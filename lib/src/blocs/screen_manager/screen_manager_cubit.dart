import 'package:bloc/bloc.dart' show Cubit;
import 'package:blocx_core/src/blocs/base/base_bloc.dart';
import 'package:blocx_core/src/core/enum_error_codes.dart';
import 'package:meta/meta.dart';

part 'screen_manager_cubit_state.dart';

class ScreenManagerCubit extends Cubit<ScreenManagerCubitState> {
  ScreenManagerCubit() : super(const ScreenManagerCubitStateInitial());

  void displayErrorWidget(Object error, [StackTrace? st]) =>
      emit(ScreenManagerCubitStateDisplayErrorPage(error: error, stackTrace: st));

  void displayErrorWidgetByErrorCode(BlocXErrorCode errorCode, {Object? error, StackTrace? st}) =>
      emit(ScreenManagerCubitStateDisplayErrorPageByErrorCode(errorCode, error: error, stackTrace: st));

  void displaySnackbar(String message, BlocXSnackbarType snackbarType, {String? title}) {
    var previous = this.state;
    emit(ScreenManagerCubitStateDisplaySnackbar(message: message, title: title, snackbarType: snackbarType));
    emit(previous);
  }

  void displaySnackbarByErrorCode(BlocXErrorCode errorCode, BlocXSnackbarType snackbarType) {
    var previous = state;
    emit(ScreenManagerCubitStateDisplaySnackbarByErrorCode(errorCode: errorCode, snackbarType: snackbarType));
    emit(previous);
  }

  void pop() {
    emit(ScreenManagerCubitStatePop());
  }
}

enum BlocXSnackbarType { error, info, warning }
