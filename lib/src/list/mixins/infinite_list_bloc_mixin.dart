import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';

mixin InfiniteListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  Future loadNextPage(ListEventLoadNextPage<T> event, Emitter<ListState<T>> emit) async {
    if (isSearchable && (this as SearchableListBlocMixin<T, P>).searchText.isNotEmpty) {
      add(ListEventSearchNextPage());
      return;
    }
    if (hasReachedEnd || isLoadingNextPage) return;
    isLoadingNextPage = true;
    var useCase = loadNextPageUseCase;
    if (useCase != null) return await _fetchNextPage(event, emit);
    throw UnimplementedError("You must either override loadMoreUseCase getter or loadNextPage method");
  }

  Future<void> _fetchNextPage(ListEventLoadNextPage<T> event, Emitter<ListState<T>> emit) async {
    var result = await loadNextPageUseCase!.execute();
    isLoadingNextPage = false;
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.nextPage);
    emitState(emit);
  }

  void initInfiniteList() {
    on<ListEventLoadNextPage<T>>(loadNextPage);
  }

  PaginationUseCase<T, P>? get loadNextPageUseCase => null;
  InfiniteListBloc get infiniteListBloc;
}
