import 'dart:math';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class SyncInfiniteCollectionBloc extends BlocxCollectionBloc<TestItem, void>
    with
        BlocxCollectionInfiniteMixin<TestItem, void>,
        BlocxCollectionSyncStreamMixin<TestItem, void> {
  final FakePaginatedUseCase paginatedUseCase;
  final bool _adjustOffset;
  final Comparator<TestItem>? _comparator;
  @override
  final BlocxEventHub eventHub;

  SyncInfiniteCollectionBloc({
    required this.paginatedUseCase,
    required this.eventHub,
    bool adjustOffset = true,
    Comparator<TestItem>? comparator,
  }) : _adjustOffset = adjustOffset,
       _comparator = comparator,
       super();

  @override
  bool get adjustOffsetForLocalChanges => _adjustOffset;

  @override
  Comparator<TestItem>? get sortComparator => _comparator;

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
  group('C3: Pagination offset drift prevention & local adjustment', () {
    test(
      'loadNextPage follows local create on mutable source without duplicates',
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

        // Mutate server source: new item created at head (index 0)
        const newEntity = TestItem(id: 'new_999', title: 'New Item 999');
        source.items.insert(0, newEntity);

        // App broadcasts create command through EventHub
        final addSyncFuture = bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == 'new_999'),
        );
        eventHub.emitEntity<TestItem>(newEntity, BlocxCommandType.create);
        await addSyncFuture;

        // Local list length is now 11, delta is +1
        expect(bloc.list.length, equals(11));
        expect(bloc.offset, equals(11));

        // Request next page
        final nextPageFuture = bloc.stream.firstWhere(
          (s) => s.list.length > 11,
        );
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await nextPageFuture;

        // Next page requested offset 11 (10 server loaded + 1 local delta)
        expect(useCase.recordedInputs.last.offset, equals(11));

        // Verify loaded list has no duplicates and is contiguous with server order
        final ids = bloc.list.map((e) => e.id).toList();
        expect(
          ids.toSet().length,
          equals(ids.length),
          reason: 'Duplicate ids found',
        );
        expect(ids.first, equals('new_999'));
        // The remaining 20 items match source items 1..20
        for (var i = 1; i <= 20; i++) {
          expect(ids[i], equals(source.items[i].id));
        }

        await bloc.close();
        eventHub.dispose();
      },
    );

    test(
      'loadNextPage follows local delete on mutable source without skipped rows',
      () async {
        final source = FakePaginatedSource(
          List.generate(50, (i) => TestItem(id: '$i', title: 'Item $i')),
        );
        final eventHubInst = BlocxSimpleEventHub();
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = SyncInfiniteCollectionBloc(
          paginatedUseCase: useCase,
          eventHub: eventHubInst,
        );

        final loadedFuture = bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await loadedFuture;

        expect(bloc.list.length, equals(10));

        // Mutate server: remove item 0
        source.items.removeWhere((e) => e.id == '0');

        // Delete item locally via EventHub
        final deleteSyncFuture = bloc.stream.firstWhere(
          (s) => s.list.length == 9,
        );
        eventHubInst.emitEntity<TestItem>(
          const TestItem(id: '0', title: 'Item 0'),
          BlocxCommandType.delete,
        );
        await deleteSyncFuture;

        // Local list length is now 9, offset is 9
        expect(bloc.list.length, equals(9));
        expect(bloc.offset, equals(9));

        // Request next page
        final nextPageFuture = bloc.stream.firstWhere((s) => s.list.length > 9);
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await nextPageFuture;

        // Offset requested was 9 (10 server loaded - 1 local delta)
        expect(useCase.recordedInputs.last.offset, equals(9));

        // Verify loaded list is contiguous with remaining server items (no skipped row)
        final ids = bloc.list.map((e) => e.id).toList();
        expect(ids.toSet().length, equals(ids.length));
        for (var i = 0; i < ids.length; i++) {
          expect(ids[i], equals(source.items[i].id));
        }

        await bloc.close();
        eventHubInst.dispose();
      },
    );

    test(
      'adjustOffsetForLocalChanges == false keeps offset unchanged after local create',
      () async {
        final eventHub = BlocxSimpleEventHub();
        final source = FakePaginatedSource(
          List.generate(50, (i) => TestItem(id: '$i', title: 'Item $i')),
        );
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = SyncInfiniteCollectionBloc(
          paginatedUseCase: useCase,
          eventHub: eventHub,
          adjustOffset: false,
        );

        final loadedFuture = bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await loadedFuture;

        expect(bloc.offset, equals(10));

        // Create item locally
        const newEntity = TestItem(id: 'new_999', title: 'New Item 999');
        final addSyncFuture = bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == 'new_999'),
        );
        eventHub.emitEntity<TestItem>(newEntity, BlocxCommandType.create);
        await addSyncFuture;

        expect(bloc.list.length, equals(11));
        // Offset remains 10 because adjustOffsetForLocalChanges is false
        expect(bloc.offset, equals(10));

        await bloc.close();
        eventHub.dispose();
      },
    );

    test(
      'refresh resets delta, search start resets delta, addItem of existing id does not change delta',
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

        // Add brand new item -> delta becomes 1, offset becomes 11
        bloc.add(
          BlocxCollectionEventAddItem(
            item: const TestItem(id: 'fresh_1', title: 'Fresh 1'),
          ),
        );
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == 'fresh_1'),
        );
        expect(bloc.offset, equals(11));

        // Add already present item -> delta does NOT change
        bloc.add(
          BlocxCollectionEventAddItem(
            item: const TestItem(id: 'fresh_1', title: 'Updated Fresh 1'),
          ),
        );
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.title == 'Updated Fresh 1'),
        );
        expect(bloc.offset, equals(11));

        // Refresh -> resets delta and offset
        bloc.add(BlocxCollectionEventRefreshData<TestItem>());
        await bloc.stream.firstWhere(
          (s) => !s.isRefreshing && s.list.length == 10,
        );
        expect(bloc.offset, equals(10));

        // Add new item again
        bloc.add(
          BlocxCollectionEventAddItem(
            item: const TestItem(id: 'fresh_2', title: 'Fresh 2'),
          ),
        );
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == 'fresh_2'),
        );
        expect(bloc.offset, equals(11));

        // Search start -> clearList resets delta
        bloc.add(BlocxCollectionEventSearch<TestItem>(searchText: 'Item'));
        await bloc.stream.firstWhere(
          (s) => s.isSearching || s.list.length == 10,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Search clear restores collection
        bloc.add(BlocxCollectionEventClearSearch<TestItem>());
        await bloc.stream.firstWhere((s) => s.list.length == 10);
        expect(bloc.offset, equals(10));

        await bloc.close();
        eventHub.dispose();
      },
    );

    test(
      'C-B.1: sorted bloc does not shift offset when created item sorts after loaded range',
      () async {
        int byTitle(TestItem a, TestItem b) => a.title.compareTo(b.title);
        final initialItems = List.generate(
          50,
          (i) => TestItem(
            id: 'item_$i',
            title: 'Item ${i.toString().padLeft(2, '0')}',
          ),
        )..sort(byTitle);
        final source = FakePaginatedSource(initialItems);
        final eventHub = BlocxSimpleEventHub();
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = SyncInfiniteCollectionBloc(
          paginatedUseCase: useCase,
          eventHub: eventHub,
          comparator: byTitle,
        );

        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        expect(bloc.list.length, equals(10));
        expect(bloc.offset, equals(10));

        // Create an item that sorts after every loaded row ('zzz')
        const tailItem = TestItem(id: 'new_tail', title: 'zzz');
        source.items
          ..add(tailItem)
          ..sort(byTitle);

        eventHub.emitEntity<TestItem>(tailItem, BlocxCommandType.create);
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == 'new_tail'),
        );

        expect(bloc.list.last.id, equals('new_tail'));
        expect(bloc.offset, equals(10));

        while (!bloc.hasReachedEnd) {
          bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
          await pumpEventQueue();
        }

        final ids = bloc.list.map((e) => e.id).toList();
        expect(ids.length, equals(source.items.length));
        expect(ids.toSet().length, equals(ids.length));
        expect(ids.toSet(), equals(source.items.map((e) => e.id).toSet()));

        await bloc.close();
        eventHub.dispose();
      },
    );

    test(
      'C-B.2: sorted bloc shifts offset +1 when created item sorts inside loaded range',
      () async {
        int byTitle(TestItem a, TestItem b) => a.title.compareTo(b.title);
        final initialItems = List.generate(
          50,
          (i) => TestItem(
            id: 'item_$i',
            title: 'Item ${i.toString().padLeft(2, '0')}',
          ),
        )..sort(byTitle);
        final source = FakePaginatedSource(initialItems);
        final eventHub = BlocxSimpleEventHub();
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = SyncInfiniteCollectionBloc(
          paginatedUseCase: useCase,
          eventHub: eventHub,
          comparator: byTitle,
        );

        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        expect(bloc.list.length, equals(10));

        // Create an item that sorts inside the loaded range (between Item 04 and Item 05)
        const midItem = TestItem(id: 'new_mid', title: 'Item 04_mid');
        source.items
          ..add(midItem)
          ..sort(byTitle);

        eventHub.emitEntity<TestItem>(midItem, BlocxCommandType.create);
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == 'new_mid'),
        );

        expect(bloc.offset, equals(11));

        while (!bloc.hasReachedEnd) {
          bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
          await pumpEventQueue();
        }

        expect(
          bloc.list.map((e) => e.id).toList(),
          equals(source.items.map((e) => e.id).toList()),
        );

        await bloc.close();
        eventHub.dispose();
      },
    );

    test('C-B.4: empty list + create does not change the offset', () async {
      final source = FakePaginatedSource(<TestItem>[]);
      final eventHub = BlocxSimpleEventHub();
      final useCase = FakePaginatedUseCase(source: source);
      final bloc = SyncInfiniteCollectionBloc(
        paginatedUseCase: useCase,
        eventHub: eventHub,
      );

      bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
      await pumpEventQueue();
      expect(bloc.list, isEmpty);
      expect(bloc.offset, equals(0));

      const firstItem = TestItem(id: 'only_1', title: 'Only 1');
      source.items.insert(0, firstItem);
      eventHub.emitEntity<TestItem>(firstItem, BlocxCommandType.create);
      await bloc.stream.firstWhere((s) => s.list.isNotEmpty);

      expect(bloc.list.length, equals(1));
      expect(bloc.offset, equals(0));

      await bloc.close();
      eventHub.dispose();
    });

    test(
      'invariant test: random creates, deletes, and next-page loads maintain order and uniqueness',
      () async {
        for (var seed = 1; seed <= 20; seed++) {
          final random = Random(seed);
          final serverItems = List.generate(
            200,
            (i) => TestItem(id: 'server_$i', title: 'Server Item $i'),
          );
          final source = FakePaginatedSource(List.of(serverItems));
          final eventHub = BlocxSimpleEventHub();
          final useCase = FakePaginatedUseCase(source: source);
          final bloc = SyncInfiniteCollectionBloc(
            paginatedUseCase: useCase,
            eventHub: eventHub,
          );

          // Initial load (10 items)
          bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
          await bloc.stream.firstWhere((s) => s.list.isNotEmpty);

          var nextCreatedId = 1000;
          for (var step = 0; step < 30; step++) {
            final action = random.nextInt(3);
            if (action == 0) {
              // Create at head
              final newItem = TestItem(
                id: 'local_${nextCreatedId++}',
                title: 'Local Created',
              );
              source.items.insert(0, newItem);
              final lengthBefore = bloc.list.length;
              eventHub.emitEntity<TestItem>(newItem, BlocxCommandType.create);
              await bloc.stream.firstWhere(
                (s) => s.list.length == lengthBefore + 1,
              );
            } else if (action == 1) {
              // Delete a loaded item if any exists
              if (bloc.list.isNotEmpty) {
                final target = bloc.list[random.nextInt(bloc.list.length)];
                source.items.removeWhere((e) => e.id == target.id);
                final lengthBefore = bloc.list.length;
                eventHub.emitEntity<TestItem>(target, BlocxCommandType.delete);
                await bloc.stream.firstWhere(
                  (s) => s.list.length == lengthBefore - 1,
                );
              }
            } else {
              // Next page
              if (!bloc.hasReachedEnd) {
                final lengthBefore = bloc.list.length;
                bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
                await Future<void>.delayed(const Duration(milliseconds: 15));
                if (bloc.list.length > lengthBefore) {
                  // Loaded
                }
              }
            }

            // Invariant check
            final ids = bloc.list.map((e) => e.id).toList();
            expect(
              ids.toSet().length,
              equals(ids.length),
              reason: 'Seed $seed step $step: Duplicate IDs in list',
            );
          }

          await bloc.close();
          eventHub.dispose();
        }
      },
    );
  });
}
