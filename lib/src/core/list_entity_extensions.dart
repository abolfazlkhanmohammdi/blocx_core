import 'package:blocx/src/core/models/list_entity.dart';

extension ListEntityExtension<T extends ListEntity<T>> on List<T> {
  List<T> get selectedItems => where((e) => e.isSelected).toList();

  void replaceItem(T item) {
    final index = indexOf(item);
    if (index == -1) return;
    this[index] = item;
  }

  void selectItem(T item) => replaceItem(item.copyWith(isSelected: true));

  void deselectItem(T item) => replaceItem(item.copyWith(isSelected: false));

  void setBeingRemoved(T item) => replaceItem(item.copyWith(isBeingRemoved: true));

  void highlightItem(T item) => replaceItem(item.copyWith(isHighlighted: true));

  void clearHighlightedItem(T item) => replaceItem(item.copyWith(isHighlighted: false));

  void clearSelection() {
    for (int i = 0; i < length; i++) {
      this[i] = this[i].copyWith(isSelected: false);
    }
  }
}
