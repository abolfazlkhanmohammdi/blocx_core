import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/misc/event_transformers.dart';
import 'package:blocx/src/list/mixins/contracts/searchable_list_bloc_contract.dart';
import 'package:blocx/src/list/models/list_entity.dart';
import 'package:blocx/src/list/models/page.dart';
import 'package:blocx/src/list/models/search_query.dart';
import 'package:blocx/src/list/use_cases/search_pagination_use_case.dart';

mixin SearchableListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
    implements SearchableListBlocContract<T> {
  @override
  void initSearch() {
    on<ListBlocEventSearch<T>>(search, transformer: debounceRestartable(searchDebounceDuration));
    on<ListBlocEventClearSearch<T>>(clearSearch, transformer: droppable());
  }

  @override
  Future<void> search(ListBlocEventSearch<T> event, Emitter<ListBlocState<T>> emit) async {
    if (searchUseCase != null) return await _fetchSearchResult(event, emit);
    throw UnimplementedError("You must either override searchList method or searchUseCase getter");
  }

  Future<void> _fetchSearchResult(ListBlocEventSearch<T> event, Emitter<ListBlocState<T>> emit) async {
    isSearching = true;
    emitState(emit);
    try {
      var result = await (event.searchText.isEmpty
          ? loadInitialPageUseCase!.execute(
              query: PaginationQuery(payload: payload, loadCount: loadCount, offset: 0),
            )
          : searchUseCase!.execute(
              query: SearchQuery(
                searchText: event.searchText,
                payload: payload,
                loadCount: loadCount,
                offset: 0,
              ),
            ));
      if (result.isFailure) {
        await handleDataError(result.error!, emit, stacktrace: result.stackTrace);
        return;
      }
      list.clear();
      await insertToList(result.data!.items, !result.data!.hasNext);
      emitState(emit);
    } finally {
      isSearching = false;
      emitState(emit);
    }
  }

  @override
  FutureOr clearSearch(ListBlocEventClearSearch<T> event, Emitter<ListBlocState<T>> emit) {
    list.clear();
    add(ListBlocEventLoadData(payload: payload));
  }

  SearchUseCase<T, P>? get searchUseCase;

  Duration get searchDebounceDuration => const Duration(milliseconds: 300);
}
