import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart'
    show
        BlocxCollectionSearchableMixin,
        BlocxCollectionBloc,
        BlocxCollectionState,
        BlocxInfiniteListEventChangeLoadBottomDataStatus,
        DataInsertSource;
import 'package:blocx_core/src/blocs/collection/use_cases/blocx_paginated_use_case.dart';

import '../search/events.dart';
import 'events.dart';

/// Adds next-page loading support to a [BlocxCollectionBloc].
///
/// When the collection is searchable and a search query is active, next-page
/// loading is delegated to [BlocxCollectionSearchableMixin].
mixin BlocxCollectionInfiniteMixin<Entity extends BlocxBaseEntity, Payload>
    on BlocxCollectionBloc<Entity, Payload> {
  /// Registers next-page event handling.
  @override
  bool initInfiniteList() {
    on<BlocxCollectionEventLoadNextPage<Entity>>(
      loadNextPage,
      transformer: droppable(),
    );
    return true;
  }

  /// Task responsible for loading the next page.
  ///
  /// Defaults to [paginationTask]. Override this only when next-page loading
  /// requires a different use case or input shape.
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>?
  get loadNextPageTask => paginationTask;

  /// Task responsible for loading the next page using cursor pagination.
  ///
  /// Defaults to [cursorPaginationTask]. Override this only when next-page loading
  /// requires a different cursor task or input shape.
  BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, Entity>?
  get loadNextPageCursorTask => cursorPaginationTask;

  /// Handles next-page loading.
  Future<void> loadNextPage(
    BlocxCollectionEventLoadNextPage<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    if (isSearchable &&
        (this as BlocxCollectionSearchableMixin<Entity, Payload>)
            .searchText
            .isNotEmpty) {
      add(BlocxCollectionEventSearchNextPage<Entity>());
      return;
    }

    if (hasReachedEnd || isLoadingNextPage) return;

    final cursorTask = loadNextPageCursorTask;
    if (cursorTask != null) {
      return _fetchNextPageWithCursor(cursorTask, emit);
    }

    final task = loadNextPageTask;
    if (task == null) {
      throw UnimplementedError(
        'Provide `paginationTask`, `cursorPaginationTask`, `loadNextPageTask`, '
        'or `loadNextPageCursorTask`, or override `loadNextPage()`.',
      );
    }

    return _fetchNextPage(task, emit);
  }

  /// Executes the next-page task.
  Future<void> _fetchNextPage(
    BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final gen = loadGeneration;
    isLoadingNextPage = true;
    emitState(emit);

    try {
      final result = await task.execute(offset: offset, limit: limit);
      if (gen != loadGeneration) return;

      if (result.isFailure) {
        await handleError(result.error!, emit, stacktrace: result.stackTrace);

        infiniteListBloc.add(
          BlocxInfiniteListEventChangeLoadBottomDataStatus(
            false,
            hasReachedEnd,
          ),
        );
        return;
      }

      final page = result.data!;

      await insertToList(page.items, !page.hasNext, DataInsertSource.nextPage);

      offset += page.items.length;
      nextCursor = page.nextCursor;
    } finally {
      if (gen == loadGeneration) {
        isLoadingNextPage = false;
        emitState(emit);
      }
    }
  }

  /// Executes the next-page cursor task.
  Future<void> _fetchNextPageWithCursor(
    BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final gen = loadGeneration;
    isLoadingNextPage = true;
    emitState(emit);

    try {
      final result = await task.execute(cursor: nextCursor, limit: limit);
      if (gen != loadGeneration) return;

      if (result.isFailure) {
        await handleError(result.error!, emit, stacktrace: result.stackTrace);

        infiniteListBloc.add(
          BlocxInfiniteListEventChangeLoadBottomDataStatus(
            false,
            hasReachedEnd,
          ),
        );
        return;
      }

      final page = result.data!;

      await insertToList(page.items, !page.hasNext, DataInsertSource.nextPage);

      offset += page.items.length;
      nextCursor = page.nextCursor;
    } finally {
      if (gen == loadGeneration) {
        isLoadingNextPage = false;
        infiniteListBloc.add(
          BlocxInfiniteListEventChangeLoadBottomDataStatus(
            false,
            hasReachedEnd,
          ),
        );
        emitState(emit);
      }
    }
  }
}
