part of 'base_bloc.dart';

class BaseBlocState {
  final bool shouldRebuild;
  final bool shouldListen;

  BaseBlocState({required this.shouldRebuild, required this.shouldListen});
}

class BaseBlocStateDisplaySnackbar extends BaseBlocState {
  final String title;
  final String? description;
  BaseBlocStateDisplaySnackbar({required this.title, required this.description})
    : super(shouldListen: true, shouldRebuild: false);
}

class BaseBlocStateError extends BaseBlocState {
  final Object error;
  final StackTrace? stackTrace;
  BaseBlocStateError({required this.error, required this.stackTrace})
    : super(shouldRebuild: true, shouldListen: false);
}
