import 'package:bloc/bloc.dart';
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
    on<BlocxCollectionEventLoadNextPage<Entity>>(loadNextPage);
    return true;
  }

  /// Task responsible for loading the next page.
  ///
  /// Defaults to [paginationTask]. Override this only when next-page loading
  /// requires a different use case or input shape.
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>? get loadNextPageTask => paginationTask;

  /// Handles next-page loading.
  Future<void> loadNextPage(
    BlocxCollectionEventLoadNextPage<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    if (isSearchable && (this as BlocxCollectionSearchableMixin<Entity, Payload>).searchText.isNotEmpty) {
      add(BlocxCollectionEventSearchNextPage<Entity>());
      return;
    }

    if (hasReachedEnd || isLoadingNextPage) return;

    final task = loadNextPageTask;
    if (task == null) {
      throw UnimplementedError(
        'Provide `paginationTask` or `loadNextPageTask`, '
        'or override `loadNextPage()`.',
      );
    }

    return _fetchNextPage(task, emit);
  }

  /// Executes the next-page task.
  Future<void> _fetchNextPage(
    BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    isLoadingNextPage = true;

    try {
      final result = await task.execute(offset: list.length, limit: limit);

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

      await insertToList(
        page.items,
        !page.hasNext,
        DataInsertSource.nextPage,
      );

      emitState(emit);
    } finally {
      isLoadingNextPage = false;
    }
  }
}
