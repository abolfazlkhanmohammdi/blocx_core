import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class SearchNextPageTestBloc extends BlocxCollectionBloc<TestItem, void>
    with
        BlocxCollectionInfiniteMixin<TestItem, void>,
        BlocxCollectionSearchableMixin<TestItem, void> {
  final FakePaginatedUseCase paginatedUseCase;
  final ControlledSearchUseCase searchUseCase;

  SearchNextPageTestBloc({
    required this.paginatedUseCase,
    required this.searchUseCase,
  }) : super();

  @override
  int get limit => 2;

  @override
  Duration get searchDebounceDuration => Duration.zero;

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>?
  get paginationTask => BlocxPaginatedUseCaseTask(
    useCase: paginatedUseCase,
    inputBuilder: (offset, limit) =>
        BlocxPaginatedInput(offset: offset, limit: limit),
  );

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, TestItem>?
  get searchUseCaseTask => BlocxPaginatedUseCaseTask(
    useCase: searchUseCase,
    inputBuilder: (offset, limit) =>
        BlocxSearchInput(searchText: searchText, offset: offset, limit: limit),
  );
}

class ControlledSearchUseCase
    extends BlocxPaginatedUseCase<BlocxSearchInput, TestItem> {
  final List<ControlledSearchCall> calls = [];

  ControlledSearchUseCase() : super();

  @override
  Future<BlocxUseCaseResult<BlocxPage<TestItem>>> perform(
    BlocxSearchInput input,
  ) async {
    final call = ControlledSearchCall(input);
    calls.add(call);
    return call.completer.future;
  }
}

class ControlledSearchCall {
  final BlocxSearchInput input;
  final Completer<BlocxUseCaseResult<BlocxPage<TestItem>>> completer =
      Completer();

  ControlledSearchCall(this.input);

  void completeSuccess(List<TestItem> items, {bool hasNext = true}) {
    completer.complete(
      BlocxUseCaseSuccess(
        BlocxPage<TestItem>(
          items: items,
          offset: input.offset,
          limit: input.limit,
          hasNext: hasNext,
        ),
      ),
    );
  }

  void completeFailure(Object error) {
    completer.complete(BlocxUseCaseFailure(error));
  }
}

void main() {
  group('K5: Search next page guards and status tracking', () {
    test(
      'state.isLoadingNextPage is true during search next page and resets to false after',
      () async {
        final searchUseCase = ControlledSearchUseCase();
        final bloc = SearchNextPageTestBloc(
          paginatedUseCase: FakePaginatedUseCase(),
          searchUseCase: searchUseCase,
        );

        // Search initial page
        bloc.add(BlocxCollectionEventSearch<TestItem>(searchText: 'query'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(searchUseCase.calls.length, equals(1));
        searchUseCase.calls.first.completeSuccess([
          const TestItem(id: 's1', title: 'Search 1'),
          const TestItem(id: 's2', title: 'Search 2'),
        ], hasNext: true);
        await bloc.stream.firstWhere(
          (s) => s.list.length == 2 && !s.isSearching,
        );

        expect(bloc.isLoadingNextPage, isFalse);
        expect(bloc.state.isLoadingNextPage, isFalse);

        // Request next page of search
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await Future<void>.delayed(Duration.zero);

        expect(searchUseCase.calls.length, equals(2));
        expect(
          bloc.isLoadingNextPage,
          isTrue,
          reason: 'bloc.isLoadingNextPage must be true during search next page',
        );
        expect(
          bloc.state.isLoadingNextPage,
          isTrue,
          reason:
              'state.isLoadingNextPage must be emitted as true during search next page',
        );

        // Complete next page
        searchUseCase.calls.last.completeSuccess([
          const TestItem(id: 's3', title: 'Search 3'),
        ], hasNext: false);
        await bloc.stream.firstWhere((s) => s.list.length == 3);

        expect(bloc.isLoadingNextPage, isFalse);
        expect(bloc.state.isLoadingNextPage, isFalse);
        expect(bloc.hasReachedEnd, isTrue);

        // Additional LoadNextPage events after reaching end must produce ZERO extra use-case calls
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          searchUseCase.calls.length,
          equals(2),
          reason:
              'No additional calls should be made after hasReachedEnd is true',
        );

        await bloc.close();
      },
    );

    test(
      'failing search next page resets isLoadingNextPage to false',
      () async {
        final searchUseCase = ControlledSearchUseCase();
        final bloc = SearchNextPageTestBloc(
          paginatedUseCase: FakePaginatedUseCase(),
          searchUseCase: searchUseCase,
        );

        // Search initial page
        bloc.add(BlocxCollectionEventSearch<TestItem>(searchText: 'query'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(searchUseCase.calls.length, equals(1));
        searchUseCase.calls.first.completeSuccess([
          const TestItem(id: 's1', title: 'Search 1'),
        ], hasNext: true);
        await bloc.stream.firstWhere(
          (s) => s.list.length == 1 && !s.isSearching,
        );

        // Request next page (fails)
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.isLoadingNextPage, isTrue);

        searchUseCase.calls.last.completeFailure(
          Exception('Search network timeout'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          bloc.isLoadingNextPage,
          isFalse,
          reason: 'isLoadingNextPage must reset to false on failure',
        );
        expect(bloc.state.isLoadingNextPage, isFalse);

        await bloc.close();
      },
    );
  });
}
