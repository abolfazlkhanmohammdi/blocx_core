import 'dart:async';

import 'package:blocx_core/src/core/use_cases/blocx_use_case_result.dart';
import 'package:meta/meta.dart';

/// Base abstraction for all use cases.
///
/// A use case encapsulates a single unit of business logic that transforms
/// an [Input] into an [Output]. All execution goes through [execute], which
/// catches exceptions and converts them into [BlocxUseCaseFailure] automatically.
///
/// ## Implementing a use case
///
/// Only [perform] is required. Use the [success] helper to wrap your output:
///
/// ```dart
/// class GetUserUseCase extends BlocxBaseUseCase<String, User> {
///   final UserRepository _repo;
///   GetUserUseCase(this._repo);
///
///   @override
///   Future<BlocxUseCaseResult<User>> perform(String userId) async {
///     final user = await _repo.getUser(userId);
///     return success(user);
///   }
/// }
/// ```
///
/// ## Custom failure mapping
///
/// Override [failureResult] to map low-level errors to domain types before
/// they reach the bloc:
///
/// ```dart
/// @override
/// BlocxUseCaseResult<User> failureResult(Object error, StackTrace st) {
///   if (error is NetworkException) return BlocxUseCaseFailure(AppError.network, st);
///   return BlocxUseCaseFailure(AppError.unknown, st);
/// }
/// ```
///
/// ## Logging / analytics
///
/// Override [handleError] for side-effects (crash reporting, analytics).
/// It must not affect control flow — [failureResult] is still called after it.
abstract class BlocxBaseUseCase<Input, Output> {
  /// Entry point for callers. Do not override.
  ///
  /// Calls [perform] inside a try/catch. On exception:
  /// 1. [handleError] is called for logging side-effects.
  /// 2. [failureResult] wraps the error and is returned.
  @nonVirtual
  Future<BlocxUseCaseResult<Output>> execute(Input input) async {
    try {
      return await perform(input);
    } catch (error, stackTrace) {
      handleError(error, stackTrace);
      return failureResult(error, stackTrace);
    }
  }

  /// The business logic implementation.
  ///
  /// Called by [execute]. Throw freely — exceptions are caught and
  /// converted to [BlocxUseCaseFailure] automatically.
  ///
  /// Return values via [success]:
  /// ```dart
  /// return success(myOutput);
  /// ```
  @protected
  Future<BlocxUseCaseResult<Output>> perform(Input input);

  /// Optional side-effect hook for logging, analytics, or crash reporting.
  ///
  /// Called before [failureResult] on every unhandled exception.
  /// Must not throw or affect control flow.
  void handleError(Object error, StackTrace stackTrace) {}

  /// Shorthand for `BlocxUseCaseSuccess(data)`.
  ///
  /// Use inside [perform] to keep return statements readable:
  /// ```dart
  /// return success(user);
  /// ```
  @protected
  BlocxUseCaseResult<Output> success(Output data) => BlocxUseCaseSuccess(data);

  /// Wraps an unhandled exception into a [BlocxUseCaseResult].
  ///
  /// The default returns `BlocxUseCaseFailure(error, stackTrace)`.
  /// Override to map exceptions to domain-specific error types before the
  /// result reaches the bloc layer.
  @protected
  FutureOr<BlocxUseCaseResult<Output>> failureResult(
    Object error,
    StackTrace stackTrace,
  ) =>
      BlocxUseCaseFailure<Output>(error, stackTrace);
}
