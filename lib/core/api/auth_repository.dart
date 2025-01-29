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

  Future<bool> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login/email',
        data: {'email': email, 'password': password},
      );
      //Debug: Stampiamo i cookie ricevuti
      print('Cookies ricevuti: ${response.headers.map['set-cookie']}');

      if (response.data['success'] == true) {
        await tokenManager.saveUserData({
          'accessToken': response.headers['set-cookie']?[0].split(';')[0].split('=')[1],
          'refreshToken': response.headers['set-cookie']?[1].split(';')[0].split('=')[1],
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

  /*dynamic _handleError(DioException e) {
    final response = e.response;
    if (response?.data is Map && response?.data['message'] != null) {
      return response?.data['message'];
    }
    return e.message ?? 'Errore sconosciuto';
  }*/
}