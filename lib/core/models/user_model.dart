// core/models/user_model.dart
import 'package:evup_feb2025_flutter/main.dart';

class User {
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? profilePicture;
  final DateTime lastLogin;
  final String plan;

  User({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profilePicture,
    required this.lastLogin,
    required this.plan,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: _parseRole(json['role']),
      profilePicture: json['picture'],
      lastLogin: DateTime.parse(json['lastLogin']),
      plan: json['plan'],
    );
  }

  static UserRole _parseRole(String role) {
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