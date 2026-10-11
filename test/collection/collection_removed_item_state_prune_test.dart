import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/test_entity.dart';

class FullyFeaturedCollectionBloc extends BlocxCollectionBloc<TestItem, void>
    with
        BlocxCollectionSelectableMixin<TestItem, void>,
        BlocxCollectionHighlightableMixin<TestItem, void>,
        BlocxCollectionExpandableMixin<TestItem, void>,
        BlocxCollectionDeletableMixin<TestItem, void> {
  FullyFeaturedCollectionBloc() : super();

  @override
  bool get isSingleSelect => false;

  @override
  bool get autoClearHighlight => false;
}

void main() {
  group('C-E: pruneItemState on item removal', () {
    late FullyFeaturedCollectionBloc bloc;
    const item1 = TestItem(id: 'item-1', title: 'First');
    const item2 = TestItem(id: 'item-2', title: 'Second');

    setUp(() {
      bloc = FullyFeaturedCollectionBloc();
    });

    tearDown(() => bloc.close());

    test(
      'prunes selectedItemIds, highlightedItemIds, and expandedItemIds on removeItemFromList',
      () async {
        // Add items
        await bloc.insertToList([item1, item2], false, DataInsertSource.init);
        expect(bloc.list.length, equals(2));

        // Select item1
        bloc.add(BlocxCollectionEventSelectItem(item: item1));
        // Highlight item1
        bloc.add(BlocxCollectionEventHighlightItem(item: item1));
        // Expand item1
        bloc.add(BlocxCollectionEventExpandItem(item: item1));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.selectedItemIds.contains('item-1'), isTrue);
        expect(bloc.highlightedItemIds.contains('item-1'), isTrue);
        expect(bloc.expandedItemIds.contains('item-1'), isTrue);

        // Remove item1 via removeItemFromList
        bloc.removeItemFromList(item1);

        expect(
          bloc.selectedItemIds.contains('item-1'),
          isFalse,
          reason: 'selectedItemIds should be pruned',
        );
        expect(
          bloc.highlightedItemIds.contains('item-1'),
          isFalse,
          reason: 'highlightedItemIds should be pruned',
        );
        expect(
          bloc.expandedItemIds.contains('item-1'),
          isFalse,
          reason: 'expandedItemIds should be pruned',
        );
      },
    );

    test(
      'prunes state sets when removed via BlocxCollectionEventRemoveFromList',
      () async {
        await bloc.insertToList([item1, item2], false, DataInsertSource.init);

        bloc.add(BlocxCollectionEventSelectItem(item: item1));
        bloc.add(BlocxCollectionEventHighlightItem(item: item1));
        bloc.add(BlocxCollectionEventExpandItem(item: item1));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.selectedItemIds.contains('item-1'), isTrue);
        expect(bloc.highlightedItemIds.contains('item-1'), isTrue);
        expect(bloc.expandedItemIds.contains('item-1'), isTrue);

        bloc.add(BlocxCollectionEventRemoveFromList(item: item1));
        await Future<void>.delayed(Duration.zero);

        expect(
          bloc.state.list.map((e) => e.identifier),
          isNot(contains('item-1')),
        );
        expect(bloc.state.selectedItemIds, isNot(contains('item-1')));
        expect(bloc.state.highlightedItemIds, isNot(contains('item-1')));
        expect(bloc.state.expandedItemIds, isNot(contains('item-1')));
      },
    );

    test(
      'prunes state sets when removed via BlocxCollectionEventRemoveItemById',
      () async {
        await bloc.insertToList([item1, item2], false, DataInsertSource.init);

        bloc.add(BlocxCollectionEventSelectItem(item: item1));
        bloc.add(BlocxCollectionEventHighlightItem(item: item1));
        bloc.add(BlocxCollectionEventExpandItem(item: item1));
        await Future<void>.delayed(Duration.zero);

        bloc.add(BlocxCollectionEventRemoveItemById(identifier: 'item-1'));
        await Future<void>.delayed(Duration.zero);

        expect(
          bloc.state.list.map((e) => e.identifier),
          isNot(contains('item-1')),
        );
        expect(bloc.state.selectedItemIds, isNot(contains('item-1')));
        expect(bloc.state.highlightedItemIds, isNot(contains('item-1')));
        expect(bloc.state.expandedItemIds, isNot(contains('item-1')));
      },
    );
  });
}
