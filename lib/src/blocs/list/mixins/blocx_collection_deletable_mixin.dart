import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionEventRemoveItem,
        BlocxCollectionEventRemoveMultipleItems,
        BlocxCollectionEventRemoveItemById,
        BlocxCollectionState,
        BlocxCollectionEventDeselectMultipleItems;

/// A mixin that adds delete & bulk-delete capabilities to a [BlocxCollectionBloc].
///
/// ## IMPORTANT (updated architecture)
/// Use cases are now:
/// `BlocxBaseUseCase<Input, bool>`
///
/// So:
/// - single delete → Input = T
/// - bulk delete → Input = List<T>
mixin BlocxCollectionDeletableMixin<T extends BlocxBaseEntity, P> on BlocxCollectionBloc<T, P> {
  final Set<String> _beingRemovedItemIds = {};

  // ---------------------------------------------------------------------------
  // USE CASES (UPDATED SIGNATURES)
  // ---------------------------------------------------------------------------

  BlocxBaseUseCase<T, bool>? get deleteItemUseCase;

  BlocxBaseUseCase<List<T>, bool>? deleteMultipleItemsUseCase(List<T> items) => null;

  void initDeletable() {
    on<BlocxCollectionEventRemoveItem<T>>(removeItem);
    on<BlocxCollectionEventRemoveMultipleItems<T>>(removeMultipleItems);
    on<BlocxCollectionEventRemoveItemById<T>>(removeItemById);
  }

  // ---------------------------------------------------------------------------
  // SINGLE DELETE
  // ---------------------------------------------------------------------------

  Future<void> removeItem(
    BlocxCollectionEventRemoveItem<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    _beingRemovedItemIds.add(event.item.identifier);
    emitState(emit);

    final uc = deleteItemUseCase;

    if (uc == null) {
      throw UnimplementedError("Delete not configured for '$T'. Provide `deleteItemUseCase(item)`.");
    }

    try {
      final BlocxUseCaseResult<bool> result = await uc.execute(event.item);

      final ok = result.isSuccess && (result.data ?? false);

      _beingRemovedItemIds.remove(event.item.identifier);

      if (ok) {
        removeItemFromList(event.item);

        if (isSelectable) {
          add(BlocxCollectionEventDeselectMultipleItems(items: [event.item]));
        }
      }

      emitState(emit);
      _onItemDeletedResult(result);
    } catch (e, s) {
      _beingRemovedItemIds.remove(event.item.identifier);
      emitState(emit);
      handleError(e, emit, stacktrace: s);
    }
  }

  // ---------------------------------------------------------------------------
  // BULK DELETE
  // ---------------------------------------------------------------------------

  Future<void> removeMultipleItems(
    BlocxCollectionEventRemoveMultipleItems<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final items = event.items;

    if (items.isEmpty) return;

    for (final it in items) {
      _beingRemovedItemIds.add(it.identifier);
    }

    emitState(emit);

    final ucMany = deleteMultipleItemsUseCase(items);
    final hasMany = ucMany != null;
    final hasSingle = deleteItemUseCase != null;

    if (!hasMany && !hasSingle) {
      for (final it in items) {
        _beingRemovedItemIds.remove(it.identifier);
      }

      emitState(emit);

      throw UnimplementedError(
        "Bulk delete not configured for '$T'.\n"
        "Provide `deleteMultipleItemsUseCase(items)` or `deleteItemUseCase(item)`.",
      );
    }

    final Map<T, bool> results = {};

    try {
      if (hasMany) {
        final BlocxUseCaseResult<bool> result = await ucMany.execute(items);

        final ok = result.isSuccess && (result.data ?? false);

        for (final it in items) {
          _beingRemovedItemIds.remove(it.identifier);

          if (ok) {
            removeItemFromList(it);
          }

          results[it] = result.isSuccess;
        }

        emitState(emit);
      } else {
        for (final it in items) {
          final uc = deleteItemUseCase!;

          try {
            final BlocxUseCaseResult<bool> r = await uc.execute(it);

            final ok = r.isSuccess && (r.data ?? false);

            if (ok) {
              removeItemFromList(it);

              if (isSelectable) {
                add(BlocxCollectionEventDeselectMultipleItems(items: [it]));
              }
            }

            results[it] = r.isSuccess;
          } catch (e) {
            results[it] = false;
          } finally {
            _beingRemovedItemIds.remove(it.identifier);
            emitState(emit);
          }
        }
      }
    } catch (e, s) {
      for (final it in items) {
        _beingRemovedItemIds.remove(it.identifier);
      }

      emitState(emit);
      handleError(e, emit, stacktrace: s);
    } finally {
      _onMultipleItemsDeletedResult(results, event.items, wasMultipleDelete: hasMany);
    }
  }

  // ---------------------------------------------------------------------------
  // HOOKS
  // ---------------------------------------------------------------------------

  void _onItemDeletedResult(BlocxUseCaseResult<bool> result) {
    if (!displayDeletedSnackbar) return;

    final ok = result.isSuccess && (result.data ?? false);

    if (ok) {
      displayInfoSnackbar("Item deleted");
    } else {
      displayWarningSnackbar("Failed to delete item");
    }
  }

  void _onMultipleItemsDeletedResult(Map<T, bool> results, List<T> items, {required bool wasMultipleDelete}) {
    if (!displayDeletedSnackbar) return;

    final total = results.length;
    final success = results.values.where((r) => r).length;
    final fail = total - success;

    if (fail == 0) {
      displayInfoSnackbar("Deleted $success item(s).");

      if (isSelectable && wasMultipleDelete) {
        add(BlocxCollectionEventDeselectMultipleItems(items: items));
      }
    } else if (success == 0) {
      displayWarningSnackbar("Failed to delete $fail item(s).");
    } else {
      displayWarningSnackbar("Deleted $success, failed $fail.");
    }
  }

  // ---------------------------------------------------------------------------
  // STATE HELPERS
  // ---------------------------------------------------------------------------

  @override
  Set<String> get beingRemovedItemIds => _beingRemovedItemIds;

  FutureOr<void> removeItemById(
    BlocxCollectionEventRemoveItemById<T> event,
    Emitter<BlocxCollectionState<T>> emit,
  ) async {
    final index = list.indexWhere((item) => item.identifier == event.identifier);

    if (index == -1) return;

    removeItemFromList(list[index]);
    emitState(emit);
  }

  bool get displayDeletedSnackbar => false;
}
