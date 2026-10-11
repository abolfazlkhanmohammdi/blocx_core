import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class OverlapPaginationCollectionBloc
    extends BlocxCollectionBloc<TestItem, void>
    with BlocxCollectionInfiniteMixin<TestItem, void> {
  final FakePaginatedUseCase paginatedUseCase;

  OverlapPaginationCollectionBloc({required this.paginatedUseCase}) : super();

  @override
  int get limit => 2;

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>?
  get paginationTask => BlocxPaginatedUseCaseTask(
    useCase: paginatedUseCase,
    inputBuilder: (offset, limit) =>
        BlocxPaginatedInput(offset: offset, limit: limit),
  );
}

void main() {
  group('K3: Dedupe in insertToList', () {
    test(
      'next page overlapping already loaded id replaces item in place without duplicating',
      () async {
        // Page 1: item 1, item 2
        // Page 2: item 2 (updated), item 3
        final source = FakePaginatedSource([
          const TestItem(id: '1', title: 'Item 1'),
          const TestItem(id: '2', title: 'Item 2 v1'),
          const TestItem(id: '2', title: 'Item 2 v2'),
          const TestItem(id: '3', title: 'Item 3'),
        ]);
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = OverlapPaginationCollectionBloc(paginatedUseCase: useCase);

        // Load initial page (items: 1, 2 v1)
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.length == 2);

        expect(bloc.list.map((e) => e.id).toList(), equals(['1', '2']));
        expect(bloc.list[1].title, equals('Item 2 v1'));
        expect(bloc.offset, equals(2));

        // Load next page: returns 2 v2, 3
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await bloc.stream.firstWhere((s) => s.list.any((e) => e.id == '3'));

        // Expect: ids are unique: ['1', '2', '3']
        final ids = bloc.list.map((e) => e.id).toList();
        expect(ids, equals(['1', '2', '3']));
        // Existing item 2 was replaced with newer instance (v2)
        expect(bloc.list[1].title, equals('Item 2 v2'));
        // Raw page size (2) was added to offset
        expect(bloc.offset, equals(4));

        await bloc.close();
      },
    );

    test(
      'page containing the same id twice within the incoming batch inserts it once',
      () async {
        final source = FakePaginatedSource([
          const TestItem(id: 'dup', title: 'First'),
          const TestItem(id: 'dup', title: 'Second'),
        ]);
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = OverlapPaginationCollectionBloc(paginatedUseCase: useCase);

        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.isNotEmpty);

        expect(bloc.list.length, equals(1));
        expect(bloc.list.first.id, equals('dup'));

        await bloc.close();
      },
    );

    test(
      'smoke test: inserting a 1,000-item page into a 5,000-item list succeeds with correct deduping',
      () async {
        final initialItems = List.generate(
          5000,
          (i) => TestItem(id: '$i', title: 'Initial $i'),
        );
        // 500 overlapping items with updated title + 500 fresh items
        final incomingPage = [
          ...List.generate(
            500,
            (i) => TestItem(id: '${4500 + i}', title: 'Updated ${4500 + i}'),
          ),
          ...List.generate(
            500,
            (i) => TestItem(id: '${5000 + i}', title: 'Fresh ${5000 + i}'),
          ),
        ];

        final source = FakePaginatedSource([...initialItems, ...incomingPage]);
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = OverlapPaginationCollectionBloc(paginatedUseCase: useCase);

        // Preload initial 5,000 items directly via replaceList
        bloc.replaceList(initialItems);
        expect(bloc.list.length, equals(5000));

        // Insert the 1,000-item incoming page as next page
        await bloc.insertToList(incomingPage, false, DataInsertSource.nextPage);

        // Assert correctness: total unique items is 5500
        expect(bloc.list.length, equals(5500));
        final uniqueIds = bloc.list.map((e) => e.id).toSet();
        expect(uniqueIds.length, equals(5500));

        // Overlapping items were updated in place
        expect(bloc.list[4500].title, equals('Updated 4500'));
        expect(bloc.list[4999].title, equals('Updated 4999'));

        // Fresh items were appended
        expect(bloc.list[5000].id, equals('5000'));
        expect(bloc.list[5499].id, equals('5499'));

        await bloc.close();
      },
    );
  });
}
