import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/models/list_entity.dart';
import 'package:blocx/src/list/use_cases/pagination_use_case.dart';
import 'package:meta/meta.dart';

abstract class ListBlocDataContract<T extends ListEntity<T>, P> {
  @protected
  FutureOr loadInitialPage(ListEventLoadInitialPage<T, P> event, Emitter<ListState<T>> emit);

  PaginationUseCase<T, P>? get loadInitialPageUseCase;
  InfiniteListBloc get infiniteListBloc;
}
