import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionSearchableMixin,
        BlocxCollectionEventSearchNextPage,
        BlocxCollectionBloc,
        BlocxCollectionEventLoadNextPage,
        BlocxCollectionState,
        BlocxInfiniteListEventChangeLoadBottomDataStatus,
        DataInsertSource;
import 'package:blocx_core/src/blocs/list/use_cases/blocx_paginated_use_case.dart';

/// Adds next-page loading support to a [BlocxCollectionBloc].
///
/// When the collection is searchable and a search query is active, next-page
/// loading is delegated to [BlocxCollectionSearchableMixin].
mixin BlocxCollectionInfiniteMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  /// Task responsible for loading the next page.
  ///
  /// Defaults to [paginationTask]. Override this only when next-page loading
  /// requires a different use case or input shape.
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, T>? get loadNextPageTask => paginationTask;

  /// Handles next-page loading.
  Future<void> loadNextPage(
    BlocxCollectionEventLoadNextPage<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    if (isSearchable && (this as BlocxCollectionSearchableMixin<T, P>).searchText.isNotEmpty) {
      add(BlocxCollectionEventSearchNextPage<T>());
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
    BlocxPaginatedUseCaseTask<BlocxPaginatedInput, T> task,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    isLoadingNextPage = true;

    try {
      final result = await task.execute(
        offset: list.length,
        limit: limit,
      );

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

  /// Registers next-page event handling.
  void initInfiniteList() {
    on<BlocxCollectionEventLoadNextPage<T>>(loadNextPage);
  }
}
