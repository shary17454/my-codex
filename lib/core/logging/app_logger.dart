import 'package:logger/logger.dart';

class AppLogger {
  AppLogger({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  void debug(String message) => _logger.d(message);

  void info(String message) => _logger.i(message);

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
