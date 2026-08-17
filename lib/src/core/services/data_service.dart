import 'package:siade2/src/core/network/api_client.dart';
import 'package:siade2/src/commons/data/models/speaker.dart';
import 'package:siade2/src/commons/data/models/program.dart';
import 'package:siade2/src/commons/data/models/news.dart';
import 'package:siade2/src/commons/data/models/exponent.dart';
import 'package:siade2/src/commons/data/models/caterer.dart';
import 'package:siade2/src/core/constants/api_constants.dart';

class DataService {
  final ApiClient _apiClient = ApiClient();

  /// Extrait la liste paginée d'une réponse DRF.
  ///
  /// Les méthodes de lecture ci-dessous ne rattrapent volontairement aucune
  /// erreur : Dio lève déjà sur tout statut hors 2xx, et transformer la panne
  /// en liste vide rendait « le serveur est injoignable » indiscernable de
  /// « il n'y a rien à afficher ». C'est [DataProvider] qui décide quoi en
  /// dire à l'utilisateur.
  List<T> _liste<T>(
    dynamic corps,
    T Function(Map<String, dynamic>) depuisJson,
  ) {
    final resultats = corps is Map ? corps['results'] : null;
    if (resultats is! List) return const [];
    return resultats
        .whereType<Map<String, dynamic>>()
        .map(depuisJson)
        .toList();
  }

  // ─── Récupérer les Speakers (Sponsors dans l'API) ───────────────────────────
  Future<List<Speaker>> fetchSpeakers() async {
    final response = await _apiClient.get(ApiConstants.sponsors);
    return _liste(response.data, Speaker.fromJson);
  }

  // ─── Récupérer les Programmes ──────────────────────────────────────────────
  Future<List<Program>> fetchPrograms() async {
    final response = await _apiClient.get(ApiConstants.program);
    return _liste(response.data, Program.fromJson);
  }
  // ─── Récupérer les Exposants ──────────────────────────────────────────────────
  Future<List<Exponent>> fetchExponents() async {
    final response = await _apiClient.get(ApiConstants.exposants);
    return _liste(response.data, Exponent.fromJson);
  }
  // ─── Récupérer les Articles (News) ─────────────────────────────────────────
  Future<List<Article>> fetchArticles() async {
    final response = await _apiClient.get(ApiConstants.articles);
    return _liste(response.data, Article.fromJson);
  }

  // ─── Récupérer les Caterers (Restauration) ────────────────────────────────
  Future<List<Caterer>> fetchCaterers() async {
    final response = await _apiClient.get(ApiConstants.caterers);
    return _liste(response.data, Caterer.fromJson);
  }

  // ─── Authentification ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _apiClient.post(ApiConstants.login, {
        'username': username,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        // Sauvegarde des tokens JWT
        await _apiClient.saveTokens(
          access: data['access'],
          refresh: data['refresh'],
        );
        return data['user']; // Retourne directement les infos utilisateur
      }
      return null;
    } catch (e) {
      rethrow; // On laisse le Provider gérer l'erreur
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.post(ApiConstants.users, userData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      final response = await _apiClient.post(ApiConstants.passwordReset, {'email': email});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
  }
}
