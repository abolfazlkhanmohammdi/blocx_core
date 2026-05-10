abstract class BlocxUseCaseResult<T> {
  T? get data;
  dynamic get error;
  StackTrace? get stackTrace;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}
