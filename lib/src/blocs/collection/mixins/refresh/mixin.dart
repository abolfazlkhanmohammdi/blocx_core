import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionSearchableMixin,
        BlocxCollectionState,
        BlocxCollectionSelectableMixin,
        BlocxInfiniteListEventCloseRefresh,
        DataInsertSource;
import 'package:blocx_core/src/blocs/collection/mixins/refresh/events.dart';
import 'package:blocx_core/src/blocs/collection/mixins/selection/events.dart';
import 'package:blocx_core/src/blocs/collection/use_cases/blocx_paginated_use_case.dart';

import '../search/events.dart';

/// Adds pull-to-refresh support to a [BlocxCollectionBloc].
///
/// When search is active, refresh is delegated to
/// [BlocxCollectionSearchableMixin].
mixin BlocxCollectionRefreshableMixin<Entity extends BlocxBaseEntity, Payload>
    on BlocxCollectionBloc<Entity, Payload> {
  /// Registers refresh event handling.
  @override
  bool initRefresh() {
    on<BlocxCollectionEventRefreshData<Entity>>(refreshPage);
    return true;
  }

  /// Task responsible for refreshing the collection.
  ///
  /// Defaults to [paginationTask]. Override this only when refresh requires a
  /// different use case or input shape.
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>? get refreshPageUseCaseTask => paginationTask;

  /// Drag distance required to trigger pull-to-refresh.
  double get refreshThreshold => 64.0;

  /// Handles refresh events.
  Future<void> refreshPage(
    BlocxCollectionEventRefreshData<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    if (isRefreshing) return;

    if (event.clearSelection && this is BlocxCollectionSelectableMixin<Entity, Payload>) {
      add(BlocxCollectionEventClearSelection<Entity>());
    }

    if (isSearchable && (this as BlocxCollectionSearchableMixin<Entity, Payload>).searchText.isNotEmpty) {
      add(BlocxCollectionEventSearchRefresh<Entity>());
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
    BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    isRefreshing = true;
    emitState(emit);

    try {
      final result = await task.execute(offset: 0, limit: list.isNotEmpty ? list.length : limit);

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
}
