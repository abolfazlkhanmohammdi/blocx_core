import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class SyncInfiniteCollectionBloc extends BlocxCollectionBloc<TestItem, void>
    with
        BlocxCollectionInfiniteMixin<TestItem, void>,
        BlocxCollectionSyncStreamMixin<TestItem, void> {
  final FakePaginatedUseCase paginatedUseCase;
  @override
  final BlocxEventHub eventHub;

  SyncInfiniteCollectionBloc({
    required this.paginatedUseCase,
    required this.eventHub,
  }) : super();

  @override
  int get limit => 10;

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>?
  get paginationTask => BlocxPaginatedUseCaseTask(
    useCase: paginatedUseCase,
    inputBuilder: (offset, limit) =>
        BlocxPaginatedInput(offset: offset, limit: limit),
  );
}

class FullInteractiveCollectionBloc extends BlocxCollectionBloc<TestItem, void>
    with
        BlocxCollectionInfiniteMixin<TestItem, void>,
        BlocxCollectionRefreshableMixin<TestItem, void>,
        BlocxCollectionSearchableMixin<TestItem, void>,
        BlocxCollectionSyncStreamMixin<TestItem, void> {
  final FakePaginatedUseCase paginatedUseCase;
  final FakeSearchUseCase searchUseCase;
  @override
  final BlocxEventHub eventHub;

  FullInteractiveCollectionBloc({
    required this.paginatedUseCase,
    required this.searchUseCase,
    required this.eventHub,
  }) : super();

  @override
  int get limit => 10;

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

void main() {
  group('C3: Pagination offset drift prevention', () {
    test(
      'loadNextPage uses server loaded count offset when items are added locally via sync',
      () async {
        final eventHub = BlocxSimpleEventHub();
        final source = FakePaginatedSource(
          List.generate(50, (i) => TestItem(id: '$i', title: 'Item $i')),
        );
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = SyncInfiniteCollectionBloc(
          paginatedUseCase: useCase,
          eventHub: eventHub,
        );

        final loadedFuture = bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await loadedFuture;

        expect(bloc.list.length, equals(10));
        expect(useCase.recordedInputs.last.offset, equals(0));

        // Emit create command through EventHub for a brand new entity
        const newEntity = TestItem(id: 'new_999', title: 'New Item 999');
        final addSyncFuture = bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == 'new_999'),
        );
        eventHub.emitEntity<TestItem>(newEntity, BlocxCommandType.create);
        await addSyncFuture;

        // Local list length is now 11
        expect(bloc.list.length, equals(11));

        // Request next page
        final nextPageFuture = bloc.stream.firstWhere(
          (s) => s.list.length > 11,
        );
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await nextPageFuture;

        // CRITICAL ASSERTION: The next page request must use offset: 10, NOT offset: 11
        expect(
          useCase.recordedInputs.last.offset,
          equals(10),
          reason:
              'Next page offset drifted to list.length (11) instead of tracking server offset (10)',
        );

        await bloc.close();
        eventHub.dispose();
      },
    );

    test(
      'loadNextPage uses server loaded count offset when items are removed locally via sync',
      () async {
        final eventHub = FakePaginatedSource(
          List.generate(50, (i) => TestItem(id: '$i', title: 'Item $i')),
        );
        final eventHubInst = BlocxSimpleEventHub();
        final useCase = FakePaginatedUseCase(source: eventHub);
        final bloc = SyncInfiniteCollectionBloc(
          paginatedUseCase: useCase,
          eventHub: eventHubInst,
        );

        final loadedFuture = bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await loadedFuture;

        expect(bloc.list.length, equals(10));

        // Delete two items locally via EventHub
        final deleteSyncFuture = bloc.stream.firstWhere(
          (s) => s.list.length == 8,
        );
        eventHubInst.emitEntity<TestItem>(
          const TestItem(id: '0', title: 'Item 0'),
          BlocxCommandType.delete,
        );
        eventHubInst.emitEntity<TestItem>(
          const TestItem(id: '1', title: 'Item 1'),
          BlocxCommandType.delete,
        );
        await deleteSyncFuture;

        // Local list length is now 8
        expect(bloc.list.length, equals(8));

        // Request next page
        final nextPageFuture = bloc.stream.firstWhere((s) => s.list.length > 8);
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await nextPageFuture;

        // CRITICAL ASSERTION: The next page request must use offset: 10, NOT offset: 8
        expect(
          useCase.recordedInputs.last.offset,
          equals(10),
          reason:
              'Next page offset drifted to list.length (8) instead of tracking server offset (10)',
        );

        await bloc.close();
        eventHubInst.dispose();
      },
    );

    test(
      'refreshPage resets offset and subsequent loadNextPage uses correct offset',
      () async {
        final eventHub = BlocxSimpleEventHub();
        final source = FakePaginatedSource(
          List.generate(50, (i) => TestItem(id: '$i', title: 'Item $i')),
        );
        final useCase = FakePaginatedUseCase(source: source);
        final searchUseCase = FakeSearchUseCase(source: source);
        final bloc = FullInteractiveCollectionBloc(
          paginatedUseCase: useCase,
          searchUseCase: searchUseCase,
          eventHub: eventHub,
        );

        // Load initial page (10 items)
        final loadedFuture = bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await loadedFuture;
        expect(bloc.offset, equals(10));

        // Load page 2 (10 items -> offset 20)
        final page2Future = bloc.stream.firstWhere((s) => s.list.length == 20);
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await page2Future;
        expect(bloc.offset, equals(20));

        // Add item via sync -> list length becomes 21
        final syncFuture = bloc.stream.firstWhere((s) => s.list.length == 21);
        eventHub.emitEntity<TestItem>(
          const TestItem(id: 'sync_item', title: 'Sync Item'),
          BlocxCommandType.create,
        );
        await syncFuture;
        expect(bloc.offset, equals(20));

        // Refresh -> list reloaded to 10 items, offset reset to 10
        final refreshFuture = bloc.stream.firstWhere(
          (s) =>
              !s.isRefreshing &&
              s.list.length == 10 &&
              !s.list.any((e) => e.id == 'sync_item'),
        );
        bloc.add(BlocxCollectionEventRefreshData<TestItem>());
        await refreshFuture;
        expect(bloc.offset, equals(10));

        // Next page after refresh must fetch at offset 10, not 20 or 21
        final pageAfterRefresh = bloc.stream.firstWhere(
          (s) => s.list.length == 20,
        );
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await pageAfterRefresh;

        expect(useCase.recordedInputs.last.offset, equals(10));

        await bloc.close();
        eventHub.dispose();
      },
    );

    test(
      'searchNextPage tracks searchOffset independently of local mutations',
      () async {
        final eventHub = BlocxSimpleEventHub();
        final source = FakePaginatedSource(
          List.generate(50, (i) => TestItem(id: '$i', title: 'Item $i')),
        );
        final useCase = FakePaginatedUseCase(source: source);
        final searchUseCase = FakeSearchUseCase(source: source);
        final bloc = FullInteractiveCollectionBloc(
          paginatedUseCase: useCase,
          searchUseCase: searchUseCase,
          eventHub: eventHub,
        );

        // Search 'Item'
        final searchFuture = bloc.stream.firstWhere((s) => s.list.length == 10);
        bloc.add(BlocxCollectionEventSearch<TestItem>(searchText: 'Item'));
        await searchFuture;
        expect(bloc.searchOffset, equals(10));

        // Add item via sync -> local list length becomes 11
        final syncFuture = bloc.stream.firstWhere((s) => s.list.length == 11);
        eventHub.emitEntity<TestItem>(
          const TestItem(id: 'sync_search_item', title: 'Item sync search'),
          BlocxCommandType.create,
        );
        await syncFuture;
        expect(bloc.searchOffset, equals(10));

        // Request next page of search -> must use offset 10, NOT 11
        final nextSearchFuture = bloc.stream.firstWhere(
          (s) => s.list.length > 11,
        );
        bloc.add(BlocxCollectionEventSearchNextPage<TestItem>());
        await nextSearchFuture;

        expect(
          searchUseCase.recordedInputs.last.offset,
          equals(10),
          reason:
              'Search next page must use searchOffset (10) rather than list.length (11)',
        );
        expect(bloc.searchOffset, equals(20));

        await bloc.close();
        eventHub.dispose();
      },
    );
  });
}
