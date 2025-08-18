import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/mixins/contracts/list_bloc_data_contract.dart';
import 'package:blocx/src/list/models/list_entity.dart';
import 'package:blocx/src/list/models/page.dart';
import 'package:blocx/src/core/base_bloc/base_bloc.dart';

mixin ListBlocDataMixin<T extends ListEntity<T>, P> on BaseBloc<ListBlocEvent<T>, ListBlocState<T>>
    implements ListBlocDataContract<T, P> {
  P? payload;
  final List<T> _list = [];
  List<T> get list => _list;
  bool isLoadingNextPage = false;
  bool isRefreshing = false;
  bool hasReachedEnd = false;
  bool isSearching = false;
  @override
  Future loadInitialPage(ListBlocEventLoadData<T, P> event, Emitter<ListBlocState<T>> emit) async {
    payload = event.payload;
    if (loadUseCase != null) return await _fetchInitialPage(event, emit);
    throw UnimplementedError("You must either override loadUseCase getter or loadData method");
  }

  Future<void> _fetchInitialPage(ListBlocEventLoadData<T, P> event, Emitter<ListBlocState<T>> emit) async {
    emit(ListBlocStateLoading<T>());
    var result = await loadUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: 0),
    );
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    await insertToList(result.data!);
    emitState(emit);
  }

  @override
  Future loadNextPage(ListBlocEventLoadMoreData<T> event, Emitter<ListBlocState<T>> emit) async {
    if (hasReachedEnd || isLoadingNextPage) return;
    isLoadingNextPage = true;
    var useCase = loadMoreUseCase;
    if (useCase != null) return await _fetchNextPage(event, emit);
    throw UnimplementedError("You must either override loadMoreUseCase getter or loadNextPage method");
  }

  Future<void> _fetchNextPage(ListBlocEventLoadMoreData<T> event, Emitter<ListBlocState<T>> emit) async {
    var result = await loadMoreUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: offset),
    );
    isLoadingNextPage = false;
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    await insertToList(result.data!, index: list.length);
    emitState(emit);
  }

  @override
  Future refreshPage(ListBlocEventRefreshData<T> event, Emitter<ListBlocState<T>> emit) async {
    if (isRefreshing) return;
    if (refreshUseCase != null) return await _fetchRefreshPage(event, emit);
    throw UnimplementedError("You must either override refreshUseCase getter or refreshPage method");
  }

  int get loadCount => 20;
  int get offset => list.length;

  FutureOr<void> handleDataError(Object error, Emitter<ListBlocState<T>> emit, {StackTrace? stacktrace});

  Future<void> insertToList(Page<T> data, {int index = 0}) async {
    await doBeforeInsert(data);
    list.insertAll(index, data.items);
    hasReachedEnd = !data.hasNext;
  }

  Future<void> doBeforeInsert(Page<T> data) async {}

  Future<void> _fetchRefreshPage(ListBlocEventRefreshData<T> event, Emitter<ListBlocState<T>> emit) async {
    isRefreshing = true;
    emitState(emit);
    var result = await refreshUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: 0),
    );
    isRefreshing = false;
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    list.clear();
    await insertToList(result.data!);
    emitState(emit);
  }

  void initDataMixin() {
    on<ListBlocEventLoadData<T, P>>(loadInitialPage);
    on<ListBlocEventLoadMoreData<T>>(loadNextPage);
    on<ListBlocEventRefreshData<T>>(refreshPage);
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
}
