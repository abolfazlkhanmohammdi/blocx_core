import 'package:blocx_core/blocx_core.dart';

extension ListEntityExtension<T extends BaseEntity> on List<T> {
  void replaceItem(T item) {
    final index = indexWhere((e) => e.identifier == item.identifier);
    if (index == -1) return;
    this[index] = item;
  }

  void removeById(T item) => removeWhere((e) => e.identifier == item.identifier);
  int indexById(T item) => indexWhere((e) => e.identifier == item.identifier);
}
