import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';

/// Adds selection behavior to a [ListBloc].
///
/// ### Features
/// - **Single- or multi-select** via [isSingleSelect].
/// - **Server sync (preferred via use cases):**
///   - Provide [selectItemUseCase] / [deselectItemUseCase] (preferred).
///   - Or override [performRemoteSelection] / [performRemoteDeselection] (fallback).
/// - **Rollback on failure** when server sync is enabled.
/// - **Extensible hooks** for UX/telemetry ([onItemSelected], [onItemDeselected], [onSelectionSyncFailed]).
///
/// ### Event wiring
/// Registers:
/// - [ListEventSelectItem]
/// - [ListEventDeselectItem]
mixin SelectableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  final Set<String> _selectedItemIds = {};
  final Set<String> _beingSelectedItemIds = {};
  // ===========================================================================
  // Configuration
  // ===========================================================================

  /// When `true`, selecting an item clears any existing selection first.
  ///
  /// Defaults to `true` (single-select). Override to enable multi-select.

  bool get isSingleSelect => true;

  /// When `true`, selection/deselection attempts a remote sync:
  /// - [selectItem] → uses [selectItemUseCase] if set, else [performRemoteSelection]
  /// - [deselectItem] → uses [deselectItemUseCase] if set, else [performRemoteDeselection]
  ///
  /// On failure/exception, the local change is **rolled back** and
  /// [onSelectionSyncFailed] is invoked.
  bool get syncWithServerOnSelection => false;

  // ===========================================================================
  // Use cases (preferred)
  // ===========================================================================

  /// Preferred: a use case that performs the remote **selection** side-effect.
  ///
  /// Return `bool` inside [UseCaseResult]:
  /// - `true`  → success
  /// - `false` → logical failure (triggers rollback)
  ///
  /// If `null`, the mixin falls back to [performRemoteSelection].

  BaseUseCase<bool>? get selectItemUseCase => null;

  /// Preferred: a use case that performs the remote **deselection** side-effect.
  ///
  /// Return `bool` inside [UseCaseResult]:
  /// - `true`  → success
  /// - `false` → logical failure (triggers rollback)
  ///
  /// If `null`, the mixin falls back to [performRemoteDeselection].

  BaseUseCase<bool>? get deselectItemUseCase => null;

  // ===========================================================================
  // Initialization
  // ===========================================================================

  /// Registers select/deselect handlers.

  void initSelectionMixin() {
    on<ListEventSelectItem<T>>(selectItem);
    on<ListEventDeselectItem<T>>(deselectItem);
    on<ListEventDeselectMultipleItems<T>>(deselectMultipleItems);
  }

  // ===========================================================================
  // Handlers
  // ===========================================================================

  /// Handles [ListEventSelectItem].
  ///
  /// Flow:
  /// 1) If [isSingleSelect], clears existing selection.
  /// 2) Selects locally; [emitState].
  /// 3) If [syncWithServerOnSelection]:
  ///    - Prefer [selectItemUseCase]; else use [performRemoteSelection].
  ///    - On failure/exception: rollback (deselect), [emitState], then [onSelectionSyncFailed].

  Future<void> selectItem(ListEventSelectItem<T> event, Emitter<ListState<T>> emit) async {
    if (isSingleSelect) _selectedItemIds.clear();
    _selectedItemIds.add(event.item.identifier);
    emitState(emit);

    if (!syncWithServerOnSelection) {
      onItemSelected(event.item);
      return;
    }

    try {
      _beingSelectedItemIds.add(event.item.identifier);
      emitState(emit);
      final ok = await _runSelectRemote();
      _beingSelectedItemIds.remove(event.item.identifier);
      emitState(emit);
      if (ok) {
        onItemSelected(event.item);
        return;
      }
      // rollback on failure
      _selectedItemIds.remove(event.item.identifier);
      emitState(emit);
      onSelectionSyncFailed(event.item, isSelectOperation: true);
    } catch (_) {
      // rollback on exception
      _selectedItemIds.remove(event.item.identifier);
      emitState(emit);
      onSelectionSyncFailed(event.item, isSelectOperation: true);
    }
  }

  /// Handles [ListEventDeselectItem].
  ///
  /// Flow:
  /// 1) Deselects locally; [emitState].
  /// 2) If [syncWithServerOnSelection]:
  ///    - Prefer [deselectItemUseCase]; else use [performRemoteDeselection].
  ///    - On failure/exception: rollback (re-select), [emitState], then [onSelectionSyncFailed].

  Future<void> deselectItem(ListEventDeselectItem<T> event, Emitter<ListState<T>> emit) async {
    _selectedItemIds.remove(event.item.identifier);
    emitState(emit);
    if (!syncWithServerOnSelection) {
      onItemDeselected(event.item);
      return;
    }

    try {
      final ok = await _runDeselectRemote();
      if (ok) {
        onItemDeselected(event.item);
        return;
      }
      // rollback on failure
      _selectedItemIds.add(event.item.identifier);
      emitState(emit);
      onSelectionSyncFailed(event.item, isSelectOperation: false);
    } catch (_) {
      // rollback on exception
      emitState(emit);
      onSelectionSyncFailed(event.item, isSelectOperation: false);
    }
  }

  // ===========================================================================
  // Remote sync runners (prefer use cases; fallback to methods)
  // ===========================================================================

  Future<bool> _runSelectRemote() async {
    final uc = selectItemUseCase;
    if (uc != null) {
      final res = await uc.execute();
      return res.isSuccess && (res.data ?? false);
    }
    return await performRemoteSelection();
  }

  Future<bool> _runDeselectRemote() async {
    final uc = deselectItemUseCase;
    if (uc != null) {
      final res = await uc.execute();
      return res.isSuccess && (res.data ?? false);
    }
    return await performRemoteDeselection();
  }

  // ===========================================================================
  // Remote sync (fallback methods)
  // ===========================================================================

  /// Fallback for **selection** if [selectItemUseCase] is `null`.
  ///
  /// Must be overridden if [syncWithServerOnSelection] is `true` and you do not
  /// provide a [selectItemUseCase].
  ///
  /// Throwing by default ensures you don’t silently ignore server sync.
  Future<bool> performRemoteSelection() {
    throw UnimplementedError(
      "performRemoteSelection() not implemented. "
      "Either provide a `selectItemUseCase` or override this method in your bloc.",
    );
  }

  /// Fallback for **deselection** if [deselectItemUseCase] is `null`.
  ///
  /// Must be overridden if [syncWithServerOnSelection] is `true` and you do not
  /// provide a [deselectItemUseCase].
  ///
  /// Throwing by default ensures you don’t silently ignore server sync.
  Future<bool> performRemoteDeselection() {
    throw UnimplementedError(
      "performRemoteDeselection() not implemented. "
      "Either provide a `deselectItemUseCase` or override this method in your bloc.",
    );
  }

  // ===========================================================================
  // Hooks (UX / telemetry)
  // ===========================================================================

  /// Called after a successful (local + optional remote) *selection*.
  void onItemSelected(T item) {}

  /// Called after a successful (local + optional remote) *deselection*.
  void onItemDeselected(T item) {}

  /// Called when remote sync fails and the local change has been rolled back.
  void onSelectionSyncFailed(T item, {required bool isSelectOperation}) {
    displayWarningSnackbar(
      isSelectOperation
          ? "Could not select the item. Please try again."
          : "Could not deselect the item. Please try again.",
    );
  }

  Set<String> get beingSelectedItemIdsOriginal => _beingSelectedItemIds;

  Set<String> get selectedItemIdsOriginal => _selectedItemIds;

  FutureOr<void> deselectMultipleItems(ListEventDeselectMultipleItems<T> event, Emitter<ListState<T>> emit) {
    for (T item in event.items) {
      selectedItemIds.remove(item.identifier);
    }
    emitState(emit);
  }
}
