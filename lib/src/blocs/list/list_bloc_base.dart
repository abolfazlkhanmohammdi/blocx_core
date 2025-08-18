import 'package:bloc/bloc.dart';
import 'package:blocx/src/blocs/base/base_bloc.dart';
import 'package:blocx/src/blocs/list/list_bloc.dart';
import 'package:blocx/src/core/models/list_entity.dart';

class ListBlocBase<T extends ListEntity<T>> extends BaseBloc<ListBlocEvent<T>, ListBlocState<T>> {
  final List<T> list = [];
  bool hasReachedEnd = false;
  ListBlocBase(super.initialState);

  emitState(Emitter<ListBlocState<T>> emit, {bool isLoadingMore = false, isRefreshing = false}) {
    emit(
      ListBlocStateLoaded(
        list: list,
        hasReachedEnd: hasReachedEnd,
        isLoadingMore: isLoadingMore,
        isRefreshing: isRefreshing,
      ),
    );
  }
}
