import 'package:blocx/src/blocs/base/base_bloc.dart';
import 'package:blocx/src/blocs/list/list_bloc_base.dart';
import 'package:blocx/src/core/models/list_entity.dart';
import 'package:blocx/src/mixins/contracts/selectable_list_bloc_contract.dart';
import 'package:blocx/src/mixins/implementations/list_bloc_data_mixin.dart';

part 'list_bloc_event.dart';
part 'list_bloc_state.dart';

abstract class ListBloc<T extends ListEntity<T>> extends ListBlocBase<T> with ListBlocDataMixin {
  ListBloc() : super(ListBlocStateLoading()) {
    _registerSelectableHandlers();
  }

  void _registerSelectableHandlers() {
    if (this is SelectableBlocContract) {
      on<ListBlocEventSelectItem<T>>((this as SelectableBlocContract).selectItem);
    }
  }
}
