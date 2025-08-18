import 'package:bloc/bloc.dart' show Cubit;
import 'package:blocx/src/core/base_bloc/base_bloc.dart';
part 'screen_manager_cubit_state.dart';

class ScreenManagerCubit extends Cubit<ScreenManagerBlocState> {
  ScreenManagerCubit() : super(ScreenManagerBlocStateInitial());

  void displayErrorPage(Object error, [StackTrace? st]) =>
      emit(ScreenManagerBlocStateDisplayErrorPage(error: error, stackTrace: st));

  void displaySnackbar(String message, BlocXSnackbarType snackbarType, {String? title}) {
    emit(ScreenManagerBlocStateDisplaySnackbar(message: message, title: title, snackbarType: snackbarType));
    emit(ScreenManagerBlocStateInitial());
  }

  void pop() {
    emit(ScreenManagerBlocStatePop());
    emit(ScreenManagerBlocStateInitial());
  }
}

enum BlocXSnackbarType { error, info, warning }
