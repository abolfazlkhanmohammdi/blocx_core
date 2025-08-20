part of 'infinite_list_bloc.dart';

class InfiniteListEvent extends BaseEvent {}

class InfiniteListEventChangeLoadTopDataStatus extends InfiniteListEvent {
  final bool isLoading;
  InfiniteListEventChangeLoadTopDataStatus(this.isLoading);
}

class InfiniteListEventChangeLoadBottomDataStatus extends InfiniteListEvent {
  final bool isLoading;
  final bool hasReachedEnd;
  InfiniteListEventChangeLoadBottomDataStatus(this.isLoading, this.hasReachedEnd);
}

class InfiniteListEventOnScroll extends InfiniteListEvent {
  final bool isScrollingUp;
  final bool isAtTop;
  final bool isAtBottom;
  final bool isIdle;
  InfiniteListEventOnScroll({
    required this.isIdle,
    required this.isAtBottom,
    required this.isAtTop,
    required this.isScrollingUp,
  });
}

class InfiniteListEventVerticalDragStarted extends InfiniteListEvent {
  final double globalY;
  InfiniteListEventVerticalDragStarted({required this.globalY});
}

class InfiniteListEventVerticalDragUpdated extends InfiniteListEvent {
  final double? globalY;
  InfiniteListEventVerticalDragUpdated({required this.globalY});
}

class InfiniteListEventVerticalDragEnded extends InfiniteListEvent {
  InfiniteListEventVerticalDragEnded();
}

class InfiniteListEventCloseRefresh extends InfiniteListEvent {}
