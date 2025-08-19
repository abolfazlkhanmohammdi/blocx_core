import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/use_cases/pagination_use_case.dart';

abstract interface class RefreshableListBlocContract<T extends ListEntity<T>, P> {
  initRefresh();
  Future refreshPage(ListBlocEventRefreshData<T> event, Emitter<ListBlocState<T>> emit);
  PaginationUseCase<T, P>? get refreshPageUseCase;
}
