import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
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
/// Supports offset pagination via [refreshPageUseCaseTask] and cursor pagination via
/// [refreshPageCursorTask]. Initial load, next-page loading, and refresh support cursors,
/// while search stays offset-based.
///
/// When search is active, refresh is delegated to
/// [BlocxCollectionSearchableMixin].
mixin BlocxCollectionRefreshableMixin<Entity extends BlocxBaseEntity, Payload>
    on BlocxCollectionBloc<Entity, Payload> {
  /// Registers refresh event handling.
  @override
  bool initRefresh() {
    on<BlocxCollectionEventRefreshData<Entity>>(
      refreshPage,
      transformer: restartable(),
    );
    return true;
  }

  /// Task responsible for refreshing the collection.
  ///
  /// Defaults to [paginationTask]. Override this only when refresh requires a
  /// different use case or input shape.
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>?
  get refreshPageUseCaseTask => paginationTask;

  /// Task used to refresh with cursor pagination. Defaults to [cursorPaginationTask].
  BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, Entity>?
  get refreshPageCursorTask => cursorPaginationTask;

  /// Drag distance required to trigger pull-to-refresh.
  double get refreshThreshold => 64.0;

  /// Handles refresh events.
  Future<void> refreshPage(
    BlocxCollectionEventRefreshData<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    if (isRefreshing) return;

    if (event.clearSelection &&
        this is BlocxCollectionSelectableMixin<Entity, Payload>) {
      add(BlocxCollectionEventClearSelection<Entity>());
    }

    if (isSearchable &&
        (this as BlocxCollectionSearchableMixin<Entity, Payload>)
            .searchText
            .isNotEmpty) {
      add(BlocxCollectionEventSearchRefresh<Entity>());
      return;
    }

    final cursorTask = refreshPageCursorTask;
    if (cursorTask != null) {
      return _fetchRefreshPageWithCursor(cursorTask, emit);
    }

    final task = refreshPageUseCaseTask;
    if (task != null) {
      return _fetchRefreshPage(task, emit);
    }

    infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());

    throw UnimplementedError(
      'Provide `paginationTask`, `cursorPaginationTask`, `refreshPageUseCaseTask`, '
      'or `refreshPageCursorTask`, or override `refreshPage()`.',
    );
  }

  /// Executes refresh using [task].
  Future<void> _fetchRefreshPage(
    BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final gen = nextLoadGeneration();
    isRefreshing = true;
    emitState(emit);

    try {
      final result = await task.execute(offset: 0, limit: limit);
      if (gen != loadGeneration) return;

      if (result.isFailure) {
        await handleError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }

      final page = result.data!;

      clearList();
      offset = page.items.length;

      await insertToList(page.items, !page.hasNext, DataInsertSource.refresh);

      emitState(emit);
    } finally {
      if (gen == loadGeneration) {
        isRefreshing = false;
        infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());
        emitState(emit);
      }
    }
  }

  /// Executes refresh using [task] with cursor pagination.
  Future<void> _fetchRefreshPageWithCursor(
    BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final gen = nextLoadGeneration();
    isRefreshing = true;
    emitState(emit);

    try {
      final result = await task.execute(cursor: null, limit: limit);
      if (gen != loadGeneration) return;

      if (result.isFailure) {
        await handleError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }

      final page = result.data!;

      clearList();
      offset = page.items.length;
      nextCursor = page.nextCursor;

      final isLast =
          !page.hasNext || page.nextCursor == null || page.nextCursor!.isEmpty;

      await insertToList(page.items, isLast, DataInsertSource.refresh);

      emitState(emit);
    } finally {
      if (gen == loadGeneration) {
        isRefreshing = false;
        infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());
        emitState(emit);
      }
    }
  }
}
