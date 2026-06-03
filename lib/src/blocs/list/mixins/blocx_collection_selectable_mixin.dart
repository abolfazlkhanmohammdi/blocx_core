import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionEventClearSelection,
        BlocxCollectionEventDeselectItem,
        BlocxCollectionEventDeselectMultipleItems,
        BlocxCollectionEventSelectItem,
        BlocxCollectionEventSelectMultipleItems,
        BlocxCollectionState,
        BlocxCollectionStateSelectionChanged,
        SelectionChangedData;

/// Adds item selection behavior to a [BlocxCollectionBloc].
///
/// Supports single-select, multi-select, optional remote selection syncing,
/// rollback on sync failure, and selection-change notifications.
mixin BlocxCollectionSelectableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  final Set<String> _selectedItemIds = <String>{};
  final Set<String> _beingSelectedItemIds = <String>{};

  /// Whether only one item can be selected at a time.
  bool get isSingleSelect => true;

  /// Whether selection and deselection should be synced with a remote source.
  bool get syncWithServerOnSelection => false;

  /// Creates the task used to sync selecting [item].
  ///
  /// Return `null` to use [performRemoteSelection] instead.
  BlocxUseCaseTask<Object?, bool>? selectItemTask(T item) => null;

  /// Creates the task used to sync deselecting [item].
  ///
  /// Return `null` to use [performRemoteDeselection] instead.
  BlocxUseCaseTask<Object?, bool>? deselectItemTask(T item) => null;

  /// Registers selection event handlers.
  void initSelectionMixin() {
    on<BlocxCollectionEventSelectItem<T>>(selectItem);
    on<BlocxCollectionEventDeselectItem<T>>(deselectItem);
    on<BlocxCollectionEventDeselectMultipleItems<T>>(deselectMultipleItems);
    on<BlocxCollectionEventSelectMultipleItems<T>>(selectMultipleItems);
    on<BlocxCollectionEventClearSelection<T>>(clearSelection);
  }

  /// Selects one item.
  Future<void> selectItem(
    BlocxCollectionEventSelectItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final item = event.item;
    final previousSelection = Set<String>.from(_selectedItemIds);

    if (isSingleSelect) {
      _selectedItemIds.clear();
    }

    _selectedItemIds.add(item.identifier);
    emitState(emit);

    if (!syncWithServerOnSelection) {
      emitSelectionChanged(emit, item, wasSelected: true);
      return;
    }

    _beingSelectedItemIds.add(item.identifier);
    emitState(emit);

    try {
      final synced = await _runSelectRemote(item, emit);

      _beingSelectedItemIds.remove(item.identifier);

      if (!synced) {
        _restoreSelection(previousSelection);
        emitState(emit);
        onSelectionSyncFailed(item, isSelectOperation: true);
        return;
      }

      emitState(emit);
      emitSelectionChanged(emit, item, wasSelected: true);
    } catch (error, stackTrace) {
      _beingSelectedItemIds.remove(item.identifier);
      _restoreSelection(previousSelection);
      emitState(emit);
      handleError(error, emit, stacktrace: stackTrace);
      onSelectionSyncFailed(item, isSelectOperation: true);
    }
  }

  /// Deselects one item.
  Future<void> deselectItem(
    BlocxCollectionEventDeselectItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final item = event.item;
    final wasSelected = _selectedItemIds.contains(item.identifier);

    if (!wasSelected) return;

    _selectedItemIds.remove(item.identifier);
    emitState(emit);

    if (!syncWithServerOnSelection) {
      emitSelectionChanged(emit, item, wasSelected: false);
      return;
    }

    _beingSelectedItemIds.add(item.identifier);
    emitState(emit);

    try {
      final synced = await _runDeselectRemote(item, emit);

      _beingSelectedItemIds.remove(item.identifier);

      if (!synced) {
        _selectedItemIds.add(item.identifier);
        emitState(emit);
        onSelectionSyncFailed(item, isSelectOperation: false);
        return;
      }

      emitState(emit);
      emitSelectionChanged(emit, item, wasSelected: false);
    } catch (error, stackTrace) {
      _beingSelectedItemIds.remove(item.identifier);
      _selectedItemIds.add(item.identifier);
      emitState(emit);
      handleError(error, emit, stacktrace: stackTrace);
      onSelectionSyncFailed(item, isSelectOperation: false);
    }
  }

  Future<bool> _runSelectRemote(
    T item,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final task = selectItemTask(item);

    if (task != null) {
      return _executeTask(task, emit);
    }

    return performRemoteSelection(item);
  }

  Future<bool> _runDeselectRemote(
    T item,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final task = deselectItemTask(item);

    if (task != null) {
      return _executeTask(task, emit);
    }

    return performRemoteDeselection(item);
  }

  Future<bool> _executeTask(
    BlocxUseCaseTask<Object?, bool> task,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final result = await task.execute();

    if (result.isFailure) {
      handleError(result.error!, emit, stacktrace: result.stackTrace);
      return false;
    }

    return result.data ?? false;
  }

  /// Fallback remote selection implementation.
  ///
  /// Override this only when you do not want to use [selectItemTask].
  Future<bool> performRemoteSelection(T item) {
    throw UnimplementedError(
      'Remote selection is not configured for `$T`. Provide '
      '`selectItemTask(item)` or override `performRemoteSelection(item)`.',
    );
  }

  /// Fallback remote deselection implementation.
  ///
  /// Override this only when you do not want to use [deselectItemTask].
  Future<bool> performRemoteDeselection(T item) {
    throw UnimplementedError(
      'Remote deselection is not configured for `$T`. Provide '
      '`deselectItemTask(item)` or override `performRemoteDeselection(item)`.',
    );
  }

  /// Emits a selection-changed state.
  void emitSelectionChanged(
    Emitter<BlocxCollectionState<T>> emit,
    T item, {
    required bool wasSelected,
  }) {
    emit(
      BlocxCollectionStateSelectionChanged<T>(
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
        selectionData: SelectionChangedData<T>(
          selection: selectedItems,
          wasSelected: wasSelected,
          item: item,
        ),
      ),
    );
  }

  /// Called when remote selection or deselection sync fails.
  void onSelectionSyncFailed(
    T item, {
    required bool isSelectOperation,
  }) {
    displayWarningSnackbar(
      isSelectOperation
          ? 'Could not select the item. Please try again.'
          : 'Could not deselect the item. Please try again.',
    );
  }

  /// Identifiers of items currently being selected or deselected remotely.
  Set<String> get beingSelectedItemIdsOriginal => _beingSelectedItemIds;

  /// Identifiers of selected items.
  Set<String> get selectedItemIdsOriginal => _selectedItemIds;

  /// Currently selected item entities.
  List<T> get selectedItems {
    return list.where((item) {
      return _selectedItemIds.contains(item.identifier);
    }).toList();
  }

  /// Deselects multiple items locally.
  FutureOr<void> deselectMultipleItems(
    BlocxCollectionEventDeselectMultipleItems<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    if (event.items.isEmpty) return Future.value();

    for (final item in event.items) {
      _selectedItemIds.remove(item.identifier);
    }

    emitSelectionChanged(
      emit,
      event.items.first,
      wasSelected: false,
    );

    emitState(emit);
  }

  /// Selects multiple items locally.
  FutureOr<void> selectMultipleItems(
    BlocxCollectionEventSelectMultipleItems<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    if (event.items.isEmpty) return Future.value();

    if (isSingleSelect) {
      _selectedItemIds
        ..clear()
        ..add(event.items.first.identifier);

      emitSelectionChanged(
        emit,
        event.items.first,
        wasSelected: true,
      );

      emitState(emit);
      return Future.value();
    }

    _selectedItemIds.addAll(
      event.items.map((item) => item.identifier),
    );

    emitSelectionChanged(
      emit,
      event.items.first,
      wasSelected: true,
    );

    emitState(emit);
  }

  /// Clears all selected items.
  FutureOr<void> clearSelection(
    BlocxCollectionEventClearSelection<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    if (_selectedItemIds.isEmpty) return Future.value();

    _selectedItemIds.clear();
    emitState(emit);
  }

  void _restoreSelection(Set<String> previousSelection) {
    _selectedItemIds
      ..clear()
      ..addAll(previousSelection);
  }
}
