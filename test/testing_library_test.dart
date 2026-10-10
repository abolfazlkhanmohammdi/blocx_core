import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/testing.dart';
import 'package:test/test.dart';

void main() {
  group('package:blocx_core/testing.dart', () {
    test('BlocxTestEventHub records and filters emitted events', () {
      final hub = BlocxTestEventHub();
      final entity1 = BlocxTestEntity(id: '1', name: 'Item 1');
      final entity2 = BlocxTestEntity(id: '2', name: 'Item 2');

      hub.emitEntity(entity1, BlocxCommandType.create);
      hub.emitEntities([entity1, entity2], BlocxCommandType.update);

      expect(hub.recordedEvents.length, equals(2));
      final entityEvents = hub.recordedEntityEvents<BlocxTestEntity>();
      expect(entityEvents.length, equals(2));
      expect(entityEvents.first.command, equals(BlocxCommandType.create));
      expect(entityEvents.last.command, equals(BlocxCommandType.update));

      hub.clearRecordedEvents();
      expect(hub.recordedEvents, isEmpty);
      hub.dispose();
    });

    test('createTestEntities generates sequentially named entities', () {
      final entities = createTestEntities(5, prefix: 'Entity');
      expect(entities.length, equals(5));
      expect(entities[0].id, equals('0'));
      expect(entities[0].name, equals('Entity 0'));
      expect(entities[4].id, equals('4'));
      expect(entities[4].name, equals('Entity 4'));
    });

    test('BlocxTestFormEntity updates fields correctly', () {
      const initial = BlocxTestFormEntity(id: 'test-form');
      final updated = initial.updateByKey(BlocxTestFormField.field1, 'hello');
      expect(updated.getValueByKey(BlocxTestFormField.field1), equals('hello'));
      expect(updated.field1, equals('hello'));
      expect(updated.identifier, equals('test-form'));
    });

    test(
      'FakePaginatedUseCase & createFakePaginatedTask slice pages properly',
      () async {
        final entities = createTestEntities(20);
        final source = FakePaginatedSource<BlocxTestEntity>(entities);
        final useCase = FakePaginatedUseCase<BlocxTestEntity>(source: source);
        final task = createFakePaginatedTask(useCase: useCase);

        final result = await task.useCase.execute(task.inputBuilder(0, 10));
        expect(result.isSuccess, isTrue);
        expect(result.data?.items.length, equals(10));
        expect(result.data?.items.first.id, equals('0'));
        expect(result.data?.hasNext, isTrue);

        final secondPage = await task.useCase.execute(
          task.inputBuilder(10, 10),
        );
        expect(secondPage.data?.items.length, equals(10));
        expect(secondPage.data?.items.first.id, equals('10'));
        expect(secondPage.data?.hasNext, isFalse);
      },
    );

    test(
      'FakeCursorPaginatedUseCase & createFakeCursorPaginatedTask paginate via cursor',
      () async {
        final entities = createTestEntities(15);
        final source = FakePaginatedSource<BlocxTestEntity>(entities);
        final useCase = FakeCursorPaginatedUseCase<BlocxTestEntity>(
          source: source,
        );
        final task = createFakeCursorPaginatedTask(useCase: useCase);

        final firstPage = await task.useCase.execute(
          task.inputBuilder(null, 10),
        );
        expect(firstPage.data?.items.length, equals(10));
        expect(firstPage.data?.nextCursor, equals('10'));
        expect(firstPage.data?.hasNext, isTrue);

        final secondPage = await task.useCase.execute(
          task.inputBuilder(firstPage.data?.nextCursor, 10),
        );
        expect(secondPage.data?.items.length, equals(5));
        expect(secondPage.data?.nextCursor, isNull);
        expect(secondPage.data?.hasNext, isFalse);
      },
    );

    test('FakeSearchUseCase filters matching entities', () async {
      final entities = [
        const BlocxTestEntity(id: '1', name: 'Apple'),
        const BlocxTestEntity(id: '2', name: 'Banana'),
        const BlocxTestEntity(id: '3', name: 'Pineapple'),
      ];
      final source = FakePaginatedSource<BlocxTestEntity>(entities);
      final useCase = FakeSearchUseCase<BlocxTestEntity>(
        source: source,
        matcher: (item, query) => item.name.toLowerCase().contains(query),
      );

      final result = await useCase.execute(
        BlocxSearchInput(searchText: 'apple', offset: 0, limit: 10),
      );
      expect(result.data?.items.length, equals(2));
      expect(
        result.data?.items.map((e) => e.name),
        containsAll(['Apple', 'Pineapple']),
      );
    });

    test('FakeUseCase & createFakeSubmitTask execute handler', () async {
      final useCase = FakeUseCase<String, int>(
        handler: (input) => input.length,
      );
      final task = createFakeSubmitTask(
        useCase: useCase,
        inputBuilder: () => 'testing',
      );

      final result = await task.useCase.execute(task.inputBuilder());
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(7));
      expect(useCase.recordedInputs, equals(['testing']));
    });
  });
}
