import 'package:dio/dio.dart';

class DioClient {
  DioClient._();

  static Dio create() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 40),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'KnowBeforeYouBuy/1.0 (contact@example.com)',
        },
      ),
    );
  }
}
