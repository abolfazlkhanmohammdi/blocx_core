part of 'blocx_infinite_list_bloc.dart';

class BlocxInfiniteListEvent extends BaseEvent {}

class BlocxInfiniteListEventChangeLoadTopDataStatus extends BlocxInfiniteListEvent {
  final bool isLoading;
  BlocxInfiniteListEventChangeLoadTopDataStatus(this.isLoading);
}

class BlocxInfiniteListEventChangeLoadBottomDataStatus extends BlocxInfiniteListEvent {
  final bool isLoading;
  final bool hasReachedEnd;
  BlocxInfiniteListEventChangeLoadBottomDataStatus(this.isLoading, this.hasReachedEnd);
}

class BlocxInfiniteListEventOnScroll extends BlocxInfiniteListEvent {
  final bool isScrollingUp;
  final bool isAtTop;
  final bool isAtBottom;
  final bool isIdle;
  BlocxInfiniteListEventOnScroll({
    required this.isIdle,
    required this.isAtBottom,
    required this.isAtTop,
    required this.isScrollingUp,
  });
}

class BlocxInfiniteListEventVerticalDragStarted extends BlocxInfiniteListEvent {
  final double globalY;
  BlocxInfiniteListEventVerticalDragStarted({required this.globalY});
}

class BlocxInfiniteListEventVerticalDragUpdated extends BlocxInfiniteListEvent {
  final double? globalY;
  BlocxInfiniteListEventVerticalDragUpdated({required this.globalY});
}

class BlocxInfiniteListEventVerticalDragEnded extends BlocxInfiniteListEvent {
  BlocxInfiniteListEventVerticalDragEnded();
}

class BlocxInfiniteListEventCloseRefresh extends BlocxInfiniteListEvent {}

class BlocxInfiniteListEventSetReachedEnd extends BlocxInfiniteListEvent {
  final bool hasReachedEnd;
  BlocxInfiniteListEventSetReachedEnd({required this.hasReachedEnd});
}
