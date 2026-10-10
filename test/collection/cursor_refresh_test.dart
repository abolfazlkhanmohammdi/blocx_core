import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

class RefreshCursorItem extends BlocxBaseEntity {
  final String id;
  final String name;

  const RefreshCursorItem({required this.id, required this.name});

  @override
  String get identifier => id;
}

class FakeCursorRefreshUseCase
    extends
        BlocxCursorPaginatedUseCase<
          BlocxCursorPaginatedInput,
          RefreshCursorItem
        > {
  final List<String?> requestedCursors = [];
  bool shouldFail = false;
  Object? failureError;
  int refreshCallCount = 0;

  @override
  Future<BlocxUseCaseResult<BlocxPage<RefreshCursorItem>>> perform(
    BlocxCursorPaginatedInput input,
  ) async {
    requestedCursors.add(input.cursor);
    if (shouldFail) {
      throw failureError ?? Exception('Cursor refresh error');
    }

    if (input.cursor == null) {
      refreshCallCount++;
      if (refreshCallCount == 1) {
        // Initial load page
        return successResult(
          items: const [
            RefreshCursorItem(id: '1', name: 'Initial 1'),
            RefreshCursorItem(id: '2', name: 'Initial 2'),
          ],
          input: input,
          nextCursor: 'cur_page_2',
        );
      } else {
        // Refreshed page
        return successResult(
          items: const [
            RefreshCursorItem(id: '10', name: 'Refreshed 10'),
            RefreshCursorItem(id: '11', name: 'Refreshed 11'),
          ],
          input: input,
          nextCursor: 'cur_refreshed_2',
        );
      }
    } else if (input.cursor == 'cur_refreshed_2') {
      return successResult(
        items: const [RefreshCursorItem(id: '12', name: 'Refreshed 12')],
        input: input,
        nextCursor: null,
      );
    }

    return successResult(items: const [], input: input, nextCursor: null);
  }
}

class FakeSearchOffsetUseCase
    extends BlocxSearchUseCase<BlocxSearchInput, RefreshCursorItem> {
  int searchRefreshCount = 0;

  @override
  Future<BlocxUseCaseResult<BlocxPage<RefreshCursorItem>>> perform(
    BlocxSearchInput input,
  ) async {
    searchRefreshCount++;
    return success(
      BlocxPage(
        items: const [RefreshCursorItem(id: 's1', name: 'Search 1')],
        limit: input.limit,
        offset: input.offset,
      ),
    );
  }
}

class CursorRefreshableBloc extends BlocxCollectionBloc<RefreshCursorItem, void>
    with
        BlocxCollectionInfiniteMixin<RefreshCursorItem, void>,
        BlocxCollectionRefreshableMixin<RefreshCursorItem, void> {
  final FakeCursorRefreshUseCase cursorUseCase;
  Object? lastHandledError;

  CursorRefreshableBloc(this.cursorUseCase);

  @override
  BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, RefreshCursorItem>?
  get cursorPaginationTask => BlocxCursorPaginatedUseCaseTask(
    useCase: cursorUseCase,
    inputBuilder: (cursor, limit) =>
        BlocxCursorPaginatedInput(cursor: cursor, limit: limit),
  );

  @override
  Future<void> handleError(
    Object error,
    Emitter<BlocxBaseState> emit, {
    StackTrace? stacktrace,
  }) async {
    lastHandledError = error;
    await super.handleError(error, emit, stacktrace: stacktrace);
  }
}

class SearchableCursorRefreshBloc
    extends BlocxCollectionBloc<RefreshCursorItem, void>
    with
        BlocxCollectionInfiniteMixin<RefreshCursorItem, void>,
        BlocxCollectionRefreshableMixin<RefreshCursorItem, void>,
        BlocxCollectionSearchableMixin<RefreshCursorItem, void> {
  final FakeCursorRefreshUseCase cursorUseCase;
  final FakeSearchOffsetUseCase searchUseCase;

  SearchableCursorRefreshBloc(this.cursorUseCase, this.searchUseCase);

  @override
  BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, RefreshCursorItem>?
  get cursorPaginationTask => BlocxCursorPaginatedUseCaseTask(
    useCase: cursorUseCase,
    inputBuilder: (cursor, limit) =>
        BlocxCursorPaginatedInput(cursor: cursor, limit: limit),
  );

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, RefreshCursorItem>?
  get searchUseCaseTask => BlocxPaginatedUseCaseTask(
    useCase: searchUseCase,
    inputBuilder: (offset, limit) =>
        BlocxSearchInput(searchText: searchText, offset: offset, limit: limit),
  );
}

void main() {
  group('T3: Cursor-based pull-to-refresh', () {
    test(
      'initial load -> refresh -> list equals freshly returned page and isRefreshing is false',
      () async {
        final useCase = FakeCursorRefreshUseCase();
        final bloc = CursorRefreshableBloc(useCase);

        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        expect(bloc.state.list.map((e) => e.id).toList(), equals(['1', '2']));
        expect(bloc.nextCursor, equals('cur_page_2'));

        bloc.add(BlocxCollectionEventRefreshData<RefreshCursorItem>());
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == '10') && !s.isRefreshing,
        );

        expect(bloc.state.list.map((e) => e.id).toList(), equals(['10', '11']));
        expect(bloc.isRefreshing, isFalse);
        expect(bloc.state.isRefreshing, isFalse);
        expect(bloc.nextCursor, equals('cur_refreshed_2'));

        await bloc.close();
      },
    );

    test(
      'after refresh, nextCursor is updated and subsequent LoadNextPage sends it',
      () async {
        final useCase = FakeCursorRefreshUseCase();
        final bloc = CursorRefreshableBloc(useCase);

        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.isNotEmpty);

        bloc.add(BlocxCollectionEventRefreshData<RefreshCursorItem>());
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == '10') && !s.isRefreshing,
        );

        expect(bloc.nextCursor, equals('cur_refreshed_2'));

        bloc.add(BlocxCollectionEventLoadNextPage());
        await bloc.stream.firstWhere((s) => s.list.length == 3);

        expect(
          useCase.requestedCursors,
          equals([null, null, 'cur_refreshed_2']),
        );
        expect(bloc.nextCursor, isNull);
        expect(bloc.hasReachedEnd, isTrue);
        expect(
          bloc.state.list.map((e) => e.id).toList(),
          equals(['10', '11', '12']),
        );

        await bloc.close();
      },
    );

    test(
      'refresh failure: isRefreshing is reset to false, previous list kept, error surfaced via handleError',
      () async {
        final useCase = FakeCursorRefreshUseCase();
        final bloc = CursorRefreshableBloc(useCase);

        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        expect(bloc.state.list.map((e) => e.id).toList(), equals(['1', '2']));

        useCase.shouldFail = true;
        bloc.add(BlocxCollectionEventRefreshData<RefreshCursorItem>());
        await bloc.stream.firstWhere((s) => !s.isRefreshing);

        expect(bloc.isRefreshing, isFalse);
        expect(bloc.state.isRefreshing, isFalse);
        expect(bloc.state.list.map((e) => e.id).toList(), equals(['1', '2']));
        expect(bloc.lastHandledError, isNotNull);

        await bloc.close();
      },
    );

    test(
      'refresh with empty search text uses cursor task, with active search text delegates to search refresh',
      () async {
        final cursorUseCase = FakeCursorRefreshUseCase();
        final searchUseCase = FakeSearchOffsetUseCase();
        final bloc = SearchableCursorRefreshBloc(cursorUseCase, searchUseCase);

        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        expect(cursorUseCase.refreshCallCount, equals(1));

        // 1. Refresh with empty search text uses cursor task
        bloc.add(BlocxCollectionEventRefreshData<RefreshCursorItem>());
        await bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == '10') && !s.isRefreshing,
        );
        expect(cursorUseCase.refreshCallCount, equals(2));
        expect(searchUseCase.searchRefreshCount, equals(0));

        // 2. Set search text and refresh -> dispatches SearchRefresh
        bloc.searchText = 'apple';
        bloc.add(BlocxCollectionEventRefreshData<RefreshCursorItem>());
        await bloc.stream.firstWhere((s) => s.list.any((e) => e.id == 's1'));
        expect(searchUseCase.searchRefreshCount, equals(1));

        await bloc.close();
      },
    );
  });
}
