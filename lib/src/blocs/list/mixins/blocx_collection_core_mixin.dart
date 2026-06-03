import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionEvent,
        BlocxCollectionState,
        BlocxCollectionEventLoadInitialPage,
        BlocxCollectionEventAddItem,
        BlocxCollectionEventUpdateItem,
        BlocxCollectionEventReplaceList,
        DataInsertSource,
        BlocxInfiniteListBloc,
        BlocxCollectionStateLoading,
        BlocxCollectionStateLoaded,
        BlocxInfiniteListEventSetReachedEnd,
        BlocxInfiniteListEventChangeLoadBottomDataStatus,
        BlocxCollectionEventHighlightItem;
import 'package:blocx_core/src/blocs/list/use_cases/blocx_paginated_use_case.dart';
import 'package:blocx_core/src/core/models/base_entity_extensions.dart';

/// Provides core collection state management and data orchestration.
///
/// This mixin owns the internal list, initial loading, insertion, replacement,
/// pagination state flags, and common state emission used by all collection
/// blocs.
mixin BlocxCollectionCoreMixin<T extends BlocxBaseEntity, P>
    on BaseBloc<BlocxCollectionEvent<T>, BlocxCollectionState<T>> {
  /// Optional external payload used for initial loading.
  P? payload;

  /// Internal mutable list storage.
  final List<T> _list = [];

  /// Immutable view of the internal list.
  UnmodifiableListView<T> get list => UnmodifiableListView(_list);

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
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, T>? get paginationTask => null;

  /// Task responsible for loading the initial page.
  ///
  /// Defaults to [paginationTask]. Override this only when initial loading uses
  /// a different use case or input shape.
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, T>? get loadInitialPageTask => paginationTask;

  /// Loads the first page of collection data.
  Future<void> loadInitialPage(
    BlocxCollectionEventLoadInitialPage<T, P> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    payload = event.payload;

    final task = loadInitialPageTask;
    if (task != null) {
      return _fetchInitialPage(task, emit);
    }

    throw UnimplementedError(
      'Provide `paginationTask` or `loadInitialPageTask`, '
      'or override `loadInitialPage()`.',
    );
  }

  /// Executes the initial load task.
  Future<void> _fetchInitialPage(
    BlocxPaginatedUseCaseTask<BlocxPaginatedInput, T> task,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    emit(BlocxCollectionStateLoading<T>());

    final result = await task.execute(offset: 0, limit: limit);

    if (result.isFailure) {
      await handleError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }

    final page = result.data!;

    clearList();

    await insertToList(
      page.items,
      !page.hasNext,
      DataInsertSource.init,
    );

    emitState(emit);
  }

  /// Default number of items to load per page.
  int get limit => 20;

  /// Current offset based on loaded items.
  int get offset => list.length;

  /// Allows modification of incoming data before insertion.
  Future<List<T>> modifyListBeforeInsert(List<T> data) async => data;

  /// Registers core collection event handlers.
  void initCoreMixin() {
    on<BlocxCollectionEventLoadInitialPage<T, P>>(loadInitialPage);
    on<BlocxCollectionEventAddItem<T>>(addItem);
    on<BlocxCollectionEventUpdateItem<T>>(updateItem);
    on<BlocxCollectionEventReplaceList<T>>(handleReplaceList);
  }

  /// Emits the current loaded collection state.
  void emitState(Emitter<BlocxCollectionState<T>> emit) {
    emit(
      BlocxCollectionStateLoaded(
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

  /// Optional additional metadata attached to loaded states.
  dynamic get additionalInfo => null;

  /// Inserts [data] into the collection using [insertSource].
  Future<void> insertToList(
    List<T> data,
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

  /// Clears all collection items.
  void clearList() => _list.clear();

  /// Replaces the entire collection with [newList].
  void replaceList(List<T> newList) {
    _list
      ..clear()
      ..addAll(newList);
  }

  /// Replaces one existing item.
  void replaceItemInList(T item) => _list.replaceItem(item);

  /// Removes one item from the collection.
  void removeItemFromList(T item) => _list.removeById(item);

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

  /// Adds [event.item] to the collection.
  Future<void> addItem(
    BlocxCollectionEventAddItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    _list.insert(event.index, event.item);
    emitState(emit);
  }

  /// Updates [event.item] inside the collection.
  FutureOr<void> updateItem(
    BlocxCollectionEventUpdateItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    final index = _list.indexById(event.item);

    if (index == -1) {
      throw Exception('Item not found in list');
    }

    _list[index] = event.item;

    if (isHighlightable) {
      add(BlocxCollectionEventHighlightItem(item: event.item));
    }

    emitState(emit);
  }

  /// Inserts a single [item] at [index].
  void insertToListSingle(T item, {int index = 0}) {
    _list.insert(index, item);
  }

  /// Sorts the collection using [comparator].
  void sortList(Comparator<T> comparator) {
    _list.sort(comparator);
  }

  /// Hook executed after insert operations.
  void doAfterInsert() {}

  /// Handles full list replacement.
  FutureOr<void> handleReplaceList(
    BlocxCollectionEventReplaceList<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
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
