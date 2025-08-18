part of 'list_bloc.dart';

sealed class ListBlocState<T extends ListEntity<T>> extends BaseBlocState {
  final List<T> list;
  final bool hasReachedEnd;
  final bool isLoadingNextPage;
  final bool isRefreshing;
  final bool isSearching;
  ListBlocState({
    required this.list,
    required super.shouldListen,
    required super.shouldRebuild,
    this.hasReachedEnd = false,
    this.isLoadingNextPage = false,
    this.isRefreshing = false,
    this.isSearching = false,
  });
}

class ListBlocStateLoading<T extends ListEntity<T>> extends ListBlocState<T> {
  ListBlocStateLoading() : super(list: const [], shouldRebuild: true, shouldListen: false);
}

class ListBlocStateLoaded<T extends ListEntity<T>> extends ListBlocState<T> {
  ListBlocStateLoaded({
    required super.list,
    required super.hasReachedEnd,
    required super.isLoadingNextPage,
    required super.isRefreshing,
  }) : super(shouldRebuild: true, shouldListen: false);
}
