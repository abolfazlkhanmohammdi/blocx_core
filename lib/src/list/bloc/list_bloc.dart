import 'package:blocx/blocx.dart';
import 'package:blocx/src/core/base_bloc/base_bloc.dart';
import 'package:blocx/src/list/mixins/contracts/highlightable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/contracts/infinite_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/contracts/refreshable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/contracts/searchable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/contracts/selectable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/implementations/list_bloc_data_mixin.dart';

part 'list_bloc_event.dart';
part 'list_bloc_state.dart';

abstract class ListBloc<T extends ListEntity<T>, P> extends BaseBloc<ListBlocEvent<T>, ListBlocState<T>>
    with ListBlocDataMixin<T, P> {
  final InfiniteListBloc _infiniteListBloc;
  ListBloc(ScreenManagerCubit screenManagerCubit, this._infiniteListBloc)
    : super(ListBlocStateLoading(), screenManagerCubit) {
    initDataMixin();
    if (isSelectable) (this as SelectableBlocContract<T>).initSelectionMixin();
    if (isHighlightable) (this as HighlightableListBlocContract<T>).initHighlightMixin();
    if (isSearchable) (this as SearchableListBlocContract<T>).initSearch();
    if (isRefreshable) (this as RefreshableListBlocContract<T, P>).initRefresh();
    if (isInfinite) (this as InfiniteListBlocContract<T, P>).initInfiniteList();
  }

  @override
  Future<void> close() async {
    await _infiniteListBloc.close();
    await super.close();
  }

  @override
  InfiniteListBloc get infiniteListBloc => _infiniteListBloc;

  bool get isSearchable => this is SearchableListBlocContract<T>;
  bool get isHighlightable => this is HighlightableListBlocContract<T>;
  bool get isSelectable => this is SelectableBlocContract<T>;
  bool get isRefreshable => this is RefreshableListBlocContract<T, P>;
  bool get isInfinite => this is InfiniteListBlocContract<T, P>;
}

enum DataInsertSource { init, nextPage, refresh, search }
