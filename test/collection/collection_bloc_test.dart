import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

class TestEntity extends BlocxBaseEntity {
  final String id;
  final String title;

  const TestEntity({required this.id, required this.title});

  @override
  String get identifier => id;
}

class TestPaginatedUseCase extends BlocxPaginatedUseCase<BlocxPaginatedInput, TestEntity> {
  @override
  Future<BlocxUseCaseResult<BlocxPage<TestEntity>>> perform(BlocxPaginatedInput input) async {
    final count = input.limit;
    final items = List.generate(
      count,
      (i) => TestEntity(id: '${input.offset + i}', title: 'Item ${input.offset + i}'),
    );
    return success(BlocxPage(items: items, offset: input.offset, limit: input.limit));
  }
}

class TestCollectionBloc extends BlocxCollectionBloc<TestEntity, void>
    with
        BlocxCollectionSelectableMixin<TestEntity, void>,
        BlocxCollectionHighlightableMixin<TestEntity, void> {
  final TestPaginatedUseCase _useCase = TestPaginatedUseCase();

  @override
  int get limit => 10;

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestEntity> get paginationTask => BlocxPaginatedUseCaseTask(
        useCase: _useCase,
        inputBuilder: (offset, limit) => BlocxPaginatedInput(limit: limit, offset: offset),
      );
}

void main() {
  group('BlocxCollectionBloc', () {
    late TestCollectionBloc bloc;

    setUp(() {
      bloc = TestCollectionBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    test('loads initial page on event dispatch', () async {
      expect(bloc.list, isEmpty);

      bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.list.length, equals(10));
      expect(bloc.list.first.title, equals('Item 0'));
      expect(bloc.hasReachedEnd, isFalse);
    });

    test('adds and updates items in list', () async {
      bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
      await Future.delayed(const Duration(milliseconds: 50));

      const newItem = TestEntity(id: '999', title: 'New Item');
      bloc.add(BlocxCollectionEventAddItem(item: newItem, index: 0));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.list.first.id, equals('999'));

      const updatedItem = TestEntity(id: '999', title: 'Updated Title');
      bloc.add(BlocxCollectionEventUpdateItem(item: updatedItem));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.list.first.title, equals('Updated Title'));
    });

    test('item selection mixin selects and deselects items', () async {
      bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(BlocxCollectionEventSelectItem(item: bloc.list.first));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.selectedItemIds, contains('0'));

      bloc.add(BlocxCollectionEventDeselectItem(item: bloc.list.first));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.selectedItemIds, isNot(contains('0')));
    });
  });
}
