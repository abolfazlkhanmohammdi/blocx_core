import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class RaceTestCollectionBloc extends BlocxCollectionBloc<TestItem, String>
    with
        BlocxCollectionInfiniteMixin<TestItem, String>,
        BlocxCollectionRefreshableMixin<TestItem, String> {
  final ControlledPaginatedUseCase paginatedUseCase;

  RaceTestCollectionBloc({
    required this.paginatedUseCase,
  }) : super();

  @override
  int get limit => 5;

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>?
      get paginationTask => BlocxPaginatedUseCaseTask(
            useCase: paginatedUseCase,
            inputBuilder: (offset, limit) =>
                BlocxPaginatedInput(offset: offset, limit: limit),
          );
}

class ControlledPaginatedUseCase
    extends BlocxPaginatedUseCase<BlocxPaginatedInput, TestItem> {
  final List<ControlledCall> calls = [];

  ControlledPaginatedUseCase() : super();

  @override
  Future<BlocxUseCaseResult<BlocxPage<TestItem>>> perform(
      BlocxPaginatedInput input) async {
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
        ),
      ),
    );
  }
}

void main() {
  group('C4: Stale-response races prevention', () {
    test('slower older initial load cannot overwrite newer initial load',
        () async {
      final useCase = ControlledPaginatedUseCase();
      final bloc = RaceTestCollectionBloc(paginatedUseCase: useCase);

      // Trigger first initial load (slow)
      bloc.add(BlocxCollectionEventLoadInitialPage(payload: 'first'));
      await Future<void>.delayed(Duration.zero);
      expect(useCase.calls.length, equals(1));
      final firstCall = useCase.calls[0];

      // Trigger second initial load (faster)
      bloc.add(BlocxCollectionEventLoadInitialPage(payload: 'second'));
      await Future<void>.delayed(Duration.zero);

      // Complete the second call first with newer items
      expect(useCase.calls.length, greaterThanOrEqualTo(1));
      final secondCall = useCase.calls.last;
      secondCall.completeSuccess([
        const TestItem(id: 'v2_1', title: 'Version 2 Item 1'),
        const TestItem(id: 'v2_2', title: 'Version 2 Item 2'),
      ]);

      // Wait for second call state to settle
      final v2State = await bloc.stream.firstWhere(
        (s) => s.list.any((item) => item.id == 'v2_1'),
      );
      expect(v2State.list.map((e) => e.id).toList(), equals(['v2_1', 'v2_2']));

      // Now complete the stale first call
      firstCall.completeSuccess([
        const TestItem(id: 'v1_1', title: 'Stale Version 1 Item 1'),
      ]);

      // Give event loop time to process if not guarded
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // CRITICAL ASSERTION: The bloc state must still contain Version 2 items, NOT overwritten by Version 1
      expect(bloc.list.map((e) => e.id).toList(), equals(['v2_1', 'v2_2']),
          reason: 'Stale older response overwrote newer initial load');

      await bloc.close();
    });

    test(
        'stale in-flight next-page response is discarded when refresh completes first',
        () async {
      final useCase = ControlledPaginatedUseCase();
      final bloc = RaceTestCollectionBloc(paginatedUseCase: useCase);

      // Initial load (5 items, hasNext is true)
      bloc.add(BlocxCollectionEventLoadInitialPage(payload: 'init'));
      await Future<void>.delayed(Duration.zero);
      useCase.calls.last.completeSuccess(
        List.generate(5, (i) => TestItem(id: 'p1_$i', title: 'Page 1 Item $i')),
      );
      await bloc.stream.firstWhere((s) => s.list.length == 5);

      // Trigger next page (slow)
      bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
      await Future<void>.delayed(Duration.zero);
      final nextPageCall = useCase.calls.last;
      expect(nextPageCall.input.offset, equals(5));

      // While next page is in-flight, user refreshes the collection
      bloc.add(BlocxCollectionEventRefreshData<TestItem>());
      await Future<void>.delayed(Duration.zero);
      final refreshCall = useCase.calls.last;
      expect(refreshCall.input.offset, equals(0));

      // Refresh completes with brand new items (5 items)
      refreshCall.completeSuccess(
        List.generate(
            5, (i) => TestItem(id: 'refreshed_$i', title: 'Refreshed Item $i')),
      );
      await bloc.stream.firstWhere(
        (s) => s.list.any((e) => e.id == 'refreshed_0') && !s.isRefreshing,
      );

      // Now the old slow next-page call finishes
      nextPageCall.completeSuccess([
        const TestItem(id: 'stale_p2_1', title: 'Stale Page 2 Item 1'),
      ]);

      // Give event loop time to process
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // CRITICAL ASSERTION: Stale page 2 items from previous generation must not be appended
      expect(bloc.list.any((e) => e.id == 'stale_p2_1'), isFalse,
          reason:
              'Stale next-page response from old generation was appended to refreshed list');

      await bloc.close();
    });

    test('concurrent loadNextPage events while one is in-flight are dropped',
        () async {
      final useCase = ControlledPaginatedUseCase();
      final bloc = RaceTestCollectionBloc(paginatedUseCase: useCase);

      // Initial load (5 items, hasNext is true)
      bloc.add(BlocxCollectionEventLoadInitialPage(payload: 'init'));
      await Future<void>.delayed(Duration.zero);
      useCase.calls.last.completeSuccess(
        List.generate(5, (i) => TestItem(id: '$i', title: 'Item $i')),
      );
      await bloc.stream.firstWhere((s) => s.list.length == 5);

      final initialCallCount = useCase.calls.length;

      // Dispatch loadNextPage (stays in-flight)
      bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
      await Future<void>.delayed(Duration.zero);
      expect(useCase.calls.length, equals(initialCallCount + 1));

      // Rapidly dispatch 3 more loadNextPage events while first is loading
      bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
      bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
      bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
      await Future<void>.delayed(Duration.zero);

      // Droppable transformer should drop all 3 subsequent calls
      expect(useCase.calls.length, equals(initialCallCount + 1),
          reason: 'Next-page calls were not dropped while one was in-flight');

      // Complete the call
      useCase.calls.last.completeSuccess([
        const TestItem(id: 'next_1', title: 'Next 1'),
      ]);
      await bloc.stream.firstWhere((s) => s.list.length == 6);

      await bloc.close();
    });

    test('slower older search response cannot overwrite newer search response',
        () async {
      final searchUseCase = ControlledSearchUseCase();
      final bloc = RaceSearchCollectionBloc(searchUseCase: searchUseCase);

      // Search 'first' (slow)
      bloc.add(BlocxCollectionEventSearch<TestItem>(searchText: 'first'));
      final firstSearchCall = await searchUseCase.nextCall;

      // Search 'second' (faster)
      bloc.add(BlocxCollectionEventSearch<TestItem>(searchText: 'second'));
      final secondSearchCall = await searchUseCase.nextCall;

      secondSearchCall.completeSuccess([
        const TestItem(id: 'search_v2', title: 'Second Search Result'),
      ]);

      await bloc.stream.firstWhere(
        (s) => s.list.any((e) => e.id == 'search_v2') && !s.isSearching,
      );

      // Now complete older search call
      firstSearchCall.completeSuccess([
        const TestItem(id: 'search_v1', title: 'Stale First Search Result'),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.list.map((e) => e.id).toList(), equals(['search_v2']),
          reason: 'Stale search response overwrote newer search results');

      await bloc.close();
    });
  });
}

class ControlledSearchUseCase
    extends BlocxSearchUseCase<BlocxSearchInput, TestItem> {
  final List<ControlledSearchCall> calls = [];
  Completer<ControlledSearchCall> _nextCallCompleter = Completer();

  Future<ControlledSearchCall> get nextCall {
    if (calls.isNotEmpty && _nextCallCompleter.isCompleted) {
      _nextCallCompleter = Completer();
    }
    return _nextCallCompleter.future;
  }

  ControlledSearchUseCase() : super();

  @override
  Future<BlocxUseCaseResult<BlocxPage<TestItem>>> perform(
      BlocxSearchInput input) async {
    final call = ControlledSearchCall(input);
    calls.add(call);
    if (!_nextCallCompleter.isCompleted) {
      _nextCallCompleter.complete(call);
    }
    return call.completer.future;
  }
}

class ControlledSearchCall {
  final BlocxSearchInput input;
  final Completer<BlocxUseCaseResult<BlocxPage<TestItem>>> completer =
      Completer();

  ControlledSearchCall(this.input);

  void completeSuccess(List<TestItem> items) {
    completer.complete(
      BlocxUseCaseSuccess(
        BlocxPage<TestItem>(
          items: items,
          offset: input.offset,
          limit: input.limit,
        ),
      ),
    );
  }
}

class RaceSearchCollectionBloc extends BlocxCollectionBloc<TestItem, void>
    with BlocxCollectionSearchableMixin<TestItem, void> {
  final ControlledSearchUseCase searchUseCase;

  RaceSearchCollectionBloc({required this.searchUseCase}) : super();

  @override
  Duration get searchDebounceDuration => Duration.zero;

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, TestItem>?
      get searchUseCaseTask => BlocxPaginatedUseCaseTask(
            useCase: searchUseCase,
            inputBuilder: (offset, limit) => BlocxSearchInput(
              searchText: searchText,
              offset: offset,
              limit: limit,
            ),
          );
}
