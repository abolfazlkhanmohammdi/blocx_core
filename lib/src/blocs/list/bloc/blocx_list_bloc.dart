import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
    BlocxInfiniteListBloc,
    BlocxHighlightableListBlocMixin,
    BlocxSelectableListBlocMixin,
    BlocxSearchableListBlocMixin,
    BlocxRefreshableListBlocMixin,
    BlocxInfiniteListBlocMixin,
    BlocxDeletableListBlocMixin,
    BlocxScrollableListBlocMixin,
    BlocxExpandableListBlocMixin,
    BlocxListBlocSyncStreamMixin,
    SelectionChangedData;
import 'package:blocx_core/src/blocs/list/mixins/blocx_list_bloc_data_mixin.dart';
part 'lis_state_extension.dart';
part 'blocx_list_event.dart';
part 'blocx_list_state.dart';

abstract class BlocxListBloc<T extends BlocxBaseEntity, P>
    extends BaseBloc<BlocxListEvent<T>, BlocxListState<T>>
    with ListBlocDataMixin<T, P> {
  final BlocxInfiniteListBloc _infiniteListBloc;
  BlocxListBloc(ScreenManagerCubit screenManagerCubit, this._infiniteListBloc)
      : super(BlocxListStateLoading(), screenManagerCubit) {
    initDataMixin();
    if (isSelectable) (this as BlocxSelectableListBlocMixin<T, P>).initSelectionMixin();
    if (isHighlightable) (this as BlocxHighlightableListBlocMixin<T, P>).initHighlightMixin();
    if (isSearchable) (this as BlocxSearchableListBlocMixin<T, P>).initSearch();
    if (isRefreshable) (this as BlocxRefreshableListBlocMixin<T, P>).initRefresh();
    if (isInfinite) (this as BlocxInfiniteListBlocMixin<T, P>).initInfiniteList();
    if (isDeletable) (this as BlocxDeletableListBlocMixin<T, P>).initDeletable();
    if (isScrollable) (this as BlocxScrollableListBlocMixin<T, P>).initScrollable();
    if (isExpandable) (this as BlocxExpandableListBlocMixin<T, P>).initExpandable();
    if (isStreamable) (this as BlocxListBlocSyncStreamMixin<T, P>).initStreams();
  }

  @override
  Future<void> close() async {
    await infiniteListBloc.close();
    if (isStreamable) (this as BlocxListBlocSyncStreamMixin<T, P>).closeStreams();
    await super.close();
  }

  bool get isSearchable => this is BlocxSearchableListBlocMixin<T, P>;
  @override
  bool get isHighlightable => this is BlocxHighlightableListBlocMixin<T, P>;
  bool get isSelectable => this is BlocxSelectableListBlocMixin<T, P>;
  bool get isRefreshable => this is BlocxRefreshableListBlocMixin<T, P>;
  bool get isInfinite => this is BlocxInfiniteListBlocMixin<T, P>;
  bool get isDeletable => this is BlocxDeletableListBlocMixin<T, P>;
  bool get isScrollable => this is BlocxScrollableListBlocMixin<T, P>;
  bool get isExpandable => this is BlocxExpandableListBlocMixin<T, P>;
  bool get isStreamable => this is BlocxListBlocSyncStreamMixin<T, P>;

  @override
  BlocxInfiniteListBloc get infiniteListBloc => _infiniteListBloc;

  @override
  Set<String> get beingRemovedItemIds =>
      isDeletable ? (this as BlocxDeletableListBlocMixin<T, P>).beingRemovedItemIds : {};
  @override
  Set<String> get selectedItemIds =>
      isSelectable ? (this as BlocxSelectableListBlocMixin<T, P>).selectedItemIdsOriginal : const {};

  @override
  Set<String> get beingSelectedItemIds =>
      isSelectable ? (this as BlocxSelectableListBlocMixin<T, P>).beingSelectedItemIdsOriginal : const {};

  @override
  Set<String> get highlightedItemIds =>
      isHighlightable ? (this as BlocxHighlightableListBlocMixin<T, P>).highlightedItemIdsOriginal : const {};

  @override
  Set<String> get expandedItemIds =>
      isExpandable ? (this as BlocxExpandableListBlocMixin<T, P>).expandedItemIdsOriginal : const {};
}

enum DataInsertSource { init, nextPage, refresh, search }
