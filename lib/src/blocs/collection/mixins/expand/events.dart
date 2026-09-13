import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

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
