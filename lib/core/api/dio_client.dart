// File: lib/core/api/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

const String _baseUrl = 'https://api.ruralhealth.bd/v1';
const String _authTokenKey = 'auth_token';

@lazySingleton
class DioClient {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage;

  Dio get dio => _dio;

  DioClient(this._secureStorage) {
    final options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10), // 10 seconds
      receiveTimeout: const Duration(seconds: 10), // 10 seconds
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    _dio = Dio(options);
    _dio.interceptors.add(AuthInterceptor(_secureStorage, _dio));
    _dio.interceptors.add(LoggingInterceptor()); // Optional: for logging
  }

  Future<void> setAuthToken(String token) async {
    await _secureStorage.write(key: _authTokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _authTokenKey);
  }

  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: _authTokenKey);
    // Also remove from Dio instance if it was set directly in headers for some reason
    _dio.options.headers.remove('Authorization');
  }
}

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Dio _dio; // Dio instance to retry requests

  AuthInterceptor(this._secureStorage, this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Routes that don't require authentication
    const noAuthRoutes = ['/auth/login', '/auth/refresh-token']; // Add other public routes

    if (noAuthRoutes.any((route) => options.path.contains(route))) {
      return handler.next(options);
    }

    final token = await _secureStorage.read(key: _authTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // If a 401 response is received, try to refresh the token
      // This is a simplified example. In a real app, you'd have a refresh token mechanism.
      // For now, we'll just clear the token and propagate the error.
      // In a full implementation, you might try to refresh the token and retry the original request.
      try {
        // Example: String? newToken = await refreshToken();
        // if (newToken != null) {
        //   await _secureStorage.write(key: _authTokenKey, value: newToken);
        //   // Update the original request's header with the new token
        //   err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        //   // Retry the request
        //   final response = await _dio.fetch(err.requestOptions);
        //   return handler.resolve(response);
        // }
        await _secureStorage.delete(key: _authTokenKey);
        // Potentially navigate to login screen or notify AuthBloc
      } catch (e) {
        // If refresh fails, propagate the error
        return handler.next(err);
      }
    }
    return handler.next(err);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print(
        'REQUEST[${options.method}] => PATH: ${options.baseUrl}${options.path} => DATA: ${options.data}');
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path} => DATA: ${response.data}');
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print(
        'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path} => MESSAGE: ${err.message}');
    return super.onError(err, handler);
  }
}

// To be injected by GetIt
@module
abstract class RegisterCoreModule {
  @lazySingleton
  FlutterSecureStorage get flutterSecureStorage => const FlutterSecureStorage();
}
