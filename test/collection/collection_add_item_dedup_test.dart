import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class DedupTestCollectionBloc extends BlocxCollectionBloc<TestItem, void>
    with BlocxCollectionSyncStreamMixin<TestItem, void> {
  @override
  final BlocxEventHub eventHub;

  DedupTestCollectionBloc({required this.eventHub}) : super();

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>?
      get paginationTask => BlocxPaginatedUseCaseTask(
            useCase: FakePaginatedUseCase(
              source: FakePaginatedSource([
                const TestItem(id: '1', title: 'Item 1'),
              ]),
            ),
            inputBuilder: (offset, limit) =>
                BlocxPaginatedInput(offset: offset, limit: limit),
          );
}

void main() {
  group('C5: Deduplicate in addItem', () {
    test(
        'consecutive AddItem events with same identifier replace instead of duplicate',
        () async {
      final eventHub = BlocxSimpleEventHub();
      final bloc = DedupTestCollectionBloc(eventHub: eventHub);

      // Load initial page
      bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
      await bloc.stream.firstWhere((s) => s.list.length == 1);

      // Add item X
      bloc.add(
        BlocxCollectionEventAddItem(
          item: const TestItem(id: 'X', title: 'Item X initial'),
        ),
      );
      // Immediately add item X again before previous completes or immediately after
      bloc.add(
        BlocxCollectionEventAddItem(
          item: const TestItem(id: 'X', title: 'Item X updated'),
        ),
      );

      await bloc.stream.firstWhere(
        (s) => s.list.any((e) => e.id == 'X' && e.title == 'Item X updated'),
      );

      // CRITICAL ASSERTION: There should be exactly one item with id 'X'
      final xItems = bloc.list.where((e) => e.id == 'X').toList();
      expect(xItems.length, equals(1),
          reason: 'Duplicate items with identical ID found in list');
      expect(xItems.first.title, equals('Item X updated'));

      await bloc.close();
      eventHub.dispose();
    });

    test(
        'rapid duplicate create events from EventHub do not result in duplicates',
        () async {
      final eventHub = BlocxSimpleEventHub();
      final bloc = DedupTestCollectionBloc(eventHub: eventHub);

      // Load initial page
      bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
      await bloc.stream.firstWhere((s) => s.list.length == 1);

      // Emit two create events synchronously for the same entity
      const duplicateEntity = TestItem(id: 'dup_1', title: 'Duplicate Item 1');
      eventHub.emitEntity<TestItem>(duplicateEntity, BlocxCommandType.create);
      eventHub.emitEntity<TestItem>(
        const TestItem(id: 'dup_1', title: 'Duplicate Item 1 (Second)'),
        BlocxCommandType.create,
      );

      // Wait for bloc to process events
      await bloc.stream.firstWhere(
        (s) => s.list.any((e) => e.id == 'dup_1'),
      );
      // Allow event loop to process any trailing queued event
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final dupItems = bloc.list.where((e) => e.id == 'dup_1').toList();
      expect(dupItems.length, equals(1),
          reason:
              'Two rapid create sync commands produced duplicate rows in collection');

      await bloc.close();
      eventHub.dispose();
    });
  });
}
