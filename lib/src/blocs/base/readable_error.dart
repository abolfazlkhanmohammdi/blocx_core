class ReadableError {
  final String message;
  final String? title;
  final dynamic error;
  final StackTrace? stackTrace;
  ReadableError({required this.message, this.title, this.error, this.stackTrace});

  ReadableError copyWith({String? message, String? title, dynamic error, StackTrace? stackTrace}) {
    return ReadableError(
      message: message ?? this.message,
      title: title ?? this.title,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}
