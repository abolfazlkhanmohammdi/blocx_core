import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/mixins/contracts/deletable_list_bloc_contract.dart';

/// Adds “delete item” behavior to a [ListBloc].
///
/// ### Default approach
/// By default, deletion is handled through a [deleteItemUseCase].
/// You provide a [BaseUseCase] that knows how to delete the entity,
/// and this mixin takes care of:
/// 1. Marking the item as *being removed* with [setItemBeingRemoved].
/// 2. Executing [deleteItemUseCase].
/// 3. On success → calling [removeItemFromList] and [emitState].
/// 4. On failure → calling [clearItemBeingRemoved] and [emitState].
/// 5. Showing user feedback through [onItemDeletedResult].
///
/// ### Secondary option
/// If you cannot use a [BaseUseCase] (e.g. ad-hoc deletion logic),
/// override [removeItem] directly. In that case, you’re fully responsible
/// for implementing the removal flow and error handling.
///
/// ### Event wiring
/// This mixin registers a handler for [ListEventRemoveItem] in [initDeletable].
mixin DeletableListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
    implements DeletableListBlocContract<T> {
  /// The deletion use case. **Default mechanism** for item removal.
  ///
  /// * Return `true` → item deleted successfully.
  /// * Return `false` → logical failure (e.g. server refused).
  ///
  /// If this is `null`, the mixin falls back to throwing an [UnimplementedError]
  /// in [removeItem], and you must override that method yourself.
  @override
  BaseUseCase<bool>? deleteItemUseCase(T item) => null;

  /// Wires [ListEventRemoveItem] → [removeItem].
  /// Uses `droppable()` so rapid delete taps don’t overlap.
  @override
  void initDeletable() {
    on<ListEventRemoveItem<T>>(removeItem, transformer: droppable());
  }

  /// Default deletion handler using [deleteItemUseCase].
  ///
  /// - If [deleteItemUseCase] is configured → executes it and applies the result.
  /// - If `null` → throws [UnimplementedError] with guidance.
  ///
  /// You may override this method only when you *cannot* provide a use case.
  @override
  Future<void> removeItem(ListEventRemoveItem<T> event, Emitter<ListState<T>> emit) async {
    setItemBeingRemoved(event.item);
    emitState(emit);

    final uc = deleteItemUseCase(event.item);
    if (uc == null) {
      throw UnimplementedError(
        "Item removal for type '$T' is not configured. "
        "Preferred: override `removeItemUseCase` to provide a deletion use case. "
        "Fallback: override `removeItem` with custom logic.",
      );
    }

    try {
      final result = await uc.execute();
      final ok = result.isSuccess && (result.data ?? false);
      if (ok) {
        removeItemFromList(event.item);
        emitState(emit);
      } else {
        clearItemBeingRemoved(event.item);
        emitState(emit);
      }

      onItemDeletedResult(result);
    } catch (error, stack) {
      clearItemBeingRemoved(event.item);
      emitState(emit);
      onDeletionUnexpectedError(error, stack);
    }
  }

  /// Called after a completed deletion attempt (success or failure).
  /// Override to customize user feedback.
  void onItemDeletedResult(UseCaseResult<bool> result) {
    final ok = result.isSuccess && (result.data ?? false);
    if (ok) {
      displayInfoSnackbar("Item was successfully deleted");
    } else {
      displayWarningSnackbar("An error occurred while deleting the item");
    }
  }

  /// Called when an unexpected exception bubbles up. Override to add logging.
  void onDeletionUnexpectedError(Object error, StackTrace stack) {
    displayWarningSnackbar("An unexpected error occurred while deleting the item");
  }
}
