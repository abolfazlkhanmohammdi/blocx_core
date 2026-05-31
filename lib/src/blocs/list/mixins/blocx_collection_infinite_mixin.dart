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
import 'package:blocx_core/src/blocs/list/use_cases/blocx_pagination_use_case.dart';

/// Adds infinite pagination (next-page loading) to a [BlocxCollectionBloc].
///
/// Uses [BlocxUseCaseTask] + [BlocxPaginationInput] for explicit pagination control.
mixin BlocxCollectionInfiniteMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  /// Task responsible for loading the next page.
  ///
  /// Defaults to [paginationTask]. Override this only when next-page loading
  /// requires a different use case or input shape from the shared pagination
  /// task.
  BlocxPaginatedUseCaseTask<BlocxPaginatedUseCase<BlocxPaginationInput, T>, BlocxPaginationInput>?
      get loadNextPageTask => paginationTask;

  /// Entry point for next-page loading.
  Future<void> loadNextPage(
      BlocxCollectionEventLoadNextPage<T> event, Emitter<BlocxCollectionState<T>> emit) async {
    // Delegate to search pagination if in search mode
    if (isSearchable && (this as BlocxCollectionSearchableMixin<T, P>).searchText.isNotEmpty) {
      add(BlocxCollectionEventSearchNextPage());
      return;
    }

    if (hasReachedEnd || isLoadingNextPage) return;

    isLoadingNextPage = true;

    if (loadNextPageTask != null) {
      return _fetchNextPage(event, emit);
    }

    throw UnimplementedError("Provide `paginationTask` (or `loadNextPageTask`) or override `loadNextPage`.");
  }

  /// Executes next-page request using task-based API.
  Future<void> _fetchNextPage(
      BlocxCollectionEventLoadNextPage<T> event, Emitter<BlocxCollectionState<T>> emit) async {
    try {
      final task = loadNextPageTask!;

      final result = await task.useCase.execute(task.inputBuilder(list.length, limit));

      isLoadingNextPage = false;

      if (result.isFailure) {
        await handleError(result.error!, emit, stacktrace: result.stackTrace);

        infiniteListBloc.add(BlocxInfiniteListEventChangeLoadBottomDataStatus(false, hasReachedEnd));
        return;
      }

      await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.nextPage);

      emitState(emit);
    } finally {
      isLoadingNextPage = false;
    }
  }

  /// Registers event handler.
  void initInfiniteList() {
    on<BlocxCollectionEventLoadNextPage<T>>(loadNextPage);
  }
}
