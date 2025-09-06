part of 'list_bloc.dart';

/// Base class for all list-related events.
///
/// Extend this to define actions that mutate or interact with a [ListBloc].
class ListEvent<T extends BaseEntity> extends BaseEvent {}

/// Selects a single [item] in the list.
///
/// Useful when building UIs that allow user selection (e.g. checkboxes, taps).
class ListEventSelectItem<T extends BaseEntity> extends ListEvent<T> {
  /// The item to be selected.
  final T item;

  ListEventSelectItem({required this.item});
}

/// Deselects a single [item] in the list.
class ListEventDeselectItem<T extends BaseEntity> extends ListEvent<T> {
  /// The item to be deselected.
  final T item;

  ListEventDeselectItem({required this.item});
}

/// Highlights a specific [item] in the list.
///
/// Highlighting is typically temporary and used for drawing user attention.
class ListEventHighlightItem<T extends BaseEntity> extends ListEvent<T> {
  /// The item to highlight.
  final T item;

  ListEventHighlightItem({required this.item});
}

/// Clears highlighting from a specific [item].
class ListEventClearHighlightedItem<T extends BaseEntity> extends ListEvent<T> {
  /// The item to clear highlighting from.
  final T item;

  ListEventClearHighlightedItem({required this.item});
}

/// Loads the initial page of data into the list.
///
/// [payload] can hold request parameters such as filters, paging info,
/// or repository instructions.
class ListEventLoadInitialPage<T extends BaseEntity, P> extends ListEvent<T> {
  /// Optional request payload (e.g. filter, page size, etc.).
  final P? payload;

  ListEventLoadInitialPage({required this.payload});
}

/// Refreshes the current list data, reloading from the source.
class ListEventRefreshData<T extends BaseEntity> extends ListEvent<T> {}

/// Loads the next page of items and appends them to the list.
class ListEventLoadNextPage<T extends BaseEntity> extends ListEvent<T> {}

/// Runs a search query against the list’s backing source.
///
/// [searchText] contains the query string.
class ListEventSearch<T extends BaseEntity> extends ListEvent<T> {
  /// The text to search for.
  final String searchText;

  ListEventSearch({required this.searchText});
}

/// Loads the next page of search results.
class ListEventSearchNextPage<T extends BaseEntity> extends ListEvent<T> {}

/// Refreshes the current search results.
class ListEventSearchRefresh<T extends BaseEntity> extends ListEvent<T> {}

/// Clears the current search results and restores the base list.
class ListEventClearSearch<T extends BaseEntity> extends ListEvent<T> {}

/// Removes a single [item] from the list.
class ListEventRemoveItem<T extends BaseEntity> extends ListEvent<T> {
  /// The item to remove.
  final T item;

  ListEventRemoveItem({required this.item});
}

/// Removes multiple [items] from the list at once.
class ListEventRemoveMultipleItems<T extends BaseEntity> extends ListEvent<T> {
  /// The items to remove.
  final List<T> items;

  ListEventRemoveMultipleItems({required this.items});
}

/// Expands a specific [item] in the list (e.g. show details).
class ListEventExpandItem<T extends BaseEntity> extends ListEvent<T> {
  /// The item to expand.
  final T item;
  ListEventExpandItem({required this.item});
}

/// Collapses a specific [item] in the list (e.g. hide details).
class ListEventCollapseItem<T extends BaseEntity> extends ListEvent<T> {
  /// The item to collapse.
  final T item;
  ListEventCollapseItem({required this.item});
}

class ListEventToggleItemExpansion<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  ListEventToggleItemExpansion({required this.item});
}

/// Scrolls the list to a given [item].
///
/// Optionally [highlightItem] to emphasize it once scrolled into view.
class ListEventScrollToItem<T extends BaseEntity> extends ListEvent<T> {
  /// The target item to scroll to.
  final T item;

  /// Whether the item should be highlighted after scrolling.
  final bool highlightItem;

  ListEventScrollToItem({required this.item, this.highlightItem = false});
}

/// Scrolls the list to an item identified by a string [BaseEntity.identifier].
///
/// Useful when you only know the item’s identifier (e.g. a username),
/// instead of having the full entity in memory.
class ListEventScrollToIdentifier<T extends BaseEntity> extends ListEvent<T> {
  /// The unique identifier of the target item.
  final String identifier;

  /// Whether the item should be highlighted after scrolling.
  final bool highlightItem;

  ListEventScrollToIdentifier({required this.identifier, this.highlightItem = false});
}

class ListEventHighlightScrolledToItems<T extends BaseEntity> extends ListEvent<T> {}

class ListEventDeselectMultipleItems<T extends BaseEntity> extends ListEvent<T> {
  final List<T> items;
  ListEventDeselectMultipleItems({required this.items});
}

class ListEventAddItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  final int index;
  ListEventAddItem({required this.item, this.index = 0});
}

class ListEventUpdateItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  ListEventUpdateItem({required this.item});
}
