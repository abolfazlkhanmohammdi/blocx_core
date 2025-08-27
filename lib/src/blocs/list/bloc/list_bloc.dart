import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/base/base_bloc.dart';
import 'package:blocx_core/src/blocs/list/mixins/list_bloc_data_mixin.dart';

part 'lis_state_extension.dart';
part 'list_event.dart';
part 'list_state.dart';

abstract class ListBloc<T extends BaseEntity, P> extends BaseBloc<ListEvent<T>, ListState<T>>
    with ListBlocDataMixin<T, P> {
  final InfiniteListBloc _infiniteListBloc;
  ListBloc(ScreenManagerCubit screenManagerCubit, this._infiniteListBloc)
    : super(ListStateLoading(), screenManagerCubit) {
    initDataMixin();
    if (isSelectable) (this as SelectableListBlocMixin<T, P>).initSelectionMixin();
    if (isHighlightable) (this as HighlightableListBlocMixin<T, P>).initHighlightMixin();
    if (isSearchable) (this as SearchableListBlocMixin<T, P>).initSearch();
    if (isRefreshable) (this as RefreshableListBlocMixin<T, P>).initRefresh();
    if (isInfinite) (this as InfiniteListBlocMixin<T, P>).initInfiniteList();
    if (isDeletable) (this as DeletableListBlocMixin<T, P>).initDeletable();
    if (isScrollable) (this as ScrollableListBlocMixin<T, P>).initScrollable();
    if (isExpandable) (this as ExpandableListBlocMixin<T, P>).initExpandable();
  }

  @override
  Future<void> close() async {
    await infiniteListBloc.close();
    await super.close();
  }

  bool get isSearchable => this is SearchableListBlocMixin<T, P>;
  bool get isHighlightable => this is HighlightableListBlocMixin<T, P>;
  bool get isSelectable => this is SelectableListBlocMixin<T, P>;
  bool get isRefreshable => this is RefreshableListBlocMixin<T, P>;
  bool get isInfinite => this is InfiniteListBlocMixin<T, P>;
  bool get isDeletable => this is DeletableListBlocMixin<T, P>;
  bool get isScrollable => this is ScrollableListBlocMixin<T, P>;
  bool get isExpandable => this is ExpandableListBlocMixin<T, P>;

  @override
  InfiniteListBloc get infiniteListBloc => _infiniteListBloc;

  @override
  Set<String> get beingRemovedItemIds =>
      isDeletable ? (this as DeletableListBlocMixin<T, P>).beingRemovedItemIdsOriginal : {};
  @override
  Set<String> get selectedItemIds =>
      isSelectable ? (this as SelectableListBlocMixin<T, P>).selectedItemIdsOriginal : const {};

  @override
  Set<String> get beingSelectedItemIds =>
      isSelectable ? (this as SelectableListBlocMixin<T, P>).beingSelectedItemIdsOriginal : const {};

  @override
  Set<String> get highlightedItemIds =>
      isHighlightable ? (this as HighlightableListBlocMixin<T, P>).highlightedItemIdsOriginal : const {};

  @override
  Set<String> get expandedItemIds =>
      isExpandable ? (this as ExpandableListBlocMixin<T, P>).expandedItemIdsOriginal : const {};
}

enum DataInsertSource { init, nextPage, refresh, search }
