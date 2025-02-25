// core/api/auth_repository.dart
import 'dart:convert';
import 'dart:io';

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

  Future<Map<String, dynamic>> fetchUser() async {
    try {
      final String? accessToken = await authRepository.tokenManager.accessToken;
      final String? refreshToken = await authRepository.tokenManager.refreshToken;

      print('Access Token letto: $accessToken');
      print('Refresh Token letto: $refreshToken');

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili - Effettua il login';
      }

      final String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      final response = await authRepository.dio.get(
        '/auth/fetch/user',
        options: Options(
          headers: {'Cookie': cookieHeader},
        ),
      );

      print('Response ricevuta: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          throw 'Formato risposta non valido';
        }
      }

      throw 'Errore nella richiesta: ${response.statusCode}';
    } on DioException catch (e) {
      throw authRepository._handleError(e);
    }
  }
  Future<bool> uploadEventImage(String eventSlug, File imageFile) async {
    try {
      // Recupera i token dal TokenManager
      String? accessToken = await authRepository.tokenManager.accessToken;
      String? refreshToken = await authRepository.tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili. Effettua nuovamente il login.';
      }

      // Costruisci il cookie header
      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      // Prepara i dati della richiesta
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
      });

      // Effettua la richiesta POST
      final response = await authRepository.dio.post(
        '/events/addImage/${Uri.encodeComponent(eventSlug)}',
        data: formData,
        options: Options(
          headers: {
            'Cookie': cookieHeader, // Invia i token come Cookie
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // Controlla il risultato della richiesta
      if (response.statusCode == 200) {
        return true; // Upload riuscito
      } else {
        throw 'Errore durante l\'upload dell\'immagine: ${response.data}';
      }
    } on DioException catch (e) {
      throw authRepository._handleError(e); // Gestisce gli errori di Dio
    }
  }



  Future<bool> updateEvent({
    required String eventSlug,
    required String title,
    required String address,
    required DateTime timeStart,
    required DateTime timeEnd,
    required String description,
  }) async {
    try {
      String? accessToken = await authRepository.tokenManager.accessToken;
      String? refreshToken = await authRepository.tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili';
      }

      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      final data = {
        "title": title,
        "sbtitle": "Default Subtitle",  // Valore di default
        "address": address,
        "special_guest": {"name": "Nessun ospite"},  // Valore predefinito
        "tags": {"name": "Generale"},  // Valore predefinito
        "time_start": timeStart.toUtc().toIso8601String(),
        "time_end": timeEnd.toUtc().toIso8601String(),
        "description": description,
      };

      final response = await authRepository.dio.put(
        '/events/update/${Uri.encodeComponent(eventSlug)}',
        data: data,
        options: Options(
          headers: {'Cookie': cookieHeader},
          contentType: Headers.jsonContentType,
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      throw authRepository._handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEventBySlug(String eventSlug) async {
    try {
      // Recupera i token dal TokenManager
      String? accessToken = await authRepository.tokenManager.accessToken;
      String? refreshToken = await authRepository.tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili - Effettua il login';
      }

      // Costruisci il cookie header
      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      // Effettua la richiesta con gli headers
      final response = await authRepository.dio.get(
        '/events/getby/slug/${Uri.encodeComponent(eventSlug)}',
        options: Options(
          headers: {'Cookie': cookieHeader},
        ),
      );

      if (response.statusCode == 200) {
        // Estrae i dati dalla risposta e verifica la struttura
        if (response.data is Map<String, dynamic> &&
            response.data['success'] == true &&
            response.data['data'] is Map<String, dynamic>) {
          return response.data['data'] as Map<String, dynamic>;
        }
        throw 'Formato risposta non valido';
      }

      throw 'Errore nella richiesta: ${response.statusCode}';
    } on DioException catch (e) {
      throw authRepository._handleError(e);
    }
  }

  Future<bool> createEvent({
    required String title,
    required String address,
    required DateTime timeStart,
    required DateTime timeEnd,
    required String description,
    String? sbtitle,
    String? specialGuestName,
    String? tagName,
  }) async {
    try {
      String? accessToken = await authRepository.tokenManager.accessToken;
      String? refreshToken = await authRepository.tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili';
      }

      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      final data = {
        "title": title,
        "sbtitle": sbtitle ?? "Default Subtitle", // Usa valore opzionale o default
        "address": address,
        "special_guest": {"name": specialGuestName ?? "Nessun ospite"},
        "tags": {"name": tagName ?? "Generale"},
        "time_start": timeStart.toUtc().toIso8601String(),
        "time_end": timeEnd.toUtc().toIso8601String(),
        "description": description,
      };

      final response = await authRepository.dio.post(
        '/events/create',
        data: data,
        options: Options(
          headers: {'Cookie': cookieHeader},
          contentType: Headers.jsonContentType,
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['error'] ?? 'Errore sconosciuto';
        throw errorMessage;
      }
      throw authRepository._handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getEventsNormalUser() async {
    try {
      // Recupera i token dal TokenManager
      String? accessToken = await authRepository.tokenManager.accessToken;
      String? refreshToken = await authRepository.tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili - Effettua il login';
      }

      // Costruisci il cookie header
      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      // Effettua la richiesta con gli headers
      final response = await authRepository.dio.get(
        '/events/get',
        options: Options(
          headers: {'Cookie': cookieHeader},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> events = response.data;
        return events.cast<Map<String, dynamic>>();
      }

      return [];
    } on DioException catch (e) {
      throw authRepository._handleError(e);
    }
  }


  Future<bool> deleteEvent(String eventSlug) async {
    try {

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

  /// Metodo per il refresh del token.
  Future<bool> refreshTokenRequest() async {
    try {
      final String? currentAccessToken = await tokenManager.accessToken;
      final String? currentRefreshToken = await tokenManager.refreshToken;
      if (currentAccessToken == null || currentRefreshToken == null) {
        throw 'Token non disponibili per il refresh';
      }

      // Costruisci l'header Cookie con i token correnti
      final String cookieHeader =
          'access-token=$currentAccessToken; refresh-token=$currentRefreshToken';

      // Effettua la richiesta POST per il refresh
      final response = await dio.post(
        '/auth/token/refresh',
        options: Options(
          headers: {'Cookie': cookieHeader},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {

        final cookies = response.headers.map['set-cookie'] ?? [];
        String? newAccessToken;
        String? newRefreshToken;

        // Itera tra i cookie per estrarre i token
        for (var cookie in cookies) {
          if (cookie.contains('access-token=')) {
            newAccessToken = _extractCookieValue(cookie, 'access-token');
          } else if (cookie.contains('refresh-token=')) {
            newRefreshToken = _extractCookieValue(cookie, 'refresh-token');
          }
        }

        if (newAccessToken != null && newRefreshToken != null) {
          // Salva i nuovi token
          await tokenManager.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          print('Refresh token riuscito. Nuovi token salvati.');
          return true;
        } else {
          throw 'Nuovi token non disponibili nella risposta';
        }
      }

      throw 'Errore nel refresh: ${response.statusCode}';
    } on DioException catch (e) {
      print('Errore Dio durante il refresh token: ${e.message}');
      return false;
    } catch (e) {
      print('Errore nel refresh token: $e');
      return false;
    }
  }

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

  Future<bool> refreshUser() async {
    try {
      final String? refreshToken = await tokenManager.refreshToken;

      if (refreshToken == null) {
        print('Refresh token non disponibile. Eseguo logout...');
        await logout();
        return false;
      }


      final String cookieHeader = 'refresh-token=$refreshToken';


      final response = await dio.post(
        '/auth/token/refresh',
        options: Options(
          headers: {'Cookie': cookieHeader},
        ),
      );


      if (response.statusCode == 200 && response.data['success'] == true) {

        final cookies = response.headers.map['set-cookie'] ?? [];
        String? newAccessToken;
        String? newRefreshToken;

        for (var cookie in cookies) {
          if (cookie.contains('access-token=')) {
            newAccessToken = _extractCookieValue(cookie, 'access-token');
          }
          if (cookie.contains('refresh-token=')) {
            newRefreshToken = _extractCookieValue(cookie, 'refresh-token');
          }
        }

        print("🔍 Token ricevuti dal server:");
        print(" - Access Token: $newAccessToken");
        print(" - Refresh Token: ${newRefreshToken ?? 'Non inviato'}");


        if (newAccessToken != null) {
          await tokenManager.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken ?? refreshToken, // 🔥 Mantieni il vecchio refresh-token se non arriva
          );

          print(' Token aggiornati con successo.');
          return true;
        } else {
          print('Access token non ricevuto. Il refresh non è riuscito.');
          await logout();
          return false;
        }
      }

      print('Errore nel refresh token. Eseguo logout...');
      await logout();
      return false;
    } on DioException catch (e) {
      print('Errore durante il refresh del token: ${e.response?.data}');
      await logout();
      return false;
    }
  }


  Future<bool> updateUserImage(File imageFile) async {
    try {
      String? accessToken = await tokenManager.accessToken;
      String? refreshToken = await tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili. Effettua nuovamente il login.';
      }

      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: 'profile.jpg'),
      });

      final response = await dio.post(
        '/auth/extra/image',
        data: formData,
        options: Options(
          headers: {
            'Cookie': cookieHeader,
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> updateDescription(String description) async {
    try {
      String? accessToken = await tokenManager.accessToken;
      String? refreshToken = await tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili. Effettua nuovamente il login.';
      }

      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      final response = await dio.post(
        '/auth/extra/description',
        data: {'description': description},
        options: Options(
          headers: {'Cookie': cookieHeader},
          contentType: Headers.jsonContentType,
        ),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }



  Future<bool> changePassword(String newPassword) async {
    try {
      String? accessToken = await tokenManager.accessToken;
      String? refreshToken = await tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibile. Effettua nuovamente il login.';
      }

      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';

      print('🔹 Invio richiesta a /auth/password/change...');
      print('🔹 Header Cookie: $cookieHeader');
      print('🔹 Nuova password: $newPassword');

      final response = await dio.post(
        '/auth/password/change',
        data: {'password': newPassword},
        options: Options(
          headers: {'Cookie': cookieHeader},
          contentType: Headers.jsonContentType,
        ),
      );

      print(' Risposta ricevuta: ${response.statusCode}');
      print(' Body della risposta: ${response.data}');

      if (response.statusCode == 200 && response.data is List) {
        bool success = response.data.contains("SUCCESS");
        print(' Il cambio password è stato confermato: $success');
        return success;
      }

      print('Errore nel cambio password: il server non ha restituito SUCCESS.');
      return false;
    } on DioException catch (e) {
      print(' Errore API cambio password:');
      print(' Codice status: ${e.response?.statusCode}');
      print(' Body della risposta: ${e.response?.data}');
      print(' Messaggio di errore: ${e.message}');

      return false;
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

  Future<List<Map<String, dynamic>>> getPlans() async {
    try {

      String? accessToken = await tokenManager.accessToken;
      String? refreshToken = await tokenManager.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw 'Token non disponibili. Effettua il login.';
      }


      String cookieHeader = 'access-token=$accessToken; refresh-token=$refreshToken';


      final response = await dio.get(
        '/plan/read',
        options: Options(headers: {'Cookie': cookieHeader}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> plans = response.data;
        return plans.cast<Map<String, dynamic>>();
      } else {
        throw 'Errore nella richiesta: ${response.statusCode}';
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
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
      final response = await dio.get('/auth/login/logout');

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('Logout riuscito');

        // Elimina i token memorizzati
        await storage.delete(key: 'access_token');
        await storage.delete(key: 'refresh_token');
        await storage.delete(key: 'user_role');
        await storage.delete(key: 'user_email');
        await storage.delete(key: 'profile_picture');
        await storage.deleteAll();
      } else {
        throw 'Errore durante il logout';
      }
    } on DioException catch (e) {
      print('Errore di logout: ${e.message}');
      throw _handleError(e.response?.data);
    }
  }

}