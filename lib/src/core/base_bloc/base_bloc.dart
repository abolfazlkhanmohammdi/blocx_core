import 'package:bloc/bloc.dart';
import 'package:blocx/src/screen_manager/screen_manager_cubit.dart';

part 'base_bloc_event.dart';
part 'base_bloc_state.dart';

class BaseBloc<E extends BaseBlocEvent, S extends BaseBlocState> extends Bloc<E, S> {
  final ScreenManagerCubit _screenManagerCubit;
  BaseBloc(super.initialState, this._screenManagerCubit);

  void pop() => _screenManagerCubit.pop();
  void displayError(Object error, {StackTrace? stackTrace}) =>
      _screenManagerCubit.displayErrorPage(error, stackTrace);

  void displayWarningSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(message, BlocXSnackbarType.warning, title: title);

  void displayErrorSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(message, BlocXSnackbarType.error, title: title);

  void displayInfoSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(message, BlocXSnackbarType.info, title: title);

  @override
  Future<void> close() async {
    await _screenManagerCubit.close();
    return super.close();
  }
}
