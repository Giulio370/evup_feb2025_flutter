// core/api/auth_repository.dart
import 'package:dio/dio.dart';
import 'package:evup_feb2025_flutter/core/utils/token_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';
import '../../main.dart';
import 'dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.read(dioClientProvider).dio,
    storage: const FlutterSecureStorage(),
  );
});

class AuthRepository {
  final Dio dio;
  final FlutterSecureStorage storage;
  final TokenManager tokenManager;


  AuthRepository({
    required this.dio,
    required this.storage,
  }) : tokenManager = TokenManager(storage: storage);


  String? _extractCookieValue(String cookie, String key) {
    final startIndex = cookie.indexOf('$key=');
    if (startIndex == -1) return null;

    final endIndex = cookie.indexOf(';', startIndex);
    return (endIndex == -1)
        ? cookie.substring(startIndex + key.length + 1)
        : cookie.substring(startIndex + key.length + 1, endIndex);
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login/email',
        data: {'email': email, 'password': password},
      );

      // 🔍 Debug: Stampiamo i cookie ricevuti
      print('Cookies ricevuti: ${response.headers.map['set-cookie']}');

      // Estrarre token dai cookie
      final cookies = response.headers.map['set-cookie'] ?? [];
      String? accessToken;
      String? refreshToken;

      for (var cookie in cookies) {
        if (cookie.contains('access-token=')) {
          accessToken = _extractCookieValue(cookie, 'access-token');
        } else if (cookie.contains('refresh-token=')) {
          refreshToken = _extractCookieValue(cookie, 'refresh-token');
        }
      }

      print('Access Token Estratto: $accessToken'); // 🔍 Debug
      print('Refresh Token Estratto: $refreshToken'); // 🔍 Debug

      if (accessToken != null && refreshToken != null) {
        await tokenManager.saveUserData({
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'role': response.data['role'],
          'email': response.data['email'],
          'picture': response.data['picture']
        });
        return true;
      }

      return false;
    } on DioException catch (e) {
      throw _handleError(e.response?.data);
    }
  }

  String _handleError(dynamic errorData) {
    if (errorData is Map<String, dynamic>) {
      return errorData['message'] ?? 'Errore sconosciuto';
    }
    return 'Errore di connessione';
  }

  Future<void> _saveTokens(Response response) async {
    final accessToken = response.headers['set-cookie']?[0].split(';')[0].split('=')[1];
    final refreshToken = response.headers['set-cookie']?[1].split(';')[0].split('=')[1];

    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      await dio.post(
        '/auth/signup/email',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phone.replaceAll('+', ''),
          'phonePrefix': '+39',
          'conditionAccepted': 'true',
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      final response = await dio.get('/auth/login/logout'); // Usa GET se il backend lo richiede

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('Logout riuscito');

        // Elimina i token memorizzati
        await storage.delete(key: 'access_token');
        await storage.delete(key: 'refresh_token');
        await storage.delete(key: 'user_role');
        await storage.delete(key: 'user_email');
        await storage.delete(key: 'profile_picture');
      } else {
        throw 'Errore durante il logout';
      }
    } on DioException catch (e) {
      print('Errore di logout: ${e.message}');
      throw _handleError(e.response?.data);
    }
  }

  /*dynamic _handleError(DioException e) {
    final response = e.response;
    if (response?.data is Map && response?.data['message'] != null) {
      return response?.data['message'];
    }
    return e.message ?? 'Errore sconosciuto';
  }*/
}