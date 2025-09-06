import 'package:logger/logger.dart';

Logger? _logger;
Logger get logger => _logger ??= Logger();
