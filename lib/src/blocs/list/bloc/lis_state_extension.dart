part of './list_bloc.dart';

extension ListStateExtensions<T extends BaseEntity> on ListState<T> {
  // --- Selection ---
  bool isSelected(T item) => selectedItemIds.contains(item.identifier);
  bool isSelectedId(String id) => selectedItemIds.contains(id);
  bool get hasSelection => selectedItemIds.isNotEmpty;
  int get selectedCount => selectedItemIds.length;

  List<T> get selectedItems => list.where((e) => selectedItemIds.contains(e.identifier)).toList();

  T? firstSelectedItemOrNull() {
    for (final e in list) {
      if (selectedItemIds.contains(e.identifier)) return e;
    }
    return null;
  }

  // --- Being selected (optimistic selection in-flight) ---
  bool isBeingSelected(T item) => beingSelectedItemIds.contains(item.identifier);
  bool isBeingSelectedId(String id) => beingSelectedItemIds.contains(id);

  // --- Highlight ---
  bool isHighlighted(T item) => highlightedItemIds.contains(item.identifier);
  bool isHighlightedId(String id) => highlightedItemIds.contains(id);

  // --- Being removed (optimistic deletion in-flight) ---
  bool isBeingRemoved(T item) => beingRemovedItemIds.contains(item.identifier);
  bool isBeingRemovedId(String id) => beingRemovedItemIds.contains(id);

  //--- Expansion ---
  bool isExpanded(T item) => expandedItemIds.contains(item.identifier);

  // --- Utilities ---
  int indexOfId(String id) => list.indexWhere((e) => e.identifier == id);

  /// Useful for quick guards in UI
  bool get isBusy => isRefreshing || isLoadingNextPage || isSearching;
}
