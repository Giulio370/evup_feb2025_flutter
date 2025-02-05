// core/api/dio_client.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';
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
  final AuthRepository _authRepository;//aggiunta dopo
// Flag per indicare se il refresh è in corso
  bool _isRefreshing = false;
  // Lista delle richieste in sospeso da ripetere dopo il refresh
  final List<Function(RequestOptions options)> _pendingRequests = [];

  DioClient(FlutterSecureStorage storage)
      : _dio = Dio(BaseOptions(
    baseUrl: Constants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )),
        _tokenManager = TokenManager(storage: storage),
        _authRepository = AuthRepository(
          dio: Dio(BaseOptions(
            baseUrl: Constants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          )),
          storage: storage,
        ) {
    _initInterceptors();
  }

  Dio get dio => _dio;

  void _initInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Recupera il token corrente e aggiungilo all'header Authorization
          final token = await _tokenManager.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioError error, handler) async {
          // Se il server risponde 401, tenta il refresh del token
          if (error.response?.statusCode == 401) {
            RequestOptions options = error.response!.requestOptions;

            // Se non è già in corso un refresh, avvialo
            if (!_isRefreshing) {
              _isRefreshing = true;
              try {
                final newToken = await _authRepository.refreshTokenRequest();
                if (newToken != null) {
                  // Salva il nuovo token (già gestito nel refreshTokenRequest)
                  // Aggiorna l'header della richiesta originale
                  options.headers['Authorization'] = 'Bearer $newToken';

                  // Esegui tutte le richieste in sospeso
                  for (final Function(RequestOptions options) retry in _pendingRequests) {
                    retry(options);
                  }
                  _pendingRequests.clear();

                  // Ripeti la richiesta originale con il nuovo token
                  final response = await _dio.request(
                    options.path,
                    options: Options(
                      method: options.method,
                      headers: options.headers,
                    ),
                    data: options.data,
                    queryParameters: options.queryParameters,
                  );
                  _isRefreshing = false;
                  return handler.resolve(response);
                } else {
                  // Se il refresh fallisce, reindirizza al login o gestisci l'errore
                  _isRefreshing = false;
                  return handler.next(error);
                }
              } catch (e) {
                _isRefreshing = false;
                return handler.next(error);
              }
            } else {
              // Se il refresh è già in corso, accoda la richiesta e attendi
              final completer = Completer<Response>();
              _pendingRequests.add((RequestOptions opts) async {
                opts.headers['Authorization'] = 'Bearer ${await _tokenManager.accessToken}';
                try {
                  final response = await _dio.request(
                    opts.path,
                    options: Options(
                      method: opts.method,
                      headers: opts.headers,
                    ),
                    data: opts.data,
                    queryParameters: opts.queryParameters,
                  );
                  completer.complete(response);
                } catch (e) {
                  completer.completeError(e);
                }
              });
              final response = await completer.future;
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}

  /*DioClient(FlutterSecureStorage storage)
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
}*/