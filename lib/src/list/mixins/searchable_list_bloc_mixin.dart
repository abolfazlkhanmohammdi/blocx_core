import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/misc/event_transformers.dart';

/// Adds **search** behavior to a [ListBloc].
///
/// ### How it works
/// - Debounces [`ListEventSearch`] with [searchDebounceDuration] and uses a
///   *restartable* transformer so only the **latest** query runs.
/// - Handles [`ListEventSearchRefresh`] and [`ListEventSearchNextPage`] with
///   *droppable* transformers (prevents overlapping executions).
/// - When a search begins, it resets pagination end-state via
///   `InfiniteListEventSetReachedEnd(false)` and toggles [isSearching] while
///   asynchronous work is in flight.
/// - Results are applied immutably using [clearList] + [insertToList], then
///   [emitState] to notify listeners/UI.
///
/// ### Important notes
/// - **Unmodifiable list:** [list] is read-only; never mutate it directly.
/// - **Empty search text:** falls back to [`ListEventLoadInitialPage`] to
///   restore the base list if [loadInitialPageUseCase] is available.
/// - **Race guard:** after awaiting the search use case, the mixin checks if
///   [searchText] became empty during the await and bails out to avoid
///   overwriting an already-cleared search.
/// - **Use cases:** Provide [searchUseCase] (and optionally
///   [loadInitialPageUseCase]) or override [search]/[searchRefresh] yourself.
///
/// If you don’t supply [searchUseCase], you must override [search] yourself.
mixin SearchableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  /// The current search query text.
  ///
  /// Updated on each [ListEventSearch] and used by refresh/next-page paths.
  String searchText = "";

  /// Wire up search events:
  /// - [`ListEventSearch`]: debounced, restartable execution
  /// - [`ListEventSearchRefresh`]: droppable (ignores overlap)
  /// - [`ListEventClearSearch`]: droppable (ignores overlap)
  /// - [`ListEventSearchNextPage`]: droppable (ignores overlap)
  void initSearch() {
    on<ListEventSearch<T>>(_search, transformer: debounceRestartable(searchDebounceDuration));
    on<ListEventSearchRefresh<T>>(searchRefresh, transformer: droppable());
    on<ListEventClearSearch<T>>(_clearSearch, transformer: droppable());
    on<ListEventSearchNextPage<T>>(searchNextPage, transformer: droppable());
  }

  /// Handles a debounced search request.
  ///
  /// Sets [searchText] and delegates to [search]. Override [search] if you need
  /// custom behavior, or provide [searchUseCase] to use the default flow.
  Future<void> _search(ListEventSearch<T> event, Emitter<ListState<T>> emit) async {
    searchText = event.searchText;
    await search(event, emit);
  }

  /// Entry point for performing a search.
  ///
  /// Default implementation requires a non-null [searchUseCase] for the given
  /// query; otherwise throws [UnimplementedError]. Override to customize.
  Future<void> search(ListEventSearch<T> event, Emitter<ListState<T>> emit) async {
    if (searchUseCase(event.searchText) != null) {
      return _fetchSearchResult(event, emit);
    }
    throw UnimplementedError(
      'Search is not configured. Either provide `searchUseCase` or override '
      '`search(...)` in your bloc.',
    );
  }

  /// Executes the current search (or restores the initial list on empty query),
  /// updates [isSearching], and replaces the list with the results.
  ///
  /// Behavior:
  /// - Resets `hasReachedEnd` and syncs the InfiniteList footer before starting.
  /// - If [searchText] is empty:
  ///   - Clears list, sets [isSearching] to false, and dispatches
  ///     [`ListEventLoadInitialPage`] to reload base data.
  /// - Otherwise:
  ///   - Sets [isSearching] to true, runs [searchUseCase], applies results via
  ///     [clearList] + [insertToList] with [DataInsertSource.search].
  /// - On failure, delegates to [handleDataError].
  /// - Always resets [isSearching] in `finally`.
  ///
  /// Includes a **race guard**: if [searchText] becomes empty while awaiting
  /// the use case, the method returns early to avoid stale updates.
  Future<void> _fetchSearchResult(ListEventSearch<T> event, Emitter<ListState<T>> emit) async {
    hasReachedEnd = false;
    infiniteListBloc.add(InfiniteListEventSetReachedEnd(hasReachedEnd: false));
    if (searchText.isEmpty) {
      isSearching = false;
      clearList();
      add(ListEventLoadInitialPage(payload: payload));
      return;
    }
    try {
      isSearching = true;
      emitState(emit);
      final useCase = searchUseCase(event.searchText);
      final result = await useCase!.execute();
      // Race guard:
      // The user might clear the query while this await is in flight, which enqueues
      // ListEventLoadInitialPage(...). If we continue, these stale search results
      // would overwrite the freshly restored base list. Bail out if the current
      // query is now empty (i.e., search mode ended).
      if (searchText != event.searchText) return;
      if (result.isFailure) {
        await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }
      // Replace data immutably
      clearList();
      await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.search);
      emitState(emit);
    } finally {
      // Make sure the flag is reset even on failures
      isSearching = false;
      emitState(emit);
    }
  }

  /// Clears search: resets the list and re-loads the initial page with the
  /// current [payload] via [clearSearch].
  ///
  /// Notes:
  /// - Resets [searchText] and clears the in-memory list.
  /// - The default [clearSearch] implementation dispatches
  ///   [`ListEventLoadInitialPage`].
  FutureOr<void> _clearSearch(ListEventClearSearch<T> event, Emitter<ListState<T>> emit) {
    searchText = "";
    clearList();
    clearSearch(event, emit);
  }

  /// Provides a use case to run searches.
  ///
  /// Return `null` if you plan to override [search] / [searchRefresh] yourself.
  ///
  /// - [searchText]: the query string.
  /// - [loadCount]: optional page size to request.
  /// - [offset]: optional offset for paginated searches.
  SearchUseCase<T, P>? searchUseCase(String searchText, {int? loadCount, int? offset}) => null;

  /// Debounce duration applied to [`ListEventSearch`].
  ///
  /// Default: 300ms.
  Duration get searchDebounceDuration => const Duration(milliseconds: 300);

  /// Restores the base list after a clear.
  ///
  /// Default implementation enqueues [`ListEventLoadInitialPage`] with
  /// the current [payload]. Override to customize.
  FutureOr<void> clearSearch(ListEventClearSearch<T> event, Emitter<ListState<T>> emit) {
    add(ListEventLoadInitialPage<T, P>(payload: payload));
  }

  /// Hook to implement **search pagination** (next page).
  ///
  /// Default: no-op. Override to fetch more search results using your
  /// [searchUseCase] with updated `loadCount`/`offset`, and append via
  /// [insertToList] with [DataInsertSource.search].
  FutureOr<void> searchNextPage(ListEventSearchNextPage<T> event, Emitter<ListState<T>> emit) {}

  /// Refreshes the current search results (same [searchText]).
  ///
  /// Default implementation requires [searchUseCase]; otherwise throws
  /// [UnimplementedError]. Override to customize behavior.
  FutureOr<void> searchRefresh(ListEventSearchRefresh<T> event, Emitter<ListState<T>> emit) {
    if (searchUseCase(searchText) != null) {
      return _fetchSearchRefreshResult(event, emit);
    }
    throw UnimplementedError(
      'Search is not configured. Either provide `searchUseCase` or override '
      '`search(...)` in your bloc.',
    );
  }

  /// Internal helper to re-fetch the **current** search for refresh.
  ///
  /// Calls [searchUseCase] with `loadCount = list.length` and `offset = 0`
  /// to rebuild the visible results, then replaces the list immutably and
  /// resets [isSearching] in `finally`.
  Future<void> _fetchSearchRefreshResult(ListEventSearchRefresh<T> event, Emitter<ListState<T>> emit) async {
    isSearching = true;
    emitState(emit);

    try {
      final useCase = searchUseCase(searchText, loadCount: list.length, offset: 0);

      if (useCase == null) {
        throw UnimplementedError(
          'No use case available for this search path. '
          'Empty query requires `loadInitialPageUseCase`; non-empty query requires `searchUseCase`.',
        );
      }

      final result = await useCase.execute();

      if (result.isFailure) {
        await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }

      // Replace data immutably
      clearList();
      await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.search);
      emitState(emit);
    } finally {
      // Make sure the flag is reset even on failures
      isSearching = false;
      emitState(emit);
    }
  }
}
