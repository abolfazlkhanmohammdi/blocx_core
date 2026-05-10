import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxListBloc,
        BlocxSearchableListBlocMixin,
        BlocxListEventRefreshData,
        BlocxListState,
        BlocxSelectableListBlocMixin,
        BlocxListEventClearSelection,
        BlocxListEventSearchRefresh,
        BlocxInfiniteListEventCloseRefresh,
        DataInsertSource;
import 'package:blocx_core/src/blocs/list/models/page.dart' show BlocxPage;

import '../use_cases/blocx_pagination_use_case.dart' show BlocxPaginationInput;

/// A mixin that adds **pull-to-refresh** capability to a [BlocxListBloc].
///
/// ## Updated architecture note
/// Refresh use cases now require explicit input:
/// `BlocxBaseUseCase<Input, Page<T>>`
mixin BlocxRefreshableListBlocMixin<T extends BlocxBaseEntity, P> on BlocxListBloc<T, P> {
  /// Refresh use case must now accept an input.
  /// Typically this is `PaginationInput`.
  BlocxBaseUseCase<BlocxPaginationInput, BlocxPage<T>>? get refreshPageUseCase => null;

  /// Entry point for refresh events.
  Future<void> refreshPage(BlocxListEventRefreshData<T> event, Emitter<BlocxListState<T>> emit) async {
    if (isRefreshing) return;

    if (event.clearSelection && this is BlocxSelectableListBlocMixin<T, P>) {
      add(BlocxListEventClearSelection());
    }

    if (isSearchable && (this as BlocxSearchableListBlocMixin<T, P>).searchText.isNotEmpty) {
      add(BlocxListEventSearchRefresh());
      return;
    }

    if (refreshPageUseCase != null) {
      return await _fetchRefreshPage(event, emit);
    }

    infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());

    throw UnimplementedError("Provide `refreshPageUseCase` or override `refreshPage()`");
  }

  /// Executes refresh using the use case with proper input.
  Future<void> _fetchRefreshPage(BlocxListEventRefreshData<T> event, Emitter<BlocxListState<T>> emit) async {
    isRefreshing = true;
    emitState(emit);

    try {
      final input = BlocxPaginationInput(loadCount: list.length, offset: 0);

      final result = await refreshPageUseCase!.execute(input);

      if (result.isFailure) {
        await handleError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }

      clearList();

      await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.refresh);

      emitState(emit);
    } finally {
      isRefreshing = false;
      infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());
      emitState(emit);
    }
  }

  /// Registers refresh event handler.
  void initRefresh() {
    on<BlocxListEventRefreshData<T>>(refreshPage);
  }
}
