import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/misc/event_transformers.dart';
import 'package:blocx/src/list/mixins/contracts/searchable_list_bloc_contract.dart';
import 'package:blocx/src/list/models/list_entity.dart';
import 'package:blocx/src/list/use_cases/search_use_case.dart';

/// Adds **search** behavior to a [ListBloc].
///
/// ### How it works
/// - Debounces [`ListEventSearch`] with [searchDebounceDuration] and uses a
///   *restartable* transformer so only the latest query runs.
/// - Handles [`ListEventClearSearch`] using a *droppable* transformer to avoid
///   queuing clears.
/// - Emits loading state via [isSearching], then replaces the list with
///   search results (immutable update).
///
/// ### Unmodifiable list
/// [list] is an **UnmodifiableListView**. Do **not** mutate it directly.
/// Always change data through the provided helpers:
/// - [clearList], [insertToList], [replaceList], and then [emitState].
///
/// ### Use cases
/// - Provide [searchUseCase] to execute the query.
/// - For empty search text (`""`), it will fall back to [loadInitialPageUseCase].
///
/// If you don’t supply [searchUseCase], you must override [search] yourself.
mixin SearchableListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
    implements SearchableListBlocContract<T, P> {
  /// Wire up search events:
  /// - [`ListEventSearch`]: debounced, restartable execution
  /// - [`ListEventClearSearch`]: droppable (ignores overlap)
  @override
  void initSearch() {
    on<ListEventSearch<T>>(_search, transformer: debounceRestartable(searchDebounceDuration));
    on<ListEventClearSearch<T>>(_clearSearch, transformer: droppable());
    on<ListEventSearchNextPage<T>>(searchNextPage, transformer: debounceRestartable(searchDebounceDuration));
  }

  /// Handles a debounced search request.
  ///
  /// Default implementation requires [searchUseCase]. If it’s `null`, you
  /// must override this method to implement custom search logic.
  ///
  /// When `event.searchText` is empty, the mixin will attempt to reload the
  /// initial page using [loadInitialPageUseCase] (if provided).
  Future<void> _search(ListEventSearch<T> event, Emitter<ListState<T>> emit) async {
    searchText = event.searchText;
    await search(event, emit);
  }

  @override
  Future<void> search(ListEventSearch<T> event, Emitter<ListState<T>> emit) async {
    if (searchUseCase(event.searchText) != null) {
      return _fetchSearchResult(event, emit);
    }
    throw UnimplementedError(
      'Search is not configured. Either provide `searchUseCase` or override '
      '`search(...)` in your bloc.',
    );
  }

  /// Executes the search or initial load, updates [isSearching], and replaces
  /// the list with the results (immutable update).
  ///
  /// - If `event.searchText.isEmpty`, falls back to [loadInitialPageUseCase].
  /// - Otherwise, uses [searchUseCase].
  /// - On failure, delegates to [handleDataError].
  Future<void> _fetchSearchResult(ListEventSearch<T> event, Emitter<ListState<T>> emit) async {
    isSearching = true;
    emitState(emit);

    try {
      final useCase = event.searchText.isEmpty ? loadInitialPageUseCase : searchUseCase(event.searchText);

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

  /// Clears search: resets the list and re-loads the initial page with the
  /// current [payload].
  ///
  /// Note: [list] is unmodifiable; we clear via [clearList] and trigger a
  /// fresh data load through an event.
  FutureOr<void> _clearSearch(ListEventClearSearch<T> event, Emitter<ListState<T>> emit) {
    searchText = "";
    clearList();
    clearSearch(event, emit);
  }

  /// Use case for fetching search results. If `null`, override [search].
  @override
  SearchUseCase<T, P>? searchUseCase(String searchText) => null;

  /// Debounce duration for search requests. Default: 300ms.
  Duration get searchDebounceDuration => const Duration(milliseconds: 300);

  @override
  FutureOr<void> clearSearch(ListEventClearSearch<T> event, Emitter<ListState<T>> emit) {
    add(ListEventLoadInitialPage<T, P>(payload: payload));
  }

  FutureOr<void> searchNextPage(ListEventSearchNextPage<T> event, Emitter<ListState<T>> emit) {}
}
