import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionEventClearHighlightedItem,
        BlocxCollectionEventHighlightItem,
        BlocxCollectionState;

/// Adds highlight behavior to a [BlocxCollectionBloc].
///
/// ### Events wired
/// - [BlocxCollectionEventHighlightItem] → sets `isHighlighted = true` for the item
/// - [BlocxCollectionEventClearHighlightedItem] → clears highlight (usually after a delay)
mixin BlocxCollectionHighlightableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  final Set<String> _highlightedItemIds = {};

  /// Whether the highlight should auto-clear after [highlightDuration].

  bool get autoClearHighlight => true;

  /// How long a highlight should remain before being auto-cleared.

  Duration get highlightDuration => const Duration(seconds: 3);

  /// Register highlight event handlers.

  void initHighlightMixin() {
    on<BlocxCollectionEventHighlightItem<T>>(highlightItem);
    on<BlocxCollectionEventClearHighlightedItem<T>>(clearHighlightedItem);
  }

  /// Handles [BlocxCollectionEventHighlightItem]:
  /// - Sets `isHighlighted = true` for the given item (immutable update).
  /// - Emits the new state.
  /// - If [autoClearHighlight] is `true`, schedules a clear via
  ///   [BlocxCollectionEventClearHighlightedItem].

  FutureOr<void> highlightItem(
    BlocxCollectionEventHighlightItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    _highlightedItemIds.add(event.item.identifier);
    emitState(emit);
    if (autoClearHighlight) {
      add(BlocxCollectionEventClearHighlightedItem<T>(item: event.item));
    }
  }

  /// Handles [BlocxCollectionEventClearHighlightedItem]:
  /// - Waits [highlightDuration].
  /// - Sets `isHighlighted = false` for the given item (immutable update).
  /// - Emits the new state.

  Future<void> clearHighlightedItem(
    BlocxCollectionEventClearHighlightedItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    await Future.delayed(highlightDuration);
    _highlightedItemIds.remove(event.item.identifier);
    emitState(emit);
  }

  bool isHighlighted(String identifier) {
    return _highlightedItemIds.contains(identifier);
  }

  Set<String> get highlightedItemIdsOriginal => _highlightedItemIds;
}
