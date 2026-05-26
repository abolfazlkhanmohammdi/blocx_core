part of 'blocx_collection_bloc.dart';

/// Base class for all list-related events.
///
/// Extend this to define actions that mutate or interact with a [BlocxCollectionBloc].
class BlocxCollectionEvent<T extends BlocxBaseEntity> extends BaseEvent {}

/// Selects a single [item] in the list.
///
/// Useful when building UIs that allow user selection (e.g. checkboxes, taps).
class BlocxCollectionEventSelectItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to be selected.
  final T item;

  BlocxCollectionEventSelectItem({required this.item});
}

/// Deselects a single [item] in the list.
class BlocxCollectionEventDeselectItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to be deselected.
  final T item;

  BlocxCollectionEventDeselectItem({required this.item});
}

/// Highlights a specific [item] in the list.
///
/// Highlighting is typically temporary and used for drawing user attention.
class BlocxCollectionEventHighlightItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to highlight.
  final T item;

  BlocxCollectionEventHighlightItem({required this.item});
}

/// Clears highlighting from a specific [item].
class BlocxCollectionEventClearHighlightedItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to clear highlighting from.
  final T item;

  BlocxCollectionEventClearHighlightedItem({required this.item});
}

/// Loads the initial page of data into the list.
///
/// [payload] can hold request parameters such as filters, paging info,
/// or repository instructions.
class BlocxCollectionEventLoadInitialPage<T extends BlocxBaseEntity, P> extends BlocxCollectionEvent<T> {
  /// Optional request payload (e.g. filter, page size, etc.).
  final P? payload;

  BlocxCollectionEventLoadInitialPage({required this.payload});
}

/// Refreshes the current list data, reloading from the source.
class BlocxCollectionEventRefreshData<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final bool clearSelection;
  BlocxCollectionEventRefreshData({this.clearSelection = false});
}

/// Loads the next page of items and appends them to the list.
class BlocxCollectionEventLoadNextPage<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {}

/// Runs a search query against the list’s backing source.
///
/// [searchText] contains the query string.
class BlocxCollectionEventSearch<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The text to search for.
  final String searchText;

  BlocxCollectionEventSearch({required this.searchText});
}

/// Loads the next page of search results.
class BlocxCollectionEventSearchNextPage<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {}

/// Refreshes the current search results.
class BlocxCollectionEventSearchRefresh<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {}

/// Clears the current search results and restores the base list.
class BlocxCollectionEventClearSearch<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {}

/// Removes a single [item] from the list.
class BlocxCollectionEventRemoveItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to remove.
  final T item;

  BlocxCollectionEventRemoveItem({required this.item});
}

/// Removes a single [item] from the list.
class BlocxCollectionEventRemoveItemById<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to remove.
  final String identifier;

  BlocxCollectionEventRemoveItemById({required this.identifier});
}

/// Removes multiple [items] from the list at once.
class BlocxCollectionEventRemoveMultipleItems<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The items to remove.
  final List<T> items;

  BlocxCollectionEventRemoveMultipleItems({required this.items});
}

/// Expands a specific [item] in the list (e.g. show details).
class BlocxCollectionEventExpandItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to expand.
  final T item;
  BlocxCollectionEventExpandItem({required this.item});
}

/// Collapses a specific [item] in the list (e.g. hide details).
class BlocxCollectionEventCollapseItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to collapse.
  final T item;
  BlocxCollectionEventCollapseItem({required this.item});
}

class BlocxCollectionEventToggleItemExpansion<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final T item;
  BlocxCollectionEventToggleItemExpansion({required this.item});
}

/// Scrolls the list to a given [item].
///
/// Optionally [highlightItem] to emphasize it once scrolled into view.
class BlocxCollectionEventScrollToItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The target item to scroll to.
  final T item;

  /// Whether the item should be highlighted after scrolling.
  final bool highlightItem;

  BlocxCollectionEventScrollToItem({required this.item, this.highlightItem = false});
}

/// Scrolls the list to an item identified by a string [BlocxBaseEntity.identifier].
///
/// Useful when you only know the item’s identifier (e.g. a username),
/// instead of having the full entity in memory.
class BlocxCollectionEventScrollToIdentifier<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The unique identifier of the target item.
  final String identifier;

  /// Whether the item should be highlighted after scrolling.
  final bool highlightItem;

  BlocxCollectionEventScrollToIdentifier({required this.identifier, this.highlightItem = false});
}

class BlocxCollectionEventHighlightScrolledToItems<T extends BlocxBaseEntity>
    extends BlocxCollectionEvent<T> {}

class BlocxCollectionEventDeselectMultipleItems<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final List<T> items;
  BlocxCollectionEventDeselectMultipleItems({required this.items});
}

class BlocxCollectionEventClearSelection<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  BlocxCollectionEventClearSelection();
}

class BlocxCollectionEventSelectMultipleItems<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final List<T> items;
  BlocxCollectionEventSelectMultipleItems({required this.items});
}

class BlocxCollectionEventAddItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final T item;
  final int index;
  BlocxCollectionEventAddItem({required this.item, this.index = 0});
}

class BlocxCollectionEventUpdateItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final T item;
  BlocxCollectionEventUpdateItem({required this.item});
}

class BlocxCollectionEventReplaceList<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final List<T> newItems;
  BlocxCollectionEventReplaceList({required this.newItems});
}
