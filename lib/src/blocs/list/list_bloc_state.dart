part of 'list_bloc.dart';

sealed class ListBlocState<T extends ListEntity<T>> extends BaseBlocState {
  final List<T> list;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  final bool isRefreshing;

  ListBlocState({
    required this.list,
    this.hasReachedEnd = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });
}

class ListBlocStateLoading<T extends ListEntity<T>> extends ListBlocState<T> {
  ListBlocStateLoading() : super(list: const []);
}

class ListBlocStateLoaded<T extends ListEntity<T>> extends ListBlocState<T> {
  ListBlocStateLoaded({
    required super.list,
    required super.hasReachedEnd,
    required super.isLoadingMore,
    required super.isRefreshing,
  });
}
