import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/mixins/contracts/refreshable_list_bloc_contract.dart';

mixin RefreshableListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
    implements RefreshableListBlocContract<T, P> {
  @override
  Future refreshPage(ListEventRefreshData<T> event, Emitter<ListState<T>> emit) async {
    if (isRefreshing) return;
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

  @override
  initRefresh() {
    on<ListEventRefreshData<T>>(refreshPage);
  }

  @override
  PaginationUseCase<T, P>? get refreshPageUseCase => null;
}
