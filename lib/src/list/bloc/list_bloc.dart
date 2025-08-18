import 'package:blocx/src/core/base_bloc/base_bloc.dart';
import 'package:blocx/src/list/mixins/contracts/highlightable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/contracts/searchable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/contracts/selectable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/implementations/list_bloc_data_mixin.dart';
import 'package:blocx/src/list/models/list_entity.dart';
import 'package:blocx/src/screen_manager/screen_manager_cubit.dart';

part 'list_bloc_event.dart';
part 'list_bloc_state.dart';

abstract class ListBloc<T extends ListEntity<T>, P> extends BaseBloc<ListBlocEvent<T>, ListBlocState<T>>
    with ListBlocDataMixin<T, P> {
  ListBloc(ScreenManagerCubit screenManagerCubit) : super(ListBlocStateLoading(), screenManagerCubit) {
    initDataMixin();
    if (this is SelectableBlocContract) (this as SelectableBlocContract).initSelectionMixin();
    if (this is HighlightableListBlocContract) (this as HighlightableListBlocContract).initHighlightMixin();
    if (this is SearchableListBlocContract) (this as SearchableListBlocContract).initSearch();
  }
}
