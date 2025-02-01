// core/api/auth_repository.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:evup_feb2025_flutter/core/utils/token_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';
import '../../main.dart';
import 'dio_client.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  return EventRepository(authRepo);
});

class EventRepository {
  final AuthRepository authRepository;

  EventRepository(this.authRepository);

  Future<List<Map<String, dynamic>>> getEventsForUser() async {
    return await authRepository.getEvents();
  }


  Future<bool> deleteEvent(String eventSlug) async {
    try {
      // Recupera i token (ad esempio, dal TokenManager o dal local storage)
      String? accessToken = await authRepository.tokenManager.accessToken;
      String? refreshToken = await authRepository.tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili';
      }

      // Crea la stringa dei cookie
      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      // Esegui la richiesta DELETE con il cookie nell'header
      final response = await authRepository.dio.delete(
        '/events/remove/${Uri.encodeComponent(eventSlug)}',
        options: Options(
          headers: {
            'Cookie': cookieHeader, // Aggiungi i cookie nell'header
          },
        ),
      );

      if (response.statusCode == 200) {
        return true; // Evento eliminato correttamente
      } else {
        throw 'Errore nella cancellazione dell\'evento';
      }
    } on DioException catch (e) {
      throw authRepository._handleError(e); // Gestisci l'errore come nelle altre funzioni
    }
  }

}


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

  Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final response = await dio.get('/events/get');


      if (response.statusCode == 200) {
        final List<dynamic> events = response.data;
        return events.cast<Map<String, dynamic>>();
      }

      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }



  Future<bool> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login/email',
        data: {'email': email, 'password': password},
      );

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

      print('Access Token Estratto: $accessToken');
      print('Refresh Token Estratto: $refreshToken');

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
      final errorData = e.response?.data;

      // Gestione specifica dell'errore EMAIL_NOT_VERIFIED
      if (e.response?.statusCode == 400 && errorData is List) {
        if (errorData.contains("EMAIL_NOT_VERIFIED")) {
          throw "EMAIL_NOT_VERIFIED";
        }
      }

      // Se non è un errore gestito, lo passiamo all'handler generale
      throw _handleError(e);
    }
  }


  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message']; // Messaggio dal server
      }

      // Gestione degli errori in base allo status code
      switch (e.response!.statusCode) {
        case 400:
          return 'Richiesta non valida. Controlla i dati inseriti.';
        case 401:
          return 'Non autorizzato. Controlla le credenziali.';
        case 403:
          return 'Accesso negato.';
        case 404:
          return 'Risorsa non trovata.';
        case 500:
          return 'Errore del server. Riprova più tardi.';
        default:
          return 'Errore sconosciuto: ${e.response!.statusCode}';
      }
    } else {
      // Errore di connessione (es. timeout, server non raggiungibile)
      return 'Errore di connessione: verifica la tua rete.';
    }
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
    required BuildContext context,
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
          'role': 'user',
        },
      );
    } on DioException catch (e) {
      final errorMessage = _handleError(e);

      // Se la risposta contiene "USER_ALREADY_EXISTS"
      if (e.response?.statusCode == 400 && e.response?.data is List) {
        final errors = e.response!.data as List;
        if (errors.contains("USER_ALREADY_EXISTS")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email già registrata. Reindirizzamento al login..."),
              duration: Duration(seconds: 2),
            ),
          );

          // Attendi 2 secondi per far vedere il messaggio, poi vai al login
          await Future.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            context.push('/login', extra: UserRole.user);
          }
          return;
        }
      }

      // Se è un altro errore, mostra il messaggio standard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
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