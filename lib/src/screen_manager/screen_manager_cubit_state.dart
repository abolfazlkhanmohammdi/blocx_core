part of 'screen_manager_cubit.dart';

class ScreenManagerBlocState extends BaseBlocState {
  ScreenManagerBlocState({required super.shouldRebuild, required super.shouldListen});
}

class ScreenManagerBlocStateInitial extends ScreenManagerBlocState {
  ScreenManagerBlocStateInitial() : super(shouldRebuild: false, shouldListen: false);
}

class ScreenManagerBlocStateDisplayErrorPage extends ScreenManagerBlocState {
  final Object error;
  final StackTrace? stackTrace;
  ScreenManagerBlocStateDisplayErrorPage({required this.error, this.stackTrace})
    : super(shouldRebuild: true, shouldListen: false);
}

class ScreenManagerBlocStateDisplaySnackbar extends ScreenManagerBlocState {
  final String message;
  final String? title;
  final BlocXSnackbarType snackbarType;
  ScreenManagerBlocStateDisplaySnackbar({required this.snackbarType, required this.message, this.title})
    : super(shouldRebuild: false, shouldListen: true);
}

class ScreenManagerBlocStatePop extends ScreenManagerBlocState {
  ScreenManagerBlocStatePop() : super(shouldListen: true, shouldRebuild: false);
}
