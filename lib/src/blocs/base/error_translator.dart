import 'package:blocx_core/blocx_core.dart' show ReadableError;

BlocxErrorTranslator? get errorTranslator => BlocxErrorTranslator.errorTranslator;

abstract class BlocxErrorTranslator {
  static BlocxErrorTranslator? _instance;
  static BlocxErrorTranslator? get errorTranslator => _instance;
  static void setInstance(BlocxErrorTranslator errorTranslator) {
    _instance = errorTranslator;
  }

  ReadableError makeErrorReadable(Object error, {StackTrace? stackTrace});
}
