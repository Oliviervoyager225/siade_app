import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:siade2/src/core/local/auth_local_service.dart';
import 'package:siade2/src/core/local/connectivity_service.dart';
import 'package:siade2/src/core/local/sync_service.dart';

import 'package:siade2/src/core/services/data_service.dart';
import 'package:siade2/src/core/services/firebase_auth_service.dart';
import 'package:siade2/src/core/services/hybrid_auth_service.dart';
import 'package:siade2/src/core/services/image_cache_service.dart';
import 'package:siade2/src/core/services/notification_service.dart';


class UserProvider extends ChangeNotifier {
  final AuthLocalService _authService = AuthLocalService();
  final ConnectivityService _connectivity = ConnectivityService();
  final SyncService _syncService = SyncService();
  final DataService _dataService = DataService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final HybridAuthService _hybridAuthService;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;
  bool _isLocalSession = false;
  int _pendingSyncCount = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  bool get isOnline => _connectivity.isOnline;

  /// true si l'utilisateur est connecté en mode hors-ligne
  bool get isLocalSession => _isLocalSession;

  /// Nombre d'inscriptions/actions en attente de sync vers le serveur
  int get pendingSyncCount => _pendingSyncCount;


  UserProvider() {
    _hybridAuthService = HybridAuthService(
      djangoAuth: _authService,
      firebaseAuth: _firebaseAuthService,
    );
    // Écouter les changements de connectivité pour mettre à jour l'UI
    _connectivity.addListener(_onConnectivityChanged);
    // Démarrer le service de synchronisation automatique
    _syncService.startListening();
    _refreshPendingCount();
  }
  // ─── SIGNUP FIREBASE UNIQUEMENT ───────────────────────────────────────────
  /// Crée le compte directement dans Firebase Auth + document Firestore.
  /// Aucune dépendance serveur Django.
  Future<SignupResult> signupFirebase(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final password = userData['password'] as String? ?? '';
      final user = await _firebaseAuthService.createUserWithEmailAndPassword(
        email: userData['email'] as String,
        password: password,
        userData: userData,
      );

      _isLoading = false;
      notifyListeners();

      if (user != null) {
        return SignupResult.success;
      } else {
        _error = 'Impossible de créer le compte. Réessayez.';
        return SignupResult.failure;
      }
    } on String catch (msg) {
      _error = msg;
      _isLoading = false;
      notifyListeners();
      return SignupResult.failure;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return SignupResult.failure;
    }
  }

  // ─── SIGNUP HYBRIDE (Django + Firebase) ────────────────────────────────
  Future<SignupResult> signupHybrid(Map<String, dynamic> userData, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _hybridAuthService.signup(userData: userData, password: password);

      _isLoading = false;
      await _refreshPendingCount();
      notifyListeners();

      if (result.success && result.isDjangoAuthenticated && result.isFirebaseAuthenticated) {
        return SignupResult.success;
      } else if (result.success && result.isDjangoAuthenticated) {
        // Mode dégradé : Django OK, Firebase KO
        _error = 'Compte créé côté Django, mais pas sur Firebase.';
        return SignupResult.savedOffline;
      } else {
        _error = result.error ?? 'Erreur lors de l\'inscription.';
        return SignupResult.failure;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return SignupResult.failure;
    }
  }

  // ─── RESTORE SESSION AU DÉMARRAGE ─────────────────────────────────────────
  /// Appelé au lancement si une session valide existe déjà.
  /// Firebase : reconstruit _user depuis FirebaseAuth.instance.currentUser.
  /// Django   : reconstruit _user depuis la BDD locale (current_user_email).
  Future<void> restoreSession() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      // Force refresh depuis le serveur pour avoir la photo à jour
      try {
        await firebaseUser.reload();
      } catch (_) {}
      final freshUser = FirebaseAuth.instance.currentUser ?? firebaseUser;

      // Priorité : stockage sécurisé local (toujours le plus récent) → Firebase Auth
      final storedPhoto = await _secureStorage.read(key: 'user_photo_url') ?? '';
      final firebasePhoto = freshUser.photoURL ?? '';
      final resolvedPhoto = storedPhoto.isNotEmpty ? storedPhoto : firebasePhoto;

      final nameParts = freshUser.displayName?.split(' ') ?? [];
      _user = {
        'id': freshUser.uid,
        'email': freshUser.email ?? '',
        'username': freshUser.displayName ??
            freshUser.email?.split('@')[0] ??
            'Utilisateur',
        'first_name': nameParts.isNotEmpty ? nameParts.first : '',
        'last_name':
            nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
        'photoURL': resolvedPhoto,
        'photo': resolvedPhoto,
        'is_local_session': false,
        'auth_provider': freshUser.providerData.isNotEmpty
            ? freshUser.providerData.first.providerId
            : 'firebase',
      };
      _isLocalSession = false;
      notifyListeners();
      return;
    }

    // Pas de session Firebase → essayer la session Django locale
    final localUser = await _authService.getUser();
    if (localUser != null) {
      _user = {
        'id': localUser['id'],
        'email': localUser['email'] ?? '',
        'username': localUser['username'] ?? '',
        'first_name': localUser['first_name'] ?? '',
        'last_name': localUser['last_name'] ?? '',
        'photoURL': localUser['photo_url'] ?? '',
        'poste': localUser['poste'] ?? '',
        'photo': localUser['photo_url'] ?? '', // Standardize
        'is_local_session': true,
      };
      _isLocalSession = true;
      notifyListeners();
    }
  }

  // ─── LOGIN GOOGLE HYBRIDE (Firebase + Django) ──────────────────────────
  Future<bool> loginWithGoogleHybrid() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _hybridAuthService.loginWithGoogle();

      if (result.success && result.isFirebaseAuthenticated) {
        final firebaseUser = result.firebaseUser!;
        final nameParts = firebaseUser.displayName?.split(' ') ?? [];
        _user = {
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'username': firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'Utilisateur',
          'first_name': nameParts.isNotEmpty ? nameParts.first : '',
          'last_name': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
          'photoURL': firebaseUser.photoURL ?? '',
          'is_local_session': false,
          'auth_provider': 'google',
        };
        _isLocalSession = false;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error ?? 'Erreur Google Sign-In.';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    _syncService.stopListening();
    super.dispose();
  }

  void _onConnectivityChanged() {
    notifyListeners(); // Met à jour isOnline dans l'UI
    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    _pendingSyncCount = await _authService.getPendingSyncCount();
    notifyListeners();
  }

  // ─── LOGIN ─────────────────────────────────────────────────────────────────

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      return await _login(username, password);
    } finally {
      // Garde-fou : quel que soit le chemin de sortie, l'écran ne doit jamais
      // rester bloqué sur son indicateur de chargement. Le bouton de connexion
      // est remplacé par un spinner tant que _isLoading vaut true, sans aucun
      // moyen pour l'utilisateur de réessayer.
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _login(String username, String password) async {
    // 1. Try Django/local auth first
    Map<String, dynamic>? data;
    try {
      data = await _authService.login(username, password);
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (data != null) {
      _user = data;
      _isLocalSession = data['is_local_session'] == true;
      _isLoading = false;
      await _refreshPendingCount();
      notifyListeners();
      // Enregistrer le token FCM avec le JWT Django maintenant disponible
      NotificationService().refreshTokenForCurrentUser().catchError((_) {});
      // Tenter aussi Firebase Auth silencieusement pour que Firestore fonctionne
      _firebaseAuthService.signInWithEmailAndPassword(
        email: username,
        password: password,
      ).catchError((_) {});
      return true;
    }

    // 2. Fallback: Firebase Auth (for users registered via signupFirebase)
    try {
      // Contrairement à Dio, firebase_auth n'impose aucun délai maximal : sans
      // cette borne, un appel resté suspendu laissait _isLoading à true et
      // l'écran de connexion figé sur son indicateur, sans message ni retour.
      final firebaseUser = await _firebaseAuthService
          .signInWithEmailAndPassword(
            email: username,
            password: password,
          )
          .timeout(const Duration(seconds: 20));
      if (firebaseUser != null) {
        final nameParts = firebaseUser.displayName?.split(' ') ?? [];
        _user = {
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? username,
          'username': firebaseUser.displayName ?? firebaseUser.email ?? username,
          'first_name': nameParts.isNotEmpty ? nameParts.first : '',
          'last_name': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
          'photoURL': firebaseUser.photoURL ?? '',
          'photo': firebaseUser.photoURL ?? '', // Standardize
          'is_local_session': false,
        };
        _isLocalSession = false;
        _isLoading = false;
        await _refreshPendingCount();
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Firebase also failed — fall through to error
    }

    _error = 'Identifiants incorrects.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ─── SIGNUP ────────────────────────────────────────────────────────────────

  Future<SignupResult> signup(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.register(userData);

      _isLoading = false;
      await _refreshPendingCount();
      notifyListeners();

      switch (result) {
        case RegisterResult.success:
          return SignupResult.success;
        case RegisterResult.savedOffline:
          return SignupResult.savedOffline;
        case RegisterResult.alreadyExists:
          _error = 'Cet email est déjà utilisé.';
          return SignupResult.failure;
        case RegisterResult.remoteError:
          _error = 'Le serveur a rejeté l\'inscription. Vérifiez vos informations.';
          return SignupResult.failure;
      }
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return SignupResult.failure;
    }
  }

  // ─── PASSWORD RESET ────────────────────────────────────────────────────────

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendPasswordResetCode');
      await callable.call({'email': email});
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseFunctionsException catch (e) {
      _error = e.message ?? 'Erreur lors de l\'envoi du code';
    } catch (e) {
      _error = 'Erreur réseau. Vérifiez votre connexion.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ─── VÉRIFICATION DU CODE DE RÉINITIALISATION ──────────────────────────────

  Future<bool> verifyResetCode(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('checkResetCode');
      await callable.call({'email': email, 'code': code});
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseFunctionsException catch (e) {
      _error = e.message ?? 'Code invalide';
    } catch (e) {
      _error = 'Erreur réseau';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> resetPasswordWithCode(String email, String code, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyCodeAndResetPassword');
      await callable.call({'email': email, 'code': code, 'newPassword': newPassword});
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseFunctionsException catch (e) {
      _error = e.message ?? 'Erreur de réinitialisation';
    } catch (e) {
      _error = 'Erreur réseau';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ─── UPDATE PHOTO ──────────────────────────────────────────────────────────

  Future<void> updatePhotoURL(String photoURL) async {
    // 0. Evict old photo from cache so all widgets show the new image immediately
    final oldPhotoURL = _user?['photoURL'] as String?;
    if (oldPhotoURL != null && oldPhotoURL.isNotEmpty) {
      await ImageCacheService().removeFromCache(oldPhotoURL);
    }

    // 1. Update local state immediately with a new Map to trigger rebuilds
    if (_user != null) {
      final newUser = Map<String, dynamic>.from(_user!);
      newUser['photoURL'] = photoURL;
      newUser['photo'] = photoURL;
      _user = newUser;

      // Persist locally for next app launch (fallback si Firebase Auth cache stale)
      await _secureStorage.write(key: 'user_photo_url', value: photoURL);
      await _authService.saveUser(_user!);
      notifyListeners();
      print('✅ [UserProvider] Local state & storage updated with new photo');
    }

    // 2. Persist in Firebase Auth
    try {
      final firebaseUser = _firebaseAuthService.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updatePhotoURL(photoURL);
        print('✅ [UserProvider] Firebase Auth profile updated');

        // 3. Persist in Firestore (try native-db AND fallback to default if needed)
        Future<void> updateFirestore(String dbId) async {
          final firestore = dbId == '(default)' 
              ? FirebaseFirestore.instance 
              : FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: dbId);
          
          await firestore.collection('users').doc(firebaseUser.uid).update({
            'photoURL': photoURL,
            'photo': photoURL, // Some widgets use 'photo'
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // 4. Update participantInfo in all conversations I'm part of
          // This ensures others see my new photo in their chat list
          try {
            final convs = await firestore.collection('conversations')
                .where('participants', arrayContains: firebaseUser.uid)
                .get();
            
            final batch = firestore.batch();
            for (final doc in convs.docs) {
              batch.update(doc.reference, {
                'participantInfo.${firebaseUser.uid}.photoUrl': photoURL,
              });
            }
            await batch.commit();
            print('✅ [UserProvider] All conversations updated with new photo');
          } catch (e) {
            print('⚠️ [UserProvider] Error updating conversations: $e');
          }

          // 5. Update user's previous posts imagePoster
          try {
            final posts = await firestore.collection('posts')
                .where('userId', isEqualTo: firebaseUser.uid)
                .get();
            
            final batch = firestore.batch();
            for (final doc in posts.docs) {
              batch.update(doc.reference, {
                'imagePoster': photoURL,
              });
            }
            await batch.commit();
            print('✅ [UserProvider] All past posts updated with new photo');
          } catch (e) {
            print('⚠️ [UserProvider] Error updating posts: $e');
          }
        }

        try {
          await updateFirestore('native-db');
          print('✅ [UserProvider] Firestore (native-db) updated');
        } catch (e) {
          print('⚠️ [UserProvider] native-db update failed, trying default: $e');
          await updateFirestore('(default)');
          print('✅ [UserProvider] Firestore (default) updated');
        }
      }
    } catch (e) {
      print('❌ [UserProvider] Error updating remote photo: $e');
    }
  }

  // ─── LOGOUT ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _dataService.logout();
    await _firebaseAuthService.signOut();
    await _secureStorage.delete(key: 'user_photo_url');
    _user = null;
    _isLocalSession = false;
    _pendingSyncCount = 0;
    notifyListeners();
  }

  // ─── SYNC MANUEL ───────────────────────────────────────────────────────────

  Future<void> triggerSync() async {
    await _authService.triggerSync();
    await _refreshPendingCount();
  }

  // ─── HELPER ────────────────────────────────────────────────────────────────

  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          final firstErrorEntry = data['errors'][0];
          if (firstErrorEntry is Map && firstErrorEntry['errors'] is Map) {
            final fieldErrors = firstErrorEntry['errors'] as Map;
            final buffer = StringBuffer();
            fieldErrors.forEach((key, value) {
              if (value is List) {
                buffer.write('$key: ${value.join(", ")}\n');
              } else {
                buffer.write('$key: $value\n');
              }
            });
            if (buffer.isNotEmpty) return buffer.toString().trim();
          }
        }

        final message = data['message'] ?? data['error'] ?? data['detail'];
        if (message != null) return message.toString();

        final buffer = StringBuffer();
        data.forEach((key, value) {
          if (value is List) {
            buffer.write('$key: ${value.join(", ")}\n');
          } else if (value is String) {
            buffer.write('$key: $value\n');
          }
        });
        if (buffer.isNotEmpty) return buffer.toString().trim();
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return "Serveur indisponible. Connexion locale utilisée.";
      }
      return "Erreur (${e.response?.statusCode ?? 'Inconnu'})";
    }
    return "Une erreur est survenue.";
  }
}

enum SignupResult { success, savedOffline, failure }
