import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionEventClearSelection,
        BlocxCollectionEventDeselectMultipleItems,
        BlocxCollectionEventSelectItem,
        BlocxCollectionEventSelectMultipleItems,
        BlocxCollectionState,
        BlocxCollectionStateSelectionChanged,
        SelectionChangedData;
import 'package:meta/meta.dart';

import 'events.dart';

/// Adds item selection behavior to a [BlocxCollectionBloc].
///
/// Supports single-select, multi-select, optional remote selection syncing,
/// rollback on sync failure, and selection-change notifications.
mixin BlocxCollectionSelectableMixin<Entity extends BlocxBaseEntity, Payload>
    on BlocxCollectionBloc<Entity, Payload> {
  final Set<String> _selectedItemIds = <String>{};
  final Set<String> _beingSelectedItemIds = <String>{};

  /// Whether only one item can be selected at a time.
  bool get isSingleSelect => true;

  /// Whether selection and deselection should be synced with a remote source.
  bool get syncWithServerOnSelection => false;

  /// Creates the task used to sync selecting [item].
  ///
  /// Return `null` to use [performRemoteSelection] instead.
  BlocxUseCaseTask<Object?, bool>? selectItemTask(Entity item) => null;

  /// Creates the task used to sync deselecting [item].
  ///
  /// Return `null` to use [performRemoteDeselection] instead.
  BlocxUseCaseTask<Object?, bool>? deselectItemTask(Entity item) => null;

  /// Registers selection event handlers.
  @override
  bool initSelection() {
    on<BlocxCollectionEventSelectItem<Entity>>(selectItem);
    on<BlocxCollectionEventDeselectItem<Entity>>(deselectItem);
    on<BlocxCollectionEventDeselectMultipleItems<Entity>>(deselectMultipleItems);
    on<BlocxCollectionEventSelectMultipleItems<Entity>>(selectMultipleItems);
    on<BlocxCollectionEventClearSelection<Entity>>(clearSelection);
    return true;
  }

  /// Selects one item.
  Future<void> selectItem(
    BlocxCollectionEventSelectItem<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
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
    BlocxCollectionEventDeselectItem<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
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
    Entity item,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final task = selectItemTask(item);

    if (task != null) {
      return _executeTask(task, emit);
    }

    return performRemoteSelection(item);
  }

  Future<bool> _runDeselectRemote(
    Entity item,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) async {
    final task = deselectItemTask(item);

    if (task != null) {
      return _executeTask(task, emit);
    }

    return performRemoteDeselection(item);
  }

  Future<bool> _executeTask(
    BlocxUseCaseTask<Object?, bool> task,
    Emitter<BlocxCollectionState<Entity>> emit,
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
  Future<bool> performRemoteSelection(Entity item) {
    throw UnimplementedError(
      'Remote selection is not configured for `$Entity`. Provide '
      '`selectItemTask(item)` or override `performRemoteSelection(item)`.',
    );
  }

  /// Fallback remote deselection implementation.
  ///
  /// Override this only when you do not want to use [deselectItemTask].
  Future<bool> performRemoteDeselection(Entity item) {
    throw UnimplementedError(
      'Remote deselection is not configured for `$Entity`. Provide '
      '`deselectItemTask(item)` or override `performRemoteDeselection(item)`.',
    );
  }

  /// Emits a selection-changed state.
  void emitSelectionChanged(
    Emitter<BlocxCollectionState<Entity>> emit,
    Entity item, {
    required bool wasSelected,
  }) {
    emit(
      BlocxCollectionStateSelectionChanged<Entity>(
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
        selectionData: SelectionChangedData<Entity>(
          selection: selectedItems,
          wasSelected: wasSelected,
          item: item,
        ),
      ),
    );
  }

  /// Called when remote selection or deselection sync fails.
  void onSelectionSyncFailed(
    Entity item, {
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
  List<Entity> get selectedItems {
    return list.where((item) {
      return _selectedItemIds.contains(item.identifier);
    }).toList();
  }

  /// Deselects multiple items locally.
  FutureOr<void> deselectMultipleItems(
    BlocxCollectionEventDeselectMultipleItems<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
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
    BlocxCollectionEventSelectMultipleItems<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
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
    BlocxCollectionEventClearSelection<Entity> event,
    Emitter<BlocxCollectionState<Entity>> emit,
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

  @protected
  @override
  Future<void> applyInitialSelection() async {
    var initiallySelectedItemIds = await getInitiallySelectedItemIds();
    _selectedItemIds.addAll(initiallySelectedItemIds);
  }

  FutureOr<Set<String>> getInitiallySelectedItemIds() async {
    return <String>{};
  }
}
