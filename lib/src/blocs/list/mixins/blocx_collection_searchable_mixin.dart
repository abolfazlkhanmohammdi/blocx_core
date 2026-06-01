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
        BlocxInfiniteListEventChangeLoadBottomDataStatus,
        BlocxPaginatedUseCase;
import 'package:blocx_core/src/blocs/list/misc/event_transformers.dart';

/// A mixin that adds **search functionality** to a [BlocxCollectionBloc].
///
/// This implementation is built on a **task-based execution model**, where
/// search behavior is defined through a [BlocxUseCaseTask] rather than
/// directly invoking use cases.
///
/// ## Overview
///
/// The mixin provides a complete search lifecycle including:
///
/// - Debounced search input handling
/// - Restartable search execution (latest query wins)
/// - Pagination support (next page loading)
/// - Refresh support for current query
/// - Clear search and reset to initial state
/// - Safe race-condition handling for async results
///
/// ## Architecture
///
/// Search execution is delegated to a task:
///
/// ```dart
/// task.useCase.execute(task.inputBuilder())
/// ```
///
/// Where:
/// - `useCase` defines the business logic
/// - `inputBuilder` constructs request parameters dynamically
///
/// ## State Management
///
/// - `isSearching` indicates active search execution
/// - List mutations are performed via immutable insert/clear operations
/// - Infinite scroll state is synchronized via [infiniteListBloc]
///
/// ## Extension Strategy
///
/// This mixin supports two usage modes:
///
/// 1. **Declarative mode**
///    - Provide [searchUseCaseTask]
///    - No overrides required
///
/// 2. **Manual mode**
///    - Override methods like [search], [searchNextPage], [searchRefresh]
mixin BlocxCollectionSearchableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  /// Current active search query.
  String searchText = "";

  /// Registers search-related event handlers on the bloc.
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

  /// Handles incoming search events and updates internal query state.
  Future<void> _search(
    BlocxCollectionEventSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    searchText = event.searchText;
    await search(event, emit);
  }

  /// Entry point for executing a search operation.
  ///
  /// By default, this uses [searchUseCaseTask].
  /// Override this method to fully customize search behavior.
  Future<void> search(
    BlocxCollectionEventSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final task = searchUseCaseTask;

    if (task != null) {
      return _fetchSearchResult(event, emit);
    }

    throw UnimplementedError(
      'Search is not configured. '
      'Provide `searchUseCaseTask` or override `search()`.',
    );
  }

  /// Executes the search request and replaces the current list with results.
  ///
  /// Handles:
  /// - Empty query reset behavior
  /// - Race condition prevention
  /// - Loading state management
  /// - Error handling
  Future<void> _fetchSearchResult(
    BlocxCollectionEventSearch<T> event,
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

      final task = searchUseCaseTask;

      if (task == null) {
        throw UnimplementedError(
          'Search is not configured. '
          'Provide `searchUseCaseTask` or override `search()`.',
        );
      }

      final result = await task.useCase.execute(
        task.inputBuilder(0, limit),
      );

      /// Prevent stale results overwriting newer searches.
      if (searchText != event.searchText) return;

      if (result.isFailure) {
        await handleError(
          result.error!,
          emit,
          stacktrace: result.stackTrace,
        );
        return;
      }

      clearList();

      await insertToList(
        result.data!.items,
        !result.data!.hasNext,
        DataInsertSource.search,
      );

      emitState(emit);
    } finally {
      isSearching = false;
      emitState(emit);
    }
  }

  /// Clears the current search state and restores the base collection.
  FutureOr<void> _clearSearch(
    BlocxCollectionEventClearSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    searchText = "";
    hasReachedEnd = false;

    clearList();

    clearSearch(event, emit);
  }

  /// Provides a task describing how search should be executed.
  ///
  /// If `null`, the mixin expects overriding implementations of search methods.
  BlocxPaginatedUseCaseTask<BlocxPaginatedUseCase<BlocxSearchInput, T>, BlocxSearchInput>?
      get searchUseCaseTask => null;

  /// Debounce duration applied to search input events.
  Duration get searchDebounceDuration => const Duration(milliseconds: 300);

  /// Restores the initial (non-search) collection state.
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
        'Search pagination is not configured. '
        'Provide `searchUseCaseTask` or override `searchNextPage()`.',
      );
    }

    final input = task.inputBuilder(list.length, limit);
    final result = await task.useCase.execute(input);

    if (result.isFailure) {
      await handleError(
        result.error!,
        emit,
        stacktrace: result.stackTrace,
      );
      return;
    }

    await insertToList(
      result.data!.items,
      !result.data!.hasNext,
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

  /// Refreshes the current search results without resetting the query.
  FutureOr<void> searchRefresh(
    BlocxCollectionEventSearchRefresh<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    final task = searchUseCaseTask;

    if (task != null) {
      return _fetchSearchRefreshResult(event, emit);
    }

    throw UnimplementedError(
      'Search refresh is not configured. '
      'Provide `searchUseCaseTask` or override `searchRefresh()`.',
    );
  }

  /// Executes a refresh of the current search query.
  ///
  /// Unlike a full search, this preserves the current query context
  /// but reloads data from the beginning.
  Future<void> _fetchSearchRefreshResult(
    BlocxCollectionEventSearchRefresh<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    isSearching = true;
    emitState(emit);

    try {
      final task = searchUseCaseTask;

      if (task == null) {
        throw UnimplementedError(
          'Search refresh is not configured. '
          'Provide `searchUseCaseTask` or override `searchRefresh()`.',
        );
      }

      final input = task.inputBuilder(0, list.length);

      final result = await task.useCase.execute(input);

      if (result.isFailure) {
        await handleError(
          result.error!,
          emit,
          stacktrace: result.stackTrace,
        );
        return;
      }

      clearList();

      await insertToList(
        result.data!.items,
        !result.data!.hasNext,
        DataInsertSource.search,
      );

      emitState(emit);
    } finally {
      isSearching = false;
      emitState(emit);
    }
  }
}
