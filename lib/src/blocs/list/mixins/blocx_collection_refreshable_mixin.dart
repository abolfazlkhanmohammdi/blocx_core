import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionSearchableMixin,
        BlocxCollectionEventRefreshData,
        BlocxCollectionState,
        BlocxCollectionSelectableMixin,
        BlocxCollectionEventClearSelection,
        BlocxCollectionEventSearchRefresh,
        BlocxInfiniteListEventCloseRefresh,
        DataInsertSource;

import '../use_cases/blocx_pagination_use_case.dart' show BlocxPaginationInput, BlocxPaginatedUseCase;

/// A mixin that adds **pull-to-refresh** capability to a [BlocxCollectionBloc].
///
/// ## Updated architecture note
/// Refresh use cases now require explicit input:
/// `BlocxBaseUseCase<Input, Page<T>>`
mixin BlocxCollectionRefreshableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  /// Task responsible for refreshing the list.
  ///
  /// Defaults to [paginationTask]. Override this only when refresh requires a
  /// different use case or input shape from the shared pagination task.
  BlocxPaginatedUseCaseTask<BlocxPaginatedUseCase<BlocxPaginationInput, T>, BlocxPaginationInput>?
      get refreshPageUseCaseTask => paginationTask;

  double get refreshThreshold => 64.0;

  /// Entry point for refresh events.
  Future<void> refreshPage(
    BlocxCollectionEventRefreshData<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    if (isRefreshing) return;

    if (event.clearSelection && this is BlocxCollectionSelectableMixin<T, P>) {
      add(BlocxCollectionEventClearSelection());
    }

    if (isSearchable && (this as BlocxCollectionSearchableMixin<T, P>).searchText.isNotEmpty) {
      add(BlocxCollectionEventSearchRefresh());
      return;
    }

    if (refreshPageUseCaseTask != null) {
      return await _fetchRefreshPage(event, emit);
    }

    infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());

    throw UnimplementedError(
        "Provide `paginationTask` (or `refreshPageUseCaseTask`) or override `refreshPage`()");
  }

  /// Executes refresh using the use case with proper input.
  Future<void> _fetchRefreshPage(
    BlocxCollectionEventRefreshData<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    isRefreshing = true;
    emitState(emit);

    try {
      final input = refreshPageUseCaseTask!.inputBuilder(0, list.length);

      final result = await refreshPageUseCaseTask!.useCase.execute(input);

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
