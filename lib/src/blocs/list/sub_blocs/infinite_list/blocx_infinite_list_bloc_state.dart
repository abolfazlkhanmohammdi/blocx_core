part of 'blocx_infinite_list_bloc.dart';

class BlocxInfiniteListState extends BaseState {
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isIdle;
  final bool isScrollingUp;
  final bool isAtTop;
  final bool isAtBottom;
  final bool hasReachedEnd;
  final double swipeRefreshHeight;
  BlocxInfiniteListState({
    required super.shouldRebuild,
    required super.shouldListen,
    required this.isLoadingMore,
    required this.isRefreshing,
    required this.isIdle,
    required this.isScrollingUp,
    required this.isAtTop,
    required this.swipeRefreshHeight,
    required this.isAtBottom,
    required this.hasReachedEnd,
  });
}

class BlocxInfiniteListStateInitial extends BlocxInfiniteListState {
  BlocxInfiniteListStateInitial()
      : super(
          shouldRebuild: false,
          shouldListen: false,
          isIdle: true,
          isLoadingMore: false,
          isRefreshing: false,
          isScrollingUp: false,
          isAtTop: true,
          isAtBottom: false,
          swipeRefreshHeight: 0,
          hasReachedEnd: false,
        );
}

class BlocxInfiniteListStateLoaded extends BlocxInfiniteListState {
  BlocxInfiniteListStateLoaded({
    required super.isAtTop,
    required super.isIdle,
    required super.isLoadingMore,
    required super.isRefreshing,
    required super.isScrollingUp,
    required super.isAtBottom,
    required super.swipeRefreshHeight,
    required super.hasReachedEnd,
  }) : super(shouldListen: false, shouldRebuild: true);
}

class BlocxInfiniteListStateRefresh extends BlocxInfiniteListState {
  BlocxInfiniteListStateRefresh({
    required super.isAtTop,
    required super.isIdle,
    required super.isLoadingMore,
    required super.isRefreshing,
    required super.isScrollingUp,
    required super.isAtBottom,
    required super.swipeRefreshHeight,
    required super.hasReachedEnd,
  }) : super(shouldListen: true, shouldRebuild: true);
}
