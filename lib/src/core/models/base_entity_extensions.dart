import 'package:blocx_core/blocx_core.dart';

extension ListEntityExtension<T extends BlocxBaseEntity> on List<T> {
  void replaceItem(T item) {
    final index = indexWhere((e) => e.identifier == item.identifier);
    if (index == -1) return;
    this[index] = item;
  }

  bool removeById(T item) {
    final index = indexById(item);
    if (index == -1) return false;
    removeAt(index);
    return true;
  }
  int indexById(T item) => indexWhere((e) => e.identifier == item.identifier);
}
