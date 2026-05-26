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

/// Adds **search capability** to a [BlocxCollectionBloc] using a **task-based execution model**.
///
/// ## Architecture
/// This mixin uses `BlocxUseCaseTask` instead of direct use cases:
///
/// - Task = (UseCase + Input builder)
/// - Execution happens at runtime via `task.useCase.execute(task.inputBuilder())`
///
/// ## Features
/// - debounced search
/// - restartable execution (latest query wins)
/// - pagination (next page search)
/// - refresh support
/// - safe race-condition handling
///
/// ## State behavior
/// - `isSearching` controls UI loading state
/// - list updates are immutable (clear + insert pattern)
/// - infinite scroll state is synced with `infiniteListBloc`
mixin BlocxCollectionBlocSearchableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  /// Current active search query.
  String searchText = "";

  /// Registers search-related event handlers.
  void initSearch() {
    on<BlocxCollectionEventSearch<T>>(_search, transformer: debounceRestartable(searchDebounceDuration));

    on<BlocxCollectionEventSearchRefresh<T>>(searchRefresh, transformer: droppable());

    on<BlocxCollectionEventClearSearch<T>>(_clearSearch, transformer: droppable());

    on<BlocxCollectionEventSearchNextPage<T>>(searchNextPage, transformer: droppable());
  }

  /// Handles incoming search event.
  Future<void> _search(BlocxCollectionEventSearch<T> event, Emitter<BlocxCollectionState<T>> emit) async {
    searchText = event.searchText;
    await search(event, emit);
  }

  /// Entry point for search execution.
  ///
  /// Override this OR provide `searchUseCase(...)`.
  Future<void> search(BlocxCollectionEventSearch<T> event, Emitter<BlocxCollectionState<T>> emit) async {
    final task = searchUseCase(event.searchText);

    if (task != null) {
      return _fetchSearchResult(event, emit);
    }

    throw UnimplementedError('Search is not configured. Provide `searchUseCase` or override `search()`.');
  }

  /// Executes search and replaces list with results.
  Future<void> _fetchSearchResult(
    BlocxCollectionEventSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    hasReachedEnd = false;

    infiniteListBloc.add(BlocxInfiniteListEventSetReachedEnd(hasReachedEnd: false));

    if (searchText.isEmpty) {
      isSearching = false;
      clearList();
      add(BlocxCollectionEventLoadInitialPage(payload: payload));
      return;
    }

    try {
      isSearching = true;
      emitState(emit);

      final task = searchUseCase(event.searchText)!;

      final result = await task.useCase.execute(task.inputBuilder());

      /// Race condition guard
      if (searchText != event.searchText) return;

      if (result.isFailure) {
        await handleError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }

      clearList();

      await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.search);

      emitState(emit);
    } finally {
      isSearching = false;
      emitState(emit);
    }
  }

  /// Clears search state and reloads base list.
  FutureOr<void> _clearSearch(
    BlocxCollectionEventClearSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    searchText = "";
    hasReachedEnd = false;
    clearList();
    clearSearch(event, emit);
  }

  /// TASK-BASED SEARCH PROVIDER
  ///
  /// Returns a [BlocxUseCaseTask] that contains:
  /// - UseCase
  /// - Input builder
  ///
  /// Return null if overriding behavior manually.
  BlocxUseCaseTask? searchUseCase(String searchText, {int? loadCount, int? offset}) => null;

  /// Search debounce duration.
  Duration get searchDebounceDuration => const Duration(milliseconds: 300);

  /// Restores initial list.
  FutureOr<void> clearSearch(
    BlocxCollectionEventClearSearch<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    add(BlocxCollectionEventLoadInitialPage<T, P>(payload: payload));
  }

  /// Loads next page of search results.
  FutureOr<void> searchNextPage(
    BlocxCollectionEventSearchNextPage<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final task = searchUseCase(searchText, offset: list.length)!;

    final result = await task.useCase.execute(task.inputBuilder());

    if (result.isFailure) {
      handleError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }

    await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.nextPage);

    infiniteListBloc.add(BlocxInfiniteListEventChangeLoadBottomDataStatus(false, hasReachedEnd));

    emitState(emit);
  }

  /// Refreshes current search results.
  FutureOr<void> searchRefresh(
    BlocxCollectionEventSearchRefresh<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    final task = searchUseCase(searchText);

    if (task != null) {
      return _fetchSearchRefreshResult(event, emit);
    }

    throw UnimplementedError(
      'Search is not configured. Provide `searchUseCase` or override `searchRefresh()`.',
    );
  }

  /// Refresh implementation.
  Future<void> _fetchSearchRefreshResult(
    BlocxCollectionEventSearchRefresh<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    isSearching = true;
    emitState(emit);

    try {
      final task = searchUseCase(searchText, loadCount: list.length, offset: 0);

      if (task == null) {
        throw UnimplementedError('Missing search use case configuration.');
      }

      final result = await task.useCase.execute(task.inputBuilder());

      if (result.isFailure) {
        await handleError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }

      clearList();

      await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.search);

      emitState(emit);
    } finally {
      isSearching = false;
      emitState(emit);
    }
  }
}
