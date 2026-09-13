import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

/// Scrolls the list to a given [item].
///
/// Optionally [highlightItem] to emphasize it once scrolled into view.
class BlocxCollectionEventScrollToItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The target item to scroll to.
  final T item;

  /// Whether the item should be highlighted after scrolling.
  final bool highlightItem;

  BlocxCollectionEventScrollToItem({required this.item, this.highlightItem = false});
}

/// Scrolls the list to an item identified by a string [BlocxBaseEntity.identifier].
///
/// Useful when you only know the item’s identifier (e.g. a username),
/// instead of having the full entity in memory.
class BlocxCollectionEventScrollToIdentifier<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The unique identifier of the target item.
  final String identifier;

  /// Whether the item should be highlighted after scrolling.
  final bool highlightItem;

  BlocxCollectionEventScrollToIdentifier({required this.identifier, this.highlightItem = false});
}

class BlocxCollectionEventHighlightScrolledToItems<T extends BlocxBaseEntity>
    extends BlocxCollectionEvent<T> {}

class BlocxCollectionEventAddItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final T item;
  final int index;
  BlocxCollectionEventAddItem({required this.item, this.index = 0});
}