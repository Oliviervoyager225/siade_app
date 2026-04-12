# 🚀 GUIDE D'IMPLÉMENTATION FINALE - Firebase Auth

## ✅ Fichiers créés

- ✅ `FIREBASE_AUTH_INTEGRATION.md` - Documentation complète
- ✅ `lib/src/core/services/firebase_auth_service.dart` - Service Firebase Auth
- ✅ `lib/src/core/services/hybrid_auth_service.dart` - Service hybride Django + Firebase
- ✅ `pubspec.yaml` - Dépendances Firebase ajoutées

---

## 📝 ÉTAPE 1 : Installer les dépendances

Dans le terminal PowerShell :

```bash
flutter pub get
```

---

## 📝 ÉTAPE 2 : Initialiser Firebase dans main.dart

Modifiez votre fichier `lib/main.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';  // ← AJOUTER

void main() async {
  // ← AJOUTER CES 3 LIGNES
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print('✅ Firebase initialisé');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Votre code existant
    return MaterialApp(
      // ...
    );
  }
}
```

---

## 📝 ÉTAPE 3 : Modifier UserProvider

Ouvrez `lib/src/providers/user_provider.dart` et ajoutez :

### **3.1. Imports en haut du fichier**

```dart
import 'package:siade2/src/core/services/firebase_auth_service.dart';
import 'package:siade2/src/core/services/hybrid_auth_service.dart';
```

### **3.2. Ajouter les services dans la classe**

```dart
class UserProvider extends ChangeNotifier {
  // Services existants
  final AuthLocalService _authService;
  final ConnectivityService _connectivity;
  final SyncService _syncService;

  // ← AJOUTER CES NOUVEAUX SERVICES
  late final FirebaseAuthService _firebaseAuth;
  late final HybridAuthService _hybridAuth;

  UserProvider({
    required AuthLocalService authService,
    required ConnectivityService connectivity,
    required SyncService syncService,
  })  : _authService = authService,
        _connectivity = connectivity,
        _syncService = syncService {
    // ← AJOUTER L'INITIALISATION
    _firebaseAuth = FirebaseAuthService();
    _hybridAuth = HybridAuthService(
      djangoAuth: _authService,
      firebaseAuth: _firebaseAuth,
    );

    _initialize();
  }

  // ... reste du code existant
```

### **3.3. Modifier la méthode login()**

Remplacez la méthode `login()` existante par :

```dart
/// Login avec authentification hybride (Django + Firebase)
Future<bool> login(String username, String password) async {
  _error = null;
  _isLoading = true;
  notifyListeners();

  try {
    // Utiliser le service hybride
    final result = await _hybridAuth.login(
      username: username,
      password: password,
    );

    if (result.success) {
      // Récupérer les données utilisateur
      _user = result.djangoUser;
      _isLocalSession = !_connectivity.isOnline || !result.isFirebaseAuthenticated;

      print('✅ Login réussi - Django: ${result.isDjangoAuthenticated}, Firebase: ${result.isFirebaseAuthenticated}');

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result.error ?? 'Erreur de connexion';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  } catch (e) {
    print('❌ Erreur login: $e');
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

### **3.4. Modifier la méthode signup()**

Remplacez la méthode `signup()` existante par :

```dart
/// Signup avec authentification hybride (Django + Firebase)
Future<SignupResult> signup(Map<String, dynamic> userData) async {
  _error = null;
  _isLoading = true;
  notifyListeners();

  try {
    // Extraire le password (ne pas le stocker dans userData)
    final password = userData['password'] as String;

    // Utiliser le service hybride
    final result = await _hybridAuth.signup(
      userData: userData,
      password: password,
    );

    if (result.success) {
      _user = result.djangoUser;
      _isLocalSession = !_connectivity.isOnline || !result.isFirebaseAuthenticated;

      print('✅ Signup réussi - Django: ${result.isDjangoAuthenticated}, Firebase: ${result.isFirebaseAuthenticated}');

      _isLoading = false;
      notifyListeners();

      // Retourner le bon résultat selon le statut
      if (result.isFullyAuthenticated) {
        return SignupResult.success;
      } else if (result.isDjangoAuthenticated) {
        return SignupResult.savedOffline; // Firebase non dispo
      } else {
        return SignupResult.failure;
      }
    } else {
      _error = result.error ?? 'Erreur lors de l\'inscription';
      _isLoading = false;
      notifyListeners();
      return SignupResult.failure;
    }
  } catch (e) {
    print('❌ Erreur signup: $e');
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return SignupResult.failure;
  }
}
```

### **3.5. Ajouter la méthode loginWithGoogle()**

Ajoutez cette nouvelle méthode :

```dart
/// Login avec Google (NOUVEAU)
Future<bool> loginWithGoogle() async {
  _error = null;
  _isLoading = true;
  notifyListeners();

  try {
    final result = await _hybridAuth.loginWithGoogle();

    if (result.success && result.firebaseUser != null) {
      // Créer un utilisateur à partir des infos Google
      _user = {
        'id': 0, // Temporaire, à synchroniser avec Django
        'email': result.firebaseUser!.email,
        'username': result.firebaseUser!.email?.split('@')[0],
        'first_name': result.firebaseUser!.displayName?.split(' ').first ?? '',
        'last_name': result.firebaseUser!.displayName?.split(' ').skip(1).join(' ') ?? '',
        'firebase_uid': result.firebaseUser!.uid,
      };
      _isLocalSession = false;

      print('✅ Google Sign-In réussi');

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result.error ?? 'Erreur Google Sign-In';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  } catch (e) {
    print('❌ Erreur Google Sign-In: $e');
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

### **3.6. Modifier la méthode logout()**

Remplacez la méthode `logout()` existante par :

```dart
/// Logout hybride (Django + Firebase)
Future<void> logout() async {
  _isLoading = true;
  notifyListeners();

  try {
    await _hybridAuth.logout();

    _user = null;
    _error = null;
    _isLocalSession = false;

    print('✅ Déconnexion hybride réussie');

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    print('❌ Erreur déconnexion: $e');
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }
}
```

---

## 📝 ÉTAPE 4 : Ajouter le bouton Google Sign-In (Optionnel)

Dans votre page de login (`lib/src/features/login/pages/login.dart`), ajoutez après le bouton de connexion classique :

```dart
// Séparateur "Or login with"
const Padding(
  padding: EdgeInsets.symmetric(vertical: 20),
  child: Row(
    children: [
      Expanded(child: Divider()),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('Or login with'),
      ),
      Expanded(child: Divider()),
    ],
  ),
),

// Bouton Google Sign-In
OutlinedButton.icon(
  onPressed: () async {
    final success = await context.read<UserProvider>().loginWithGoogle();
    if (mounted && success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AppLayout()),
      );
    }
  },
  icon: Image.asset(
    'assets/images/google-logo.png', // Ajoutez le logo Google
    height: 24,
  ),
  label: const Text('Sign in with Google'),
  style: OutlinedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
    side: const BorderSide(color: Colors.grey),
  ),
),
```

---

## 📝 ÉTAPE 5 : Configurer Firebase Console

### **5.1. Activer Email/Password**

1. Firebase Console → **Authentication**
2. **Sign-in method** → **Email/Password**
3. Activez → **Save**

### **5.2. Activer Google Sign-In**

1. **Sign-in method** → **Google**
2. Activez
3. **Support email** : votre email
4. **Save**

### **5.3. Ajouter SHA-1 (pour Google Sign-In)**

Dans PowerShell :

```powershell
cd C:\Users\OD233007\StudioProjects\siade2\android
./gradlew signingReport
```

Copiez le **SHA1** affiché.

Dans Firebase Console :
1. ⚙️ **Settings** → **Project Settings**
2. Votre app Android
3. **Add fingerprint** → Collez le SHA-1
4. **Save**

---

## 📝 ÉTAPE 6 : Tester

### **Test 1 : Inscription**

```dart
// Créez un compte de test
final userData = {
  'first_name': 'Test',
  'last_name': 'User',
  'email': 'test@example.com',
  'username': 'testuser',
  'password': 'password123',
  'phone': '',
  'poste': 'ETUDIANT',
  'organisation': 'Test Org',
};

final result = await context.read<UserProvider>().signup(userData);
// Devrait créer le compte dans Django ET Firebase
```

### **Test 2 : Connexion Email/Password**

```dart
final success = await context.read<UserProvider>().login(
  'test@example.com',
  'password123',
);
// Devrait connecter aux deux systèmes
```

### **Test 3 : Google Sign-In**

```dart
final success = await context.read<UserProvider>().loginWithGoogle();
// Devrait ouvrir le sélecteur de compte Google
```

### **Test 4 : Vérifier Firestore**

Dans Firebase Console → Firestore Database :
- Collection `users` devrait contenir vos utilisateurs
- Chaque document devrait avoir : `firebaseUid`, `djangoUserId`, `email`, etc.

---

## ✅ Checklist finale

- [ ] `flutter pub get` exécuté
- [ ] Firebase initialisé dans `main.dart`
- [ ] Services Firebase ajoutés dans `UserProvider`
- [ ] Méthodes `login()`, `signup()`, `logout()` modifiées
- [ ] Méthode `loginWithGoogle()` ajoutée (optionnel)
- [ ] Firebase Console configuré (Email/Password + Google)
- [ ] SHA-1 ajouté pour Google Sign-In
- [ ] Test d'inscription réussi
- [ ] Test de connexion réussi
- [ ] Données visibles dans Firestore

---

## 🎯 Prochaine étape : Live Streaming !

Une fois l'authentification hybride fonctionnelle, vous pourrez :

1. ✅ Créer des sessions live dans Firestore
2. ✅ Utiliser Firebase UID pour Agora tokens
3. ✅ Gérer le chat en temps réel
4. ✅ Compter les viewers
5. ✅ Envoyer des notifications

**Fichier documentation complet** : `FIREBASE_AUTH_INTEGRATION.md`

---

**Besoin d'aide ?** Testez d'abord l'inscription, puis la connexion. Vérifiez les logs dans la console pour voir si Firebase et Django sont bien synchronisés !

---

**Date** : 30 Mars 2026  
**Auteur** : GitHub Copilot  
**Projet** : SIADE Mobile App
