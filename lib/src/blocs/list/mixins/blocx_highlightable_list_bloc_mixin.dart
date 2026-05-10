import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show BlocxListBloc, BlocxListEventClearHighlightedItem, BlocxListEventHighlightItem, BlocxListState;

/// Adds highlight behavior to a [BlocxListBloc].
///
/// ### Events wired
/// - [BlocxListEventHighlightItem] → sets `isHighlighted = true` for the item
/// - [BlocxListEventClearHighlightedItem] → clears highlight (usually after a delay)
mixin BlocxHighlightableListBlocMixin<T extends BlocxBaseEntity, P> on BlocxListBloc<T, P> {
  final Set<String> _highlightedItemIds = {};

  /// Whether the highlight should auto-clear after [highlightDuration].

  bool get autoClearHighlight => true;

  /// How long a highlight should remain before being auto-cleared.

  Duration get highlightDuration => const Duration(seconds: 3);

  /// Register highlight event handlers.

  void initHighlightMixin() {
    on<BlocxListEventHighlightItem<T>>(highlightItem);
    on<BlocxListEventClearHighlightedItem<T>>(clearHighlightedItem);
  }

  /// Handles [BlocxListEventHighlightItem]:
  /// - Sets `isHighlighted = true` for the given item (immutable update).
  /// - Emits the new state.
  /// - If [autoClearHighlight] is `true`, schedules a clear via
  ///   [BlocxListEventClearHighlightedItem].

  FutureOr<void> highlightItem(BlocxListEventHighlightItem<T> event, Emitter<BlocxListState<T>> emit) async {
    _highlightedItemIds.add(event.item.identifier);
    emitState(emit);
    if (autoClearHighlight) {
      add(BlocxListEventClearHighlightedItem<T>(item: event.item));
    }
  }

  /// Handles [BlocxListEventClearHighlightedItem]:
  /// - Waits [highlightDuration].
  /// - Sets `isHighlighted = false` for the given item (immutable update).
  /// - Emits the new state.

  Future<void> clearHighlightedItem(
    BlocxListEventClearHighlightedItem<T> event,
    Emitter<BlocxListState<T>> emit,
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
