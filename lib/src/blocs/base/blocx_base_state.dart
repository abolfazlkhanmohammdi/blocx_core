part of 'blocx_base_bloc.dart';

@immutable
class BlocxBaseState {
  final bool shouldRebuild;
  final bool shouldListen;

  const BlocxBaseState({required this.shouldRebuild, required this.shouldListen});
}
