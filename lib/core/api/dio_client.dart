// core/api/dio_client.dart
import 'package:dio/dio.dart';
import 'package:evup_feb2025_flutter/core/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';
import '../utils/token_manager.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(secureStorageProvider));
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class DioClient {
  final Dio _dio;
  final TokenManager _tokenManager;

  DioClient(FlutterSecureStorage storage)
      : _dio = Dio(BaseOptions(
    baseUrl: Constants.apiBaseUrl, // Usa l'API base URL
    connectTimeout: const Duration(seconds: 10), // Timeout di connessione
    receiveTimeout: const Duration(seconds: 10), // Timeout di risposta
  )),
        _tokenManager = TokenManager(storage: storage) {
    _initInterceptors();
  }

  Dio get dio => _dio;

  void _initInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenManager.accessToken;
          print('TOKEN RECUPERATO: $token'); // 🔍 Debug
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          print('ERRORE DIO: ${error.response?.statusCode} - ${error.message}'); // 🔍 Debug
          if (error.response?.statusCode == 401) {
            final newToken = await _tokenManager.refreshToken;
            print('NUOVO TOKEN: $newToken'); // 🔍 Debug
          }
          return handler.next(error);
        },
      ),
    );
  }
}