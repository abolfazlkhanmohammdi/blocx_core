import 'package:bloc_test/bloc_test.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '../helpers/fake_use_cases.dart';
import '../helpers/test_entity.dart';

class FakeDeleteUseCase extends BlocxBaseUseCase<TestItem, bool> {
  final List<TestItem> deletedItems = [];

  FakeDeleteUseCase({super.eventHub})
    : super(commandType: BlocxCommandType.delete);

  @override
  Future<BlocxUseCaseResult<bool>> perform(TestItem input) async {
    deletedItems.add(input);
    return success(true);
  }
}

class CombinationCollectionBloc extends BlocxCollectionBloc<TestItem, void>
    with
        BlocxCollectionInfiniteMixin<TestItem, void>,
        BlocxCollectionRefreshableMixin<TestItem, void>,
        BlocxCollectionSearchableMixin<TestItem, void>,
        BlocxCollectionSelectableMixin<TestItem, void>,
        BlocxCollectionDeletableMixin<TestItem, void>,
        BlocxCollectionSyncStreamMixin<TestItem, void> {
  final FakePaginatedUseCase paginatedUseCase;
  final FakeSearchUseCase searchUseCase;
  final FakeDeleteUseCase deleteUseCase;

  @override
  final BlocxEventHub eventHub;

  CombinationCollectionBloc({
    required this.paginatedUseCase,
    required this.searchUseCase,
    required this.deleteUseCase,
    required this.eventHub,
  }) : super();

  @override
  int get limit => 10;

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem> get paginationTask =>
      BlocxPaginatedUseCaseTask(
        useCase: paginatedUseCase,
        inputBuilder: (offset, limit) =>
            BlocxPaginatedInput(offset: offset, limit: limit),
      );

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, TestItem> get searchUseCaseTask =>
      BlocxPaginatedUseCaseTask(
        useCase: searchUseCase,
        inputBuilder: (offset, limit) => BlocxSearchInput(
          searchText: searchText,
          offset: offset,
          limit: limit,
        ),
      );

  @override
  BlocxUseCaseTask<Object?, bool>? deleteItemTask(TestItem item) =>
      BlocxUseCaseTask(useCase: deleteUseCase, inputBuilder: () => item);
}

void main() {
  group('C9: Multi-mixin combination scenarios (README flagship stack)', () {
    late BlocxEventHub eventHub;
    late FakePaginatedSource source;
    late FakePaginatedUseCase paginatedUseCase;
    late FakeSearchUseCase searchUseCase;
    late FakeDeleteUseCase deleteUseCase;

    setUp(() {
      eventHub = BlocxSimpleEventHub();
      source = FakePaginatedSource(
        List.generate(
          50,
          (i) => TestItem(id: 'item_$i', title: 'Product $i', order: i),
        ),
      );
      paginatedUseCase = FakePaginatedUseCase(source: source);
      searchUseCase = FakeSearchUseCase(source: source);
      deleteUseCase = FakeDeleteUseCase(eventHub: eventHub);
    });

    tearDown(() {
      eventHub.dispose();
    });

    blocTest<CombinationCollectionBloc, BlocxCollectionState<TestItem>>(
      'loads initial page, loads next page, and tracks server offset correctly',
      build: () => CombinationCollectionBloc(
        paginatedUseCase: paginatedUseCase,
        searchUseCase: searchUseCase,
        deleteUseCase: deleteUseCase,
        eventHub: eventHub,
      ),
      act: (bloc) async {
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await pumpEventQueue();
        bloc.add(BlocxCollectionEventLoadNextPage());
        await pumpEventQueue();
      },
      verify: (bloc) {
        expect(bloc.state.list.length, equals(20));
        expect(bloc.offset, equals(20));
        expect(bloc.state.isLoadingNextPage, isFalse);
        expect(
          paginatedUseCase.recordedInputs.map((e) => e.offset),
          equals([0, 10]),
        );
      },
    );

    blocTest<CombinationCollectionBloc, BlocxCollectionState<TestItem>>(
      'handles live sync creation at index 0 without drifting next-page server offset',
      build: () => CombinationCollectionBloc(
        paginatedUseCase: paginatedUseCase,
        searchUseCase: searchUseCase,
        deleteUseCase: deleteUseCase,
        eventHub: eventHub,
      ),
      act: (bloc) async {
        // 1. Initial load
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await pumpEventQueue();

        // 2. Sync incoming new item created by a UseCase
        eventHub.emitEntity<TestItem>(
          const TestItem(id: 'item_new', title: 'New Item', order: -1),
          BlocxCommandType.create,
        );
        await pumpEventQueue();

        // 3. Next page load
        bloc.add(BlocxCollectionEventLoadNextPage());
        await pumpEventQueue();
      },
      verify: (bloc) {
        // List has 1 synced + 10 initial + 10 next = 21 items
        expect(bloc.state.list.length, equals(21));
        expect(bloc.state.list.first.id, equals('item_new'));

        // Next-page input should be offset 11 (10 server loaded + 1 local create shift)
        expect(
          paginatedUseCase.recordedInputs.map((e) => e.offset),
          equals([0, 11]),
        );
        expect(bloc.offset, equals(21));
      },
    );

    blocTest<CombinationCollectionBloc, BlocxCollectionState<TestItem>>(
      'selects items and removes from selection when item is deleted',
      build: () => CombinationCollectionBloc(
        paginatedUseCase: paginatedUseCase,
        searchUseCase: searchUseCase,
        deleteUseCase: deleteUseCase,
        eventHub: eventHub,
      ),
      act: (bloc) async {
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await pumpEventQueue();

        final itemToSelect = bloc.state.list.first;
        bloc.add(BlocxCollectionEventSelectItem(item: itemToSelect));
        await pumpEventQueue();

        bloc.add(BlocxCollectionEventRemoveItem(item: itemToSelect));
        await pumpEventQueue();
      },
      verify: (bloc) {
        expect(bloc.state.list.any((e) => e.id == 'item_0'), isFalse);
        expect(bloc.state.selectedItemIds.contains('item_0'), isFalse);
        expect(deleteUseCase.deletedItems.map((e) => e.id), contains('item_0'));
      },
    );

    test(
      'searches debounced, replaces active list, and clearSearch reloads initial collection',
      () {
        fakeAsync((async) {
          final bloc = CombinationCollectionBloc(
            paginatedUseCase: paginatedUseCase,
            searchUseCase: searchUseCase,
            deleteUseCase: deleteUseCase,
            eventHub: eventHub,
          );

          bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
          async.flushMicrotasks();

          // Search for specific product
          bloc.add(BlocxCollectionEventSearch(searchText: 'Product 5'));
          // Wait for search debounce (300ms)
          async.elapse(const Duration(milliseconds: 350));
          async.flushMicrotasks();

          // Clear search
          bloc.add(BlocxCollectionEventClearSearch());
          async.flushMicrotasks();

          expect(bloc.state.isSearching, isFalse);
          expect(bloc.searchText, isEmpty);
          expect(bloc.state.list.length, equals(10));
          expect(bloc.state.list.first.id, equals('item_0'));

          bloc.close();
        });
      },
    );

    blocTest<CombinationCollectionBloc, BlocxCollectionState<TestItem>>(
      'refreshes collection resetting loaded count and reloading fresh initial page',
      build: () => CombinationCollectionBloc(
        paginatedUseCase: paginatedUseCase,
        searchUseCase: searchUseCase,
        deleteUseCase: deleteUseCase,
        eventHub: eventHub,
      ),
      act: (bloc) async {
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await pumpEventQueue();

        bloc.add(BlocxCollectionEventLoadNextPage());
        await pumpEventQueue();

        bloc.add(BlocxCollectionEventRefreshData());
        await pumpEventQueue();
      },
      verify: (bloc) {
        expect(bloc.state.list.length, equals(10));
        expect(bloc.offset, equals(10));
        expect(bloc.state.isRefreshing, isFalse);
        expect(
          paginatedUseCase.recordedInputs.map((e) => e.offset),
          equals([0, 10, 0]),
        );
      },
    );
  });
}
