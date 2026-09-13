import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

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
