import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;
import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/core/models/base_entity_extensions.dart';

mixin ListBlocDataMixin<T extends BaseEntity, P> on BaseBloc<ListEvent<T>, ListState<T>> {
  P? payload;
  final List<T> _list = [];

  /// **Important:** This list is an [UnmodifiableListView].
  /// You cannot add/remove/mutate items directly.
  /// Always use the provided helpers.
  UnmodifiableListView<T> get list => UnmodifiableListView(_list);

  bool isLoadingNextPage = false;
  bool hasReachedEnd = false;
  bool isSearching = false;
  bool isRefreshing = false;

  Set<String> get selectedItemIds;
  Set<String> get beingSelectedItemIds;
  Set<String> get highlightedItemIds;
  Set<String> get beingRemovedItemIds;
  Set<String> get expandedItemIds;

  Future loadInitialPage(ListEventLoadInitialPage<T, P> event, Emitter<ListState<T>> emit) async {
    payload = event.payload;
    if (loadInitialPageUseCase != null) {
      return await _fetchInitialPage(event, emit);
    }
    throw UnimplementedError("You must either override loadUseCase getter or loadData method");
  }

  Future<void> _fetchInitialPage(ListEventLoadInitialPage<T, P> event, Emitter<ListState<T>> emit) async {
    emit(ListStateLoading<T>());
    var result = await loadInitialPageUseCase!.execute();
    if (result.isFailure) {
      await handleError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.init);
    emitState(emit);
  }

  int get loadCount => 20;
  int get offset => list.length;

  Future<List<T>> modifyListBeforeInsert(List<T> data) async {
    return data;
  }

  void initDataMixin() {
    on<ListEventLoadInitialPage<T, P>>(loadInitialPage);
    on<ListEventAddItem<T>>(addItem);
    on<ListEventUpdateItem<T>>(updateItem);
    on<ListEventReplaceList<T>>(handleReplaceList);
  }

  emitState(Emitter<ListState<T>> emit) {
    emit(
      ListStateLoaded(
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

  dynamic get additionalInfo => null;

  PaginationUseCase<T>? get loadInitialPageUseCase => null;

  Future<void> insertToList(List<T> data, bool hasReachedEnd, DataInsertSource insertSource) async {
    data = await modifyListBeforeInsert(data);
    int index = insertSource.insertIndex(list);
    _addInfiniteListEvent(insertSource);
    _list.insertAll(index, data);
    doAfterInsert();
    this.hasReachedEnd = hasReachedEnd;
    if (hasReachedEnd) {
      infiniteListBloc.add(InfiniteListEventSetReachedEnd(hasReachedEnd: true));
    }
  }

  void clearList() {
    _list.clear();
  }

  void replaceList(List<T> newList) {
    _list
      ..clear()
      ..addAll(newList);
  }

  void replaceItemInList(T item) {
    _list.replaceItem(item);
  }

  void removeItemFromList(T item) {
    _list.removeById(item);
  }

  void _addInfiniteListEvent(DataInsertSource insertSource) {
    switch (insertSource) {
      case DataInsertSource.search:
      case DataInsertSource.init:
        break;
      case DataInsertSource.nextPage:
        infiniteListBloc.add(InfiniteListEventChangeLoadBottomDataStatus(false, hasReachedEnd));
        break;
      case DataInsertSource.refresh:
        infiniteListBloc.add(InfiniteListEventCloseRefresh());
        break;
    }
  }

  InfiniteListBloc get infiniteListBloc;

  bool get isHighlightable;

  Future<void> addItem(ListEventAddItem<T> event, Emitter<ListState<T>> emit) async {
    _list.insert(event.index, event.item);
    emitState(emit);
  }

  FutureOr<void> updateItem(ListEventUpdateItem<T> event, Emitter<ListState<T>> emit) {
    int index = _list.indexById(event.item);
    if (index == -1) {
      throw Exception('Item not found in list');
    }
    _list[index] = event.item;
    if (isHighlightable) add(ListEventHighlightItem(item: event.item));
    emitState(emit);
  }

  void insertToListSingle(T item, {int index = 0}) {
    _list.insert(index, item);
  }

  sortList(Comparator<T> comparator) {
    _list.sort(comparator);
  }

  void doAfterInsert() {}

  FutureOr<void> handleReplaceList(ListEventReplaceList<T> event, Emitter<ListState<T>> emit) {
    replaceList(event.newItems);
    emitState(emit);
  }
}

extension on DataInsertSource {
  int insertIndex(List list) {
    return switch (this) {
      DataInsertSource.init => 0,
      DataInsertSource.nextPage => list.length,
      DataInsertSource.refresh => 0,
      DataInsertSource.search => 0,
    };
  }
}
