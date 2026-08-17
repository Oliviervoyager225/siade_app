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
          if (e.response?.statusCode != 401) return handler.next(e);

          // Une seule reprise par requête. Sans ce garde-fou, un point d'entrée
          // réellement protégé ferait boucler l'intercepteur indéfiniment :
          // 401 → reprise → 401 → reprise.
          if (e.requestOptions.extra[_cleReprise] == true) {
            return handler.next(e);
          }
          e.requestOptions.extra[_cleReprise] = true;

          if (await _refreshToken()) {
            return _rejouer(e, handler);
          }

          // Le rafraîchissement a échoué : les deux jetons sont morts. Les
          // conserver empoisonnerait toutes les requêtes suivantes, car
          // `onRequest` rattache l'en-tête dès qu'il trouve un jeton — y
          // compris vers les ressources publiques, qui répondent 200 sans
          // authentification. L'app restait vide jusqu'à une déconnexion
          // manuelle, sans jamais se réparer d'elle-même.
          await clearTokens();
          return _rejouer(e, handler);
        },
      ),
    );
  }

  /// Clé marquant une requête déjà reprise, portée par `RequestOptions.extra`.
  static const String _cleReprise = 'reprise_401';

  /// Rejoue la requête, en laissant remonter un éventuel second échec.
  ///
  /// `handler.resolve` attend une réponse : si [_retry] lève, l'exception
  /// s'échapperait de l'intercepteur au lieu d'atteindre l'appelant.
  Future<void> _rejouer(
    DioException e,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      handler.resolve(await _retry(e.requestOptions));
    } on DioException catch (echec) {
      handler.next(echec);
    }
  }

  /// Rafraîchissement en cours, partagé entre les appels concurrents.
  Future<bool>? _rafraichissementEnCours;

  /// Mutualise les rafraîchissements concurrents.
  ///
  /// `DataProvider.loadAllData` lance cinq requêtes en parallèle : avec un
  /// jeton expiré, elles déclencheraient cinq échanges de rafraîchissement
  /// simultanés pour un seul résultat utile.
  Future<bool> _refreshToken() {
    return _rafraichissementEnCours ??= _rafraichir()
        .whenComplete(() => _rafraichissementEnCours = null);
  }

  Future<bool> _rafraichir() async {
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
    // L'en-tête est retiré ici, puis reposé par `onRequest` à partir du
    // stockage. Le transmettre tel quel renverrait le jeton qu'on vient
    // précisément de remplacer ou d'écarter.
    final headers = Map<String, dynamic>.from(requestOptions.headers)
      ..remove('Authorization');

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        // `extra` porte le garde-fou anti-boucle : le perdre autoriserait une
        // nouvelle reprise à chaque 401.
        extra: requestOptions.extra,
      ),
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
