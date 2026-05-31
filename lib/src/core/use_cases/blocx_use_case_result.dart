/// Represents the outcome of a [BlocxBaseUseCase] execution.
///
/// The two concrete subtypes cover every case:
/// - [BlocxUseCaseSuccess] — operation completed; [data] is guaranteed non-null.
/// - [BlocxUseCaseFailure] — operation failed; [error] and [stackTrace] are set.
///
/// ## Usage
/// Prefer [when] for exhaustive handling:
/// ```dart
/// result.when(
///   onSuccess: (data) => print(data),
///   onFailure: (error, st) => log(error),
/// );
/// ```
///
/// Use [isSuccess] / [isFailure] for simple guards:
/// ```dart
/// if (result.isFailure) {
///   handleError(result.error!);
///   return;
/// }
/// doSomethingWith(result.data!);
/// ```
///
/// Use [dataOrThrow] when you are certain the result succeeded and want
/// to propagate exceptions rather than handle them inline.
///
/// ## Note on sealing
/// These subtypes are not yet Dart-sealed. Exhaustive pattern-matching
/// via [when] is provided as an equivalent until sealed classes are adopted.
abstract class BlocxUseCaseResult<T> {
  const BlocxUseCaseResult();

  /// The output value, or `null` if this is a [BlocxUseCaseFailure].
  T? get data;

  /// The thrown object, or `null` if this is a [BlocxUseCaseSuccess].
  dynamic get error;

  /// The stack trace captured at the failure site, or `null` on success.
  StackTrace? get stackTrace;

  /// Whether this result represents a successful execution.
  bool get isSuccess => error == null;

  /// Whether this result represents a failed execution.
  bool get isFailure => error != null;

  /// Unwraps [data], throwing [error] if this is a failure.
  ///
  /// Only use this when you are certain the use case succeeded, or when
  /// you intentionally want to propagate the error as an exception.
  T get dataOrThrow {
    if (isFailure) throw error!;
    return data as T;
  }

  /// Handles both outcomes without null-guarding [data] or [error] manually.
  ///
  /// ```dart
  /// final greeting = result.when(
  ///   onSuccess: (user) => 'Hello, ${user.name}',
  ///   onFailure: (error, _) => 'Failed: $error',
  /// );
  /// ```
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(dynamic error, StackTrace? stackTrace) onFailure,
  }) {
    if (isSuccess) return onSuccess(data as T);
    return onFailure(error, stackTrace);
  }
}

/// A successful [BlocxUseCaseResult] carrying the output [data].
///
/// Constructed by [BlocxBaseUseCase.success] — prefer that helper over
/// instantiating this class directly.
class BlocxUseCaseSuccess<T> extends BlocxUseCaseResult<T> {
  /// The output produced by the use case.
  @override
  final T data;

  @override
  dynamic get error => null;

  @override
  StackTrace? get stackTrace => null;

  /// Creates a successful result wrapping [data].
  const BlocxUseCaseSuccess(this.data);
}

/// A failed [BlocxUseCaseResult] carrying the [error] and optional [stackTrace].
///
/// Constructed automatically by [BlocxBaseUseCase.failureResult] when an
/// unhandled exception escapes [BlocxBaseUseCase.perform]. Override
/// [BlocxBaseUseCase.failureResult] to wrap [error] in a domain-specific type
/// before it reaches the bloc.
class BlocxUseCaseFailure<T> extends BlocxUseCaseResult<T> {
  @override
  Null get data => null;

  /// The error object that caused the failure.
  @override
  final dynamic error;

  /// The stack trace captured at the failure site.
  @override
  final StackTrace? stackTrace;

  /// Creates a failure result.
  ///
  /// [stackTrace] is optional but strongly recommended — it is forwarded to
  /// [BaseBloc.handleError] for logging and crash reporting.
  const BlocxUseCaseFailure(this.error, [this.stackTrace]);
}
