import 'package:bloc_test/bloc_test.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class FailingCollectionBloc extends BlocxCollectionBloc<TestItem, void>
    with
        BlocxCollectionRefreshableMixin<TestItem, void>,
        BlocxCollectionInfiniteMixin<TestItem, void>,
        BlocxCollectionSearchableMixin<TestItem, void> {
  final FakePaginatedUseCase paginatedUseCase;
  final FakeSearchUseCase searchUseCase;

  FailingCollectionBloc({
    required this.paginatedUseCase,
    required this.searchUseCase,
  }) : super();

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>?
  get paginationTask => BlocxPaginatedUseCaseTask(
    useCase: paginatedUseCase,
    inputBuilder: (offset, limit) =>
        BlocxPaginatedInput(offset: offset, limit: limit),
  );

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, TestItem>?
  get searchUseCaseTask => BlocxPaginatedUseCaseTask(
    useCase: searchUseCase,
    inputBuilder: (offset, limit) =>
        BlocxSearchInput(searchText: searchText, offset: offset, limit: limit),
  );
}

void main() {
  group('C1: Collection failure paths', () {
    test('initial-load failure emits [Loading, Error] states', () async {
      final paginatedUseCase = FakePaginatedUseCase(
        shouldFail: true,
        failureError: Exception('Database offline'),
      );
      final searchUseCase = FakeSearchUseCase();
      final bloc = FailingCollectionBloc(
        paginatedUseCase: paginatedUseCase,
        searchUseCase: searchUseCase,
      );

      final states = <BlocxCollectionState<TestItem>>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));

      // Wait for async processing
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.length, equals(2));
      expect(states[0], isA<BlocxCollectionStateLoading<TestItem>>());
      expect(states[1], isA<BlocxCollectionStateError<TestItem>>());
      final errorState = states[1] as BlocxCollectionStateError<TestItem>;
      expect(errorState.message, isNotEmpty);

      await sub.cancel();
      await bloc.close();
    });

    blocTest<FailingCollectionBloc, BlocxCollectionState<TestItem>>(
      'loadNextPage failure resets isLoadingNextPage',
      build: () {
        final paginatedUseCase = FakePaginatedUseCase();
        final searchUseCase = FakeSearchUseCase();
        return FailingCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
        );
      },
      seed: () => BlocxCollectionStateLoaded<TestItem>(
        list: [const TestItem(id: '1', title: 'Item 1')],
        hasReachedEnd: false,
        isLoadingNextPage: false,
        isRefreshing: false,
        isSearching: false,
        selectedItemIds: const {},
        beingSelectedItemIds: const {},
        highlightedItemIds: const {},
        beingRemovedItemIds: const {},
        expandedItemIds: const {},
      ),
      act: (bloc) {
        bloc.paginatedUseCase.shouldFail = true;
        bloc.add(BlocxCollectionEventLoadNextPage<TestItem>());
      },
      verify: (bloc) {
        expect(bloc.isLoadingNextPage, isFalse);
      },
    );

    blocTest<FailingCollectionBloc, BlocxCollectionState<TestItem>>(
      'refresh failure resets isRefreshing',
      build: () {
        final paginatedUseCase = FakePaginatedUseCase();
        final searchUseCase = FakeSearchUseCase();
        return FailingCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
        );
      },
      seed: () => BlocxCollectionStateLoaded<TestItem>(
        list: [const TestItem(id: '1', title: 'Item 1')],
        hasReachedEnd: false,
        isLoadingNextPage: false,
        isRefreshing: false,
        isSearching: false,
        selectedItemIds: const {},
        beingSelectedItemIds: const {},
        highlightedItemIds: const {},
        beingRemovedItemIds: const {},
        expandedItemIds: const {},
      ),
      act: (bloc) {
        bloc.paginatedUseCase.shouldFail = true;
        bloc.add(BlocxCollectionEventRefreshData<TestItem>());
      },
      verify: (bloc) {
        expect(bloc.isRefreshing, isFalse);
      },
    );

    blocTest<FailingCollectionBloc, BlocxCollectionState<TestItem>>(
      'search failure resets isSearching',
      build: () {
        final paginatedUseCase = FakePaginatedUseCase();
        final searchUseCase = FakeSearchUseCase(shouldFail: true);
        return FailingCollectionBloc(
          paginatedUseCase: paginatedUseCase,
          searchUseCase: searchUseCase,
        );
      },
      seed: () => BlocxCollectionStateLoaded<TestItem>(
        list: [const TestItem(id: '1', title: 'Item 1')],
        hasReachedEnd: false,
        isLoadingNextPage: false,
        isRefreshing: false,
        isSearching: false,
        selectedItemIds: const {},
        beingSelectedItemIds: const {},
        highlightedItemIds: const {},
        beingRemovedItemIds: const {},
        expandedItemIds: const {},
      ),
      act: (bloc) {
        bloc.add(BlocxCollectionEventSearch<TestItem>(searchText: 'query'));
      },
      wait: const Duration(milliseconds: 350), // Search debounce
      verify: (bloc) {
        expect(bloc.isSearching, isFalse);
      },
    );
  });
}
