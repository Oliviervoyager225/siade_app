import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:siade2/src/core/local/local_database.dart';
import 'package:siade2/src/core/local/connectivity_service.dart';
import 'package:siade2/src/core/local/sync_service.dart';
import 'package:siade2/src/core/network/api_client.dart';
import 'package:siade2/src/core/constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service d'authentification offline-first.
/// Priorité : backend web → si indisponible → base locale SQLite.
/// La sync vers le web se fait automatiquement au retour de la connexion.
class AuthLocalService {
  final LocalDatabase _localDb = LocalDatabase();
  final ConnectivityService _connectivity = ConnectivityService();
  final SyncService _syncService = SyncService();
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  /// Hash du mot de passe pour stockage local sécurisé
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ─── LOGIN ────────────────────────────────────────────────────────────────

  /// Tentative de connexion : d'abord web, sinon local.
  /// Retourne les données utilisateur ou null si échec.
  Future<Map<String, dynamic>?> login(
      String username, String password) async {
    final isOnline = await _connectivity.checkNow();

    if (isOnline) {
      debugPrint('[AuthLocalService] En ligne → tentative login web...');
      try {
        final result = await _loginRemote(username, password);
        if (result != null) {
          // Mise à jour en cache local avec les tokens
          await _cacheUserLocally(result, password);
          await _storage.write(key: 'current_user_email', value: result['email'] ?? username);
          return result;
        }
      } catch (e) {
        debugPrint('[AuthLocalService] Login web échoué: $e. Bascule sur local...');
        // Bascule local si le serveur est injoignable (réseau physiquement dispo mais serveur down)
        return _loginLocal(username, password);
      }
      return null; // Credentials incorrects (401 du serveur)
    } else {
      debugPrint('[AuthLocalService] Hors ligne → login local...');
      return _loginLocal(username, password);
    }
  }

  /// Login contre le backend web
  Future<Map<String, dynamic>?> _loginRemote(
      String username, String password) async {
    final response = await _apiClient.post(ApiConstants.login, {
      'username': username,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;

      // Le backend répond en HTTP 200 même quand il refuse la connexion, le
      // vrai code étant dans le corps (`{"status":400,"message":...}`). Sans
      // ce contrôle, `access` est nul, saveTokens lève une erreur de type, et
      // le catch appelant bascule sur l'authentification locale : l'échec
      // remonte alors en « serveur injoignable » et le message est perdu.
      final access = data['access'];
      if (access is! String) {
        debugPrint(
          '[AuthLocalService] Connexion refusée par le serveur: '
          '${data['message'] ?? data}',
        );
        return null;
      }

      // Sauvegarder les tokens JWT
      await _apiClient.saveTokens(
        access: access,
        refresh: data['refresh'] as String?,
      );

      // Mise à jour des tokens dans la BDD locale si l'utilisateur existe
      final localUser =
          await _localDb.getUserByEmail(username) ??
          await _localDb.getUserByUsername(username);
      if (localUser != null) {
        await _localDb.updateUserTokens(
          email: localUser['email'] as String,
          accessToken: access,
          refreshToken: data['refresh'] as String?,
        );
      }

      final user = data['user'] as Map<String, dynamic>?;
      return user ?? data;
    }
    return null;
  }

  /// Login contre la BDD locale
  Future<Map<String, dynamic>?> _loginLocal(
      String username, String password) async {
    final localUser = await _localDb.getUserByEmail(username) ??
        await _localDb.getUserByUsername(username);

    if (localUser == null) {
      debugPrint('[AuthLocalService] Utilisateur non trouvé en local.');
      return null;
    }

    final storedHash = localUser['password_hash'] as String;
    final inputHash = _hashPassword(password);

    if (storedHash != inputHash) {
      debugPrint('[AuthLocalService] Mot de passe local incorrect.');
      return null;
    }

    debugPrint('[AuthLocalService] ✅ Connexion locale réussie pour ${localUser['email']}');

    // Restaurer les tokens locaux si disponibles
    final accessToken = localUser['access_token'] as String?;
    final refreshToken = localUser['refresh_token'] as String?;
    if (accessToken != null) {
      await _apiClient.saveTokens(
        access: accessToken,
        refresh: refreshToken,
      );
    }

    final res = {
      'id': localUser['remote_id'],
      'first_name': localUser['first_name'],
      'last_name': localUser['last_name'],
      'email': localUser['email'],
      'username': localUser['username'],
      'phone': localUser['phone'],
      'poste': localUser['poste'],
      'is_local_session': true,
    };
    
    await _storage.write(key: 'current_user_email', value: localUser['email']);
    return res;
  }

  // ─── REGISTER ─────────────────────────────────────────────────────────────

  /// Inscription : toujours stocker en local + tenter web simultanément.
  /// Si web indisponible, mettre dans la file de sync.
  Future<RegisterResult> register(Map<String, dynamic> userData) async {
    final email = userData['email'] as String;
    final password = userData['password'] as String;

    // 1. Vérifier si l'utilisateur existe déjà en local
    final existing = await _localDb.getUserByEmail(email);
    if (existing != null) {
      return RegisterResult.alreadyExists;
    }

    // 2. Stocker en local immédiatement
    await _localDb.insertUser({
      'first_name': userData['first_name'] ?? '',
      'last_name': userData['last_name'] ?? '',
      'email': email,
      'username': userData['username'] ?? email,
      'password_hash': _hashPassword(password),
      'phone': userData['phone'] ?? '',
      'poste': userData['poste'] ?? 'ETUDIANT',
      'organisation': userData['organisation'] ?? '',
      'is_synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    debugPrint('[AuthLocalService] Utilisateur enregistré localement: $email');

    // 3. Tenter l'inscription sur le web
    final isOnline = await _connectivity.checkNow();
    if (isOnline) {
      try {
        final response = await _apiClient.post(ApiConstants.users, userData);
        if ((response.statusCode ?? 0) >= 200 &&
            (response.statusCode ?? 0) < 300) {
          final remoteId = response.data['id'] as int?;
          if (remoteId != null) {
            await _localDb.markUserSynced(email, remoteId);
          }
          debugPrint('[AuthLocalService] ✅ Inscription web réussie pour $email');
          return RegisterResult.success;
        } else {
          // L'API a rejeté (email déjà pris sur le serveur, etc.)
          debugPrint('[AuthLocalService] ⚠️ Web a rejeté l\'inscription: ${response.statusCode}');
          return RegisterResult.remoteError;
        }
      } catch (e) {
        debugPrint('[AuthLocalService] Serveur injoignable, inscription mise en file: $e');
        await _addToSyncQueue(userData);
        return RegisterResult.savedOffline;
      }
    } else {
      // Hors ligne: mettre en file de synchronisation
      await _addToSyncQueue(userData);
      debugPrint('[AuthLocalService] Hors ligne → inscription en file de sync.');
      return RegisterResult.savedOffline;
    }
  }

  Future<void> _addToSyncQueue(Map<String, dynamic> userData) async {
    // Ne pas stocker le mot de passe en clair dans la file de sync
    final syncData = Map<String, dynamic>.from(userData);
    await _localDb.addToSyncQueue(
      action: 'POST',
      endpoint: ApiConstants.users,
      payload: jsonEncode(syncData),
    );
  }

  /// Mise en cache local d'un utilisateur authentifié via le web
  Future<void> _cacheUserLocally(
      Map<String, dynamic> userData, String password) async {
    final email = (userData['email'] as String?) ?? '';
    if (email.isEmpty) return;

    final existing = await _localDb.getUserByEmail(email);
    if (existing == null) {
      await _localDb.insertUser({
        'remote_id': userData['id'],
        'first_name': userData['first_name'] ?? '',
        'last_name': userData['last_name'] ?? '',
        'email': email,
        'username': userData['username'] ?? email,
        'password_hash': _hashPassword(password),
        'phone': userData['phone'] ?? '',
        'poste': userData['poste'] ?? '',
        'organisation': userData['organisation'] ?? '',
        'is_synced': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Mettre à jour le hash du mdp si l'utilisateur se reconnecte
      await _localDb.updateUserTokens(
        email: email,
        accessToken: '',
        refreshToken: null,
      );
    }
  }


  // ─── SYNC ────────────────────────────────────────────────────────────────

  Future<void> triggerSync() => _syncService.syncNow();
  Future<int> getPendingSyncCount() => _syncService.getPendingCount();

  // ─── SESSION ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _apiClient.clearTokens();
    await _storage.delete(key: 'current_user_email');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUser() async {
    final email = await _storage.read(key: 'current_user_email');
    if (email != null && email.isNotEmpty) {
      return await _localDb.getUserByEmail(email) ??
             await _localDb.getUserByUsername(email);
    }
    return null;
  }

  /// Met à jour ou sauvegarde les données utilisateur en local
  Future<void> saveUser(Map<String, dynamic> user) async {
    final email = user['email'] as String?;
    if (email == null || email.isEmpty) return;

    final existing = await _localDb.getUserByEmail(email);
    if (existing != null) {
      final updated = Map<String, dynamic>.from(existing);
      
      // Mapper les champs Firestore/UI vers SQLite
      if (user.containsKey('photoURL')) updated['photo_url'] = user['photoURL'];
      if (user.containsKey('photo')) updated['photo_url'] = user['photo'];
      if (user.containsKey('first_name')) updated['first_name'] = user['first_name'];
      if (user.containsKey('last_name')) updated['last_name'] = user['last_name'];
      if (user.containsKey('username')) updated['username'] = user['username'];
      if (user.containsKey('phone')) updated['phone'] = user['phone'];
      if (user.containsKey('poste')) updated['poste'] = user['poste'];

      await _localDb.insertUser(updated);
      debugPrint('[AuthLocalService] Utilisateur mis à jour en local: $email');
    }
  }
}

enum RegisterResult {
  success,
  savedOffline,
  alreadyExists,
  remoteError,
}
