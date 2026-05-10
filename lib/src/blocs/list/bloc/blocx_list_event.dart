part of 'blocx_list_bloc.dart';

/// Base class for all list-related events.
///
/// Extend this to define actions that mutate or interact with a [BlocxListBloc].
class BlocxListEvent<T extends BlocxBaseEntity> extends BaseEvent {}

/// Selects a single [item] in the list.
///
/// Useful when building UIs that allow user selection (e.g. checkboxes, taps).
class BlocxListEventSelectItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The item to be selected.
  final T item;

  BlocxListEventSelectItem({required this.item});
}

/// Deselects a single [item] in the list.
class BlocxListEventDeselectItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The item to be deselected.
  final T item;

  BlocxListEventDeselectItem({required this.item});
}

/// Highlights a specific [item] in the list.
///
/// Highlighting is typically temporary and used for drawing user attention.
class BlocxListEventHighlightItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The item to highlight.
  final T item;

  BlocxListEventHighlightItem({required this.item});
}

/// Clears highlighting from a specific [item].
class BlocxListEventClearHighlightedItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The item to clear highlighting from.
  final T item;

  BlocxListEventClearHighlightedItem({required this.item});
}

/// Loads the initial page of data into the list.
///
/// [payload] can hold request parameters such as filters, paging info,
/// or repository instructions.
class BlocxListEventLoadInitialPage<T extends BlocxBaseEntity, P> extends BlocxListEvent<T> {
  /// Optional request payload (e.g. filter, page size, etc.).
  final P? payload;

  BlocxListEventLoadInitialPage({required this.payload});
}

/// Refreshes the current list data, reloading from the source.
class BlocxListEventRefreshData<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  final bool clearSelection;
  BlocxListEventRefreshData({this.clearSelection = false});
}

/// Loads the next page of items and appends them to the list.
class BlocxListEventLoadNextPage<T extends BlocxBaseEntity> extends BlocxListEvent<T> {}

/// Runs a search query against the list’s backing source.
///
/// [searchText] contains the query string.
class BlocxListEventSearch<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The text to search for.
  final String searchText;

  BlocxListEventSearch({required this.searchText});
}

/// Loads the next page of search results.
class BlocxListEventSearchNextPage<T extends BlocxBaseEntity> extends BlocxListEvent<T> {}

/// Refreshes the current search results.
class BlocxListEventSearchRefresh<T extends BlocxBaseEntity> extends BlocxListEvent<T> {}

/// Clears the current search results and restores the base list.
class BlocxListEventClearSearch<T extends BlocxBaseEntity> extends BlocxListEvent<T> {}

/// Removes a single [item] from the list.
class BlocxListEventRemoveItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The item to remove.
  final T item;

  BlocxListEventRemoveItem({required this.item});
}

/// Removes a single [item] from the list.
class BlocxListEventRemoveItemById<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The item to remove.
  final String identifier;

  BlocxListEventRemoveItemById({required this.identifier});
}

/// Removes multiple [items] from the list at once.
class BlocxListEventRemoveMultipleItems<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The items to remove.
  final List<T> items;

  BlocxListEventRemoveMultipleItems({required this.items});
}

/// Expands a specific [item] in the list (e.g. show details).
class BlocxListEventExpandItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The item to expand.
  final T item;
  BlocxListEventExpandItem({required this.item});
}

/// Collapses a specific [item] in the list (e.g. hide details).
class BlocxListEventCollapseItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The item to collapse.
  final T item;
  BlocxListEventCollapseItem({required this.item});
}

class BlocxListEventToggleItemExpansion<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  final T item;
  BlocxListEventToggleItemExpansion({required this.item});
}

/// Scrolls the list to a given [item].
///
/// Optionally [highlightItem] to emphasize it once scrolled into view.
class BlocxListEventScrollToItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The target item to scroll to.
  final T item;

  /// Whether the item should be highlighted after scrolling.
  final bool highlightItem;

  BlocxListEventScrollToItem({required this.item, this.highlightItem = false});
}

/// Scrolls the list to an item identified by a string [BlocxBaseEntity.identifier].
///
/// Useful when you only know the item’s identifier (e.g. a username),
/// instead of having the full entity in memory.
class BlocxListEventScrollToIdentifier<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  /// The unique identifier of the target item.
  final String identifier;

  /// Whether the item should be highlighted after scrolling.
  final bool highlightItem;

  BlocxListEventScrollToIdentifier({required this.identifier, this.highlightItem = false});
}

class BlocxListEventHighlightScrolledToItems<T extends BlocxBaseEntity> extends BlocxListEvent<T> {}

class BlocxListEventDeselectMultipleItems<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  final List<T> items;
  BlocxListEventDeselectMultipleItems({required this.items});
}

class BlocxListEventClearSelection<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  BlocxListEventClearSelection();
}

class BlocxListEventSelectMultipleItems<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  final List<T> items;
  BlocxListEventSelectMultipleItems({required this.items});
}

class BlocxListEventAddItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  final T item;
  final int index;
  BlocxListEventAddItem({required this.item, this.index = 0});
}

class BlocxListEventUpdateItem<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  final T item;
  BlocxListEventUpdateItem({required this.item});
}

class BlocxListEventReplaceList<T extends BlocxBaseEntity> extends BlocxListEvent<T> {
  final List<T> newItems;
  BlocxListEventReplaceList({required this.newItems});
}
