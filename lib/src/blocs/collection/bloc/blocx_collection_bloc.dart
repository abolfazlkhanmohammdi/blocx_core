import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart'
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
        SelectionChangedData;
import 'package:blocx_core/src/blocs/collection/bloc/blocx_collection_core_mixin.dart';

import '../mixins/stream/exports.dart';

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
///         BlocxPaginatedInput(limit: limit, offset: offset),
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
/// - [Entity]: The entity type. Must extend [BlocxBaseEntity].
/// - [Payload]: The payload type passed with [BlocxCollectionEventLoadInitialPage].
///   Use `void` when no payload is needed.
abstract class BlocxCollectionBloc<Entity extends BlocxBaseEntity, Payload>
    extends BlocxBaseBloc<BlocxCollectionEvent<Entity>, BlocxCollectionState<Entity>>
    with BlocxCollectionCoreMixin<Entity, Payload> {
  late final BlocxInfiniteListBloc _infiniteListBloc =
      BlocxInfiniteListBloc(refreshThreshold: infiniteListRefreshThreshold);

  late final bool hasFilters;
  @override
  late final bool isSelectable;
  @override
  late final bool isHighlightable;
  late final bool isSearchable;
  late final bool isRefreshable;
  late final bool isInfinite;
  late final bool isDeletable;
  late final bool isScrollable;
  late final bool isExpandable;
  late final bool isStreamable;

  /// The drag distance (in pixels) required to trigger a pull-to-refresh.
  ///
  /// Delegates to [BlocxCollectionRefreshableMixin.refreshThreshold] when
  /// [isRefreshable] is true. Returns `0` otherwise.
  double get infiniteListRefreshThreshold =>
      isRefreshable ? (this as BlocxCollectionRefreshableMixin).refreshThreshold : 0;

  /// Creates the bloc.
  ///
  /// No [ScreenManagerCubit] needed — it is managed by [BlocxBaseBloc].
  /// Enabled mixins are detected and initialised automatically.
  BlocxCollectionBloc() : super(BlocxCollectionStateLoading()) {
    initCoreMixin();
    isSelectable = initSelection();
    isHighlightable = initHighlight();
    isSearchable = initSearch();
    isRefreshable = initRefresh();
    isInfinite = initInfiniteList();
    isDeletable = initDeletable();
    isScrollable = initScrollable();
    isExpandable = initExpandable();
    isStreamable = initStreams();
    hasFilters = initFilters();
  }

  @override
  Future<void> close() async {
    await infiniteListBloc.close();
    if (isStreamable) (this as BlocxCollectionSyncStreamMixin<Entity, Payload>).closeStreams();
    await super.close();
  }

  @override
  BlocxInfiniteListBloc get infiniteListBloc => _infiniteListBloc;

  @override
  Set<String> get beingRemovedItemIds =>
      isDeletable ? (this as BlocxCollectionDeletableMixin<Entity, Payload>).beingRemovedItemIds : {};

  @override
  Set<String> get selectedItemIds => isSelectable
      ? (this as BlocxCollectionSelectableMixin<Entity, Payload>).selectedItemIdsOriginal
      : const {};

  @override
  Set<String> get beingSelectedItemIds => isSelectable
      ? (this as BlocxCollectionSelectableMixin<Entity, Payload>).beingSelectedItemIdsOriginal
      : const {};

  @override
  Set<String> get highlightedItemIds => isHighlightable
      ? (this as BlocxCollectionHighlightableMixin<Entity, Payload>).highlightedItemIdsOriginal
      : const {};

  @override
  Set<String> get expandedItemIds => isExpandable
      ? (this as BlocxCollectionExpandableMixin<Entity, Payload>).expandedItemIdsOriginal
      : const {};

  bool initFilters() {
    return false;
  }

  bool initSelection() {
    return false;
  }

  bool initHighlight() {
    return false;
  }

  bool initSearch() {
    return false;
  }

  bool initRefresh() {
    return false;
  }

  bool initInfiniteList() {
    return false;
  }

  bool initDeletable() {
    return false;
  }

  bool initScrollable() {
    return false;
  }

  bool initExpandable() {
    return false;
  }

  bool initStreams() {
    return false;
  }
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
