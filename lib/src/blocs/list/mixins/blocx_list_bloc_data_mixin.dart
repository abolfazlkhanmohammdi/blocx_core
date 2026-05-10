import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxListEvent,
        BlocxListState,
        BlocxListEventLoadInitialPage,
        BlocxListEventAddItem,
        BlocxListEventUpdateItem,
        BlocxListEventReplaceList,
        DataInsertSource,
        BlocxInfiniteListBloc,
        BlocxListStateLoading,
        BlocxListStateLoaded,
        BlocxInfiniteListEventSetReachedEnd,
        BlocxInfiniteListEventChangeLoadBottomDataStatus,
        BlocxInfiniteListEventCloseRefresh,
        BlocxListEventHighlightItem;
import 'package:blocx_core/src/blocs/list/use_cases/blocx_pagination_use_case.dart';
import 'package:blocx_core/src/core/models/base_entity_extensions.dart';
import 'package:blocx_core/src/core/use_cases/blocx_use_case_task.dart';

/// Mixin that provides **core list state management and data orchestration**
/// for a [BlocxListBloc].
///
/// This mixin is responsible for:
/// - Maintaining the internal immutable list state
/// - Loading initial paginated data
/// - Inserting, updating, and replacing items
/// - Coordinating infinite scroll events
/// - Tracking UI flags (loading, refreshing, searching)
/// - Emitting consistent [BlocxListStateLoaded] updates
///
/// ## Architecture role
/// This mixin acts as the **data layer backbone** of list-based blocs.
/// It does NOT handle UI logic directly; instead it emits normalized state
/// used by presentation layers.
///
/// ## Immutability guarantee
/// The exposed [list] is an [UnmodifiableListView], meaning:
/// - External code cannot mutate internal state
/// - All mutations must go through provided methods
///
/// ## Pagination model
/// Pagination is handled through a task-based or use-case-based system
/// (depending on implementation), and inserts are categorized using
/// [DataInsertSource].
///
/// ## State emission strategy
/// All updates go through [emitState], ensuring consistent state shape.
mixin ListBlocDataMixin<T extends BlocxBaseEntity, P> on BaseBloc<BlocxListEvent<T>, BlocxListState<T>> {
  /// Optional external payload used for initial loading.
  P? payload;

  /// Internal mutable list storage.
  final List<T> _list = [];

  /// Immutable view of the internal list.
  ///
  /// This prevents external mutation of bloc state.
  UnmodifiableListView<T> get list => UnmodifiableListView(_list);

  /// Indicates whether a "next page" request is in progress.
  bool isLoadingNextPage = false;

  /// Indicates whether all pages have been loaded.
  bool hasReachedEnd = false;

  /// Indicates whether a search operation is active.
  bool isSearching = false;

  /// Indicates whether a refresh operation is active.
  bool isRefreshing = false;

  /// IDs of selected items.
  Set<String> get selectedItemIds;

  /// IDs currently being selected (UI transition state).
  Set<String> get beingSelectedItemIds;

  /// IDs of highlighted items.
  Set<String> get highlightedItemIds;

  /// IDs of items currently being removed.
  Set<String> get beingRemovedItemIds;

  /// IDs of expanded items.
  Set<String> get expandedItemIds;

  /// Task responsible for loading the initial page of data.
  ///
  /// Must return a [BlocxUseCaseTask] configured with pagination input.
  BlocxUseCaseTask<BlocxBaseUseCase, BlocxPaginationInput>? get loadInitialPageTask => null;

  /// Loads the initial page of data.
  ///
  /// This method:
  /// - Stores the provided payload
  /// - Executes the initial page use case task
  /// - Emits loading and loaded states accordingly
  ///
  /// Throws [UnimplementedError] if no loading strategy is provided.
  Future loadInitialPage(BlocxListEventLoadInitialPage<T, P> event, Emitter<BlocxListState<T>> emit) async {
    payload = event.payload;

    if (loadInitialPageTask != null) {
      return _fetchInitialPage(event, emit);
    }

    throw UnimplementedError("Provide `loadInitialPageTask` or override `loadInitialPage`.");
  }

  /// Internal handler that executes the initial load task.
  ///
  /// Emits [BlocxListStateLoading] before execution and updates state
  /// upon success or failure.
  Future<void> _fetchInitialPage(
    BlocxListEventLoadInitialPage<T, P> event,
    Emitter<BlocxListState<T>> emit,
  ) async {
    emit(BlocxListStateLoading<T>());

    final task = loadInitialPageTask!;

    final result = await task.useCase.execute(task.inputBuilder());

    if (result.isFailure) {
      await handleError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }

    await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.init);

    emitState(emit);
  }

  /// Default number of items to load per page.
  int get loadCount => 20;

  /// Current offset based on loaded items.
  int get offset => list.length;

  /// Allows modification of incoming data before insertion.
  ///
  /// Override for preprocessing (sorting, filtering, mapping).
  Future<List<T>> modifyListBeforeInsert(List<T> data) async => data;

  /// Registers all internal event handlers for this mixin.
  void initDataMixin() {
    on<BlocxListEventLoadInitialPage<T, P>>(loadInitialPage);
    on<BlocxListEventAddItem<T>>(addItem);
    on<BlocxListEventUpdateItem<T>>(updateItem);
    on<BlocxListEventReplaceList<T>>(handleReplaceList);
  }

  /// Emits the current list state to listeners.
  ///
  /// This is the single source of truth for UI updates.
  void emitState(Emitter<BlocxListState<T>> emit) {
    emit(
      BlocxListStateLoaded(
        additionalInfo: additionalInfo,
        list: list,
        hasReachedEnd: hasReachedEnd,
        isLoadingNextPage: isLoadingNextPage,
        isRefreshing: isRefreshing,
        isSearching: isSearching,
        selectedItemIds: selectedItemIds,
        beingSelectedItemIds: beingSelectedItemIds,
        highlightedItemIds: highlightedItemIds,
        beingRemovedItemIds: beingRemovedItemIds,
        expandedItemIds: expandedItemIds,
      ),
    );
  }

  /// Optional additional metadata attached to state.
  dynamic get additionalInfo => null;

  /// Inserts a batch of items into the list.
  ///
  /// Handles:
  /// - insertion position based on [DataInsertSource]
  /// - infinite scroll coordination
  /// - end-of-list detection
  Future<void> insertToList(List<T> data, bool hasReachedEnd, DataInsertSource insertSource) async {
    data = await modifyListBeforeInsert(data);

    final index = insertSource.insertIndex(list);

    _addBlocxInfiniteListEvent(insertSource);

    _list.insertAll(index, data);

    doAfterInsert();

    this.hasReachedEnd = hasReachedEnd;

    if (hasReachedEnd) {
      infiniteListBloc.add(BlocxInfiniteListEventSetReachedEnd(hasReachedEnd: true));
    }
  }

  /// Clears all items from the list.
  void clearList() => _list.clear();

  /// Replaces entire list with a new set of items.
  void replaceList(List<T> newList) {
    _list
      ..clear()
      ..addAll(newList);
  }

  /// Replaces a single item in the list.
  void replaceItemInList(T item) => _list.replaceItem(item);

  /// Removes an item from the list.
  void removeItemFromList(T item) => _list.removeById(item);

  /// Internal handler for insert source side-effects.
  void _addBlocxInfiniteListEvent(DataInsertSource insertSource) {
    switch (insertSource) {
      case DataInsertSource.search:
      case DataInsertSource.init:
        break;

      case DataInsertSource.nextPage:
        infiniteListBloc.add(BlocxInfiniteListEventChangeLoadBottomDataStatus(false, hasReachedEnd));
        break;

      case DataInsertSource.refresh:
        infiniteListBloc.add(BlocxInfiniteListEventCloseRefresh());
        break;
    }
  }

  /// Infinite list controller used for pagination state coordination.
  BlocxInfiniteListBloc get infiniteListBloc;

  /// Whether item highlighting is enabled.
  bool get isHighlightable;

  /// Adds a new item to the list.
  Future<void> addItem(BlocxListEventAddItem<T> event, Emitter<BlocxListState<T>> emit) async {
    _list.insert(event.index, event.item);
    emitState(emit);
  }

  /// Updates an existing item in the list.
  FutureOr<void> updateItem(BlocxListEventUpdateItem<T> event, Emitter<BlocxListState<T>> emit) {
    final index = _list.indexById(event.item);

    if (index == -1) {
      throw Exception('Item not found in list');
    }

    _list[index] = event.item;

    if (isHighlightable) {
      add(BlocxListEventHighlightItem(item: event.item));
    }

    emitState(emit);
  }

  /// Inserts a single item at a specific index.
  void insertToListSingle(T item, {int index = 0}) {
    _list.insert(index, item);
  }

  /// Sorts list using provided comparator.
  void sortList(Comparator<T> comparator) {
    _list.sort(comparator);
  }

  /// Hook executed after insert operations.
  void doAfterInsert() {}

  /// Handles full list replacement event.
  FutureOr<void> handleReplaceList(BlocxListEventReplaceList<T> event, Emitter<BlocxListState<T>> emit) {
    replaceList(event.newItems);
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
