import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:siade2/src/core/constants/api_constants.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class ApiClient {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    // Configuration de base
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);

    // Forcer le décodage UTF-8 pour corriger les caractères accentués (ex: CÃ©rÃ©mone → Cérémone)
    _dio.options.responseDecoder = (responseBytes, options, responseBody) {
      return utf8.decode(responseBytes, allowMalformed: true);
    };

    // Logging pour le débogage
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));

    // Gestion des headers par défaut
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    };

    // Ajout de l'intercepteur pour les tokens
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Récupérer le token du stockage
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Si erreur 401 (token expiré), on tente de refresh
          if (e.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // On rejoue la requête initiale avec le nouveau token
              return handler.resolve(await _retry(e.requestOptions));
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;

    try {
      final response = await Dio().post(
        ApiConstants.tokenRefresh,
        data: {'refresh': refresh},
      );
      if (response.statusCode == 200) {
        final newToken = response.data['access'];
        await _storage.write(key: 'access_token', value: newToken);
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // --- Méthodes publiques ---
  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, dynamic data) => _dio.post(path, data: data);
  Future<Response> put(String path, dynamic data) => _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _storage.write(key: 'access_token', value: access);
    if (refresh != null) {
      await _storage.write(key: 'refresh_token', value: refresh);
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
