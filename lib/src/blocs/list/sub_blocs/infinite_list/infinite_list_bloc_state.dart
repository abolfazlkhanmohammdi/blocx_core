part of 'infinite_list_bloc.dart';

class InfiniteListState extends BaseState {
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isIdle;
  final bool isScrollingUp;
  final bool isAtTop;
  final bool isAtBottom;
  final bool hasReachedEnd;
  final double swipeRefreshHeight;
  InfiniteListState({
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

class InfiniteListStateInitial extends InfiniteListState {
  InfiniteListStateInitial()
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

class InfiniteListStateLoaded extends InfiniteListState {
  InfiniteListStateLoaded({
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

class InfiniteListStateRefresh extends InfiniteListState {
  InfiniteListStateRefresh({
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
