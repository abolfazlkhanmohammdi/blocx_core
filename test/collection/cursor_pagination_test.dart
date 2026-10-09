import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

class CursorTestItem extends BlocxBaseEntity {
  final String id;
  final String label;

  const CursorTestItem({required this.id, required this.label});

  @override
  String get identifier => id;
}

class FakeCursorUseCase extends BlocxCursorPaginatedUseCase<
    BlocxCursorPaginatedInput, CursorTestItem> {
  final List<String?> requestedCursors = [];

  @override
  Future<BlocxUseCaseResult<BlocxPage<CursorTestItem>>> perform(
    BlocxCursorPaginatedInput input,
  ) async {
    requestedCursors.add(input.cursor);
    if (input.cursor == null) {
      return successResult(
        items: [
          const CursorTestItem(id: '1', label: 'Item 1'),
          const CursorTestItem(id: '2', label: 'Item 2'),
        ],
        input: input,
        nextCursor: 'cursor_page_2',
      );
    } else if (input.cursor == 'cursor_page_2') {
      return successResult(
        items: [
          const CursorTestItem(id: '3', label: 'Item 3'),
        ],
        input: input,
        nextCursor: null,
      );
    }
    return successResult(items: [], input: input, nextCursor: null);
  }
}

class CursorCollectionBloc extends BlocxCollectionBloc<CursorTestItem, void>
    with BlocxCollectionInfiniteMixin<CursorTestItem, void> {
  final FakeCursorUseCase cursorUseCase;

  CursorCollectionBloc(this.cursorUseCase);

  @override
  BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, CursorTestItem>?
      get cursorPaginationTask => BlocxCursorPaginatedUseCaseTask(
            useCase: cursorUseCase,
            inputBuilder: (cursor, limit) =>
                BlocxCursorPaginatedInput(cursor: cursor, limit: limit),
          );
}

void main() {
  group('K2: Cursor pagination', () {
    test('BlocxPage supports nextCursor and derives hasNext correctly', () {
      final page1 = BlocxPage<CursorTestItem>(
        items: [const CursorTestItem(id: '1', label: 'Item 1')],
        limit: 10,
        nextCursor: 'abc',
      );
      expect(page1.nextCursor, equals('abc'));
      expect(page1.hasNext, isTrue);

      final page2 = BlocxPage<CursorTestItem>(
        items: [const CursorTestItem(id: '2', label: 'Item 2')],
        limit: 10,
        nextCursor: null,
      );
      expect(page2.nextCursor, isNull);
      expect(page2.hasNext, isFalse);
    });

    test(
        'CursorCollectionBloc tracks cursor across initial load and pagination',
        () async {
      final useCase = FakeCursorUseCase();
      final bloc = CursorCollectionBloc(useCase);

      expect(bloc.nextCursor, isNull);

      bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
      await bloc.stream.firstWhere((s) => s.list.isNotEmpty);

      expect(useCase.requestedCursors, equals([null]));
      expect(bloc.nextCursor, equals('cursor_page_2'));
      expect(bloc.state.list.length, equals(2));
      expect(bloc.offset, equals(2));

      bloc.add(BlocxCollectionEventLoadNextPage());
      await bloc.stream.firstWhere((s) => s.list.length == 3);

      expect(useCase.requestedCursors, equals([null, 'cursor_page_2']));
      expect(bloc.nextCursor, isNull);
      expect(bloc.state.list.length, equals(3));
      expect(bloc.offset, equals(3));

      bloc.clearList();
      expect(bloc.nextCursor, isNull);
      expect(bloc.offset, equals(0));

      await bloc.close();
    });
  });
}
