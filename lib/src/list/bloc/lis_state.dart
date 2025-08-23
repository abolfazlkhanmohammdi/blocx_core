part of 'list_bloc.dart';

sealed class ListState<T extends BaseEntity> extends BaseState {
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

  dynamic get additionalInfo => null;
}

class ListStateLoading<T extends BaseEntity> extends ListState<T> {
  ListStateLoading() : super(list: const [], shouldRebuild: true, shouldListen: false);
}

class ListStateLoaded<T extends BaseEntity> extends ListState<T> {
  ListStateLoaded({
    required super.list,
    required super.hasReachedEnd,
    required super.isLoadingNextPage,
    required super.isRefreshing,
    required super.isSearching,
  }) : super(shouldRebuild: true, shouldListen: false);
}

class ListStateScrollToItem<T extends BaseEntity> extends ListState<T> {
  final T item;
  final int index;
  ListStateScrollToItem({required this.item, required this.index})
    : super(shouldRebuild: false, shouldListen: true, list: []);
}
