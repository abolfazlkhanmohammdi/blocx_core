import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';

mixin DeletableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  final Set<String> _beingRemovedItemIds = {};

  BaseUseCase<bool>? deleteItemUseCase(T item) => null;
  BaseUseCase<bool>? deleteMultipleItemsUseCase(List<T> items) => null;

  void initDeletable() {
    on<ListEventRemoveItem<T>>(removeItem);
    on<ListEventRemoveMultipleItems<T>>(removeMultipleItems);
  }

  Future<void> removeItem(ListEventRemoveItem<T> event, Emitter<ListState<T>> emit) async {
    _beingRemovedItemIds.add(event.item.identifier);
    emitState(emit);

    final uc = deleteItemUseCase(event.item);
    if (uc == null) {
      throw UnimplementedError(
        "Item removal for type '$T' is not configured. "
        "Preferred: override `deleteItemUseCase(item)` to provide a deletion use case. "
        "Fallback: override `removeItem` with custom logic.",
      );
    }

    try {
      final result = await uc.execute();

      // Update local state based on outcome
      final ok = result.isSuccess && (result.data ?? false);
      _beingRemovedItemIds.remove(event.item.identifier);
      if (ok) {
        removeItemFromList(event.item);
        if (isSelectable) add(ListEventDeselectMultipleItems(items: [event.item]));
      }

      emitState(emit);
      _onItemDeletedResult(result);
    } catch (e, s) {
      _beingRemovedItemIds.remove(event.item.identifier);
      emitState(emit);
      handleDataError(e, emit, stacktrace: s);
    }
  }

  /// NEW: removeMultipleItems
  Future<void> removeMultipleItems(ListEventRemoveMultipleItems<T> event, Emitter<ListState<T>> emit) async {
    final items = event.items;

    if (items.isEmpty) return;

    // Mark all as being removed (for UI feedback)
    for (final it in items) {
      _beingRemovedItemIds.add(it.identifier);
    }
    emitState(emit);

    final ucMany = deleteMultipleItemsUseCase(items);
    final hasMany = ucMany != null;
    final hasSingle = deleteItemUseCase(items.first) != null;

    if (!hasMany && !hasSingle) {
      // Revert the flags to avoid leaving items stuck as "being removed"
      for (final it in items) {
        _beingRemovedItemIds.remove(it.identifier);
      }
      emitState(emit);
      throw UnimplementedError(
        "Bulk removal for '$T' is not configured.\n"
        "Preferred: override `deleteMultipleItemsUseCase(items)`.\n"
        "Alternative: override `deleteItemUseCase(item)` (per-item).\n"
        "Fallback: override `removeMultipleItems` with custom logic.",
      );
    }

    final Map<T, UseCaseResult<bool>> results = {};

    try {
      if (hasMany) {
        // Try bulk use case once
        final result = await ucMany.execute();
        final ok = result.isSuccess && (result.data ?? false);

        // If bulk succeeds, consider all deleted; else none
        if (ok) {
          for (final it in items) {
            _beingRemovedItemIds.remove(it.identifier);
            removeItemFromList(it);
            results[it] = UseCaseResult.success(true);
          }
        } else {
          for (final it in items) {
            _beingRemovedItemIds.remove(it.identifier);
            results[it] = result; // same failure result for each
          }
        }
        emitState(emit);
      } else {
        // Fall back to per-item use case
        for (final it in items) {
          final uc = deleteItemUseCase(it)!; // safe due to hasSingle
          try {
            final r = await uc.execute();
            final ok = r.isSuccess && (r.data ?? false);
            if (ok) {
              removeItemFromList(it);
              if (isSelectable) add(ListEventDeselectMultipleItems(items: [it]));
            }
            results[it] = r;
          } catch (e, s) {
            results[it] = UseCaseResult.failure(e, stackTrace: s);
          } finally {
            _beingRemovedItemIds.remove(it.identifier);
            emitState(emit);
          }
        }
      }
    } catch (e, s) {
      // Catastrophic path (e.g., bulk UC threw)
      for (final it in items) {
        _beingRemovedItemIds.remove(it.identifier);
      }
      emitState(emit);
      handleDataError(e, emit, stacktrace: s);
    } finally {
      _onMultipleItemsDeletedResult(results, event.items, wasMultipleDelete: hasMany);
    }
  }

  // ---- Hooks ----------------------------------------------------------------

  void _onItemDeletedResult(UseCaseResult<bool> result) {
    final ok = result.isSuccess && (result.data ?? false);
    if (ok) {
      displayInfoSnackbar("Item deleted");
    } else {
      displayWarningSnackbar("Failed to delete item");
    }
  }

  /// Called after multi-delete completes (successes + failures mixed).
  /// Default: shows a brief summary; override for richer UX/telemetry.
  void _onMultipleItemsDeletedResult(
    Map<T, UseCaseResult<bool>> results,
    List<T> items, {
    required bool wasMultipleDelete,
  }) {
    final total = results.length;
    final successes = results.values.where((r) => r.isSuccess && (r.data ?? false)).length;
    final failures = total - successes;
    if (failures == 0) {
      displayInfoSnackbar("Deleted $successes item(s).");
      if (isSelectable && wasMultipleDelete) add(ListEventDeselectMultipleItems(items: items));
    } else if (successes == 0) {
      displayWarningSnackbar("Failed to delete $failures item(s).");
    } else {
      displayWarningSnackbar("Deleted $successes, failed $failures.");
    }
  }

  Set<String> get beingRemovedItemIdsOriginal => _beingRemovedItemIds;
}
