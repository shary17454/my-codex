import 'package:logger/logger.dart';

class AppLogger {
  AppLogger() : _logger = Logger();

  final Logger _logger;

  void info(String message) => _logger.i(message);

  void warning(String message, [Object? error]) => _logger.w(message, error: error);

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
