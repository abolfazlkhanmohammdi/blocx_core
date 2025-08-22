import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';

mixin RefreshableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  Future refreshPage(ListEventRefreshData<T> event, Emitter<ListState<T>> emit) async {
    if (isRefreshing) return;
    if (isSearchable && (this as SearchableListBlocMixin<T, P>).searchText.isNotEmpty) {
      add(ListEventSearchRefresh());
      return;
    }
    if (refreshPageUseCase != null) return await _fetchRefreshPage(event, emit);
    throw UnimplementedError("You must either override refreshUseCase getter or refreshPage method");
  }

  Future<void> _fetchRefreshPage(ListEventRefreshData<T> event, Emitter<ListState<T>> emit) async {
    isRefreshing = true;
    emitState(emit);
    var result = await refreshPageUseCase!.execute();
    isRefreshing = false;
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    clearList();
    await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.refresh);
    emitState(emit);
  }

  initRefresh() {
    on<ListEventRefreshData<T>>(refreshPage);
  }

  PaginationUseCase<T, P>? get refreshPageUseCase => null;
}
