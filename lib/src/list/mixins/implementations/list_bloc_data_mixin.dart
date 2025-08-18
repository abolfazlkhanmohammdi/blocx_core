import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/core/base_bloc/base_bloc.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/mixins/contracts/list_bloc_data_contract.dart';
import 'package:blocx/src/list/models/list_entity.dart';
import 'package:blocx/src/list/models/page.dart';
import 'package:blocx/src/list/use_cases/pagination_use_case.dart';

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
    if (loadInitialPageUseCase != null) return await _fetchInitialPage(event, emit);
    throw UnimplementedError("You must either override loadUseCase getter or loadData method");
  }

  Future<void> _fetchInitialPage(ListBlocEventLoadData<T, P> event, Emitter<ListBlocState<T>> emit) async {
    emit(ListBlocStateLoading<T>());
    var result = await loadInitialPageUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: 0),
    );
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    await insertToList(result.data!.items, !result.data!.hasNext);
    emitState(emit);
  }

  @override
  Future loadNextPage(ListBlocEventLoadMoreData<T> event, Emitter<ListBlocState<T>> emit) async {
    if (hasReachedEnd || isLoadingNextPage) return;
    isLoadingNextPage = true;
    var useCase = loadNextPageUseCase;
    if (useCase != null) return await _fetchNextPage(event, emit);
    throw UnimplementedError("You must either override loadMoreUseCase getter or loadNextPage method");
  }

  Future<void> _fetchNextPage(ListBlocEventLoadMoreData<T> event, Emitter<ListBlocState<T>> emit) async {
    var result = await loadNextPageUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: offset),
    );
    isLoadingNextPage = false;
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    await insertToList(result.data!.items, !result.data!.hasNext, index: list.length);
    emitState(emit);
  }

  @override
  Future refreshPage(ListBlocEventRefreshData<T> event, Emitter<ListBlocState<T>> emit) async {
    if (isRefreshing) return;
    if (refreshPageUseCase != null) return await _fetchRefreshPage(event, emit);
    throw UnimplementedError("You must either override refreshUseCase getter or refreshPage method");
  }

  int get loadCount => 20;
  int get offset => list.length;

  FutureOr<void> handleDataError(Object error, Emitter<ListBlocState<T>> emit, {StackTrace? stacktrace});

  Future<void> insertToList(List<T> data, bool hasReachedEnd, {int index = 0}) async {
    await doBeforeInsert(data);
    list.insertAll(index, data);
    this.hasReachedEnd = hasReachedEnd;
  }

  Future<void> doBeforeInsert(List<T> data) async {}

  Future<void> _fetchRefreshPage(ListBlocEventRefreshData<T> event, Emitter<ListBlocState<T>> emit) async {
    isRefreshing = true;
    emitState(emit);
    var result = await refreshPageUseCase!.execute(
      query: PaginationQuery(payload: payload, loadCount: loadCount, offset: 0),
    );
    isRefreshing = false;
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    list.clear();
    await insertToList(result.data!.items, !result.data!.hasNext);
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

  @override
  PaginationUseCase<T, P>? get loadInitialPageUseCase => null;
  @override
  PaginationUseCase<T, P>? get loadNextPageUseCase => null;
  @override
  PaginationUseCase<T, P>? get refreshPageUseCase => null;
}
