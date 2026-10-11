import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/fake_use_cases.dart';
import '../helpers/test_entity.dart';

class ReportingCollectionBloc extends BlocxCollectionBloc<TestItem, void> {
  final List<Object> reportedErrors = [];
  final List<StackTrace?> reportedStackTraces = [];

  ReportingCollectionBloc({
    required BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>
    paginationTask,
  }) : _paginationTask = paginationTask,
       super();

  final BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>
  _paginationTask;

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TestItem>?
  get paginationTask => _paginationTask;

  @override
  void reportError(Object error, StackTrace? stackTrace) {
    reportedErrors.add(error);
    reportedStackTraces.add(stackTrace);
    super.reportError(error, stackTrace);
  }
}

class _TestEvent extends BlocxBaseEvent {}

class _TestState extends BlocxBaseState {
  const _TestState() : super(shouldRebuild: true, shouldListen: false);
}

class TestBaseBloc extends BlocxBaseBloc<_TestEvent, _TestState> {
  final List<Object> reportedErrors = [];
  final List<StackTrace?> reportedStackTraces = [];

  TestBaseBloc() : super(const _TestState()) {
    on<_TestEvent>((event, emit) {
      try {
        throw StateError('BaseBloc failed');
      } catch (e, st) {
        handleError(e, emit, stacktrace: st);
      }
    });
  }

  @override
  void reportError(Object error, StackTrace? stackTrace) {
    reportedErrors.add(error);
    reportedStackTraces.add(stackTrace);
    super.reportError(error, stackTrace);
  }
}

void main() {
  group('BlocxBaseBloc.reportError', () {
    test(
      'handleError calls reportError with error and stackTrace in BlocxBaseBloc',
      () async {
        final bloc = TestBaseBloc();
        bloc.add(_TestEvent());

        await pumpEventQueue();

        expect(bloc.reportedErrors.length, equals(1));
        expect(bloc.reportedErrors.first, isA<StateError>());
        expect(
          (bloc.reportedErrors.first as StateError).message,
          equals('BaseBloc failed'),
        );
        expect(bloc.reportedStackTraces.length, equals(1));
        expect(bloc.reportedStackTraces.first, isNotNull);

        await bloc.close();
      },
    );

    test(
      'CollectionBloc failure routes error and stackTrace through reportError hook',
      () async {
        final expectedError = Exception('Paginated task failed');
        final paginatedUseCase = FakePaginatedUseCase(
          shouldFail: true,
          failureError: expectedError,
        );

        final bloc = ReportingCollectionBloc(
          paginationTask: BlocxPaginatedUseCaseTask(
            useCase: paginatedUseCase,
            inputBuilder: (offset, limit) =>
                BlocxPaginatedInput(offset: offset, limit: limit),
          ),
        );

        bloc.add(BlocxCollectionEventLoadInitialPage(payload: null));

        await pumpEventQueue();

        expect(bloc.reportedErrors.length, equals(1));
        expect(bloc.reportedErrors.first, equals(expectedError));
        expect(bloc.reportedStackTraces.length, equals(1));

        await bloc.close();
      },
    );
  });
}
