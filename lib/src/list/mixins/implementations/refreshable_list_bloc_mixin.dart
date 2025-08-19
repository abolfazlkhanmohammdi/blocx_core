import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/mixins/contracts/refreshable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/implementations/list_bloc_data_mixin.dart';
import 'package:blocx/src/list/models/page.dart';
import 'package:blocx/src/list/use_cases/pagination_use_case.dart';

mixin RefreshableListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
    implements RefreshableListBlocContract<T, P> {
  @override
  Future refreshPage(ListBlocEventRefreshData<T> event, Emitter<ListBlocState<T>> emit) async {
    if (isRefreshing) return;
    if (refreshPageUseCase != null) return await _fetchRefreshPage(event, emit);
    throw UnimplementedError("You must either override refreshUseCase getter or refreshPage method");
  }

  Future<void> _fetchRefreshPage(ListBlocEventRefreshData<T> event, Emitter<ListBlocState<T>> emit) async {
    isRefreshing = true;
    emitState(emit);
    var result = await refreshPageUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: 0),
    );
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
    on<ListBlocEventRefreshData<T>>(refreshPage);
  }

  @override
  PaginationUseCase<T, P>? get refreshPageUseCase => null;
}
