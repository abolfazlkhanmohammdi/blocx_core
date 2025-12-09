import 'dart:async';
import 'dart:collection';
import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/core/models/base_entity_extensions.dart';

mixin ListBlocDataMixin<T extends BaseEntity, P> on BaseBloc<BlocxListEvent<T>, BlocxListState<T>> {
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

  Future loadInitialPage(BlocxListEventLoadInitialPage<T, P> event, Emitter<BlocxListState<T>> emit) async {
    payload = event.payload;
    if (loadInitialPageUseCase != null) {
      return await _fetchInitialPage(event, emit);
    }
    throw UnimplementedError("You must either override loadUseCase getter or loadData method");
  }

  Future<void> _fetchInitialPage(
    BlocxListEventLoadInitialPage<T, P> event,
    Emitter<BlocxListState<T>> emit,
  ) async {
    emit(BlocxListStateLoading<T>());
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
    on<BlocxListEventLoadInitialPage<T, P>>(loadInitialPage);
    on<BlocxListEventAddItem<T>>(addItem);
    on<BlocxListEventUpdateItem<T>>(updateItem);
    on<BlocxListEventReplaceList<T>>(handleReplaceList);
  }

  emitState(Emitter<BlocxListState<T>> emit) {
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

  dynamic get additionalInfo => null;

  BlocxPaginationUseCase<T>? get loadInitialPageUseCase => null;

  Future<void> insertToList(List<T> data, bool hasReachedEnd, DataInsertSource insertSource) async {
    data = await modifyListBeforeInsert(data);
    int index = insertSource.insertIndex(list);
    _addBlocxInfiniteListEvent(insertSource);
    _list.insertAll(index, data);
    doAfterInsert();
    this.hasReachedEnd = hasReachedEnd;
    if (hasReachedEnd) {
      infiniteListBloc.add(BlocxInfiniteListEventSetReachedEnd(hasReachedEnd: true));
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

  BlocxInfiniteListBloc get infiniteListBloc;

  bool get isHighlightable;

  Future<void> addItem(BlocxListEventAddItem<T> event, Emitter<BlocxListState<T>> emit) async {
    _list.insert(event.index, event.item);
    emitState(emit);
  }

  FutureOr<void> updateItem(BlocxListEventUpdateItem<T> event, Emitter<BlocxListState<T>> emit) {
    int index = _list.indexById(event.item);
    if (index == -1) {
      throw Exception('Item not found in list');
    }
    _list[index] = event.item;
    if (isHighlightable) add(BlocxListEventHighlightItem(item: event.item));
    emitState(emit);
  }

  void insertToListSingle(T item, {int index = 0}) {
    _list.insert(index, item);
  }

  sortList(Comparator<T> comparator) {
    _list.sort(comparator);
  }

  void doAfterInsert() {}

  FutureOr<void> handleReplaceList(BlocxListEventReplaceList<T> event, Emitter<BlocxListState<T>> emit) {
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
