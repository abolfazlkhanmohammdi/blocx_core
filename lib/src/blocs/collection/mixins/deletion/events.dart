import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

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
