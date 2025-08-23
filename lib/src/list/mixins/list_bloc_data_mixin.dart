import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/core/base_bloc/base_bloc.dart';
import 'package:blocx/src/core/list_entity_extensions.dart';

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
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.init);
    emitState(emit);
  }

  int get loadCount => 20;
  int get offset => list.length;

  FutureOr<void> handleDataError(Object error, Emitter<ListState<T>> emit, {StackTrace? stacktrace}) {
    (String message, String? title) converted = convertErrorToMessageAndTitle(error);
    if (errorDisplayPolicy == ErrorDisplayPolicy.snackBar) {
      displayErrorSnackbar(converted.$1, title: converted.$2);
    } else {
      displayErrorWidget(error, stackTrace: stacktrace);
    }
  }

  Future<void> doBeforeInsert(List<T> data) async {}

  void initDataMixin() {
    on<ListEventLoadInitialPage<T, P>>(loadInitialPage);
  }

  emitState(Emitter<ListState<T>> emit) {
    emit(
      ListStateLoaded(
        list: list,
        hasReachedEnd: hasReachedEnd,
        isLoadingNextPage: isLoadingNextPage,
        isRefreshing: isRefreshing,
        isSearching: isSearching,
        // pass state-driven sets from getters
        selectedItemIds: selectedItemIds,
        beingSelectedItemIds: beingSelectedItemIds,
        highlightedItemIds: highlightedItemIds,
        beingRemovedItemIds: beingRemovedItemIds,
        expandedItemIds: expandedItemIds,
      ),
    );
  }

  PaginationUseCase<T, P>? get loadInitialPageUseCase => null;

  (String, String?) convertErrorToMessageAndTitle(Object error);
  ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.snackBar;

  Future<void> insertToList(List<T> data, bool hasReachedEnd, DataInsertSource insertSource) async {
    await doBeforeInsert(data);
    int index = insertSource.insertIndex(list);
    _addInfiniteListEvent(insertSource);
    _list.insertAll(index, data);
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
