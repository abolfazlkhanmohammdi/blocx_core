import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/models/list_entity.dart';
import 'package:blocx/src/list/use_cases/pagination_use_case.dart';
import 'package:meta/meta.dart';

abstract class ListBlocDataContract<T extends ListEntity<T>, P> {
  @protected
  FutureOr loadInitialPage(ListBlocEventLoadInitialPage<T, P> event, Emitter<ListBlocState<T>> emit);
  @protected
  FutureOr refreshPage(ListBlocEventRefreshData<T> event, Emitter<ListBlocState<T>> emit);
  @protected
  FutureOr loadNextPage(ListBlocEventLoadNextPage<T> event, Emitter<ListBlocState<T>> emit);

  PaginationUseCase<T, P>? get loadInitialPageUseCase;
  InfiniteListBloc get infiniteListBloc;
}
