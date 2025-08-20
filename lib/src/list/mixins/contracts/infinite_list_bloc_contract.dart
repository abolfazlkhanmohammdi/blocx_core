import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/use_cases/pagination_use_case.dart';

abstract interface class InfiniteListBlocContract<T extends ListEntity<T>, P> {
  void initInfiniteList();
  Future loadNextPage(ListEventLoadNextPage<T> event, Emitter<ListState<T>> emit);
  PaginationUseCase<T, P>? get loadNextPageUseCase;
}
