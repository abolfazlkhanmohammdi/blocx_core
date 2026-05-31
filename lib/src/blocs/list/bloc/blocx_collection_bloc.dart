import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxInfiniteListBloc,
        BlocxCollectionHighlightableMixin,
        BlocxCollectionSelectableMixin,
        BlocxCollectionSearchableMixin,
        BlocxCollectionRefreshableMixin,
        BlocxCollectionInfiniteMixin,
        BlocxCollectionDeletableMixin,
        BlocxCollectionScrollableMixin,
        BlocxCollectionExpandableMixin,
        BlocxCollectionSyncStreamMixin,
        SelectionChangedData;
import 'package:blocx_core/src/blocs/list/mixins/blocx_collection_core_mixin.dart';

part 'lis_state_extension.dart';
part 'blocx_collection_event.dart';
part 'blocx_collection_state.dart';

/// Base class for all list/collection blocs in the blocx ecosystem.
///
/// Manages an immutable, paginated list of [BlocxBaseEntity] items. Mixin
/// capabilities are auto-initialised in the constructor based on which mixins
/// are applied to the concrete subclass — no manual `init` calls needed.
///
/// ## Minimal setup
///
/// Override [paginationTask] with a [BlocxPaginatedUseCaseTask] and dispatch
/// [BlocxCollectionEventLoadInitialPage] to trigger the first load:
///
/// ```dart
/// class OrdersBloc extends BlocxCollectionBloc<Order, void> {
///   OrdersBloc() : super();
///
///   @override
///   BlocxPaginatedUseCaseTask get paginationTask => BlocxPaginatedUseCaseTask(
///     useCase: _getOrdersUseCase,
///     inputBuilder: ({required limit, required offset}) =>
///         BlocxPaginationInput(limit: limit, offset: offset),
///   );
/// }
/// ```
///
/// ## Optional features (applied via mixins)
///
/// | Mixin | Behaviour unlocked |
/// |---|---|
/// | [BlocxCollectionRefreshableMixin] | Pull-to-refresh |
/// | [BlocxCollectionInfiniteMixin] | Infinite scroll / next-page loading |
/// | [BlocxCollectionSearchableMixin] | Debounced search with separate result list |
/// | [BlocxCollectionSelectableMixin] | Multi-item selection |
/// | [BlocxCollectionDeletableMixin] | Animated item removal |
/// | [BlocxCollectionHighlightableMixin] | Temporary item highlighting |
/// | [BlocxCollectionExpandableMixin] | Expandable / collapsible items |
/// | [BlocxCollectionScrollableMixin] | Programmatic scroll-to-item |
/// | [BlocxCollectionSyncStreamMixin] | Live updates via a stream |
///
/// ## Type parameters
///
/// - [T]: The entity type. Must extend [BlocxBaseEntity].
/// - [P]: The payload type passed with [BlocxCollectionEventLoadInitialPage].
///   Use `void` when no payload is needed.
abstract class BlocxCollectionBloc<T extends BlocxBaseEntity, P>
    extends BaseBloc<BlocxCollectionEvent<T>, BlocxCollectionState<T>> with BlocxCollectionCoreMixin<T, P> {
  late final BlocxInfiniteListBloc _infiniteListBloc =
      BlocxInfiniteListBloc(refreshThreshold: infiniteListRefreshThreshold);

  /// The drag distance (in pixels) required to trigger a pull-to-refresh.
  ///
  /// Delegates to [BlocxCollectionRefreshableMixin.refreshThreshold] when
  /// [isRefreshable] is true. Returns `0` otherwise.
  double get infiniteListRefreshThreshold =>
      isRefreshable ? (this as BlocxCollectionRefreshableMixin).refreshThreshold : 0;

  /// Creates the bloc.
  ///
  /// No [ScreenManagerCubit] needed — it is managed by [BaseBloc].
  /// Enabled mixins are detected and initialised automatically.
  BlocxCollectionBloc() : super(BlocxCollectionStateLoading()) {
    initCoreMixin();
    if (isSelectable) (this as BlocxCollectionSelectableMixin<T, P>).initSelectionMixin();
    if (isHighlightable) (this as BlocxCollectionHighlightableMixin<T, P>).initHighlightMixin();
    if (isSearchable) (this as BlocxCollectionSearchableMixin<T, P>).initSearch();
    if (isRefreshable) (this as BlocxCollectionRefreshableMixin<T, P>).initRefresh();
    if (isInfinite) (this as BlocxCollectionInfiniteMixin<T, P>).initInfiniteList();
    if (isDeletable) (this as BlocxCollectionDeletableMixin<T, P>).initDeletable();
    if (isScrollable) (this as BlocxCollectionScrollableMixin<T, P>).initScrollable();
    if (isExpandable) (this as BlocxCollectionExpandableMixin<T, P>).initExpandable();
    if (isStreamable) (this as BlocxCollectionSyncStreamMixin<T, P>).initStreams();
  }

  @override
  Future<void> close() async {
    await infiniteListBloc.close();
    if (isStreamable) (this as BlocxCollectionSyncStreamMixin<T, P>).closeStreams();
    await super.close();
  }

  /// Whether [BlocxCollectionSearchableMixin] is applied.
  bool get isSearchable => this is BlocxCollectionSearchableMixin<T, P>;

  @override
  bool get isHighlightable => this is BlocxCollectionHighlightableMixin<T, P>;

  /// Whether [BlocxCollectionSelectableMixin] is applied.
  bool get isSelectable => this is BlocxCollectionSelectableMixin<T, P>;

  /// Whether [BlocxCollectionRefreshableMixin] is applied.
  bool get isRefreshable => this is BlocxCollectionRefreshableMixin<T, P>;

  /// Whether [BlocxCollectionInfiniteMixin] is applied.
  bool get isInfinite => this is BlocxCollectionInfiniteMixin<T, P>;

  /// Whether [BlocxCollectionDeletableMixin] is applied.
  bool get isDeletable => this is BlocxCollectionDeletableMixin<T, P>;

  /// Whether [BlocxCollectionScrollableMixin] is applied.
  bool get isScrollable => this is BlocxCollectionScrollableMixin<T, P>;

  /// Whether [BlocxCollectionExpandableMixin] is applied.
  bool get isExpandable => this is BlocxCollectionExpandableMixin<T, P>;

  /// Whether [BlocxCollectionSyncStreamMixin] is applied.
  bool get isStreamable => this is BlocxCollectionSyncStreamMixin<T, P>;

  @override
  BlocxInfiniteListBloc get infiniteListBloc => _infiniteListBloc;

  @override
  Set<String> get beingRemovedItemIds =>
      isDeletable ? (this as BlocxCollectionDeletableMixin<T, P>).beingRemovedItemIds : {};

  @override
  Set<String> get selectedItemIds =>
      isSelectable ? (this as BlocxCollectionSelectableMixin<T, P>).selectedItemIdsOriginal : const {};

  @override
  Set<String> get beingSelectedItemIds =>
      isSelectable ? (this as BlocxCollectionSelectableMixin<T, P>).beingSelectedItemIdsOriginal : const {};

  @override
  Set<String> get highlightedItemIds => isHighlightable
      ? (this as BlocxCollectionHighlightableMixin<T, P>).highlightedItemIdsOriginal
      : const {};

  @override
  Set<String> get expandedItemIds =>
      isExpandable ? (this as BlocxCollectionExpandableMixin<T, P>).expandedItemIdsOriginal : const {};
}

/// Describes where in the list new items are inserted during a data load.
enum DataInsertSource {
  /// Initial page load — inserts at index 0, clears previous content.
  init,

  /// Next-page load — appends to the end of the list.
  nextPage,

  /// Pull-to-refresh — replaces from index 0.
  refresh,

  /// Search result — inserts at index 0 into the search result list.
  search,
}
