import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionEventSelectMultipleItems,
        BlocxCollectionEventSelectItem,
        BlocxCollectionEventDeselectItem,
        BlocxCollectionEventDeselectMultipleItems,
        BlocxCollectionEventClearSelection,
        BlocxCollectionState,
        SelectionChangedData,
        BlocxCollectionStateSelectionChanged;

/// Adds selection behavior to a [BlocxCollectionBloc].
///
/// ### Features
/// - Single / multi select support
/// - Optional server sync
/// - Rollback on failure
/// - Hooks for UX / analytics
mixin BlocxCollectionSelectableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  final Set<String> _selectedItemIds = {};
  final Set<String> _beingSelectedItemIds = {};

  // ===========================================================================
  // Configuration
  // ===========================================================================

  bool get isSingleSelect => true;
  bool get syncWithServerOnSelection => false;

  // ===========================================================================
  // Use cases (optional)
  // ===========================================================================

  BlocxBaseUseCase<T, bool>? get selectItemUseCase => null;
  BlocxBaseUseCase<T, bool>? get deselectItemUseCase => null;

  // ===========================================================================
  // Init
  // ===========================================================================

  void initSelectionMixin() {
    on<BlocxCollectionEventSelectItem<T>>(selectItem);
    on<BlocxCollectionEventDeselectItem<T>>(deselectItem);
    on<BlocxCollectionEventDeselectMultipleItems<T>>(deselectMultipleItems);
    on<BlocxCollectionEventSelectMultipleItems<T>>(selectMultipleItems);
    on<BlocxCollectionEventClearSelection<T>>(clearSelection);
  }

  // ===========================================================================
  // Select
  // ===========================================================================

  Future<void> selectItem(
    BlocxCollectionEventSelectItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    if (isSingleSelect) _selectedItemIds.clear();

    _selectedItemIds.add(event.item.identifier);
    emitState(emit);

    if (!syncWithServerOnSelection) {
      emitSelectionChanged(emit, event.item, true);
      return;
    }

    try {
      _beingSelectedItemIds.add(event.item.identifier);
      emitState(emit);

      final ok = await _runSelectRemote(event.item);

      _beingSelectedItemIds.remove(event.item.identifier);
      emitState(emit);

      if (!ok) {
        _selectedItemIds.remove(event.item.identifier);
        emitState(emit);
        onSelectionSyncFailed(event.item, isSelectOperation: true);
        return;
      }

      emitSelectionChanged(emit, event.item, true);
    } catch (_) {
      _selectedItemIds.remove(event.item.identifier);
      emitState(emit);
      onSelectionSyncFailed(event.item, isSelectOperation: true);
    }
  }

  // ===========================================================================
  // Deselect
  // ===========================================================================

  Future<void> deselectItem(
    BlocxCollectionEventDeselectItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    _selectedItemIds.remove(event.item.identifier);
    emitState(emit);

    if (!syncWithServerOnSelection) {
      emitSelectionChanged(emit, event.item, false);
      return;
    }

    try {
      final ok = await _runDeselectRemote(event.item);

      if (!ok) {
        _selectedItemIds.add(event.item.identifier);
        emitState(emit);
        onSelectionSyncFailed(event.item, isSelectOperation: false);
        return;
      }

      emitSelectionChanged(emit, event.item, false);
    } catch (_) {
      _selectedItemIds.add(event.item.identifier);
      emitState(emit);
      onSelectionSyncFailed(event.item, isSelectOperation: false);
    }
  }

  // ===========================================================================
  // Remote execution (FIXED)
  // ===========================================================================

  Future<bool> _runSelectRemote(T item) async {
    final uc = selectItemUseCase;

    if (uc != null) {
      final res = await uc.execute(item); // ✅ FIXED
      return res.isSuccess && (res.data ?? false);
    }

    return performRemoteSelection();
  }

  Future<bool> _runDeselectRemote(T item) async {
    final uc = deselectItemUseCase;

    if (uc != null) {
      final res = await uc.execute(item); // ✅ FIXED
      return res.isSuccess && (res.data ?? false);
    }

    return performRemoteDeselection();
  }

  // ===========================================================================
  // Fallbacks
  // ===========================================================================

  Future<bool> performRemoteSelection() {
    throw UnimplementedError(
      "performRemoteSelection() not implemented. "
      "Provide selectItemUseCase or override this method.",
    );
  }

  Future<bool> performRemoteDeselection() {
    throw UnimplementedError(
      "performRemoteDeselection() not implemented. "
      "Provide deselectItemUseCase or override this method.",
    );
  }

  // ===========================================================================
  // Emit helpers
  // ===========================================================================

  void emitSelectionChanged(Emitter<BlocxCollectionState<T>> emit, T item, bool wasSelected) {
    emit(
      BlocxCollectionStateSelectionChanged(
        list: list,
        hasReachedEnd: hasReachedEnd,
        isLoadingNextPage: isLoadingNextPage,
        isRefreshing: isRefreshing,
        isSearching: isSearching,
        selectedItemIds: selectedItemIds,
        beingSelectedItemIds: beingSelectedItemIds,
        highlightedItemIds: highlightedItemIds,
        beingRemovedItemIds: beingRemovedItemIds,
        expandedItemIds: expandedItemIds,
        selectionData: SelectionChangedData(selection: selectedItems, wasSelected: wasSelected, item: item),
      ),
    );
  }

  // ===========================================================================
  // Hooks
  // ===========================================================================

  void onSelectionSyncFailed(T item, {required bool isSelectOperation}) {
    displayWarningSnackbar(
      isSelectOperation
          ? "Could not select the item. Please try again."
          : "Could not deselect the item. Please try again.",
    );
  }

  // ===========================================================================
  // Public state
  // ===========================================================================

  Set<String> get beingSelectedItemIdsOriginal => _beingSelectedItemIds;
  Set<String> get selectedItemIdsOriginal => _selectedItemIds;

  List<T> get selectedItems => list.where((e) => _selectedItemIds.contains(e.identifier)).toList();

  // ===========================================================================
  // Multi select
  // ===========================================================================

  FutureOr<void> deselectMultipleItems(
    BlocxCollectionEventDeselectMultipleItems<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    for (final item in event.items) {
      _selectedItemIds.remove(item.identifier);
    }

    emitSelectionChanged(emit, event.items.first, true);
    emitState(emit);
  }

  FutureOr<void> selectMultipleItems(
    BlocxCollectionEventSelectMultipleItems<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    _selectedItemIds
      ..clear()
      ..addAll(event.items.map((e) => e.identifier));

    emitSelectionChanged(emit, event.items.first, false);
    emitState(emit);
  }

  FutureOr<void> clearSelection(
    BlocxCollectionEventClearSelection<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    _selectedItemIds.clear();
    emitState(emit);
  }
}
