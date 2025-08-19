part of 'infinite_list_bloc.dart';

class InfiniteListBlocEvent extends BaseBlocEvent {}

class InfiniteListBlocEventChangeLoadTopDataStatus extends InfiniteListBlocEvent {
  final bool isLoading;
  InfiniteListBlocEventChangeLoadTopDataStatus(this.isLoading);
}

class InfiniteListBlocEventChangeLoadBottomDataStatus extends InfiniteListBlocEvent {
  final bool isLoading;
  final bool hasReachedEnd;
  InfiniteListBlocEventChangeLoadBottomDataStatus(this.isLoading, this.hasReachedEnd);
}

class InfiniteListBlocEventOnScroll extends InfiniteListBlocEvent {
  final bool isScrollingUp;
  final bool isAtTop;
  final bool isAtBottom;
  final bool isIdle;
  InfiniteListBlocEventOnScroll({
    required this.isIdle,
    required this.isAtBottom,
    required this.isAtTop,
    required this.isScrollingUp,
  });
}

class InfiniteListBlocEventVerticalDragStarted extends InfiniteListBlocEvent {
  final double globalY;
  InfiniteListBlocEventVerticalDragStarted({required this.globalY});
}

class InfiniteListBlocEventVerticalDragUpdated extends InfiniteListBlocEvent {
  final double? globalY;
  InfiniteListBlocEventVerticalDragUpdated({required this.globalY});
}

class InfiniteListBlocEventVerticalDragEnded extends InfiniteListBlocEvent {
  InfiniteListBlocEventVerticalDragEnded();
}

class InfiniteListBlocEventCloseRefresh extends InfiniteListBlocEvent {}
