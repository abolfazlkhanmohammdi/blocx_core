import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart' show BlocxCollectionBloc, BlocxCollectionState;

import 'events.dart';

/// A mixin that adds **expand/collapse support** to a [BlocxCollectionBloc].
///
/// This is useful for UIs where list items can be expanded to show additional
/// content (e.g. accordions, nested details, expandable rows).
///
/// ### How it works
/// - Tracks a set of expanded items by their [BlocxBaseEntity.identifier].
/// - Listens to [BlocxCollectionEventExpandItem] and [BlocxCollectionEventCollapseItem].
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
/// - [BlocxBaseEntity.identifier] must be **unique and stable** per entity,
///   otherwise expansion state cannot be tracked reliably.
/// - Expansion state is held in-memory; if you rebuild/recreate the bloc,
///   expanded state will reset unless you persist it separately.
mixin BlocxCollectionExpandableMixin<Entity extends BlocxBaseEntity, Payload>
    on BlocxCollectionBloc<Entity, Payload> {
  /// Stores the identifiers of currently expanded items.
  ///
  /// Each item is tracked by its [BlocxBaseEntity.identifier].
  final Set<String> _expandedItemIds = {};

  /// Registers the event handlers for expansion/collapse.
  ///
  /// Call this in your bloc constructor:
  /// ```dart
  /// MyBloc() {
  ///   initExpandable();
  /// }
  /// ```
  @override
  bool initExpandable() {
    on<BlocxCollectionEventExpandItem<Entity>>(expandItem);
    on<BlocxCollectionEventCollapseItem<Entity>>(collapseItem);
    on<BlocxCollectionEventToggleItemExpansion<Entity>>(toggleItemExpansion);
    return true;
  }

  /// Handles [BlocxCollectionEventExpandItem].
  ///
  /// - Adds the item’s [BlocxBaseEntity.identifier] to [_expandedItemIds].
  /// - Emits the updated state so the UI can rebuild accordingly.
  FutureOr<void> expandItem(
      BlocxCollectionEventExpandItem<Entity> event, Emitter<BlocxCollectionState<Entity>> emit) {
    _expandedItemIds.add(event.item.identifier);
    emitState(emit);
  }

  /// Handles [BlocxCollectionEventCollapseItem].
  ///
  /// - Removes the item’s [BlocxBaseEntity.identifier] from [_expandedItemIds].
  /// - Emits the updated state so the UI can rebuild accordingly.
  FutureOr<void> collapseItem(
    BlocxCollectionEventCollapseItem<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) {
    _expandedItemIds.remove(event.item.identifier);
    emitState(emit);
  }

  Set<String> get expandedItemIdsOriginal => _expandedItemIds;

  FutureOr<void> toggleItemExpansion(
    BlocxCollectionEventToggleItemExpansion<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) {
    final isExpanded = _expandedItemIds.contains(event.item.identifier);
    isExpanded ? _expandedItemIds.remove(event.item.identifier) : _expandedItemIds.add(event.item.identifier);
    emitState(emit);
  }
}
