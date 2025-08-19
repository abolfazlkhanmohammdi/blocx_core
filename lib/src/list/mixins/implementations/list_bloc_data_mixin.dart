import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/core/base_bloc/base_bloc.dart';
import 'package:blocx/src/core/list_entity_extensions.dart';
import 'package:blocx/src/list/mixins/contracts/list_bloc_data_contract.dart';
import 'package:blocx/src/list/models/page.dart';
import 'package:blocx/src/list/use_cases/pagination_use_case.dart';

mixin ListBlocDataMixin<T extends ListEntity<T>, P> on BaseBloc<ListBlocEvent<T>, ListBlocState<T>>
    implements ListBlocDataContract<T, P> {
  P? payload;
  final List<T> _list = [];
  UnmodifiableListView<T> get list => UnmodifiableListView(_list);
  bool isLoadingNextPage = false;
  bool hasReachedEnd = false;
  bool isSearching = false;
  bool isRefreshing = false;
  @override
  Future loadInitialPage(ListBlocEventLoadInitialPage<T, P> event, Emitter<ListBlocState<T>> emit) async {
    payload = event.payload;
    if (loadInitialPageUseCase != null) return await _fetchInitialPage(event, emit);
    throw UnimplementedError("You must either override loadUseCase getter or loadData method");
  }

  Future<void> _fetchInitialPage(
    ListBlocEventLoadInitialPage<T, P> event,
    Emitter<ListBlocState<T>> emit,
  ) async {
    emit(ListBlocStateLoading<T>());
    var result = await loadInitialPageUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: 0),
    );
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.init);
    emitState(emit);
  }

  int get loadCount => 20;
  int get offset => list.length;

  FutureOr<void> handleDataError(Object error, Emitter<ListBlocState<T>> emit, {StackTrace? stacktrace}) {
    (String message, String? title) converted = convertErrorToMessageAndTitle(error);
    if (errorDisplayPolicy == ErrorDisplayPolicy.snackBar) {
      displayErrorSnackbar(converted.$1, title: converted.$2);
    } else {
      displayErrorWidget(error, stackTrace: stacktrace);
    }
  }

  Future<void> doBeforeInsert(List<T> data) async {}

  void initDataMixin() {
    on<ListBlocEventLoadInitialPage<T, P>>(loadInitialPage);
  }

  emitState(Emitter<ListBlocState<T>> emit) {
    emit(
      ListBlocStateLoaded(
        list: list,
        hasReachedEnd: hasReachedEnd,
        isLoadingNextPage: this.isLoadingNextPage,
        isRefreshing: this.isRefreshing,
      ),
    );
  }

  @override
  PaginationUseCase<T, P>? get loadInitialPageUseCase => null;

  (String, String?) convertErrorToMessageAndTitle(Object error);
  ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.snackBar;

  Future<void> insertToList(List<T> data, bool hasReachedEnd, DataInsertSource insertSource) async {
    await doBeforeInsert(data);
    int index = insertSource.insertIndex(list);
    _addInfiniteListEvent(insertSource);
    _list.insertAll(index, data);
    this.hasReachedEnd = hasReachedEnd;
  }

  void clearList() {
    _list.clear();
  }

  void replaceList(List<T> newList) {
    _list.clear();
    _list.addAll(newList);
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
        infiniteListBloc.add(InfiniteListBlocEventChangeLoadBottomDataStatus(false, hasReachedEnd));
        break;
      case DataInsertSource.refresh:
        infiniteListBloc.add(InfiniteListBlocEventCloseRefresh());
        break;
    }
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
