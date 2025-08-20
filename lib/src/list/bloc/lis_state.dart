part of 'list_bloc.dart';

sealed class ListState<T extends ListEntity<T>> extends BaseState {
  final List<T> list;
  final bool hasReachedEnd;
  final bool isLoadingNextPage;
  final bool isRefreshing;
  final bool isSearching;
  ListState({
    required this.list,
    required super.shouldListen,
    required super.shouldRebuild,
    this.hasReachedEnd = false,
    this.isLoadingNextPage = false,
    this.isRefreshing = false,
    this.isSearching = false,
  });
}

class ListStateLoading<T extends ListEntity<T>> extends ListState<T> {
  ListStateLoading() : super(list: const [], shouldRebuild: true, shouldListen: false);
}

class ListStateLoaded<T extends ListEntity<T>> extends ListState<T> {
  ListStateLoaded({
    required super.list,
    required super.hasReachedEnd,
    required super.isLoadingNextPage,
    required super.isRefreshing,
  }) : super(shouldRebuild: true, shouldListen: false);
}
