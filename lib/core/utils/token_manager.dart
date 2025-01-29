// core/utils/token_manager.dart
import 'package:evup_feb2025_flutter/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final FlutterSecureStorage storage;

  TokenManager({required this.storage}); // Costruttore corretto

  Future<String?> get accessToken => storage.read(key: 'access_token');
  Future<String?> get refreshToken => storage.read(key: 'refresh_token');

  Future<void> saveTokens({String? accessToken, String? refreshToken}) async {
    if (accessToken != null) {
      await storage.write(key: 'access_token', value: accessToken);
    }
    if (refreshToken != null) {
      await storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await storage.write(key: 'access_token', value: userData['accessToken']);
    await storage.write(key: 'refresh_token', value: userData['refreshToken']);
    await storage.write(key: 'user_role', value: userData['role']);
    await storage.write(key: 'user_email', value: userData['email']);
    await storage.write(key: 'profile_picture', value: userData['picture']);
  }

  Future<bool> hasToken() async => await storage.containsKey(key: 'access_token');

  Future<UserRole> getRole() async {
    final role = await storage.read(key: 'user_role');
    return _parseRole(role ?? 'user');
  }

  UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'organizer':
        return UserRole.organizer;
      default:
        return UserRole.user;
    }
  }
}