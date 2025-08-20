part of 'base_bloc.dart';

@immutable
class BaseState {
  final bool shouldRebuild;
  final bool shouldListen;

  const BaseState({required this.shouldRebuild, required this.shouldListen});
}
