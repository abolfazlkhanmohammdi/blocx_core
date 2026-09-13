import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

/// Highlights a specific [item] in the list.
///
/// Highlighting is typically temporary and used for drawing user attention.
class BlocxCollectionEventHighlightItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to highlight.
  final T item;

  BlocxCollectionEventHighlightItem({required this.item});
}

/// Clears highlighting from a specific [item].
class BlocxCollectionEventClearHighlightedItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The item to clear highlighting from.
  final T item;

  BlocxCollectionEventClearHighlightedItem({required this.item});
}