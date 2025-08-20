// core/use_cases/base_use_case.dart
import 'package:meta/meta.dart';
import 'package:blocx/src/list/models/use_case_result.dart';

abstract class BaseUseCase<T> {
  @nonVirtual
  Future<UseCaseResult<T>> execute() async {
    try {
      return await perform();
    } on Object catch (e, s) {
      return UseCaseResult.failure(e, stackTrace: s);
    }
  }

  /// Subclasses must implement this. Public so it can be overridden.
  @protected
  Future<UseCaseResult<T>> perform();
}
