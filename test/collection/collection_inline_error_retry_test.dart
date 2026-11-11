import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class _TestErrorTranslator extends BlocxErrorTranslator {
  @override
  ReadableError makeErrorReadable(Object error, {StackTrace? stackTrace}) {
    return ReadableError(
      title: 'Request Failed',
      message: error.toString().replaceFirst('Exception: ', ''),
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class _CustomFilter {
  final String category;
  const _CustomFilter(this.category);
}

class _ConfigurableCollectionBloc extends BlocxCollectionBloc<TestItem, String>
    with
        BlocxCollectionInfiniteMixin<TestItem, String>,
        BlocxCollectionRefreshableMixin<TestItem, String>,
        BlocxCollectionSearchableMixin<TestItem, String>,
        BlocxCollectionSelectableMixin<TestItem, String>,
        BlocxCollectionDeletableMixin<TestItem, String>,
        BlocxCollectionFilterMixin<TestItem, String, dynamic> {
  final FakePaginatedUseCase paginatedUseCase;
  final FakeSearchUseCase searchUseCase;
  final FakeCursorPaginatedUseCase? cursorUseCase;
  final bool useInlineError;
  final List<Object> reportedErrors = [];
  final List<String?> capturedPayloads = [];
  final List<dynamic> capturedFilters = [];
  bool failNextDelete = false;
  bool failNextSelect = false;

  _ConfigurableCollectionBloc({
    required this.paginatedUseCase,
    required this.searchUseCase,
    this.cursorUseCase,
    this.useInlineError = true,
    super.errorTranslator,
  });

  @override
  bool get useInlineErrorForInitialLoad => useInlineError;

  @override
  bool get syncWithServerOnSelection => true;

  @override
  Duration get searchDebounceDuration => const Duration(milliseconds: 20);

  @override
  Duration get filterDebounceDuration => const Duration(milliseconds: 20);

  @override
  void reportError(Object error, StackTrace? stackTrace) {
    reportedErrors.add(error);
    super.reportError(error, stackTrace);
  }

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>? get paginationTask {
    if (cursorUseCase != null) return null;
    return BlocxPaginatedUseCaseTask(
      useCase: paginatedUseCase,
      inputBuilder: (offset, limit) {
        capturedPayloads.add(payload);
        capturedFilters.add(getFilter());
        return BlocxPaginatedInput(offset: offset, limit: limit);
      },
    );
  }

  @override
  BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, TestItem>?
  get cursorPaginationTask {
    final uc = cursorUseCase;
    if (uc == null) return null;
    return BlocxCursorPaginatedUseCaseTask(
      useCase: uc,
      inputBuilder: (cursor, limit) {
        capturedPayloads.add(payload);
        return BlocxCursorPaginatedInput(cursor: cursor, limit: limit);
      },
    );
  }

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, TestItem>? get searchUseCaseTask {
    return BlocxPaginatedUseCaseTask(
      useCase: searchUseCase,
      inputBuilder: (offset, limit) => BlocxSearchInput(
        searchText: searchText,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  Future<bool> performDeleteItem(TestItem item) async {
    if (failNextDelete) {
      throw Exception('Delete failed');
    }
    return true;
  }

  @override
  Future<bool> performRemoteSelection(TestItem item) async {
    if (failNextSelect) {
      throw Exception('Select failed');
    }
    return true;
  }
}

class FakeCursorPaginatedUseCase
    extends BlocxCursorPaginatedUseCase<BlocxCursorPaginatedInput, TestItem> {
  final FakePaginatedSource source;
  bool shouldFail;
  Object? failureError;

  FakeCursorPaginatedUseCase({
    required this.source,
    this.shouldFail = false,
    this.failureError,
  });

  @override
  Future<BlocxUseCaseResult<BlocxPage<TestItem>>> perform(
    BlocxCursorPaginatedInput input,
  ) async {
    if (shouldFail) {
      throw failureError ?? Exception('Cursor load failed');
    }
    final items = source.getPage(offset: 0, limit: input.limit);
    return successResult(
      items: items.items,
      input: input,
      nextCursor: items.hasNext ? 'next_cursor' : null,
    );
  }
}

void main() {
  group('Inline collection error policy & retry', () {
    late FakePaginatedSource source;
    late FakePaginatedUseCase paginatedUseCase;
    late FakeSearchUseCase searchUseCase;
    late _TestErrorTranslator translator;

    setUp(() {
      source = FakePaginatedSource([
        const TestItem(id: '1', title: 'Alpha'),
        const TestItem(id: '2', title: 'Beta'),
        const TestItem(id: '3', title: 'Gamma'),
      ]);
      paginatedUseCase = FakePaginatedUseCase(source: source);
      searchUseCase = FakeSearchUseCase(source: source);
      translator = _TestErrorTranslator();
    });

    test(
      'useInlineErrorForInitialLoad=true emits inline error state and keeps ScreenManagerCubit silent',
      () async {
        paginatedUseCase.shouldFail = true;
        paginatedUseCase.failureError = Exception('Network down');

        final bloc = _ConfigurableCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
          errorTranslator: translator,
        );

        final screenStates = <ScreenManagerCubitState>[];
        final screenSub = bloc.screenManagerCubit.stream.listen(
          screenStates.add,
        );
        final blocStates = <BlocxCollectionState<TestItem>>[];
        final blocSub = bloc.stream.listen(blocStates.add);

        bloc.add(
          BlocxCollectionEventLoadInitialPage<TestItem, String>(
            payload: 'tenant-1',
          ),
        );
        await pumpEventQueue();

        expect(blocStates.length, equals(2));
        expect(blocStates[0], isA<BlocxCollectionStateLoading<TestItem>>());
        expect(blocStates[0].isInitialLoading, isTrue);
        expect(blocStates[1], isA<BlocxCollectionStateError<TestItem>>());

        final errorState = bloc.state;
        expect(errorState.hasInitialError, isTrue);
        expect(errorState.initialError?.title, equals('Request Failed'));
        expect(errorState.initialError?.message, equals('Network down'));
        expect(errorState.initialLoadError, same(errorState.initialError));
        expect(errorState.isEmptyFilteredResult, isFalse);

        // Error reporting hook STILL runs, while ScreenManagerCubit stays silent.
        expect(bloc.reportedErrors.length, equals(1));
        expect(screenStates, isEmpty);

        await screenSub.cancel();
        await blocSub.cancel();
        await bloc.close();
      },
    );

    test(
      'useInlineErrorForInitialLoad=false routes initial error to ScreenManagerCubit page error',
      () async {
        paginatedUseCase.shouldFail = true;
        paginatedUseCase.failureError = Exception('Critical failure');

        final bloc = _ConfigurableCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
          useInlineError: false,
          errorTranslator: translator,
        );

        final screenStates = <ScreenManagerCubitState>[];
        final screenSub = bloc.screenManagerCubit.stream.listen(
          screenStates.add,
        );

        bloc.add(
          BlocxCollectionEventLoadInitialPage<TestItem, String>(payload: null),
        );
        await pumpEventQueue();

        expect(bloc.state.hasInitialError, isTrue);
        expect(
          screenStates.whereType<ScreenManagerCubitStateDisplayErrorPage>(),
          isNotEmpty,
        );

        await screenSub.cancel();
        await bloc.close();
      },
    );

    test(
      'secondary failures (loadNextPage, non-empty refresh, delete, select) still trigger snackbars',
      () async {
        final multiSource = FakePaginatedSource(
          List.generate(25, (i) => TestItem(id: '$i', title: 'Item $i')),
        );
        final paged = FakePaginatedUseCase(source: multiSource);
        final bloc = _ConfigurableCollectionBloc(
          paginatedUseCase: paged,
          searchUseCase: searchUseCase,
          errorTranslator: translator,
        );

        final screenStates = <ScreenManagerCubitState>[];
        final screenSub = bloc.screenManagerCubit.stream.listen(
          screenStates.add,
        );

        // Initial load succeeds cleanly
        bloc.add(
          BlocxCollectionEventLoadInitialPage<TestItem, String>(payload: null),
        );
        await pumpEventQueue();
        expect(bloc.state.list.length, equals(20));
        expect(screenStates, isEmpty);

        // Next-page failure -> snackbar & keeps loaded items
        paged.shouldFail = true;
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
        await pumpEventQueue();
        expect(
          screenStates
              .whereType<ScreenManagerCubitStateDisplaySnackbar>()
              .length,
          equals(1),
        );
        expect(bloc.state.hasInitialError, isFalse);
        expect(bloc.state.list.length, equals(20));

        // Non-empty refresh failure -> snackbar & keeps loaded items
        bloc.add(BlocxCollectionEventRefreshData<TestItem>());
        await pumpEventQueue();
        expect(
          screenStates
              .whereType<ScreenManagerCubitStateDisplaySnackbar>()
              .length,
          equals(2),
        );
        expect(bloc.state.hasInitialError, isFalse);
        expect(bloc.state.list.length, equals(20));

        // Delete failure -> snackbar
        bloc.failNextDelete = true;
        bloc.add(
          BlocxCollectionEventRemoveItem<TestItem>(item: bloc.state.list[0]),
        );
        await pumpEventQueue();
        expect(
          screenStates
              .whereType<ScreenManagerCubitStateDisplaySnackbar>()
              .length,
          equals(3),
        );

        // Remote selection failure -> snackbar
        bloc.failNextSelect = true;
        bloc.add(
          BlocxCollectionEventSelectItem<TestItem>(item: bloc.state.list[0]),
        );
        await pumpEventQueue();
        expect(
          screenStates
              .whereType<ScreenManagerCubitStateDisplaySnackbar>()
              .length,
          greaterThanOrEqualTo(4),
        );

        await screenSub.cancel();
        await bloc.close();
      },
    );

    test(
      'empty refresh failure sets inline error without triggering ScreenManagerCubit',
      () async {
        paginatedUseCase = FakePaginatedUseCase(
          source: FakePaginatedSource([]),
        );
        final bloc = _ConfigurableCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
          errorTranslator: translator,
        );

        final screenStates = <ScreenManagerCubitState>[];
        final screenSub = bloc.screenManagerCubit.stream.listen(
          screenStates.add,
        );

        bloc.add(
          BlocxCollectionEventLoadInitialPage<TestItem, String>(payload: null),
        );
        await pumpEventQueue();
        expect(bloc.state.isEmpty, isTrue);

        paginatedUseCase.shouldFail = true;
        bloc.add(BlocxCollectionEventRefreshData<TestItem>());
        await pumpEventQueue();

        expect(bloc.isRefreshing, isFalse);
        expect(bloc.state.isRefreshing, isFalse);
        expect(bloc.state.hasInitialError, isTrue);
        expect(screenStates, isEmpty);

        await screenSub.cancel();
        await bloc.close();
      },
    );

    test(
      'search error sets inline error keeping ScreenManagerCubit silent and RetryLastLoad retries search immediately',
      () async {
        final bloc = _ConfigurableCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
          errorTranslator: translator,
        );
        final screenStates = <ScreenManagerCubitState>[];
        final screenSub = bloc.screenManagerCubit.stream.listen(
          screenStates.add,
        );

        searchUseCase.shouldFail = true;
        searchUseCase.failureError = Exception('Search timeout');
        bloc.add(BlocxCollectionEventSearch<TestItem>(searchText: 'Alpha'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<BlocxCollectionStateError<TestItem>>());
        expect(bloc.state.hasInitialError, isTrue);
        expect(bloc.state.initialError?.message, equals('Search timeout'));
        expect(bloc.state.searchQuery, equals('Alpha'));
        expect(bloc.state.hasActiveQueryOrFilters, isTrue);
        expect(bloc.state.isSearching, isFalse);
        expect(bloc.isSearching, isFalse);
        expect(screenStates, isEmpty);

        // RetryLastLoad retries search immediately without debounce and succeeds
        searchUseCase.shouldFail = false;
        bloc.add(const BlocxCollectionEventRetryLastLoad<TestItem>());
        await pumpEventQueue();

        expect(bloc.state, isA<BlocxCollectionStateLoaded<TestItem>>());
        expect(bloc.state.hasInitialError, isFalse);
        expect(bloc.state.initialError, isNull);
        expect(bloc.state.searchQuery, equals('Alpha'));
        expect(bloc.state.list.map((e) => e.id), equals(['1']));

        await screenSub.cancel();
        await bloc.close();
      },
    );

    test(
      'RetryLastLoad preserves payload & active filter and recovers from filtered error',
      () async {
        final bloc = _ConfigurableCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
          errorTranslator: translator,
        );

        // 1. Initial load with payload
        bloc.add(
          BlocxCollectionEventLoadInitialPage<TestItem, String>(
            payload: 'org-42',
          ),
        );
        await pumpEventQueue();
        expect(bloc.state.list.length, equals(3));

        // 2. Apply Map filter while backend fails
        paginatedUseCase.shouldFail = true;
        paginatedUseCase.failureError = Exception('Filter backend error');
        bloc.add(
          BlocxCollectionEventFilter<TestItem, dynamic>(
            filter: {'status': 'archived', 'minAge': 18},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.hasInitialError, isTrue);
        expect(bloc.state.hasActiveQueryOrFilters, isTrue);
        expect(bloc.state.filterValue<String>('status'), equals('archived'));
        expect(bloc.state.filterValue<int>('status'), isNull);
        expect(bloc.state.filterValue<int>('minAge'), equals(18));
        expect(bloc.state.hasFilter('status'), isTrue);
        expect(bloc.state.hasFilter('status', 'archived'), isTrue);
        expect(bloc.state.hasFilter('status', 'open'), isFalse);
        expect(bloc.state.hasFilter('missing'), isFalse);

        // 3. Retry last load -> preserves both payload and active filter
        paginatedUseCase.shouldFail = false;
        bloc.capturedPayloads.clear();
        bloc.capturedFilters.clear();
        bloc.add(const BlocxCollectionEventRetryLastLoad<TestItem>());
        await pumpEventQueue();

        expect(bloc.capturedPayloads, equals(['org-42']));
        expect(
          bloc.capturedFilters.single,
          equals({'status': 'archived', 'minAge': 18}),
        );
        expect(bloc.state, isA<BlocxCollectionStateLoaded<TestItem>>());
        expect(bloc.state.hasInitialError, isFalse);
        expect(bloc.state.filterValue<String>('status'), equals('archived'));
        expect(bloc.state.list.length, equals(3));

        await bloc.close();
      },
    );

    test(
      'isEmptyFilteredResult and custom/empty filter helpers behave accurately',
      () async {
        final emptySource = FakePaginatedSource([]);
        paginatedUseCase = FakePaginatedUseCase(source: emptySource);
        final bloc = _ConfigurableCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
        );

        // Empty unfiltered list
        bloc.add(
          BlocxCollectionEventLoadInitialPage<TestItem, String>(payload: null),
        );
        await pumpEventQueue();
        expect(bloc.state.isEmpty, isTrue);
        expect(bloc.state.hasActiveQueryOrFilters, isFalse);
        expect(bloc.state.isEmptyFilteredResult, isFalse);

        // Filter with null value / empty map does NOT count as active
        bloc.add(
          BlocxCollectionEventFilter<TestItem, dynamic>(
            filter: {'status': null},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(bloc.state.hasFilter('status'), isFalse);
        expect(bloc.state.hasActiveQueryOrFilters, isFalse);
        expect(bloc.state.isEmptyFilteredResult, isFalse);

        // Custom non-Map filter returning empty list -> isEmptyFilteredResult
        bloc.add(
          BlocxCollectionEventFilter<TestItem, dynamic>(
            filter: const _CustomFilter('books'),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(bloc.state.filter, isA<_CustomFilter>());
        expect(bloc.state.activeFilters, isEmpty);
        expect(bloc.state.hasActiveQueryOrFilters, isTrue);
        expect(bloc.state.isEmptyFilteredResult, isTrue);

        await bloc.close();
      },
    );

    test(
      'RetryLastLoad supports cursor-paginated initial load recovery',
      () async {
        final cursorUseCase = FakeCursorPaginatedUseCase(
          source: source,
          shouldFail: true,
        );
        final bloc = _ConfigurableCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
          cursorUseCase: cursorUseCase,
        );

        bloc.add(
          BlocxCollectionEventLoadInitialPage<TestItem, String>(
            payload: 'cur-p',
          ),
        );
        await pumpEventQueue();
        expect(bloc.state.hasInitialError, isTrue);

        cursorUseCase.shouldFail = false;
        bloc.add(const BlocxCollectionEventRetryLastLoad<TestItem>());
        await pumpEventQueue();

        expect(bloc.state.hasInitialError, isFalse);
        expect(bloc.state.list.length, equals(3));
        expect(bloc.payload, equals('cur-p'));

        await bloc.close();
      },
    );
  });
}
