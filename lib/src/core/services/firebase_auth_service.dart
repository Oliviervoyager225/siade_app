import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'notification_service.dart';

/// Service pour gérer l'authentification Firebase
/// Supporte Email/Password, Google Sign-In et Sign in with Apple
class FirebaseAuthService {
  /// Délai au-delà duquel une écriture Firestore est abandonnée.
  ///
  /// Le SDK Firestore ne lève pas d'exception quand le serveur refuse ou reste
  /// injoignable : il conserve l'écriture en attente et réessaie sans fin. Le
  /// `Future` ne se termine donc jamais, aucun `catch` ne se déclenche, et
  /// l'écran appelant reste figé sur son indicateur de chargement. Cette borne
  /// laisse l'inscription s'achever côté Django même si Firestore ne répond
  /// pas ; la donnée manquante sera recréée à la prochaine connexion.
  static const Duration _delaiFirestore = Duration(seconds: 15);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web client ID (from google-services.json → oauth_client where client_type == 3)
    serverClientId: '595661721350-80h65bkfkqvcanhcldssoc933504bg6e.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );

  /// Utilisateur Firebase actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Stream des changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// ═══════════════════════════════════════════════════════════════
  /// 📧 AUTHENTICATION EMAIL/PASSWORD
  /// ═══════════════════════════════════════════════════════════════

  /// Créer un compte avec email/password
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Mettre à jour le profil
        await user.updateDisplayName(
          '${userData['first_name']} ${userData['last_name']}'.trim(),
        );
        // Recharger pour que displayName soit à jour
        await user.reload();
        final updatedUser = _auth.currentUser!;

        // Créer le document utilisateur dans Firestore
        await _createUserDocument(updatedUser, userData);
        await NotificationService()
            .refreshTokenForCurrentUser()
            .timeout(_delaiFirestore, onTimeout: () {});

        print('✅ Firebase: Compte créé avec succès - ${updatedUser.uid}');
        return updatedUser;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      
      // Gérer les erreurs courantes
      switch (e.code) {
        case 'email-already-in-use':
          // Email déjà utilisé, essayer de se connecter
          return await signInWithEmailAndPassword(email: email, password: password);
        case 'weak-password':
          throw 'Le mot de passe est trop faible';
        case 'invalid-email':
          throw 'Format d\'email invalide';
        default:
          throw 'Erreur Firebase: ${e.message}';
      }
    } catch (e) {
      print('❌ Erreur inattendue: $e');
      return null;
    }
  }

  /// Se connecter avec email/password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // L'utilisateur est authentifié dès cet instant : la synchronisation
        // Firestore et le jeton de notification se font en arrière-plan. Les
        // attendre ajoutait jusqu'à 45 s au retour de cette méthode quand
        // Firestore ne répond pas, dépassant le délai posé par l'appelant, qui
        // prenait alors une connexion réussie pour des identifiants invalides.
        unawaited(_createOrUpdateUserDocument(user, fournisseur: 'email'));
        unawaited(
          NotificationService().refreshTokenForCurrentUser().catchError((_) {}),
        );
      }
      print('✅ Firebase: Connexion réussie - ${user?.uid}');
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          throw 'Aucun utilisateur trouvé avec cet email';
        case 'wrong-password':
          throw 'Mot de passe incorrect';
        case 'invalid-credential':
          throw 'Identifiants invalides';
        default:
          throw 'Erreur de connexion: ${e.message}';
      }
    } catch (e) {
      print('❌ Erreur inattendue: $e');
      return null;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 🔐 GOOGLE SIGN-IN
  /// ═══════════════════════════════════════════════════════════════

  /// Se connecter avec Google
  Future<User?> signInWithGoogle() async {
    try {
      // Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Utilisateur a annulé
        print('⚠️  Google Sign-In annulé');
        return null;
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer une nouvelle credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter à Firebase avec la credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Même raison que pour la connexion e-mail : Firestore en arrière-plan.
        unawaited(_createOrUpdateUserDocument(user, fournisseur: 'google'));
        unawaited(
          NotificationService().refreshTokenForCurrentUser().catchError((_) {}),
        );

        print('✅ Firebase: Connexion Google réussie - ${user.uid}');
        return user;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw 'Erreur Google Sign-In: ${e.message}';
    } catch (e) {
      print('❌ Erreur Google Sign-In: $e');
      return null;
    }
  }

  /// Déconnexion Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      print('✅ Google Sign-Out réussi');
    } catch (e) {
      print('❌ Erreur Google Sign-Out: $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  ///  SIGN IN WITH APPLE
  /// ═══════════════════════════════════════════════════════════════

  /// Vrai quand la connexion Apple peut réellement aboutir sur cet appareil.
  ///
  /// Uniquement sur les plateformes Apple, où le système délivre lui-même un
  /// jeton d'identité signé sans configuration serveur. Ailleurs — Android,
  /// web — Apple n'expose que son flux OAuth par navigateur, qui réclame un
  /// Services ID et une clé privée déclarés dans le Developer Portal : sans
  /// eux le bouton s'afficherait pour répondre `invalid_client` au premier
  /// appui, et un service de connexion visible mais non fonctionnel est pire
  /// que son absence.
  ///
  /// Sert à décider de l'affichage du bouton. Le jour où la connexion Apple
  /// sur Android devient souhaitable, c'est ici et dans [signInWithApple]
  /// qu'il faut intervenir, en passant un `webAuthenticationOptions`.
  static bool get appleProposable => Platform.isIOS || Platform.isMacOS;

  /// Chaîne aléatoire liant la demande Apple à la réponse Firebase.
  ///
  /// Apple signe le nonce haché dans son jeton d'identité ; Firebase compare
  /// ensuite le nonce brut que nous lui transmettons. Sans ce couple, un jeton
  /// Apple intercepté ailleurs pourrait être rejoué contre notre projet.
  String _genererNonce([int longueur = 32]) {
    const alphabet =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final aleatoire = Random.secure();
    return List.generate(
      longueur,
      (_) => alphabet[aleatoire.nextInt(alphabet.length)],
    ).join();
  }

  /// Se connecter avec Apple.
  ///
  /// Renvoie `null` si l'utilisateur ferme la feuille système, comme
  /// [signInWithGoogle], pour que l'appelant distingue une annulation d'un
  /// échec.
  Future<User?> signInWithApple() async {
    try {
      final nonceBrut = _genererNonce();
      final nonceHache = sha256.convert(utf8.encode(nonceBrut)).toString();

      final identifiantApple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonceHache,
      );

      final jeton = identifiantApple.identityToken;
      if (jeton == null) {
        throw 'Apple n\'a pas renvoyé de jeton d\'identité.';
      }

      // `accessToken` reçoit le code d'autorisation d'Apple. Il n'est pas
      // facultatif malgré son nom : sans lui, Firebase refuse la connexion
      // avec « Invalid OAuth response from apple.com », alors même que le
      // jeton d'identité, son audience et le nonce sont tous corrects. Le
      // SDK Firebase l'exige depuis firebase_auth 4.3.0.
      final credential = OAuthProvider('apple.com').credential(
        idToken: jeton,
        accessToken: identifiantApple.authorizationCode,
        rawNonce: nonceBrut,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      var user = userCredential.user;
      if (user == null) return null;

      // Apple ne transmet le nom qu'à la toute première autorisation : si on ne
      // le persiste pas maintenant, il est définitivement perdu et le profil
      // reste anonyme aux connexions suivantes.
      final prenom = identifiantApple.givenName ?? '';
      final nomFamille = identifiantApple.familyName ?? '';
      final nomComplet = '$prenom $nomFamille'.trim();
      if (nomComplet.isNotEmpty &&
          (user.displayName == null || user.displayName!.trim().isEmpty)) {
        await user.updateDisplayName(nomComplet);
        await user.reload();
        user = _auth.currentUser ?? user;
      }

      // Même raison que pour Google : Firestore ne doit pas retarder l'écran.
      unawaited(_createOrUpdateUserDocument(user, fournisseur: 'apple'));
      unawaited(
        NotificationService().refreshTokenForCurrentUser().catchError((_) {}),
      );

      print('✅ Firebase: Connexion Apple réussie - ${user.uid}');
      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        print('⚠️  Sign in with Apple annulé');
        return null;
      }
      print('❌ Apple Authorization Error: ${e.code} - ${e.message}');
      throw 'Connexion Apple impossible : ${e.message}';
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      if (e.code == 'account-exists-with-different-credential') {
        throw 'Un compte existe déjà avec cette adresse. Connectez-vous avec '
            'votre méthode habituelle.';
      }
      throw 'Erreur Sign in with Apple : ${e.message}';
    } catch (e) {
      print('❌ Erreur Sign in with Apple: $e');
      rethrow;
    }
  }

  /// Sign in with Apple n'est disponible qu'à partir d'iOS 13 / macOS 10.15.
  Future<bool> appleDisponible() => SignInWithApple.isAvailable();

  /// ═══════════════════════════════════════════════════════════════
  /// 🗄️ FIRESTORE - GESTION DES DOCUMENTS UTILISATEUR
  /// ═══════════════════════════════════════════════════════════════

  /// Créer le document utilisateur dans Firestore (signup)
  Future<void> _createUserDocument(
    User user,
    Map<String, dynamic> userData,
  ) async {
    try {
      final fullName =
          '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
      await _firestore.collection('users').doc(user.uid).set({
        'firebaseUid': user.uid,
        'djangoUserId': userData['id'],
        'email': user.email,
        'username': userData['username'] ?? user.email?.split('@')[0],
        'displayName': fullName.isNotEmpty ? fullName : user.displayName,
        'firstName': userData['first_name'] ?? '',
        'lastName': userData['last_name'] ?? '',
        'phone': userData['phone'] ?? '',
        'poste': userData['poste'] ?? 'ETUDIANT',
        'organisation': userData['organisation'] ?? '',
        'photoURL': user.photoURL ?? '',
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_delaiFirestore);

      print('✅ Firestore: Document utilisateur créé - ${user.uid}');
    } on TimeoutException {
      print('⚠️ Firestore injoignable, document utilisateur non créé pour '
          '${user.uid}. L\'inscription se poursuit sans lui.');
    } catch (e) {
      print('❌ Erreur création Firestore: $e');
    }
  }

  /// Créer ou mettre à jour le document utilisateur (Google Sign-In)
  Future<void> _createOrUpdateUserDocument(
    User user, {
    String fournisseur = 'email',
  }) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get().timeout(_delaiFirestore);

      if (userDoc.exists) {
        // Utilisateur existe, mettre à jour
        await userDocRef.update({
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(_delaiFirestore);
        print('✅ Firestore: Document utilisateur mis à jour - ${user.uid}');
      } else {
        // Nouvel utilisateur, créer le document
        await userDocRef.set({
          'firebaseUid': user.uid,
          'djangoUserId': null, // À synchroniser plus tard
          'email': user.email,
          'username': user.email?.split('@')[0],
          'displayName': user.displayName,
          'firstName': user.displayName?.split(' ').first,
          'lastName': user.displayName?.split(' ').skip(1).join(' '),
          'phone': null,
          'poste': 'ETUDIANT', // Valeur par défaut
          'organisation': '',
          'photoURL': user.photoURL,
          'provider': fournisseur,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(_delaiFirestore);
        print('✅ Firestore: Document utilisateur créé - ${user.uid}');
      }
    } on TimeoutException {
      print('⚠️ Firestore injoignable, profil non synchronisé pour '
          '${user.uid}. La connexion se poursuit sans lui.');
    } catch (e) {
      print('❌ Erreur Firestore: $e');
    }
  }

  /// Mettre à jour le lien Django User ID
  Future<void> updateDjangoUserId(String firebaseUid, int djangoUserId) async {
    try {
      await _firestore.collection('users').doc(firebaseUid).update({
        'djangoUserId': djangoUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_delaiFirestore);

      print('✅ Firestore: Django User ID mis à jour - Firebase UID: $firebaseUid → Django ID: $djangoUserId');
    } on TimeoutException {
      print('⚠️ Firestore injoignable, lien Django non enregistré pour '
          '$firebaseUid.');
    } catch (e) {
      print('❌ Erreur mise à jour Django ID: $e');
    }
  }

  /// Récupérer les données utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc =
          await _firestore.collection('users').doc(uid).get().timeout(
                _delaiFirestore,
              );
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Erreur lecture Firestore: $e');
      return null;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 🚪 DÉCONNEXION
  /// ═══════════════════════════════════════════════════════════════

  /// Se déconnecter de Firebase
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await signOutGoogle(); // Déconnexion Google si nécessaire
      print('✅ Firebase: Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur déconnexion Firebase: $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 🔄 RÉINITIALISATION DU MOT DE PASSE
  /// ═══════════════════════════════════════════════════════════════

  /// Envoyer un email de réinitialisation de mot de passe
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Firebase: Email de réinitialisation envoyé à $email');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'user-not-found':
          throw 'Aucun utilisateur trouvé avec cet email';
        case 'invalid-email':
          throw 'Format d\'email invalide';
        default:
          throw 'Erreur: ${e.message}';
      }
    } catch (e) {
      print('❌ Erreur envoi email: $e');
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 🔍 VÉRIFICATIONS
  /// ═══════════════════════════════════════════════════════════════

  /// Vérifier si un email existe dans Firebase
  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification email: $e');
      return false;
    }
  }

  /// Vérifier si l'utilisateur est connecté
  bool get isSignedIn => _auth.currentUser != null;

  /// Obtenir l'UID Firebase
  String? get firebaseUid => _auth.currentUser?.uid;

  /// Obtenir l'email
  String? get email => _auth.currentUser?.email;
}
