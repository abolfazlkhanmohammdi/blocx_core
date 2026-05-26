import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxInfiniteListBloc,
        BlocxCollectionBlocHighlightableMixin,
        BlocxCollectionBlocSelectableMixin,
        BlocxCollectionBlocSearchableMixin,
        BlocxCollectionBlocRefreshableMixin,
        BlocxCollectionBlocInfiniteMixin,
        BlocxCollectionBlocDeletableMixin,
        BlocxCollectionBlocScrollableMixin,
        BlocxCollectionBlocExpandableMixin,
        BlocxListBlocSyncStreamMixin,
        SelectionChangedData;
import 'package:blocx_core/src/blocs/list/mixins/blocx_collection_bloc_data_mixin.dart';
part 'lis_state_extension.dart';
part 'blocx_collection_event.dart';
part 'blocx_collection_state.dart';

abstract class BlocxCollectionBloc<T extends BlocxBaseEntity, P>
    extends BaseBloc<BlocxCollectionEvent<T>, BlocxCollectionState<T>>
    with ListBlocDataMixin<T, P> {
  final BlocxInfiniteListBloc _infiniteListBloc;
  BlocxCollectionBloc(ScreenManagerCubit screenManagerCubit, this._infiniteListBloc)
    : super(BlocxCollectionStateLoading(), screenManagerCubit) {
    initDataMixin();
    if (isSelectable) (this as BlocxCollectionBlocSelectableMixin<T, P>).initSelectionMixin();
    if (isHighlightable) (this as BlocxCollectionBlocHighlightableMixin<T, P>).initHighlightMixin();
    if (isSearchable) (this as BlocxCollectionBlocSearchableMixin<T, P>).initSearch();
    if (isRefreshable) (this as BlocxCollectionBlocRefreshableMixin<T, P>).initRefresh();
    if (isInfinite) (this as BlocxCollectionBlocInfiniteMixin<T, P>).initInfiniteList();
    if (isDeletable) (this as BlocxCollectionBlocDeletableMixin<T, P>).initDeletable();
    if (isScrollable) (this as BlocxCollectionBlocScrollableMixin<T, P>).initScrollable();
    if (isExpandable) (this as BlocxCollectionBlocExpandableMixin<T, P>).initExpandable();
    if (isStreamable) (this as BlocxListBlocSyncStreamMixin<T, P>).initStreams();
  }

  @override
  Future<void> close() async {
    await infiniteListBloc.close();
    if (isStreamable) (this as BlocxListBlocSyncStreamMixin<T, P>).closeStreams();
    await super.close();
  }

  bool get isSearchable => this is BlocxCollectionBlocSearchableMixin<T, P>;
  @override
  bool get isHighlightable => this is BlocxCollectionBlocHighlightableMixin<T, P>;
  bool get isSelectable => this is BlocxCollectionBlocSelectableMixin<T, P>;
  bool get isRefreshable => this is BlocxCollectionBlocRefreshableMixin<T, P>;
  bool get isInfinite => this is BlocxCollectionBlocInfiniteMixin<T, P>;
  bool get isDeletable => this is BlocxCollectionBlocDeletableMixin<T, P>;
  bool get isScrollable => this is BlocxCollectionBlocScrollableMixin<T, P>;
  bool get isExpandable => this is BlocxCollectionBlocExpandableMixin<T, P>;
  bool get isStreamable => this is BlocxListBlocSyncStreamMixin<T, P>;

  @override
  BlocxInfiniteListBloc get infiniteListBloc => _infiniteListBloc;

  @override
  Set<String> get beingRemovedItemIds =>
      isDeletable ? (this as BlocxCollectionBlocDeletableMixin<T, P>).beingRemovedItemIds : {};
  @override
  Set<String> get selectedItemIds =>
      isSelectable ? (this as BlocxCollectionBlocSelectableMixin<T, P>).selectedItemIdsOriginal : const {};

  @override
  Set<String> get beingSelectedItemIds => isSelectable
      ? (this as BlocxCollectionBlocSelectableMixin<T, P>).beingSelectedItemIdsOriginal
      : const {};

  @override
  Set<String> get highlightedItemIds => isHighlightable
      ? (this as BlocxCollectionBlocHighlightableMixin<T, P>).highlightedItemIdsOriginal
      : const {};

  @override
  Set<String> get expandedItemIds =>
      isExpandable ? (this as BlocxCollectionBlocExpandableMixin<T, P>).expandedItemIdsOriginal : const {};
}

enum DataInsertSource { init, nextPage, refresh, search }
