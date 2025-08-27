import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';

/// Mixin that adds **pull-to-refresh** behavior to a [ListBloc].
///
/// This mixin wires a refresh event, coordinates the `refreshPageUseCase`
/// (if provided), updates the `isRefreshing` flag, and re-emits state so the UI
/// can display a loading indicator during refresh.
///
/// ### Behavior
/// - Ignores refresh requests while a refresh is already in progress.
/// - If the list is **searchable** and there is an active non-empty query,
///   it dispatches a `ListEventSearchRefresh` instead of running a generic refresh,
///   ensuring the refresh respects the current search context.
/// - If `refreshPageUseCase` is available, it is executed to fetch fresh data.
///   On success, the current list is cleared and replaced; on failure, the
///   configured error policy is applied via `handleDataError`.
mixin RefreshableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  /// Handles a request to refresh the list data.
  ///
  /// Guard clauses:
  /// - Returns immediately if a refresh is already in progress (`isRefreshing`).
  /// - If searchable and `searchText` is non-empty, dispatches
  ///   [ListEventSearchRefresh] to refresh within the search context.
  ///
  /// Execution path:
  /// - If [refreshPageUseCase] is provided, calls [_fetchRefreshPage].
  /// - Otherwise throws [UnimplementedError], requiring the bloc to either
  ///   provide a use case or override this method.
  ///
  /// *Note:* This method emits new list states via [emitState] so the UI can
  /// react (e.g., show/hide refresh indicators).
  Future refreshPage(ListEventRefreshData<T> event, Emitter<ListState<T>> emit) async {
    if (isRefreshing) return;
    if (isSearchable && (this as SearchableListBlocMixin<T, P>).searchText.isNotEmpty) {
      add(ListEventSearchRefresh());
      return;
    }
    if (refreshPageUseCase != null) return await _fetchRefreshPage(event, emit);
    throw UnimplementedError("You must either override refreshUseCase getter or refreshPage method");
  }

  /// Executes the refresh flow using [refreshPageUseCase].
  ///
  /// Steps:
  /// 1. Sets `isRefreshing = true` and emits state (so UI can show a spinner).
  /// 2. Awaits the result from [refreshPageUseCase].
  /// 3. Resets `isRefreshing = false`.
  /// 4. On failure: delegates to [handleDataError] (snackbar or error widget).
  /// 5. On success:
  ///    - Clears the current list.
  ///    - Inserts the fresh items via [insertToList] with source
  ///      [DataInsertSource.refresh].
  ///    - Emits the updated state via [emitState].
  ///
  /// Any exceptions or failures are surfaced through the error policy defined
  /// by the host bloc (see [errorDisplayPolicy]).
  Future<void> _fetchRefreshPage(ListEventRefreshData<T> event, Emitter<ListState<T>> emit) async {
    isRefreshing = true;
    emitState(emit);
    var result = await refreshPageUseCase!.execute();
    isRefreshing = false;
    if (result.isFailure) {
      await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
      return;
    }
    clearList();
    await insertToList(result.data!.items, !result.data!.hasNext, DataInsertSource.refresh);
    emitState(emit);
  }

  /// Registers the event handler for [ListEventRefreshData].
  ///
  /// Call this during bloc initialization (the base [ListBloc] typically
  /// invokes `initRefresh()` when the bloc mixes in this capability).
  initRefresh() {
    on<ListEventRefreshData<T>>(refreshPage);
  }

  /// Optional use case that fetches a fresh page of data for refresh.
  ///
  /// If `null`, you must either provide an implementation by overriding
  /// [refreshPage] or supply this use case in the concrete bloc.
  PaginationUseCase<T, P>? get refreshPageUseCase => null;
}
