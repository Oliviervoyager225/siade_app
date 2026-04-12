import 'package:siade2/src/core/local/auth_local_service.dart';
import 'package:siade2/src/core/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service hybride qui orchestre l'authentification Django + Firebase
/// 
/// Stratégie :
/// 1. Authentifier d'abord via Django (système existant)
/// 2. En parallèle, créer/connecter à Firebase
/// 3. Synchroniser les identités (Django ID ↔ Firebase UID)
class HybridAuthService {
  final AuthLocalService _djangoAuth;
  final FirebaseAuthService _firebaseAuth;

  HybridAuthService({
    required AuthLocalService djangoAuth,
    required FirebaseAuthService firebaseAuth,
  })  : _djangoAuth = djangoAuth,
        _firebaseAuth = firebaseAuth;

  /// ═══════════════════════════════════════════════════════════════
  /// 🔐 LOGIN HYBRIDE (Django + Firebase)
  /// ═══════════════════════════════════════════════════════════════

  /// Login avec email/password (Django + Firebase)
  /// 
  /// Flow :
  /// 1. Authentifier via Django (prioritaire)
  /// 2. Si succès Django → Authentifier Firebase en parallèle
  /// 3. Synchroniser les identités
  Future<HybridAuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      print('🔄 Hybrid Auth: Tentative de login - $username');

      // 1. AUTHENTIFICATION DJANGO (Prioritaire)
      final djangoUser = await _djangoAuth.login(username, password);

      if (djangoUser == null) {
        print('❌ Django Auth: Échec de connexion');
        return HybridAuthResult(
          success: false,
          isDjangoAuthenticated: false,
          isFirebaseAuthenticated: false,
          error: 'Identifiants invalides',
        );
      }

      print('✅ Django Auth: Connexion réussie');

      // 2. AUTHENTIFICATION FIREBASE (En parallèle)
      User? firebaseUser;
      try {
        firebaseUser = await _firebaseAuth.signInWithEmailAndPassword(
          email: djangoUser['username'] ?? djangoUser['email'],
          password: password,
        );

        if (firebaseUser != null) {
          print('✅ Firebase Auth: Connexion réussie - ${firebaseUser.uid}');

          // 3. SYNCHRONISER LES IDENTITÉS
          await _syncIdentities(
            firebaseUid: firebaseUser.uid,
            djangoUserId: djangoUser['id'],
          );

          return HybridAuthResult(
            success: true,
            isDjangoAuthenticated: true,
            isFirebaseAuthenticated: true,
            djangoUser: djangoUser,
            firebaseUser: firebaseUser,
          );
        }
      } catch (e) {
        print('⚠️  Firebase Auth: Échec ($e) - Continuons avec Django seulement');
      }

      // Si Firebase échoue, l'utilisateur peut quand même utiliser l'app
      return HybridAuthResult(
        success: true,
        isDjangoAuthenticated: true,
        isFirebaseAuthenticated: false,
        djangoUser: djangoUser,
        error: 'Firebase indisponible (mode dégradé)',
      );
    } catch (e) {
      print('❌ Hybrid Auth Error: $e');
      return HybridAuthResult(
        success: false,
        isDjangoAuthenticated: false,
        isFirebaseAuthenticated: false,
        error: e.toString(),
      );
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 📝 SIGNUP HYBRIDE (Django + Firebase)
  /// ═══════════════════════════════════════════════════════════════

  /// Inscription avec email/password (Django + Firebase)
  /// 
  /// Flow :
  /// 1. Créer le compte Django (prioritaire)
  /// 2. Créer le compte Firebase en parallèle
  /// 3. Synchroniser les identités
  Future<HybridAuthResult> signup({
    required Map<String, dynamic> userData,
    required String password,
  }) async {
    try {
      print('🔄 Hybrid Auth: Tentative d\'inscription - ${userData['email']}');

      // 1. CRÉATION COMPTE DJANGO (Prioritaire)
      final djangoResult = await _djangoAuth.register(userData);
      final djangoSuccess = djangoResult == RegisterResult.success || 
                            djangoResult == RegisterResult.savedOffline;

      if (!djangoSuccess) {
        print('❌ Django Auth: Échec d\'inscription');
        return HybridAuthResult(
          success: false,
          isDjangoAuthenticated: false,
          isFirebaseAuthenticated: false,
          error: djangoResult == RegisterResult.alreadyExists ? 'Email déjà utilisé' : 'Erreur lors de la création du compte',
        );
      }

      print('✅ Django Auth: Compte créé avec succès');

      // Récupérer l'utilisateur Django nouvellement créé
      final djangoUser = await _djangoAuth.login(userData['username'] ?? userData['email'], password);

      // 2. CRÉATION COMPTE FIREBASE (En parallèle)
      User? firebaseUser;
      try {
        firebaseUser = await _firebaseAuth.createUserWithEmailAndPassword(
          email: userData['email'],
          password: password,
          userData: {
            ...userData,
            'id': djangoUser?['id'], // Ajouter l'ID Django
          },
        );

        if (firebaseUser != null) {
          print('✅ Firebase Auth: Compte créé - ${firebaseUser.uid}');

          // 3. SYNCHRONISER LES IDENTITÉS
          if (djangoUser != null) {
            await _syncIdentities(
              firebaseUid: firebaseUser.uid,
              djangoUserId: djangoUser['id'],
            );
          }

          return HybridAuthResult(
            success: true,
            isDjangoAuthenticated: true,
            isFirebaseAuthenticated: true,
            djangoUser: djangoUser,
            firebaseUser: firebaseUser,
          );
        }
      } catch (e) {
        print('⚠️  Firebase Auth: Échec ($e) - Continuons avec Django seulement');
      }

      // Si Firebase échoue, l'utilisateur peut quand même utiliser l'app
      return HybridAuthResult(
        success: true,
        isDjangoAuthenticated: true,
        isFirebaseAuthenticated: false,
        djangoUser: djangoUser,
        error: 'Firebase indisponible (mode dégradé)',
      );
    } catch (e) {
      print('❌ Hybrid Auth Error: $e');
      return HybridAuthResult(
        success: false,
        isDjangoAuthenticated: false,
        isFirebaseAuthenticated: false,
        error: e.toString(),
      );
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 🔐 GOOGLE SIGN-IN
  /// ═══════════════════════════════════════════════════════════════

  /// Connexion avec Google (Firebase → Django)
  /// 
  /// Flow :
  /// 1. Authentifier via Google (Firebase)
  /// 2. Créer/mettre à jour le compte Django
  /// 3. Synchroniser les identités
  Future<HybridAuthResult> loginWithGoogle() async {
    try {
      print('🔄 Hybrid Auth: Tentative de connexion Google');

      // 1. AUTHENTIFICATION GOOGLE (via Firebase)
      final firebaseUser = await _firebaseAuth.signInWithGoogle();

      if (firebaseUser == null) {
        print('❌ Google Sign-In annulé');
        return HybridAuthResult(
          success: false,
          isDjangoAuthenticated: false,
          isFirebaseAuthenticated: false,
          error: 'Connexion Google annulée',
        );
      }

      print('✅ Firebase Auth: Connexion Google réussie - ${firebaseUser.uid}');

      // 2. SYNCHRONISER AVEC DJANGO
      // TODO: Implémenter l'endpoint Django pour Google Sign-In
      // Pour l'instant, on utilise seulement Firebase
      // Dans une version future, vous pouvez créer un endpoint Django :
      // POST /api/auth/google/ avec { idToken, accessToken }

      return HybridAuthResult(
        success: true,
        isDjangoAuthenticated: false, // À implémenter côté Django
        isFirebaseAuthenticated: true,
        firebaseUser: firebaseUser,
        error: 'Django sync non implémenté pour Google (Firebase seul)',
      );
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      return HybridAuthResult(
        success: false,
        isDjangoAuthenticated: false,
        isFirebaseAuthenticated: false,
        error: e.toString(),
      );
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 🔄 SYNCHRONISATION DES IDENTITÉS
  /// ═══════════════════════════════════════════════════════════════

  /// Synchroniser les identités Django ↔ Firebase
  Future<void> _syncIdentities({
    required String firebaseUid,
    required int djangoUserId,
  }) async {
    try {
      // Mettre à jour Firestore avec l'ID Django
      await _firebaseAuth.updateDjangoUserId(firebaseUid, djangoUserId);

      // TODO: Optionnel - Mettre à jour Django avec Firebase UID
      // Vous pouvez ajouter un champ 'firebase_uid' dans votre modèle Django User
      // et le mettre à jour via l'API

      print('✅ Identités synchronisées: Django ID $djangoUserId ↔ Firebase UID $firebaseUid');
    } catch (e) {
      print('⚠️  Erreur synchronisation identités: $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 🚪 DÉCONNEXION
  /// ═══════════════════════════════════════════════════════════════

  /// Déconnexion hybride (Django + Firebase)
  Future<void> logout() async {
    try {
      print('🔄 Hybrid Auth: Déconnexion');

      await Future.wait([
        _djangoAuth.logout(),
        _firebaseAuth.signOut(),
      ]);

      print('✅ Déconnexion hybride réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 🔍 VÉRIFICATIONS
  /// ═══════════════════════════════════════════════════════════════

  /// Vérifier si l'utilisateur est authentifié (Django ou Firebase)
  Future<bool> isAuthenticated()async {
    final djangoAuth = await _djangoAuth.isLoggedIn();
    final firebaseAuth = _firebaseAuth.isSignedIn;
    return djangoAuth || firebaseAuth;
  }

  /// Obtenir l'utilisateur actuel
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _djangoAuth.getUser();
  }

  /// Obtenir l'UID Firebase
  String? get firebaseUid => _firebaseAuth.firebaseUid;

  /// Obtenir l'ID Django
  Future<int?> get djangoUserId async {
    final user = await _djangoAuth.getUser();
    return user?['id'];
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 📦 RÉSULTAT D'AUTHENTIFICATION HYBRIDE
/// ═══════════════════════════════════════════════════════════════

class HybridAuthResult {
  final bool success;
  final bool isDjangoAuthenticated;
  final bool isFirebaseAuthenticated;
  final Map<String, dynamic>? djangoUser;
  final User? firebaseUser;
  final String? error;

  HybridAuthResult({
    required this.success,
    required this.isDjangoAuthenticated,
    required this.isFirebaseAuthenticated,
    this.djangoUser,
    this.firebaseUser,
    this.error,
  });

  /// Authentification complète (Django + Firebase)
  bool get isFullyAuthenticated => isDjangoAuthenticated && isFirebaseAuthenticated;

  /// Mode dégradé (un seul système fonctionnel)
  bool get isDegradedMode => success && !isFullyAuthenticated;

  /// Firebase UID
  String? get firebaseUid => firebaseUser?.uid;

  /// Django User ID
  int? get djangoUserId => djangoUser?['id'];

  @override
  String toString() {
    return 'HybridAuthResult('
        'success: $success, '
        'django: $isDjangoAuthenticated, '
        'firebase: $isFirebaseAuthenticated, '
        'djangoId: $djangoUserId, '
        'firebaseUid: $firebaseUid, '
        'error: $error'
        ')';
  }
}
