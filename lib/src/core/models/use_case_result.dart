class UseCaseResult<T> {
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  const UseCaseResult._({this.data, this.error, this.stackTrace});
  factory UseCaseResult.success(T data) {
    return UseCaseResult._(data: data);
  }

  factory UseCaseResult.failure(Object error, {StackTrace? stackTrace}) {
    return UseCaseResult._(error: error, stackTrace: stackTrace);
  }
  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  @override
  String toString() => isSuccess ? 'Success($data)' : 'Failure($error, $stackTrace)';
}
