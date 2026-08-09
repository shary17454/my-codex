import 'package:dio/dio.dart';

class ApiClient {
  ApiClient([String? base])
      : dio = Dio(
          BaseOptions(
            baseUrl: base ?? const String.fromEnvironment('RAWAYA_API_BASE', defaultValue: 'http://10.0.2.2:4000/api'),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 12),
            headers: const {'Content-Type': 'application/json'},
          ),
        );

  final Dio dio;

  Options _options({String? accessToken}) {
    if (accessToken == null || accessToken.isEmpty) return Options();
    return Options(headers: {'Authorization': 'Bearer $accessToken'});
  }

  Future<Response<T>> get<T>(String path, {String? accessToken}) {
    return dio.get<T>(path, options: _options(accessToken: accessToken));
  }

  Future<Response<T>> post<T>(String path, {Object? data, String? accessToken}) {
    return dio.post<T>(path, data: data, options: _options(accessToken: accessToken));
  }
}
