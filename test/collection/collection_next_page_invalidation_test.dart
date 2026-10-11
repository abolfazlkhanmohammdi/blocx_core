import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class InvalidationTestCollectionBloc
    extends BlocxCollectionBloc<TestItem, String>
    with
        BlocxCollectionInfiniteMixin<TestItem, String>,
        BlocxCollectionRefreshableMixin<TestItem, String>,
        BlocxCollectionSearchableMixin<TestItem, String> {
  final ControlledPaginatedUseCase paginatedUseCase;

  InvalidationTestCollectionBloc({required this.paginatedUseCase}) : super();

  @override
  int get limit => 5;

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>?
  get paginationTask => BlocxPaginatedUseCaseTask(
    useCase: paginatedUseCase,
    inputBuilder: (offset, limit) =>
        BlocxPaginatedInput(offset: offset, limit: limit),
  );

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, TestItem> get searchUseCaseTask =>
      BlocxPaginatedUseCaseTask(
        useCase: FakeSearchUseCase(),
        inputBuilder: (offset, limit) => BlocxSearchInput(
          searchText: searchText,
          offset: offset,
          limit: limit,
        ),
      );
}

class ControlledPaginatedUseCase
    extends BlocxPaginatedUseCase<BlocxPaginatedInput, TestItem> {
  final List<ControlledCall> calls = [];

  ControlledPaginatedUseCase() : super();

  @override
  Future<BlocxUseCaseResult<BlocxPage<TestItem>>> perform(
    BlocxPaginatedInput input,
  ) async {
    final call = ControlledCall(input);
    calls.add(call);
    return call.completer.future;
  }
}

class ControlledCall {
  final BlocxPaginatedInput input;
  final Completer<BlocxUseCaseResult<BlocxPage<TestItem>>> completer =
      Completer();

  ControlledCall(this.input);

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
}

class FakeSearchUseCase
    extends BlocxPaginatedUseCase<BlocxSearchInput, TestItem> {
  @override
  Future<BlocxUseCaseResult<BlocxPage<TestItem>>> perform(
    BlocxSearchInput input,
  ) async {
    return BlocxUseCaseSuccess(
      BlocxPage<TestItem>(
        items: [const TestItem(id: 'search_1', title: 'Search Item 1')],
        offset: input.offset,
        limit: input.limit,
        hasNext: false,
      ),
    );
  }
}

void main() {
  group('K1: Pagination invalidation after refresh / initial load / search', () {
    test(
      'refresh resets isLoadingNextPage and allows next page to be requested after completion',
      () async {
        final useCase = ControlledPaginatedUseCase();
        final bloc = InvalidationTestCollectionBloc(paginatedUseCase: useCase);

        // Initial load (5 items, hasNext = true)
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: 'init'));
        await Future<void>.delayed(Duration.zero);
        expect(useCase.calls.length, equals(1));
        useCase.calls[0].completeSuccess(
          List.generate(
            5,
            (i) => TestItem(id: 'p1_$i', title: 'Page 1 Item $i'),
          ),
          hasNext: true,
        );
        await bloc.stream.firstWhere((s) => s.list.length == 5);

        // Start next page (do not complete yet)
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await Future<void>.delayed(Duration.zero);
        expect(useCase.calls.length, equals(2));
        final inFlightNextPageCall = useCase.calls[1];
        expect(bloc.isLoadingNextPage, isTrue);
        expect(bloc.state.isLoadingNextPage, isTrue);

        // Dispatch refresh while next page is in flight
        bloc.add(BlocxCollectionEventRefreshData<TestItem>());
        await Future<void>.delayed(Duration.zero);
        expect(useCase.calls.length, equals(3));
        final refreshCall = useCase.calls[2];

        // Complete refresh
        refreshCall.completeSuccess(
          List.generate(
            5,
            (i) => TestItem(id: 'refreshed_$i', title: 'Refreshed Item $i'),
          ),
          hasNext: true,
        );
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == 'refreshed_0') && !s.isRefreshing,
        );

        // Expect isLoadingNextPage to be reset
        expect(
          bloc.state.isLoadingNextPage,
          isFalse,
          reason:
              'state.isLoadingNextPage must be reset when refresh completes',
        );
        expect(
          bloc.isLoadingNextPage,
          isFalse,
          reason:
              'bloc.isLoadingNextPage must be reset when nextLoadGeneration is called',
        );

        // Now complete the stale next page call
        inFlightNextPageCall.completeSuccess([
          const TestItem(id: 'stale_item', title: 'Stale Item'),
        ]);
        await pumpEventQueue();

        // Stale item not added, flag still false
        expect(bloc.list.any((e) => e.id == 'stale_item'), isFalse);
        expect(bloc.isLoadingNextPage, isFalse);
        expect(bloc.state.isLoadingNextPage, isFalse);

        // Dispatch LoadNextPage again -> new use-case call is made
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await pumpEventQueue();
        expect(
          useCase.calls.length,
          equals(4),
          reason: 'Subsequent LoadNextPage must not be blocked',
        );
        expect(useCase.calls.last.input.offset, equals(5));

        await bloc.close();
      },
    );

    test(
      'restarted LoadInitialPage resets in-flight next-page request',
      () async {
        final useCase = ControlledPaginatedUseCase();
        final bloc = InvalidationTestCollectionBloc(paginatedUseCase: useCase);

        // Initial load
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: 'init'));
        await pumpEventQueue();
        useCase.calls[0].completeSuccess(
          List.generate(5, (i) => TestItem(id: 'p1_$i', title: 'Item $i')),
          hasNext: true,
        );
        await bloc.stream.firstWhere((s) => s.list.length == 5);

        // Start next page (in flight)
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await pumpEventQueue();
        expect(bloc.isLoadingNextPage, isTrue);
        expect(useCase.calls.length, equals(2));
        final nextPageCall = useCase.calls[1];

        // Restart initial load
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: 'restart'));
        await pumpEventQueue();

        expect(
          bloc.isLoadingNextPage,
          isFalse,
          reason: 'Restarting initial load must reset isLoadingNextPage',
        );

        expect(useCase.calls.length, equals(3));
        useCase.calls.last.completeSuccess(
          List.generate(
            5,
            (i) => TestItem(id: 'restarted_$i', title: 'Restarted $i'),
          ),
          hasNext: true,
        );
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == 'restarted_0'),
        );

        expect(bloc.state.isLoadingNextPage, isFalse);
        expect(bloc.isLoadingNextPage, isFalse);

        // Complete the stale next page call
        nextPageCall.completeSuccess([
          const TestItem(id: 'stale_item', title: 'Stale Item'),
        ]);
        await pumpEventQueue();

        // Stale item ignored
        expect(bloc.list.any((e) => e.id == 'stale_item'), isFalse);

        // Can load next page again
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await pumpEventQueue();
        expect(useCase.calls.length, equals(4));
        expect(useCase.calls.last.input.offset, equals(5));

        await bloc.close();
      },
    );

    test('search start resets in-flight next-page request', () {
      fakeAsync((async) {
        final useCase = ControlledPaginatedUseCase();
        final bloc = InvalidationTestCollectionBloc(paginatedUseCase: useCase);

        // Initial load
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: 'init'));
        async.flushMicrotasks();
        useCase.calls[0].completeSuccess(
          List.generate(5, (i) => TestItem(id: 'p1_$i', title: 'Item $i')),
          hasNext: true,
        );
        async.flushMicrotasks();
        expect(bloc.list.length, equals(5));

        // Start next page
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        async.flushMicrotasks();
        expect(bloc.isLoadingNextPage, isTrue);

        // Start search
        bloc.add(BlocxCollectionEventSearch<TestItem>(searchText: 'query'));
        async.elapse(const Duration(milliseconds: 350)); // debounce
        async.flushMicrotasks();

        expect(bloc.isLoadingNextPage, isFalse);
        expect(bloc.state.isLoadingNextPage, isFalse);

        bloc.close();
      });
    });
  });
}
