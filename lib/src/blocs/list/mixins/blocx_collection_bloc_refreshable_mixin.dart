import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionBlocSearchableMixin,
        BlocxCollectionEventRefreshData,
        BlocxCollectionState,
        BlocxCollectionBlocSelectableMixin,
        BlocxCollectionEventClearSelection,
        BlocxCollectionEventSearchRefresh,
        BlocxInfiniteListEventCloseRefresh,
        DataInsertSource;
import 'package:blocx_core/src/blocs/list/models/page.dart' show BlocxPage;

import '../use_cases/blocx_pagination_use_case.dart' show BlocxPaginationInput;

/// A mixin that adds **pull-to-refresh** capability to a [BlocxCollectionBloc].
///
/// ## Updated architecture note
/// Refresh use cases now require explicit input:
/// `BlocxBaseUseCase<Input, Page<T>>`
mixin BlocxCollectionBlocRefreshableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  /// Refresh use case must now accept an input.
  /// Typically this is `PaginationInput`.
  BlocxBaseUseCase<BlocxPaginationInput, BlocxPage<T>>? get refreshPageUseCase => null;

  /// Entry point for refresh events.
  Future<void> refreshPage(
    BlocxCollectionEventRefreshData<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    if (isRefreshing) return;

    if (event.clearSelection && this is BlocxCollectionBlocSelectableMixin<T, P>) {
      add(BlocxCollectionEventClearSelection());
    }

    if (isSearchable && (this as BlocxCollectionBlocSearchableMixin<T, P>).searchText.isNotEmpty) {
      add(BlocxCollectionEventSearchRefresh());
      return;
    }

    if (refreshPageUseCase != null) {
      return await _fetchRefreshPage(event, emit);
    }

    infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());

    throw UnimplementedError("Provide `refreshPageUseCase` or override `refreshPage()`");
  }

  /// Executes refresh using the use case with proper input.
  Future<void> _fetchRefreshPage(
    BlocxCollectionEventRefreshData<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
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
    on<BlocxCollectionEventRefreshData<T>>(refreshPage);
  }
}
