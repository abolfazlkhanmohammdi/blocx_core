import 'package:blocx_core/src/core/use_cases/blocx_use_case_result.dart';
import 'package:meta/meta.dart';

/// Base abstraction for all use cases.
///
/// A use case represents a single unit of business logic that transforms
/// an [Input] into an [Output].
///
/// This enforces:
/// - explicit dependencies (via input)
/// - predictable execution flow
/// - consistent error handling
abstract class BlocxBaseUseCase<Input, Output> {
  /// Executes the use case with the given [input].
  ///
  /// All exceptions are caught and converted into a failure result.
  @nonVirtual
  Future<BlocxUseCaseResult<Output>> execute(Input input) async {
    try {
      return await perform(input);
    } catch (error, stackTrace) {
      handleError(error, stackTrace);
      return failureResult(error,stackTrace);
    }
  }

  /// Internal implementation of the use case.
  @protected
  Future<BlocxUseCaseResult<Output>> perform(Input input);

  /// Optional hook for logging / analytics / crash reporting.
  ///
  /// Must NOT affect control flow.
  @protected
  void handleError(Object error, StackTrace stackTrace) {}

  Future<BlocxUseCaseResult<Output>> failureResult(Object error, StackTrace stackTrace);
}
