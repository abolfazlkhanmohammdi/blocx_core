part of 'infinite_list_bloc.dart';

class InfiniteListBlocState extends BaseBlocState {
  final bool isLoadingTop;
  final bool isLoadingBottom;
  final bool isRefreshing;
  final bool isIdle;
  final bool isScrollingUp;
  final bool isAtTop;
  final bool isAtBottom;
  final bool hasReachedEnd;
  final double swipeRefreshHeight;
  InfiniteListBlocState({
    required super.shouldRebuild,
    required super.shouldListen,
    required this.isLoadingTop,
    required this.isLoadingBottom,
    required this.isRefreshing,
    required this.isIdle,
    required this.isScrollingUp,
    required this.isAtTop,
    required this.swipeRefreshHeight,
    required this.isAtBottom,
    required this.hasReachedEnd,
  });
}

class InfiniteListBlocStateInitial extends InfiniteListBlocState {
  InfiniteListBlocStateInitial()
    : super(
        shouldRebuild: false,
        shouldListen: false,
        isIdle: true,
        isLoadingBottom: false,
        isLoadingTop: false,
        isRefreshing: false,
        isScrollingUp: false,
        isAtTop: true,
        isAtBottom: false,
        swipeRefreshHeight: 0,
        hasReachedEnd: false,
      );
}

class InfiniteListBlocStateLoaded extends InfiniteListBlocState {
  InfiniteListBlocStateLoaded({
    required super.isAtTop,
    required super.isIdle,
    required super.isLoadingBottom,
    required super.isLoadingTop,
    required super.isRefreshing,
    required super.isScrollingUp,
    required super.isAtBottom,
    required super.swipeRefreshHeight,
    required super.hasReachedEnd,
  }) : super(shouldListen: false, shouldRebuild: true);
}

class InfiniteListBlocStateRefresh extends InfiniteListBlocState {
  InfiniteListBlocStateRefresh({
    required super.isAtTop,
    required super.isIdle,
    required super.isLoadingBottom,
    required super.isLoadingTop,
    required super.isRefreshing,
    required super.isScrollingUp,
    required super.isAtBottom,
    required super.swipeRefreshHeight,
    required super.hasReachedEnd,
  }) : super(shouldListen: true, shouldRebuild: true);
}
