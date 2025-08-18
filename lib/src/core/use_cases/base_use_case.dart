// core/use_cases/base_use_case.dart
import 'package:meta/meta.dart';
import 'package:blocx/src/core/models/use_case_result.dart';

abstract class BaseUseCase<T, S> {
  @nonVirtual
  Future<UseCaseResult<T>> execute({S? query}) async {
    try {
      return await perform(payload: query);
    } on Object catch (e, s) {
      return UseCaseResult.failure(e, stackTrace: s);
    }
  }

  /// Subclasses must implement this. Public so it can be overridden.
  @protected
  Future<UseCaseResult<T>> perform({S? payload});
}
