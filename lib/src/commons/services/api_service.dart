import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  
  // Base URL - Ajout du slash final pour une résolution correcte
  static const String baseUrl = 'https://siade.ci/api/';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    
    // Intercepteur pour ajouter le token de sécurité + Logging pour le débug
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('--- API REQUEST ---');
        print('Method: ${options.method}');
        print('Full URL: ${options.uri}'); // Affiche l'URL résolue complète
        print('Data: ${options.data}');
        
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('--- API RESPONSE ---');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('--- API ERROR ---');
        print('Type: ${e.type}');
        print('Message: ${e.message}');
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        
        if (e.response?.statusCode == 401) {
          // Logique de logout ici
        }
        return handler.next(e);
      },
    ));
  }

  // --- Authentification ---
  Future<Response> login(String email, String password) async {
    return await _dio.post('login/', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> signup(Map<String, dynamic> userData) async {
    return await _dio.post('users/', data: userData);
  }

  Future<Response> getUserProfile(String slug) async {
    return await _dio.get('user/$slug/');
  }

  // --- Contenu Événement ---
  Future<Response> getSpeakers() async {
    return await _dio.get('sponsors/', queryParameters: {'is_speaker': 'true'});
  }

  Future<Response> getExponents() async {
    return await _dio.get('sponsors/');
  }

  Future<Response> getPrograms() async {
    return await _dio.get('program/');
  }


  Future<Response> getArticles() async {
    return await _dio.get('articles/');
  }

  Future<Response> resetPassword(String email) async {
    return await _dio.post('reset_password/', data: {'email': email});
  }
}
