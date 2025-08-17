import 'package:bloc/bloc.dart';
import 'package:blocx/src/blocs/base/base_bloc.dart';
import 'package:blocx/src/core/models/list_entity.dart';
import 'package:blocx/src/mixins/contracts/selectable_list_bloc_contract.dart';

part 'list_bloc_event.dart';
part 'list_bloc_state.dart';

class ListBloc<T extends ListEntity<T>> extends BaseBloc<ListBlocEvent<T>, ListBlocState<T>> {
  final List<T> list = [];
  ListBloc() : super(ListBlocStateLoading()) {
    _registerSelectableHandlers();
  }

  void _registerSelectableHandlers() {
    if (this is SelectableBlocContract) {
      on<ListBlocEventSelectItem<T>>((this as SelectableBlocContract).selectItem);
    }
  }

  emitState(Emitter<ListBlocState<T>> emit) {
    emit(ListBlocStateLoaded(list: list));
  }
}
