import 'package:siade2/src/core/network/api_client.dart';
import 'package:siade2/src/commons/data/models/speaker.dart';
import 'package:siade2/src/commons/data/models/program.dart';
import 'package:siade2/src/commons/data/models/news.dart';
import 'package:siade2/src/commons/data/models/exponent.dart';
import 'package:siade2/src/commons/data/models/caterer.dart';
import 'package:siade2/src/core/constants/api_constants.dart';

class DataService {
  final ApiClient _apiClient = ApiClient();

  // ─── Récupérer les Speakers (Sponsors dans l'API) ───────────────────────────
  Future<List<Speaker>> fetchSpeakers() async {
    try {
      final response = await _apiClient.get(ApiConstants.sponsors);
      if (response.statusCode == 200) {
        // DRF renvoie les données dans une clé 'results' quand il y a pagination
        final List<dynamic> data = response.data['results'] ?? [];
        return data.map((json) => Speaker.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Erreur fetchSpeakers: $e");
      return [];
    }
  }

  // ─── Récupérer les Programmes ──────────────────────────────────────────────
  Future<List<Program>> fetchPrograms() async {
    try {
      final response = await _apiClient.get(ApiConstants.program);
      if (response.statusCode == 200) {
        // Idem pour les programmes
        final List<dynamic> data = response.data['results'] ?? [];
        return data.map((json) => Program.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Erreur fetchPrograms: $e");
      return [];
    }
  }
  // ─── Récupérer les Exposants ──────────────────────────────────────────────────
  Future<List<Exponent>> fetchExponents() async {
    try {
      final response = await _apiClient.get(ApiConstants.exposants);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? [];
        return data.map((json) => Exponent.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur fetchExponents: $e');
      return [];
    }
  }
  // ─── Récupérer les Articles (News) ─────────────────────────────────────────
  Future<List<Article>> fetchArticles() async {
    try {
      final response = await _apiClient.get(ApiConstants.articles);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? [];
        return data.map((json) => Article.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Erreur fetchArticles: $e");
      return [];
    }
  }

  // ─── Récupérer les Caterers (Restauration) ────────────────────────────────
  Future<List<Caterer>> fetchCaterers() async {
    try {
      final response = await _apiClient.get(ApiConstants.caterers);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? [];
        return data.map((json) => Caterer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur fetchCaterers: $e');
      return [];
    }
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
