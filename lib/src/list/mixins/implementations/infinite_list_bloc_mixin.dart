import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/mixins/contracts/infinite_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/implementations/list_bloc_data_mixin.dart';
import 'package:blocx/src/list/models/page.dart';
import 'package:blocx/src/list/use_cases/pagination_use_case.dart';

mixin InfiniteListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
    implements InfiniteListBlocContract<T, P> {
  @override
  Future loadNextPage(ListBlocEventLoadNextPage<T> event, Emitter<ListBlocState<T>> emit) async {
    if (hasReachedEnd || isLoadingNextPage) return;
    isLoadingNextPage = true;
    var useCase = loadNextPageUseCase;
    if (useCase != null) return await _fetchNextPage(event, emit);
    throw UnimplementedError("You must either override loadMoreUseCase getter or loadNextPage method");
  }

  Future<void> _fetchNextPage(ListBlocEventLoadNextPage<T> event, Emitter<ListBlocState<T>> emit) async {
    var result = await loadNextPageUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: offset),
    );
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
    on<ListBlocEventLoadNextPage<T>>(loadNextPage);
  }

  @override
  PaginationUseCase<T, P>? get loadNextPageUseCase => null;
}
