import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionState,
        BlocxInfiniteListEventSetReachedEnd,
        BlocxCollectionEventLoadInitialPage,
        DataInsertSource,
        BlocxInfiniteListEventChangeLoadBottomDataStatus;
import 'package:blocx_core/src/blocs/collection/misc/event_transformers.dart';

import 'events.dart';

/// Adds debounced search support to a [BlocxCollectionBloc].
///
/// Supports initial search, search pagination, search refresh, and clearing the
/// search query back to the normal collection state.
mixin BlocxCollectionSearchableMixin<Entity extends BlocxBaseEntity, Payload>
    on BlocxCollectionBloc<Entity, Payload> {
  /// Current active search query.
  String searchText = '';

  /// Registers search event handlers.
  @override
  bool initSearch() {
    on<BlocxCollectionEventSearch<Entity>>(
      _search,
      transformer: debounceRestartable(searchDebounceDuration),
    );

    on<BlocxCollectionEventSearchRefresh<Entity>>(
      searchRefresh,
      transformer: droppable(),
    );

    on<BlocxCollectionEventClearSearch<Entity>>(
      _clearSearch,
      transformer: droppable(),
    );

    on<BlocxCollectionEventSearchNextPage<Entity>>(
      searchNextPage,
      transformer: droppable(),
    );

    return true;
  }

  /// Stores the current query and starts search.
  Future<void> _search(
    BlocxCollectionEventSearch<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    searchText = event.searchText;
    await search(event, emit);
  }

  /// Runs a search request.
  ///
  /// Override this method for custom search behavior.
  Future<void> search(
    BlocxCollectionEventSearch<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
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
    BlocxCollectionEventSearch<Entity> event,
    BlocxPaginatedUseCaseTask<BlocxSearchInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    hasReachedEnd = false;

    infiniteListBloc.add(
      BlocxInfiniteListEventSetReachedEnd(hasReachedEnd: false),
    );

    if (searchText.isEmpty) {
      isSearching = false;

      clearList();

      add(
        BlocxCollectionEventLoadInitialPage<Entity, Payload>(
          payload: payload,
        ),
      );

      return;
    }

    try {
      isSearching = true;
      emitState(emit);

      final result = await task.execute(offset: 0, limit: limit);

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
    BlocxCollectionEventClearSearch<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) {
    searchText = '';
    hasReachedEnd = false;

    clearList();

    clearSearch(event, emit);
  }

  /// Task responsible for search requests.
  ///
  /// Override this to enable search.
  BlocxPaginatedUseCaseTask<BlocxSearchInput, Entity>? get searchUseCaseTask => null;

  /// Debounce duration applied to search input.
  Duration get searchDebounceDuration => const Duration(milliseconds: 300);

  /// Restores the non-search collection.
  FutureOr<void> clearSearch(
    BlocxCollectionEventClearSearch<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) {
    add(
      BlocxCollectionEventLoadInitialPage<Entity, Payload>(
        payload: payload,
      ),
    );
  }

  /// Loads the next page of search results.
  FutureOr<void> searchNextPage(
    BlocxCollectionEventSearchNextPage<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final task = searchUseCaseTask;

    if (task == null) {
      throw UnimplementedError(
        'Search pagination is not configured. Provide `searchUseCaseTask` or '
        'override `searchNextPage()`.',
      );
    }

    final result = await task.execute(offset: list.length, limit: limit);

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
    BlocxCollectionEventSearchRefresh<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
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
    BlocxPaginatedUseCaseTask<BlocxSearchInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    isSearching = true;
    emitState(emit);

    try {
      final result = await task.execute(offset: 0, limit: list.isNotEmpty ? list.length : limit);

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
