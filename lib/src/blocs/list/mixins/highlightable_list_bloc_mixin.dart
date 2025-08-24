import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';

/// Adds highlight behavior to a [ListBloc].
///
/// ### Events wired
/// - [ListEventHighlightItem] → sets `isHighlighted = true` for the item
/// - [ListEventClearHighlightedItem] → clears highlight (usually after a delay)
mixin HighlightableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  final Set<String> _highlightedItemIds = {};

  /// Whether the highlight should auto-clear after [highlightDuration].

  bool get autoClearHighlight => true;

  /// How long a highlight should remain before being auto-cleared.

  Duration get highlightDuration => const Duration(seconds: 3);

  /// Register highlight event handlers.

  void initHighlightMixin() {
    on<ListEventHighlightItem<T>>(highlightItem);
    on<ListEventClearHighlightedItem<T>>(clearHighlightedItem);
  }

  /// Handles [ListEventHighlightItem]:
  /// - Sets `isHighlighted = true` for the given item (immutable update).
  /// - Emits the new state.
  /// - If [autoClearHighlight] is `true`, schedules a clear via
  ///   [ListEventClearHighlightedItem].

  FutureOr<void> highlightItem(ListEventHighlightItem<T> event, Emitter<ListState<T>> emit) async {
    _highlightedItemIds.add(event.item.identifier);
    emitState(emit);
    if (autoClearHighlight) {
      add(ListEventClearHighlightedItem<T>(item: event.item));
    }
  }

  /// Handles [ListEventClearHighlightedItem]:
  /// - Waits [highlightDuration].
  /// - Sets `isHighlighted = false` for the given item (immutable update).
  /// - Emits the new state.

  Future<void> clearHighlightedItem(
    ListEventClearHighlightedItem<T> event,
    Emitter<ListState<T>> emit,
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
