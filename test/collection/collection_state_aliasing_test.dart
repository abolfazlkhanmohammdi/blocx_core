import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class AliasingCollectionBloc extends BlocxCollectionBloc<TestItem, void>
    with BlocxCollectionSelectableMixin<TestItem, void> {
  final FakePaginatedUseCase paginatedUseCase;

  AliasingCollectionBloc({required this.paginatedUseCase}) : super();

  @override
  int get limit => 5;

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>?
  get paginationTask => BlocxPaginatedUseCaseTask(
    useCase: paginatedUseCase,
    inputBuilder: (offset, limit) =>
        BlocxPaginatedInput(offset: offset, limit: limit),
  );
}

void main() {
  group('C2: State immutability and aliasing', () {
    test(
      'emitted state list is an immutable snapshot and does not mutate retroactively',
      () async {
        final source = FakePaginatedSource(
          List.generate(10, (i) => TestItem(id: '$i', title: 'Item $i')),
        );
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = AliasingCollectionBloc(paginatedUseCase: useCase);

        final states = <BlocxCollectionState<TestItem>>[];
        final sub = bloc.stream.listen(states.add);

        final loadedFuture = bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await loadedFuture;

        final stateA = bloc.state as BlocxCollectionStateLoaded<TestItem>;
        expect(stateA.list.length, equals(5));
        expect(
          stateA.list.map((e) => e.id).toList(),
          equals(['0', '1', '2', '3', '4']),
        );

        // Add a new item to the collection
        const newItem = TestItem(id: '99', title: 'New Item');
        final addFuture = bloc.stream.firstWhere(
          (s) => s.list.any((e) => e.id == '99'),
        );
        bloc.add(BlocxCollectionEventAddItem(item: newItem, index: 0));
        await addFuture;

        final stateB = bloc.state as BlocxCollectionStateLoaded<TestItem>;
        expect(stateB.list.length, equals(6));

        // CRITICAL ASSERTION: stateA.list must NOT have changed retroactively!
        expect(
          stateA.list.length,
          equals(5),
          reason:
              'State A list was aliased to live mutable list and changed retroactively',
        );
        expect(
          stateA.list.map((e) => e.id).toList(),
          equals(['0', '1', '2', '3', '4']),
        );

        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'emitted state selectedItemIds is an immutable snapshot and does not mutate retroactively',
      () async {
        final source = FakePaginatedSource(
          List.generate(10, (i) => TestItem(id: '$i', title: 'Item $i')),
        );
        final useCase = FakePaginatedUseCase(source: source);
        final bloc = AliasingCollectionBloc(paginatedUseCase: useCase);

        final loadedFuture = bloc.stream.firstWhere((s) => s.list.isNotEmpty);
        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
        await loadedFuture;

        // Select item '0'
        final select0Future = bloc.stream.firstWhere(
          (s) => s.selectedItemIds.contains('0'),
        );
        bloc.add(BlocxCollectionEventSelectItem(item: bloc.list.first));
        await select0Future;

        final stateAfterFirstSelect = bloc.state;
        expect(stateAfterFirstSelect.selectedItemIds, equals({'0'}));

        // Select item '1'
        final select1Future = bloc.stream.firstWhere(
          (s) => s.selectedItemIds.contains('1'),
        );
        bloc.add(BlocxCollectionEventSelectItem(item: bloc.list[1]));
        await select1Future;

        final stateAfterSecondSelect = bloc.state;
        expect(stateAfterSecondSelect.selectedItemIds, equals({'1'}));

        // CRITICAL ASSERTION: stateAfterFirstSelect.selectedItemIds must still be {'0'}, not mutated to {'1'}
        expect(
          stateAfterFirstSelect.selectedItemIds,
          equals({'0'}),
          reason:
              'State selectedItemIds was aliased to live mutable Set and changed retroactively',
        );

        await bloc.close();
      },
    );
  });
}
