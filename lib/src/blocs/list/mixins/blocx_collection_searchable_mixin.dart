import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionEventSearch,
        BlocxCollectionBloc,
        BlocxCollectionEventSearchRefresh,
        BlocxCollectionEventClearSearch,
        BlocxCollectionEventSearchNextPage,
        BlocxCollectionState,
        BlocxInfiniteListEventSetReachedEnd,
        BlocxCollectionEventLoadInitialPage,
        DataInsertSource,
        BlocxInfiniteListEventChangeLoadBottomDataStatus;
import 'package:blocx_core/src/blocs/list/misc/event_transformers.dart';

/// Adds debounced search support to a [BlocxCollectionBloc].
///
/// Supports initial search, search pagination, search refresh, and clearing the
/// search query back to the normal collection state.
mixin BlocxCollectionSearchableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  /// Current active search query.
  String searchText = '';

  /// Registers search event handlers.
  void initSearch() {
    on<BlocxCollectionEventSearch<T>>(
      _search,
      transformer: debounceRestartable(searchDebounceDuration),
    );

    on<BlocxCollectionEventSearchRefresh<T>>(
      searchRefresh,
      transformer: droppable(),
    );

    on<BlocxCollectionEventClearSearch<T>>(
      _clearSearch,
      transformer: droppable(),
    );

    on<BlocxCollectionEventSearchNextPage<T>>(
      searchNextPage,
      transformer: droppable(),
    );
  }

  /// Stores the current query and starts search.
  Future<void> _search(
    BlocxCollectionEventSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    searchText = event.searchText;
    await search(event, emit);
  }

  /// Runs a search request.
  ///
  /// Override this method for custom search behavior.
  Future<void> search(
    BlocxCollectionEventSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final task = searchUseCaseTask;

    if (task != null) {
      return _fetchSearchResult(event, task, emit);
    }

    throw UnimplementedError(
      'Search is not configured. Provide `searchUseCaseTask` or override '
      '`search()`.',
    );
  }

  /// Executes the search task and replaces the current list.
  Future<void> _fetchSearchResult(
    BlocxCollectionEventSearch<T> event,
    BlocxPaginatedUseCaseTask<BlocxSearchInput, T> task,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    hasReachedEnd = false;

    infiniteListBloc.add(
      BlocxInfiniteListEventSetReachedEnd(hasReachedEnd: false),
    );

    if (searchText.isEmpty) {
      isSearching = false;

      clearList();

      add(
        BlocxCollectionEventLoadInitialPage<T, P>(
          payload: payload,
        ),
      );

      return;
    }

    try {
      isSearching = true;
      emitState(emit);

      final result = await task.execute(
        offset: 0,
        limit: limit,
      );

      if (searchText != event.searchText) return;

      if (result.isFailure) {
        await handleError(
          result.error!,
          emit,
          stacktrace: result.stackTrace,
        );
        return;
      }

      final page = result.data!;

      clearList();

      await insertToList(
        page.items,
        !page.hasNext,
        DataInsertSource.search,
      );

      emitState(emit);
    } finally {
      isSearching = false;
      emitState(emit);
    }
  }

  /// Clears active search and restores the normal initial list.
  FutureOr<void> _clearSearch(
    BlocxCollectionEventClearSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    searchText = '';
    hasReachedEnd = false;

    clearList();

    clearSearch(event, emit);
  }

  /// Task responsible for search requests.
  ///
  /// Override this to enable search.
  BlocxPaginatedUseCaseTask<BlocxSearchInput, T>? get searchUseCaseTask => null;

  /// Debounce duration applied to search input.
  Duration get searchDebounceDuration => const Duration(milliseconds: 300);

  /// Restores the non-search collection.
  FutureOr<void> clearSearch(
    BlocxCollectionEventClearSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    add(
      BlocxCollectionEventLoadInitialPage<T, P>(
        payload: payload,
      ),
    );
  }

  /// Loads the next page of search results.
  FutureOr<void> searchNextPage(
    BlocxCollectionEventSearchNextPage<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final task = searchUseCaseTask;

    if (task == null) {
      throw UnimplementedError(
        'Search pagination is not configured. Provide `searchUseCaseTask` or '
        'override `searchNextPage()`.',
      );
    }

    final result = await task.execute(
      offset: list.length,
      limit: limit,
    );

    if (result.isFailure) {
      await handleError(
        result.error!,
        emit,
        stacktrace: result.stackTrace,
      );
      return;
    }

    final page = result.data!;

    await insertToList(
      page.items,
      !page.hasNext,
      DataInsertSource.nextPage,
    );

    infiniteListBloc.add(
      BlocxInfiniteListEventChangeLoadBottomDataStatus(
        false,
        hasReachedEnd,
      ),
    );

    emitState(emit);
  }

  /// Refreshes the current search results.
  FutureOr<void> searchRefresh(
    BlocxCollectionEventSearchRefresh<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    final task = searchUseCaseTask;

    if (task != null) {
      return _fetchSearchRefreshResult(task, emit);
    }

    throw UnimplementedError(
      'Search refresh is not configured. Provide `searchUseCaseTask` or '
      'override `searchRefresh()`.',
    );
  }

  /// Executes a refresh request for the current search query.
  Future<void> _fetchSearchRefreshResult(
    BlocxPaginatedUseCaseTask<BlocxSearchInput, T> task,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    isSearching = true;
    emitState(emit);

    try {
      final result = await task.execute(
        offset: 0,
        limit: list.isNotEmpty ? list.length : limit,
      );

      if (result.isFailure) {
        await handleError(
          result.error!,
          emit,
          stacktrace: result.stackTrace,
        );
        return;
      }

      final page = result.data!;

      clearList();

      await insertToList(
        page.items,
        !page.hasNext,
        DataInsertSource.search,
      );

      emitState(emit);
    } finally {
      isSearching = false;
      emitState(emit);
    }
  }
}
