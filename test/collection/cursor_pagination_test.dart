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

class FakeCursorUseCase
    extends
        BlocxCursorPaginatedUseCase<BlocxCursorPaginatedInput, CursorTestItem> {
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
        items: [const CursorTestItem(id: '3', label: 'Item 3')],
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
      },
    );

    test(
      'successResult with nextCursor: null and no explicit hasNext defaults hasNext to false even when items.length == limit',
      () {
        final helper = TestCursorUseCase();
        final input = const BlocxCursorPaginatedInput<void>(limit: 2);
        final res = helper.testSuccessResult(
          items: const [
            CursorTestItem(id: '1', label: 'Item 1'),
            CursorTestItem(id: '2', label: 'Item 2'),
          ],
          input: input,
          nextCursor: null,
        );
        final page = res.data!;
        expect(page.hasNext, isFalse);
      },
    );

    test(
      'successResult hasNext respects non-empty cursor, empty cursor, and explicit override',
      () {
        final helper = TestCursorUseCase();
        final input = const BlocxCursorPaginatedInput<void>(limit: 5);

        final pageWithCursor = helper
            .testSuccessResult(
              items: const [CursorTestItem(id: '1', label: 'Item 1')],
              input: input,
              nextCursor: 'abc',
            )
            .data!;
        expect(pageWithCursor.hasNext, isTrue);

        final pageWithEmptyCursor = helper
            .testSuccessResult(
              items: const [CursorTestItem(id: '1', label: 'Item 1')],
              input: input,
              nextCursor: '',
            )
            .data!;
        expect(pageWithEmptyCursor.hasNext, isFalse);

        final pageWithExplicit = helper
            .testSuccessResult(
              items: const [CursorTestItem(id: '1', label: 'Item 1')],
              input: input,
              nextCursor: null,
              hasNext: true,
            )
            .data!;
        expect(pageWithExplicit.hasNext, isTrue);
      },
    );

    test(
      'first page has exactly limit items and nextCursor: null -> hasReachedEnd is true and LoadNextPage makes 0 extra calls',
      () async {
        int callCount = 0;
        final useCase = CallbackCursorUseCase((input) async {
          callCount++;
          return BlocxUseCaseSuccess(
            BlocxPage(
              items: const [
                CursorTestItem(id: '1', label: 'Item 1'),
                CursorTestItem(id: '2', label: 'Item 2'),
              ],
              limit: 2,
              nextCursor: null,
            ),
          );
        });
        final bloc = CursorCollectionBlocWithLimit(useCase, limit: 2);

        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.isNotEmpty);

        expect(callCount, equals(1));
        expect(bloc.hasReachedEnd, isTrue);
        expect(bloc.state.hasReachedEnd, isTrue);

        bloc.add(BlocxCollectionEventLoadNextPage());
        // Pump event loop
        await Future<void>.delayed(Duration.zero);

        expect(callCount, equals(1));
        await bloc.close();
      },
    );

    test(
      'two pages (cursor c1 then null) -> exactly 2 calls, second receives c1, list has both pages, hasReachedEnd is true',
      () async {
        int callCount = 0;
        final requestedCursors = <String?>[];
        final useCase = CallbackCursorUseCase((input) async {
          callCount++;
          requestedCursors.add(input.cursor);
          if (input.cursor == null) {
            return BlocxUseCaseSuccess(
              const BlocxPage(
                items: [
                  CursorTestItem(id: '1', label: 'Item 1'),
                  CursorTestItem(id: '2', label: 'Item 2'),
                ],
                limit: 2,
                nextCursor: 'c1',
                hasNext: true,
              ),
            );
          } else if (input.cursor == 'c1') {
            return BlocxUseCaseSuccess(
              const BlocxPage(
                items: [
                  CursorTestItem(id: '3', label: 'Item 3'),
                  CursorTestItem(id: '4', label: 'Item 4'),
                ],
                limit: 2,
                nextCursor: null,
              ),
            );
          }
          return BlocxUseCaseSuccess(
            const BlocxPage(items: [], limit: 2, nextCursor: null),
          );
        });

        final bloc = CursorCollectionBlocWithLimit(useCase, limit: 2);
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.isNotEmpty);

        expect(bloc.nextCursor, equals('c1'));
        expect(bloc.hasReachedEnd, isFalse);

        bloc.add(BlocxCollectionEventLoadNextPage());
        await bloc.stream.firstWhere((s) => s.list.length == 4);

        expect(callCount, equals(2));
        expect(requestedCursors, equals([null, 'c1']));
        expect(bloc.nextCursor, isNull);
        expect(bloc.hasReachedEnd, isTrue);
        expect(bloc.state.hasReachedEnd, isTrue);
        expect(
          bloc.state.list.map((e) => e.id).toList(),
          equals(['1', '2', '3', '4']),
        );

        await bloc.close();
      },
    );
  });
}

class TestCursorUseCase
    extends
        BlocxCursorPaginatedUseCase<BlocxCursorPaginatedInput, CursorTestItem> {
  BlocxUseCaseResult<BlocxPage<CursorTestItem>> testSuccessResult({
    required List<CursorTestItem> items,
    required BlocxCursorPaginatedInput input,
    String? nextCursor,
    bool? hasNext,
  }) {
    return successResult(
      items: items,
      input: input,
      nextCursor: nextCursor,
      hasNext: hasNext,
    );
  }

  @override
  Future<BlocxUseCaseResult<BlocxPage<CursorTestItem>>> perform(
    BlocxCursorPaginatedInput input,
  ) async => throw UnimplementedError();
}

class CallbackCursorUseCase
    extends
        BlocxCursorPaginatedUseCase<BlocxCursorPaginatedInput, CursorTestItem> {
  final Future<BlocxUseCaseResult<BlocxPage<CursorTestItem>>> Function(
    BlocxCursorPaginatedInput input,
  )
  handler;

  CallbackCursorUseCase(this.handler);

  @override
  Future<BlocxUseCaseResult<BlocxPage<CursorTestItem>>> perform(
    BlocxCursorPaginatedInput input,
  ) => handler(input);
}

class CursorCollectionBlocWithLimit
    extends BlocxCollectionBloc<CursorTestItem, void>
    with BlocxCollectionInfiniteMixin<CursorTestItem, void> {
  final CallbackCursorUseCase cursorUseCase;
  final int _customLimit;

  CursorCollectionBlocWithLimit(this.cursorUseCase, {int limit = 10})
    : _customLimit = limit;

  @override
  int get limit => _customLimit;

  @override
  BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, CursorTestItem>?
  get cursorPaginationTask => BlocxCursorPaginatedUseCaseTask(
    useCase: cursorUseCase,
    inputBuilder: (cursor, limit) =>
        BlocxCursorPaginatedInput(cursor: cursor, limit: limit),
  );
}
