import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';

/// A mixin that adds **expand/collapse support** to a [ListBloc].
///
/// This is useful for UIs where list items can be expanded to show additional
/// content (e.g. accordions, nested details, expandable rows).
///
/// ### How it works
/// - Tracks a set of expanded items by their [BaseEntity.identifier].
/// - Listens to [ListEventExpandItem] and [ListEventCollapseItem].
/// - Updates [expandedItemIds] accordingly and emits the latest state via [emitState].
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
/// final isExpanded = bloc.expandedItemIds.contains(entity.identifier);
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
  final Set<String> expandedItemIds = {};

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
  }

  /// Handles [ListEventExpandItem].
  ///
  /// - Adds the item’s [BaseEntity.identifier] to [expandedItemIds].
  /// - Emits the updated state so the UI can rebuild accordingly.
  FutureOr<void> expandItem(ListEventExpandItem<T> event, Emitter<ListState<T>> emit) {
    expandedItemIds.add(event.item.identifier);
    emitState(emit);
  }

  /// Handles [ListEventCollapseItem].
  ///
  /// - Removes the item’s [BaseEntity.identifier] from [expandedItemIds].
  /// - Emits the updated state so the UI can rebuild accordingly.
  FutureOr<void> collapseItem(ListEventCollapseItem<T> event, Emitter<ListState<T>> emit) {
    expandedItemIds.remove(event.item.identifier);
    emitState(emit);
  }
}
