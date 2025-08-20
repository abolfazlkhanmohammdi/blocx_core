import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/mixins/contracts/infinite_list_bloc_contract.dart';

mixin InfiniteListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
    implements InfiniteListBlocContract<T, P> {
  @override
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

  @override
  void initInfiniteList() {
    on<ListEventLoadNextPage<T>>(loadNextPage);
  }

  @override
  PaginationUseCase<T, P>? get loadNextPageUseCase => null;
}
