import 'package:blocx/src/list/models/list_entity.dart';

extension ListEntityExtension<T extends ListEntity<T>> on List<T> {
  List<T> get selectedItems => where((e) => e.isSelected).toList();

  void replaceItem(T item) {
    final index = indexWhere((e) => e.identifier == item.identifier);
    if (index == -1) return;
    this[index] = item;
  }

  void selectItem(T item) => replaceItem(item.copyWithListFlags(isSelected: true));

  void deselectItem(T item) => replaceItem(item.copyWithListFlags(isSelected: false));

  void setBeingRemoved(T item) => replaceItem(item.copyWithListFlags(isBeingRemoved: true));
  void clearItemBeingRemoved(T item) => replaceItem(item.copyWithListFlags(isBeingRemoved: false));

  void highlightItem(T item) => replaceItem(item.copyWithListFlags(isHighlighted: true));

  void clearHighlightedItem(T item) => replaceItem(item.copyWithListFlags(isHighlighted: false));

  void removeById(T item) => removeWhere((e) => e.identifier == item.identifier);

  void clearSelection() {
    for (int i = 0; i < length; i++) {
      this[i] = this[i].copyWithListFlags(isSelected: false);
    }
  }
}
