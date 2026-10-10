import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:meta/meta.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart'
    show
        BlocxCollectionEvent,
        BlocxCollectionState,
        BlocxCollectionEventLoadInitialPage,
        BlocxCollectionEventUpdateItem,
        BlocxCollectionEventReplaceList,
        DataInsertSource,
        BlocxInfiniteListBloc,
        BlocxCollectionStateLoading,
        BlocxCollectionStateLoaded,
        BlocxInfiniteListEventSetReachedEnd,
        BlocxInfiniteListEventChangeLoadBottomDataStatus;
import 'package:blocx_core/src/blocs/collection/bloc/blocx_collection_bloc.dart';
import 'package:blocx_core/src/blocs/collection/mixins/highlight/events.dart';
import 'package:blocx_core/src/blocs/collection/mixins/scroll_to/events.dart';
import 'package:blocx_core/src/blocs/collection/models/blocx_page.dart';
import 'package:blocx_core/src/blocs/collection/use_cases/blocx_paginated_use_case.dart';
import 'package:blocx_core/src/core/models/base_entity_extensions.dart';

/// Provides core collection state management and data orchestration.
///
/// This mixin owns the internal list, initial loading, insertion, replacement,
/// pagination state flags, and common state emission used by all collection
/// blocs.
mixin BlocxCollectionCoreMixin<Entity extends BlocxBaseEntity, Payload>
    on
        BlocxBaseBloc<
          BlocxCollectionEvent<Entity>,
          BlocxCollectionState<Entity>
        > {
  /// Optional external payload used for initial loading.
  Payload? payload;

  /// Internal mutable list storage.
  final List<Entity> _list = [];

  /// Immutable view of the internal list.
  UnmodifiableListView<Entity> get list => UnmodifiableListView(_list);

  /// Whether a next-page request is currently running.
  bool isLoadingNextPage = false;

  /// Whether the collection has reached the final page.
  bool hasReachedEnd = false;

  /// Whether a search operation is currently active.
  bool isSearching = false;

  /// Whether a refresh operation is currently active.
  bool isRefreshing = false;

  /// Identifiers of selected items.
  Set<String> get selectedItemIds;

  /// Identifiers of items currently being selected.
  Set<String> get beingSelectedItemIds;

  /// Identifiers of highlighted items.
  Set<String> get highlightedItemIds;

  /// Identifiers of items currently being removed.
  Set<String> get beingRemovedItemIds;

  /// Identifiers of expanded items.
  Set<String> get expandedItemIds;

  /// Shared paginated task used by initial load, next-page load, and refresh.
  ///
  /// Override this when all paginated operations use the same use case.
  ///
  /// Example:
  ///
  /// ```dart
  /// @override
  /// BlocxPaginatedUseCaseTask<GetCategoriesInput, CategoryEntity>?
  ///     get paginationTask {
  ///   return BlocxPaginatedUseCaseTask<GetCategoriesInput, CategoryEntity>(
  ///     useCase: getCategoriesUseCase,
  ///     inputBuilder: (offset, limit) {
  ///       return GetCategoriesInput(
  ///         offset: offset,
  ///         limit: limit,
  ///       );
  ///     },
  ///   );
  /// }
  /// ```
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>? get paginationTask =>
      null;

  /// Shared cursor-based paginated task used by initial load and next-page load.
  BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, Entity>?
  get cursorPaginationTask => null;

  /// Task responsible for loading the initial page.
  ///
  /// Defaults to [paginationTask]. Override this only when initial loading uses
  /// a different use case or input shape.
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>?
  get loadInitialPageTask => paginationTask;

  /// Task responsible for loading the initial page using cursor pagination.
  ///
  /// Defaults to [cursorPaginationTask]. Override this only when initial loading
  /// uses a different cursor task or input shape.
  BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, Entity>?
  get loadInitialPageCursorTask => cursorPaginationTask;

  /// Loads the first page of collection data.
  Future<void> loadInitialPage(
    BlocxCollectionEventLoadInitialPage<Entity, Payload> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    payload = event.payload;

    final cursorTask = loadInitialPageCursorTask;
    if (cursorTask != null) {
      return _fetchInitialPageWithCursor(cursorTask, emit);
    }

    final task = loadInitialPageTask;
    if (task != null) {
      return _fetchInitialPage(task, emit);
    }

    throw UnimplementedError(
      'Provide `paginationTask`, `cursorPaginationTask`, `loadInitialPageTask`, '
      'or `loadInitialPageCursorTask`, or override `loadInitialPage()`.',
    );
  }

  /// Executes the initial load task using cursor pagination.
  Future<void> _fetchInitialPageWithCursor(
    BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final gen = nextLoadGeneration();
    emit(BlocxCollectionStateLoading<Entity>());

    final result = await task.execute(cursor: null, limit: limit);
    if (gen != _loadGeneration) return;

    if (result.isFailure) {
      await _emitInitialLoadError(result.error!, result.stackTrace, emit);
      return;
    }

    final page = result.data!;
    final isLast =
        !page.hasNext || page.nextCursor == null || page.nextCursor!.isEmpty;
    await _applyInitialPage(page, isLast, emit);
  }

  /// Executes the initial load task.
  Future<void> _fetchInitialPage(
    BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity> task,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final gen = nextLoadGeneration();
    emit(BlocxCollectionStateLoading<Entity>());

    final result = await task.execute(offset: 0, limit: limit);
    if (gen != _loadGeneration) return;

    if (result.isFailure) {
      await _emitInitialLoadError(result.error!, result.stackTrace, emit);
      return;
    }

    final page = result.data!;
    await _applyInitialPage(page, !page.hasNext, emit);
  }

  Future<void> _emitInitialLoadError(
    Object error,
    StackTrace? st,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    await handleError(error, emit, stacktrace: st);
    final readableError = readableErrorOf(error, stacktrace: st);
    emit(
      BlocxCollectionStateError<Entity>(
        message: readableError.message,
        list: List<Entity>.unmodifiable(_list),
        hasReachedEnd: hasReachedEnd,
        isLoadingNextPage: isLoadingNextPage,
        isRefreshing: isRefreshing,
        isSearching: isSearching,
        selectedItemIds: Set<String>.unmodifiable(selectedItemIds),
        beingSelectedItemIds: Set<String>.unmodifiable(beingSelectedItemIds),
        highlightedItemIds: Set<String>.unmodifiable(highlightedItemIds),
        beingRemovedItemIds: Set<String>.unmodifiable(beingRemovedItemIds),
        expandedItemIds: Set<String>.unmodifiable(expandedItemIds),
        additionalInfo: additionalInfo,
      ),
    );
  }

  Future<void> _applyInitialPage(
    BlocxPage<Entity> page,
    bool isLast,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    clearList();
    offset = page.items.length;
    nextCursor = page.nextCursor;

    await insertToList(page.items, isLast, DataInsertSource.init);
    if (isSelectable) await applyInitialSelection();

    emitState(emit);
  }

  /// Default number of items to load per page.
  int get limit => 20;

  int _loadedCount = 0;
  String? _nextCursor;

  /// Current pagination cursor returned by the datasource.
  String? get nextCursor => _nextCursor;

  /// Updates the pagination cursor.
  @protected
  set nextCursor(String? value) => _nextCursor = value;

  /// Current pagination offset based on items fetched from the datasource.
  ///
  /// This tracks the server pagination cursor independently of local additions
  /// or removals (e.g. from sync streams or local mutations), preventing
  /// pagination offset drift when loading subsequent pages.
  int get offset => _loadedCount;

  /// Updates the pagination offset cursor.
  @protected
  set offset(int value) => _loadedCount = value;

  int _loadGeneration = 0;

  /// Current generation counter of collection loads.
  ///
  /// Incremented on each new major collection load (initial load, refresh,
  /// search, or clear) to ensure stale in-flight asynchronous operations are
  /// safely discarded and cannot overwrite newer state.
  int get loadGeneration => _loadGeneration;

  /// Increments and returns the next load generation identifier.
  @protected
  int nextLoadGeneration() => ++_loadGeneration;

  /// Allows modification of incoming data before insertion.
  Future<List<Entity>> modifyListBeforeInsert(List<Entity> data) async => data;

  /// Optional comparator used to maintain sorted order in the collection list.
  ///
  /// When non-null, [getInsertIndexForItem] locates the sorted insertion position.
  /// When null, defaults to inserting at index 0.
  Comparator<Entity>? get sortComparator => null;

  /// Returns the target insertion index for [item] using [sortComparator] if present.
  ///
  /// If [sortComparator] is non-null, iterates through [list] to find the index where
  /// [item] should be placed to preserve order. Otherwise, returns 0.
  int getInsertIndexForItem(Entity item) {
    final comparator = sortComparator;
    if (comparator == null) return 0;

    final currentList = list;
    for (var i = 0; i < currentList.length; i++) {
      if (comparator(item, currentList[i]) < 0) {
        return i;
      }
    }
    return currentList.length;
  }

  /// Registers core collection event handlers.
  void initCoreMixin() {
    on<BlocxCollectionEventLoadInitialPage<Entity, Payload>>(
      loadInitialPage,
      transformer: restartable(),
    );
    on<BlocxCollectionEventAddItem<Entity>>(addItem);
    on<BlocxCollectionEventUpdateItem<Entity>>(updateItem);
    on<BlocxCollectionEventReplaceList<Entity>>(handleReplaceList);
    on<BlocxCollectionEventRemoveFromList<Entity>>(removeFromList);
  }

  /// Emits the current loaded collection state.
  ///
  /// Emitted states receive unmodifiable snapshot copies of the collection
  /// items and ID sets to guarantee true state immutability. Creating these
  /// snapshots incurs an O(n) cost per emission.
  void emitState(Emitter<BlocxCollectionState<Entity>> emit) {
    emit(
      BlocxCollectionStateLoaded(
        additionalInfo: additionalInfo,
        list: List<Entity>.unmodifiable(_list),
        hasReachedEnd: hasReachedEnd,
        isLoadingNextPage: isLoadingNextPage,
        isRefreshing: isRefreshing,
        isSearching: isSearching,
        selectedItemIds: Set<String>.unmodifiable(selectedItemIds),
        beingSelectedItemIds: Set<String>.unmodifiable(beingSelectedItemIds),
        highlightedItemIds: Set<String>.unmodifiable(highlightedItemIds),
        beingRemovedItemIds: Set<String>.unmodifiable(beingRemovedItemIds),
        expandedItemIds: Set<String>.unmodifiable(expandedItemIds),
      ),
    );
  }

  /// Optional additional metadata attached to loaded states.
  dynamic get additionalInfo => null;

  /// Inserts [data] into the collection using [insertSource].
  Future<void> insertToList(
    List<Entity> data,
    bool hasReachedEnd,
    DataInsertSource insertSource,
  ) async {
    final modifiedData = await modifyListBeforeInsert(data);
    final index = insertSource.insertIndex(list);

    _addBlocxInfiniteListEvent(insertSource);

    _list.insertAll(index, modifiedData);

    doAfterInsert();

    this.hasReachedEnd = hasReachedEnd;

    if (hasReachedEnd) {
      infiniteListBloc.add(
        BlocxInfiniteListEventSetReachedEnd(hasReachedEnd: true),
      );
    }
  }

  /// Clears all collection items and resets pagination offset.
  void clearList() {
    _list.clear();
    _loadedCount = 0;
    _nextCursor = null;
  }

  /// Replaces the entire collection with [newList].
  void replaceList(List<Entity> newList) {
    _list
      ..clear()
      ..addAll(newList);
  }

  /// Replaces one existing item.
  void replaceItemInList(Entity item) => _list.replaceItem(item);

  /// Removes one item from the collection.
  void removeItemFromList(Entity item) => _list.removeById(item);

  void _addBlocxInfiniteListEvent(DataInsertSource insertSource) {
    switch (insertSource) {
      case DataInsertSource.search:
      case DataInsertSource.init:
        break;

      case DataInsertSource.nextPage:
        infiniteListBloc.add(
          BlocxInfiniteListEventChangeLoadBottomDataStatus(
            false,
            hasReachedEnd,
          ),
        );
        break;

      case DataInsertSource.refresh:
        break;
    }
  }

  /// Infinite list controller used for pagination coordination.
  BlocxInfiniteListBloc get infiniteListBloc;

  /// Whether item highlighting is enabled.
  bool get isHighlightable;

  bool get isSelectable;

  /// Adds [event.item] to the collection.
  ///
  /// If an item with matching [identifier] already exists in the collection,
  /// it is updated in-place instead of creating a duplicate row.
  Future<void> addItem(
    BlocxCollectionEventAddItem<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final existingIndex = _list.indexById(event.item);
    if (existingIndex != -1) {
      _list[existingIndex] = event.item;
      if (isHighlightable) {
        add(BlocxCollectionEventHighlightItem(item: event.item));
      }
      emitState(emit);
      return;
    }

    final safeIndex = event.index.clamp(0, _list.length);
    _list.insert(safeIndex, event.item);
    emitState(emit);
  }

  /// Updates [event.item] inside the collection.
  FutureOr<void> updateItem(
    BlocxCollectionEventUpdateItem<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) {
    final index = _list.indexById(event.item);

    if (index == -1) {
      return Future.value();
    }

    _list[index] = event.item;

    if (isHighlightable) {
      add(BlocxCollectionEventHighlightItem(item: event.item));
    }

    emitState(emit);
  }

  /// Inserts a single [item] at [index].
  ///
  /// If an item with matching [identifier] already exists, it is updated in place.
  void insertToListSingle(Entity item, {int index = 0}) {
    final existingIndex = _list.indexById(item);
    if (existingIndex != -1) {
      _list[existingIndex] = item;
      return;
    }
    final safeIndex = index.clamp(0, _list.length);
    _list.insert(safeIndex, item);
  }

  /// Sorts the collection using [comparator].
  void sortList(Comparator<Entity> comparator) {
    _list.sort(comparator);
  }

  /// Hook executed after insert operations.
  void doAfterInsert() {}

  /// Handles full list replacement.
  FutureOr<void> handleReplaceList(
    BlocxCollectionEventReplaceList<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) {
    replaceList(event.newItems);
    emitState(emit);
  }

  FutureOr<void> applyInitialSelection() {}

  FutureOr<void> removeFromList(
    BlocxCollectionEventRemoveFromList<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    var index = _list.indexById(event.item);
    if (index < 0) return;
    _list.removeAt(index);
    emitState(emit);
  }
}

/// Extension defining insertion behavior based on source type.
extension on DataInsertSource {
  /// Returns insertion index based on source type.
  int insertIndex(List list) {
    return switch (this) {
      DataInsertSource.init => 0,
      DataInsertSource.nextPage => list.length,
      DataInsertSource.refresh => 0,
      DataInsertSource.search => 0,
    };
  }
}
