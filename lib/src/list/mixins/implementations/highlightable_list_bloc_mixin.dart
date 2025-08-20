import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/mixins/contracts/highlightable_list_bloc_contract.dart';
import 'package:blocx/src/list/models/list_entity.dart';

/// Adds highlight behavior to a [ListBloc].
///
/// ### Events wired
/// - [ListEventHighlightItem] → sets `isHighlighted = true` for the item
/// - [ListEventClearHighlightedItem] → clears highlight (usually after a delay)
mixin HighlightableListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
    implements HighlightableListBlocContract<T> {
  /// Whether the highlight should auto-clear after [highlightDuration].
  @override
  bool get autoClearHighlight => true;

  /// How long a highlight should remain before being auto-cleared.
  @override
  Duration get highlightDuration => const Duration(seconds: 3);

  /// Register highlight event handlers.
  @override
  void initHighlightMixin() {
    on<ListEventHighlightItem<T>>(highlightItem);
    on<ListEventClearHighlightedItem<T>>(clearHighlightedItem);
  }

  /// Handles [ListEventHighlightItem]:
  /// - Sets `isHighlighted = true` for the given item (immutable update).
  /// - Emits the new state.
  /// - If [autoClearHighlight] is `true`, schedules a clear via
  ///   [ListEventClearHighlightedItem].
  @override
  FutureOr<void> highlightItem(ListEventHighlightItem<T> event, Emitter<ListState<T>> emit) async {
    highlightItemInList(event.item);
    emitState(emit);

    if (autoClearHighlight) {
      add(ListEventClearHighlightedItem<T>(item: event.item));
    }
  }

  /// Handles [ListEventClearHighlightedItem]:
  /// - Waits [highlightDuration].
  /// - Sets `isHighlighted = false` for the given item (immutable update).
  /// - Emits the new state.
  @override
  Future<void> clearHighlightedItem(
    ListEventClearHighlightedItem<T> event,
    Emitter<ListState<T>> emit,
  ) async {
    await Future.delayed(highlightDuration);
    clearHighlightedItemInList(event.item);
    emitState(emit);
  }
}
