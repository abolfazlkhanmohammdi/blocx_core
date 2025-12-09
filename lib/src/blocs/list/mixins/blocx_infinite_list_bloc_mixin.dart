import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';

mixin BlocxInfiniteListBlocMixin<T extends BaseEntity, P> on BlocxListBloc<T, P> {
  Future loadNextPage(BlocxListEventLoadNextPage<T> event, Emitter<BlocxListState<T>> emit) async {
    if (isSearchable && (this as BlocxSearchableListBlocMixin<T, P>).searchText.isNotEmpty) {
      add(BlocxListEventSearchNextPage());
      return;
    }
    if (hasReachedEnd || isLoadingNextPage) return;
    isLoadingNextPage = true;
    var useCase = loadNextPageUseCase;
    if (useCase != null) return await _fetchNextPage(event, emit);
    throw UnimplementedError("You must either override loadMoreUseCase getter or loadNextPage method");
  }

  Future<void> _fetchNextPage(BlocxListEventLoadNextPage<T> event, Emitter<BlocxListState<T>> emit) async {
    var result = await loadNextPageUseCase!.execute();
    isLoadingNextPage = false;
    if (result.isFailure) {
      await handleError(result.error!, emit, stacktrace: result.stackTrace);
      infiniteListBloc.add(BlocxInfiniteListEventChangeLoadBottomDataStatus(false, hasReachedEnd));
      return;
    }
    await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.nextPage);
    emitState(emit);
  }

  void initInfiniteList() {
    on<BlocxListEventLoadNextPage<T>>(loadNextPage);
  }

  BlocxPaginationUseCase<T>? get loadNextPageUseCase => null;
}
