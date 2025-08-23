import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/core/list_entity_extensions.dart';
import 'package:blocx/src/core/logger.dart';
import 'package:blocx/src/list/misc/event_transformers.dart';

/// A mixin that adds **scroll-to-item** capabilities for list-based blocs.
///
/// This mixin enables your [ListBloc] to:
/// - Scroll directly to a concrete [item] ([ListEventScrollToItem]).
/// - Scroll to an item by its stable [BaseEntity.identifier]
///   ([ListEventScrollToIdentifier]).
/// - Optionally highlight the item (if [HighlightableListBlocMixin] is also applied).
///
/// Usage:
/// ```dart
/// class MyListBloc extends ListBloc<MyEntity, Params>
///     with ScrollableListBlocMixin<MyEntity, Params>,
///          HighlightableListBlocMixin<MyEntity, Params> {
///   MyListBloc() {
///     initScrollable();
///     initHighlightable();
///   }
/// }
/// ```
///
/// Events:
/// - [ListEventScrollToItem]
/// - [ListEventScrollToIdentifier]
///
/// States:
/// - [ListStateScrollToItem] is emitted with the resolved item and target index.
mixin ScrollableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  List<T> toBeHighlightedItems = [];

  /// Initializes the mixin by registering its event handlers.
  ///
  /// Must be called inside the bloc constructor after super initialization:
  /// ```dart
  /// MyListBloc() {
  ///   initScrollable();
  /// }
  /// ```
  void initScrollable() {
    on<ListEventScrollToItem<T>>(scrollToItem);
    on<ListEventScrollToIdentifier<T>>(scrollToIdentifier);
    on<ListEventHighlightScrolledToItems<T>>(
      highlightScrolledToItems,
      transformer: debounceRestartable(Duration(milliseconds: 500)),
    );
  }

  /// Handles [ListEventScrollToItem]:
  /// - Resolves the index of [event.item] in the current list.
  /// - Optionally highlights it.
  /// - Emits [ListStateScrollToItem] so the UI can perform the scroll.
  FutureOr<void> scrollToItem(ListEventScrollToItem<T> event, Emitter<ListState<T>> emit) {
    final index = list.indexById(event.item);
    if (event.highlightItem) toBeHighlightedItems.add(event.item);
    emit(ListStateScrollToItem(item: event.item, index: index));
    emitState(emit);
  }

  /// Handles [ListEventScrollToIdentifier]:
  /// - Finds the item whose [BaseEntity.identifier] matches [event.identifier].
  /// - If found, optionally highlights it and emits [ListStateScrollToItem].
  /// - If not found, no state is emitted (no-op).
  FutureOr<void> scrollToIdentifier(ListEventScrollToIdentifier<T> event, Emitter<ListState<T>> emit) async {
    // If you have an extension like `indexByIdentifier`, use that.
    // Fallback to a simple search to avoid tight coupling.
    final index = list.indexWhere((e) => e.identifier == event.identifier);
    if (index < 0) return; // not found -> ignore (or emit a dedicated error state if you prefer)
    final item = list[index];
    if (event.highlightItem) toBeHighlightedItems.add(item);
    emit(ListStateScrollToItem(item: item, index: index));
    emitState(emit);
  }

  /// Attempts to highlight the given [item].
  ///
  /// Requires that the bloc also mixes in [HighlightableListBlocMixin].
  /// Dispatches a [ListEventHighlightItem] if available.
  ///
  /// Throws a [StateError] if highlight was requested but the mixin is not present.
  void _tryHighlightItem(T item) {
    if (this is HighlightableListBlocMixin<T, P>) {
      add(ListEventHighlightItem<T>(item: item));
    } else {
      throw StateError(
        'ToIndexScrollableListBlocMixin: highlight requested but '
        'HighlightableListBlocMixin is not applied.',
      );
    }
  }

  FutureOr<void> highlightScrolledToItems(
    ListEventHighlightScrolledToItems<T> event,
    Emitter<ListState<T>> emit,
  ) {
    logger.i("ListEventHighlightScrollToItems");
    for (T item in toBeHighlightedItems) {
      add(ListEventHighlightItem(item: item));
    }
    toBeHighlightedItems.clear();
  }
}
