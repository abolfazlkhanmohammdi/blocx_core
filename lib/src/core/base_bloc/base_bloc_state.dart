part of 'base_bloc.dart';

@immutable
class BaseBlocState {
  final bool shouldRebuild;
  final bool shouldListen;

  const BaseBlocState({required this.shouldRebuild, required this.shouldListen});
}
