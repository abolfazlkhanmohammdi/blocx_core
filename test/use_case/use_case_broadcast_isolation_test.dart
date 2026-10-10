import 'package:blocx_core/blocx_core.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class ThrowingBroadcastUseCase extends BlocxBaseUseCase<String, TestItem> {
  Object? capturedBroadcastError;
  StackTrace? capturedBroadcastStackTrace;

  ThrowingBroadcastUseCase({super.eventHub})
    : super(commandType: BlocxCommandType.create);

  @override
  Future<BlocxUseCaseResult<TestItem>> perform(String input) async {
    return success(TestItem(id: input, title: 'Item $input'));
  }

  @override
  List<BlocxBaseEntity> resolveCommandEntities(String input, TestItem output) {
    throw StateError(
      'Simulated broadcast resolution failure after successful write',
    );
  }

  @override
  void handleBroadcastError(Object error, StackTrace stackTrace) {
    capturedBroadcastError = error;
    capturedBroadcastStackTrace = stackTrace;
    super.handleBroadcastError(error, stackTrace);
  }
}

void main() {
  group('C6: Isolate broadcast in UseCase execute', () {
    test(
      'successful perform returns success even if resolveCommandEntities throws',
      () async {
        final eventHub = BlocxSimpleEventHub();
        final useCase = ThrowingBroadcastUseCase(eventHub: eventHub);

        final result = await useCase.execute('item_1');

        // CRITICAL ASSERTION: The use case must be considered a SUCCESS because perform succeeded
        expect(
          result.isSuccess,
          isTrue,
          reason:
              'A throwing resolveCommandEntities caused a successful perform to fail',
        );
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('item_1'));
        expect(result.data!.title, equals('Item item_1'));

        // The broadcast error must be caught and routed to handleBroadcastError
        expect(useCase.capturedBroadcastError, isA<StateError>());

        eventHub.dispose();
      },
    );
  });
}
