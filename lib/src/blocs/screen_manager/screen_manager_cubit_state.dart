part of 'screen_manager_cubit.dart';

@immutable
class ScreenManagerCubitState extends BaseState {
  const ScreenManagerCubitState({required super.shouldRebuild, required super.shouldListen});
}

@immutable
class ScreenManagerCubitStateInitial extends ScreenManagerCubitState {
  const ScreenManagerCubitStateInitial() : super(shouldRebuild: false, shouldListen: false);
}

@immutable
class ScreenManagerCubitStateDisplayErrorPage extends ScreenManagerCubitState {
  final Object error;
  final StackTrace? stackTrace;
  const ScreenManagerCubitStateDisplayErrorPage({required this.error, this.stackTrace})
    : super(shouldRebuild: true, shouldListen: false);
}

@immutable
class ScreenManagerCubitStateDisplaySnackbar extends ScreenManagerCubitState {
  final String message;
  final String? title;
  final BlocXSnackbarType snackbarType;
  const ScreenManagerCubitStateDisplaySnackbar({
    required this.snackbarType,
    required this.message,
    this.title,
  }) : super(shouldRebuild: false, shouldListen: true);
}

@immutable
class ScreenManagerCubitStatePop extends ScreenManagerCubitState {
  const ScreenManagerCubitStatePop() : super(shouldListen: true, shouldRebuild: false);
}
