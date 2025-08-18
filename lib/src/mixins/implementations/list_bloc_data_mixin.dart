import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/blocs/list/list_bloc.dart';
import 'package:blocx/src/blocs/list/list_bloc_base.dart';
import 'package:blocx/src/core/models/list_entity.dart';
import 'package:blocx/src/core/models/page.dart';
import 'package:blocx/src/mixins/contracts/list_bloc_data_contract.dart';

mixin ListBlocDataMixin<T extends ListEntity<T>, P> on ListBlocBase<T> implements ListBlocDataContract<T, P> {
  P? payload;

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
    if (hasReachedEnd || state.isLoadingMore) return;
    emitState(emit, isLoadingMore: true);
    var useCase = loadMoreUseCase;
    if (useCase != null) return await _fetchNextPage(event, emit);
    throw UnimplementedError("You must either override loadMoreUseCase getter or loadMoreData method");
  }

  Future<void> _fetchNextPage(ListBlocEventLoadMoreData<T> event, Emitter<ListBlocState<T>> emit) async {
    var result = await loadMoreUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: offset),
    );
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    await insertToList(result.data!, index: list.length);
    emitState(emit);
  }

  @override
  Future refreshPage(ListBlocEventRefreshData<T> event, Emitter<ListBlocState<T>> emit) async {
    if (state.isRefreshing) return;
    if (refreshUseCase != null) return await _fetchRefreshPage(event, emit);
    throw UnimplementedError("You must either override refreshUseCase getter or refreshData method");
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
    emitState(emit, isRefreshing: true);
    var result = await refreshUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: 0),
    );
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    list.clear();
    await insertToList(result.data!);
    emitState(emit);
  }

  void init() {
    on<ListBlocEventLoadData<T, P>>(loadInitialPage);
    on<ListBlocEventLoadMoreData<T>>(loadNextPage);
    on<ListBlocEventRefreshData<T>>(refreshPage);
  }
}
