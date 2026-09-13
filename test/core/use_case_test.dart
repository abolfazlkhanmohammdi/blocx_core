import 'package:blocx_core/blocx_core.dart';
import 'package:test/test.dart';

class TestSuccessUseCase extends BlocxBaseUseCase<String, int> {
  @override
  Future<BlocxUseCaseResult<int>> perform(String input) async {
    return success(input.length);
  }
}

class TestFailureUseCase extends BlocxBaseUseCase<String, int> {
  @override
  Future<BlocxUseCaseResult<int>> perform(String input) async {
    throw Exception('Something went wrong');
  }
}

void main() {
  group('BlocxBaseUseCase & BlocxUseCaseResult', () {
    test('successful execution returns BlocxUseCaseSuccess', () async {
      final useCase = TestSuccessUseCase();
      final result = await useCase.execute('hello');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, equals(5));
      expect(result.dataOrThrow, equals(5));

      final output = result.when(
        onSuccess: (data) => 'Length is $data',
        onFailure: (err, st) => 'Failed',
      );
      expect(output, equals('Length is 5'));
    });

    test('failed execution catches exception and returns BlocxUseCaseFailure', () async {
      final useCase = TestFailureUseCase();
      final result = await useCase.execute('hello');

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.data, isNull);
      expect(result.error, isA<Exception>());
      expect(() => result.dataOrThrow, throwsA(isA<Exception>()));

      final output = result.when(
        onSuccess: (data) => 'Success',
        onFailure: (err, st) => 'Handled error: $err',
      );
      expect(output, contains('Something went wrong'));
    });
  });
}
