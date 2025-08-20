import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';

abstract interface class RefreshableListBlocContract<T extends ListEntity<T>, P> {
  initRefresh();
  Future refreshPage(ListEventRefreshData<T> event, Emitter<ListState<T>> emit);
  PaginationUseCase<T, P>? get refreshPageUseCase;
}
