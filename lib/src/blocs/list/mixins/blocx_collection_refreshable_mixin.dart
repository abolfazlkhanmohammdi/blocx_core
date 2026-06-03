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
import 'package:blocx_core/src/blocs/list/use_cases/blocx_paginated_use_case.dart';

/// Adds pull-to-refresh support to a [BlocxCollectionBloc].
///
/// When search is active, refresh is delegated to
/// [BlocxCollectionSearchableMixin].
mixin BlocxCollectionRefreshableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  /// Task responsible for refreshing the collection.
  ///
  /// Defaults to [paginationTask]. Override this only when refresh requires a
  /// different use case or input shape.
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, T>? get refreshPageUseCaseTask => paginationTask;

  /// Drag distance required to trigger pull-to-refresh.
  double get refreshThreshold => 64.0;

  /// Handles refresh events.
  Future<void> refreshPage(
    BlocxCollectionEventRefreshData<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    if (isRefreshing) return;

    if (event.clearSelection && this is BlocxCollectionSelectableMixin<T, P>) {
      add(BlocxCollectionEventClearSelection<T>());
    }

    if (isSearchable && (this as BlocxCollectionSearchableMixin<T, P>).searchText.isNotEmpty) {
      add(BlocxCollectionEventSearchRefresh<T>());
      return;
    }

    final task = refreshPageUseCaseTask;
    if (task != null) {
      return _fetchRefreshPage(task, emit);
    }

    infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());

    throw UnimplementedError(
      'Provide `paginationTask` or `refreshPageUseCaseTask`, '
      'or override `refreshPage()`.',
    );
  }

  /// Executes refresh using [task].
  Future<void> _fetchRefreshPage(
    BlocxPaginatedUseCaseTask<BlocxPaginatedInput, T> task,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    isRefreshing = true;
    emitState(emit);

    try {
      final result = await task.execute(
        offset: 0,
        limit: list.length > 0 ? list.length : limit,
      );

      if (result.isFailure) {
        await handleError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }

      final page = result.data!;

      clearList();

      await insertToList(
        page.items,
        !page.hasNext,
        DataInsertSource.refresh,
      );

      emitState(emit);
    } finally {
      isRefreshing = false;
      infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());
      emitState(emit);
    }
  }

  /// Registers refresh event handling.
  void initRefresh() {
    on<BlocxCollectionEventRefreshData<T>>(refreshPage);
  }
}
