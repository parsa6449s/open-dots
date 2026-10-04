import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// HTTP client for the Open Dots FastAPI backend.
///
/// The mobile app authenticates with the single-user app token via the
/// `Authorization: Bearer <APP_AUTH_TOKEN>` header (no cookie login needed).
class ApiClient {
  ApiClient._(this._dio);

  final Dio _dio;

  static ApiClient? _instance;

  static ApiClient get instance {
    assert(_instance != null, 'Call ApiClient.configure() first.');
    return _instance!;
  }

  /// Rebuilds the client from the persisted config (base URL + token).
  static Future<void> configure() async {
    final config = await AppConfig.load();
    final dio = Dio(
      BaseOptions(
        baseUrl: '${config.baseUrl}/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = config.authToken;
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    _instance = ApiClient._(dio);
  }

  Dio get dio => _dio;
}
