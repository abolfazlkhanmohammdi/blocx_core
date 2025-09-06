import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';

/// A mixin that adds **expand/collapse support** to a [ListBloc].
///
/// This is useful for UIs where list items can be expanded to show additional
/// content (e.g. accordions, nested details, expandable rows).
///
/// ### How it works
/// - Tracks a set of expanded items by their [BaseEntity.identifier].
/// - Listens to [ListEventExpandItem] and [ListEventCollapseItem].
/// - Updates [_expandedItemIds] accordingly and emits the latest state via [emitState].
///
/// ### Usage
/// ```dart
/// class MyListBloc extends ListBloc<MyEntity, Params>
///     with ExpandableListBlocMixin<MyEntity, Params> {
///   MyListBloc() {
///     initExpandable(); // must be called inside constructor
///   }
/// }
/// ```
///
/// In your UI, you can check whether an item is expanded:
/// ```dart
/// final isExpanded = bloc._expandedItemIds.contains(entity.identifier);
/// ```
///
/// ### Notes
/// - [BaseEntity.identifier] must be **unique and stable** per entity,
///   otherwise expansion state cannot be tracked reliably.
/// - Expansion state is held in-memory; if you rebuild/recreate the bloc,
///   expanded state will reset unless you persist it separately.
mixin ExpandableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  /// Stores the identifiers of currently expanded items.
  ///
  /// Each item is tracked by its [BaseEntity.identifier].
  final Set<String> _expandedItemIds = {};

  /// Registers the event handlers for expansion/collapse.
  ///
  /// Call this in your bloc constructor:
  /// ```dart
  /// MyBloc() {
  ///   initExpandable();
  /// }
  /// ```
  void initExpandable() {
    on<ListEventExpandItem<T>>(expandItem);
    on<ListEventCollapseItem<T>>(collapseItem);
    on<ListEventToggleItemExpansion<T>>(toggleItemExpansion);
  }

  /// Handles [ListEventExpandItem].
  ///
  /// - Adds the item’s [BaseEntity.identifier] to [_expandedItemIds].
  /// - Emits the updated state so the UI can rebuild accordingly.
  FutureOr<void> expandItem(ListEventExpandItem<T> event, Emitter<ListState<T>> emit) {
    _expandedItemIds.add(event.item.identifier);
    emitState(emit);
  }

  /// Handles [ListEventCollapseItem].
  ///
  /// - Removes the item’s [BaseEntity.identifier] from [_expandedItemIds].
  /// - Emits the updated state so the UI can rebuild accordingly.
  FutureOr<void> collapseItem(ListEventCollapseItem<T> event, Emitter<ListState<T>> emit) {
    _expandedItemIds.remove(event.item.identifier);
    emitState(emit);
  }

  Set<String> get expandedItemIdsOriginal => _expandedItemIds;

  FutureOr<void> toggleItemExpansion(ListEventToggleItemExpansion<T> event, Emitter<ListState<T>> emit) {
    final isExpanded = _expandedItemIds.contains(event.item.identifier);
    isExpanded ? _expandedItemIds.remove(event.item.identifier) : _expandedItemIds.add(event.item.identifier);
    emitState(emit);
  }
}
