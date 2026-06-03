import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionEventDeselectMultipleItems,
        BlocxCollectionEventRemoveItem,
        BlocxCollectionEventRemoveItemById,
        BlocxCollectionEventRemoveMultipleItems,
        BlocxCollectionState;

/// Adds single-item and bulk-delete behavior to a [BlocxCollectionBloc].
///
/// Deletion can be configured with [deleteItemTask] and
/// [deleteMultipleItemsTask]. Both are task factories so each feature can build
/// whatever input its API requires.
///
/// Example:
///
/// ```dart
/// @override
/// BlocxUseCaseTask<DeleteCategoryInput, bool>? deleteItemTask(
///   CategoryEntity item,
/// ) {
///   return BlocxUseCaseTask<DeleteCategoryInput, bool>(
///     useCase: deleteCategoryUseCase,
///     inputBuilder: () => DeleteCategoryInput(id: item.id),
///   );
/// }
/// ```
mixin BlocxCollectionDeletableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  final Set<String> _beingRemovedItemIds = <String>{};

  /// Creates the task used to delete a single [item].
  ///
  /// Return `null` to use [performDeleteItem] instead.
  BlocxUseCaseTask<Object?, bool>? deleteItemTask(T item) => null;

  /// Creates the task used to delete multiple [items] at once.
  ///
  /// Return `null` to fall back to deleting each item individually through
  /// [deleteItemTask] or [performDeleteItem].
  BlocxUseCaseTask<Object?, bool>? deleteMultipleItemsTask(List<T> items) => null;

  /// Registers delete event handlers.
  void initDeletable() {
    on<BlocxCollectionEventRemoveItem<T>>(removeItem);
    on<BlocxCollectionEventRemoveMultipleItems<T>>(removeMultipleItems);
    on<BlocxCollectionEventRemoveItemById<T>>(removeItemById);
  }

  /// Removes one item from the remote source and then from the local list.
  Future<void> removeItem(
    BlocxCollectionEventRemoveItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final item = event.item;

    _beingRemovedItemIds.add(item.identifier);
    emitState(emit);

    try {
      final deleted = await _deleteItem(item, emit);

      if (deleted) {
        removeItemFromList(item);

        if (isSelectable) {
          add(BlocxCollectionEventDeselectMultipleItems<T>(items: <T>[item]));
        }
      }

      _beingRemovedItemIds.remove(item.identifier);
      emitState(emit);
      onItemDeleted(item, deleted);
    } catch (error, stackTrace) {
      _beingRemovedItemIds.remove(item.identifier);
      emitState(emit);
      handleError(error, emit, stacktrace: stackTrace);
      onItemDeleted(item, false);
    }
  }

  /// Removes multiple items from the remote source and then from the local list.
  Future<void> removeMultipleItems(
    BlocxCollectionEventRemoveMultipleItems<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final items = event.items;

    if (items.isEmpty) return;

    for (final item in items) {
      _beingRemovedItemIds.add(item.identifier);
    }

    emitState(emit);

    final results = <T, bool>{};

    try {
      final bulkTask = deleteMultipleItemsTask(items);

      if (bulkTask != null) {
        final deleted = await _executeTask(bulkTask, emit);

        for (final item in items) {
          results[item] = deleted;

          if (deleted) {
            removeItemFromList(item);
          }
        }

        if (deleted && isSelectable) {
          add(BlocxCollectionEventDeselectMultipleItems<T>(items: items));
        }
      } else {
        for (final item in items) {
          final deleted = await _deleteItem(item, emit);

          results[item] = deleted;

          if (deleted) {
            removeItemFromList(item);

            if (isSelectable) {
              add(
                BlocxCollectionEventDeselectMultipleItems<T>(
                  items: <T>[item],
                ),
              );
            }
          }
        }
      }

      for (final item in items) {
        _beingRemovedItemIds.remove(item.identifier);
      }

      emitState(emit);
      onMultipleItemsDeleted(items, results);
    } catch (error, stackTrace) {
      for (final item in items) {
        _beingRemovedItemIds.remove(item.identifier);
        results.putIfAbsent(item, () => false);
      }

      emitState(emit);
      handleError(error, emit, stacktrace: stackTrace);
      onMultipleItemsDeleted(items, results);
    }
  }

  Future<bool> _deleteItem(
    T item,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final task = deleteItemTask(item);

    if (task != null) {
      return _executeTask(task, emit);
    }

    return performDeleteItem(item);
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

  /// Fallback delete implementation when [deleteItemTask] is not provided.
  ///
  /// Override this only when you do not want to use task-based deletion.
  Future<bool> performDeleteItem(T item) {
    throw UnimplementedError(
      'Delete is not configured for `$T`. Provide `deleteItemTask(item)` '
      'or override `performDeleteItem(item)`.',
    );
  }

  /// Called after a single delete operation finishes.
  void onItemDeleted(T item, bool deleted) {
    if (!displayDeletedSnackbar) return;

    if (deleted) {
      displayInfoSnackbar('Item deleted');
    } else {
      displayWarningSnackbar('Failed to delete item');
    }
  }

  /// Called after a bulk delete operation finishes.
  void onMultipleItemsDeleted(
    List<T> items,
    Map<T, bool> results,
  ) {
    if (!displayDeletedSnackbar) return;

    final successCount = results.values.where((deleted) => deleted).length;
    final failedCount = results.length - successCount;

    if (failedCount == 0) {
      displayInfoSnackbar('Deleted $successCount item(s).');
    } else if (successCount == 0) {
      displayWarningSnackbar('Failed to delete $failedCount item(s).');
    } else {
      displayWarningSnackbar('Deleted $successCount, failed $failedCount.');
    }
  }

  /// Removes an item locally by its identifier.
  ///
  /// This does not call the remote delete task. Use this for local-only removal.
  FutureOr<void> removeItemById(
    BlocxCollectionEventRemoveItemById<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) {
    final index = list.indexWhere(
      (item) => item.identifier == event.identifier,
    );

    if (index == -1) return Future.value();

    removeItemFromList(list[index]);
    emitState(emit);
  }

  /// Identifiers of items currently being removed.
  @override
  Set<String> get beingRemovedItemIds => _beingRemovedItemIds;

  /// Whether delete result snackbars should be displayed.
  bool get displayDeletedSnackbar => false;
}
