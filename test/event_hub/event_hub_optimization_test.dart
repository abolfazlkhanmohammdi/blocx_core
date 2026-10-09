import 'package:blocx_core/blocx_core.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class AnotherTestEntity extends BlocxBaseEntity {
  final String key;
  const AnotherTestEntity({required this.key});

  @override
  String get identifier => key;
}

void main() {
  group('C7: EventHub optimizations and metadata preservation', () {
    test('onEntity preserves id and createdAt when re-wrapping untyped events',
        () async {
      final hub = BlocxSimpleEventHub();
      const item = TestItem(id: '1', title: 'Item 1');

      final originalEvent = BlocxEntityEvent<BlocxBaseEntity>(
        entities: [item],
        command: BlocxCommandType.create,
      );

      final streamFuture = hub.onEntity<TestItem>().first;
      hub.emit(originalEvent);
      final receivedEvent = await streamFuture;

      expect(receivedEvent.id, equals(originalEvent.id),
          reason:
              'Re-wrapped event created a new ID instead of preserving original');
      expect(receivedEvent.createdAt, equals(originalEvent.createdAt),
          reason:
              'Re-wrapped event created a new timestamp instead of preserving original');
      expect(receivedEvent.entities.first.id, equals('1'));

      hub.dispose();
    });

    test(
        'onEntity delivers matching entities from mixed-type batches instead of dropping',
        () async {
      final hub = BlocxSimpleEventHub();
      const testItem = TestItem(id: 'item_1', title: 'Item 1');
      const otherItem = AnotherTestEntity(key: 'other_1');

      // Emit a mixed-type batch of entities as BlocxBaseEntity
      final mixedBatchEvent = BlocxEntityEvent<BlocxBaseEntity>(
        entities: [testItem, otherItem],
        command: BlocxCommandType.update,
      );

      final testItemFuture = hub.onEntity<TestItem>().first;
      final otherItemFuture = hub.onEntity<AnotherTestEntity>().first;

      hub.emit(mixedBatchEvent);

      final receivedTestItemEvent = await testItemFuture;
      final receivedOtherItemEvent = await otherItemFuture;

      // Both typed subscribers should receive their respective entities
      expect(receivedTestItemEvent.entities.length, equals(1));
      expect(receivedTestItemEvent.entities.first.id, equals('item_1'));
      expect(receivedTestItemEvent.id, equals(mixedBatchEvent.id));

      expect(receivedOtherItemEvent.entities.length, equals(1));
      expect(receivedOtherItemEvent.entities.first.key, equals('other_1'));
      expect(receivedOtherItemEvent.id, equals(mixedBatchEvent.id));

      hub.dispose();
    });

    test('emit populates debugTrace in debug/test assertions', () {
      final hub = BlocxSimpleEventHub();
      const item = TestItem(id: 'trace_1', title: 'Trace');
      final event = BlocxEntityEvent<TestItem>.single(
        entity: item,
        command: BlocxCommandType.read,
      );

      expect(event.debugTrace, isNull);
      hub.emit(event);
      expect(event.debugTrace, isNotNull);

      hub.dispose();
    });
  });
}
