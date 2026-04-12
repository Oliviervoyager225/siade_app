# 🔐 INTÉGRATION FIREBASE AUTHENTICATION - SIADE

## 📋 Vue d'ensemble

Ce guide explique comment intégrer Firebase Authentication (Email/Password + Google) avec votre système d'authentification Django existant.

---

## 🎯 Architecture Hybride

```
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION SIADE                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [Login/Signup UI] (existant)                               │
│         ↓                                                    │
│  ┌──────────────────────────────────────────┐               │
│  │   UserProvider (state management)         │               │
│  └──────────────────────────────────────────┘               │
│         ↓                                                    │
│  ┌─────────────────────────────────────────────────┐        │
│  │   HybridAuthService (NOUVEAU)                   │        │
│  │   - Orchestre Django + Firebase                 │        │
│  │   - Synchronise les identités                   │        │
│  └─────────────────────────────────────────────────┘        │
│         ↓                      ↓                             │
│  ┌──────────────────┐   ┌─────────────────────┐            │
│  │ AuthLocalService │   │ FirebaseAuthService │ NOUVEAU    │
│  │ (Django + SQLite)│   │ (Firebase Auth)     │            │
│  └──────────────────┘   └─────────────────────┘            │
│         ↓                      ↓                             │
│  ┌──────────────────┐   ┌─────────────────────┐            │
│  │  SQLite Local    │   │   Firestore         │ NOUVEAU    │
│  │  (offline-first) │   │   (live sessions)   │            │
│  └──────────────────┘   └─────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚡ Principe de fonctionnement

### **1. Connexion/Inscription classique**
- ✅ Garde votre système Django actuel (offline-first)
- ✅ Authentification via API Django + SQLite local
- ✅ Aucun changement pour l'utilisateur

### **2. Firebase Auth en arrière-plan**
- 🔥 Création automatique d'un compte Firebase en parallèle
- 🔥 Synchronisation de l'email/username
- 🔥 Liaison des deux identités (Django ID ↔ Firebase UID)

### **3. Usage pour le Live Streaming**
- 📹 Firebase Auth pour sécuriser les sessions live
- 📹 Firestore pour stocker messages, viewers, etc.
- 📹 Tokens Agora générés via Firebase UID

---

## 📦 Dépendances à ajouter

Ajoutez dans `pubspec.yaml` :

```yaml
dependencies:
  # Firebase Core (obligatoire)
  firebase_core: ^3.6.0
  
  # Firebase Authentication
  firebase_auth: ^5.3.1
  
  # Firestore (pour live sessions)
  cloud_firestore: ^5.4.3
  
  # Google Sign-In
  google_sign_in: ^6.2.2
  
  # Firebase Cloud Functions (pour tokens Agora)
  cloud_functions: ^5.1.3
  
  # Firebase Messaging (notifications)
  firebase_messaging: ^15.1.3
```

Puis exécutez :
```bash
flutter pub get
```

---

## 🔧 Fichiers à créer

### **1. Service Firebase Auth**
📄 `lib/src/core/services/firebase_auth_service.dart`

Gère l'authentification Firebase (email/password + Google).

### **2. Service Hybride**
📄 `lib/src/core/services/hybrid_auth_service.dart`

Orchestre Django + Firebase, synchronise les identités.

### **3. Modification du UserProvider**
📄 `lib/src/providers/user_provider.dart`

Ajoute les appels à Firebase lors des login/signup.

---

## 🔐 Configuration Firebase Console

### **Étape 1 : Activer Email/Password**

1. Allez sur **Firebase Console** → **Authentication**
2. Cliquez sur **"Get started"**
3. Onglet **"Sign-in method"**
4. Activez **"Email/Password"**
5. Cliquez sur **"Save"**

### **Étape 2 : Activer Google Sign-In**

1. Dans **"Sign-in method"**, cliquez sur **"Google"**
2. Activez le switch
3. **Support email** : `votre-email@exemple.com`
4. Cliquez sur **"Save"**

### **Étape 3 : Configurer SHA-1 (pour Google Sign-In)**

**Sur Windows (PowerShell) :**
```powershell
cd C:\Users\OD233007\StudioProjects\siade2\android
./gradlew signingReport
```

Copiez le SHA-1 affiché (ligne **SHA1:**).

**Dans Firebase Console :**
1. ⚙️ **Settings** → **Project Settings**
2. Descendez jusqu'à **"Your apps"**
3. Cliquez sur votre app Android
4. **"Add fingerprint"**
5. Collez le SHA-1
6. Cliquez sur **"Save"**

---

## 🚀 Utilisation dans votre code

### **Login avec Email/Password**

```dart
// Dans votre login.dart existant
final result = await context.read<UserProvider>().login(email, password);

// Désormais, cela va :
// 1. Authentifier via Django (comme avant)
// 2. Créer/connecter automatiquement à Firebase (en arrière-plan)
// 3. Synchroniser l'identité
```

### **Login avec Google**

```dart
// Bouton Google Sign-In
ElevatedButton.icon(
  onPressed: () async {
    final result = await context.read<UserProvider>().loginWithGoogle();
    if (result) {
      // Connecté avec succès
      Navigator.pushReplacement(context, /* ... */);
    }
  },
  icon: Icon(Icons.g_mobiledata),
  label: Text('Sign in with Google'),
);
```

### **Signup**

```dart
// Dans votre signup_page.dart existant
final result = await context.read<UserProvider>().signup(userData);

// Désormais, cela va :
// 1. Créer le compte Django (comme avant)
// 2. Créer automatiquement le compte Firebase (en arrière-plan)
// 3. Synchroniser les données
```

---

## 📊 Structure Firestore pour Live Streaming

Une fois authentifié avec Firebase, votre app pourra utiliser Firestore :

```
firestore/
├── users/
│   └── {firebaseUid}/
│       ├── djangoUserId: int       ← Lien vers votre DB Django
│       ├── email: string
│       ├── username: string
│       ├── displayName: string
│       └── createdAt: timestamp
│
├── live_sessions/
│   └── {liveId}/
│       ├── hostId: string (firebase UID)
│       ├── hostName: string
│       ├── title: string
│       ├── channelName: string     ← Pour Agora
│       ├── status: "live" | "ended"
│       ├── viewerCount: number
│       ├── startedAt: timestamp
│       │
│       ├── messages/ (subcollection)
│       │   └── {messageId}/
│       │       ├── userId: string
│       │       ├── userName: string
│       │       ├── message: string
│       │       └── timestamp: timestamp
│       │
│       └── viewers/ (subcollection)
│           └── {userId}/
│               ├── joinedAt: timestamp
│               └── userName: string
```

---

## ✅ Checklist d'intégration

### **Configuration Firebase**
- [ ] Firestore Database créé
- [ ] Authentication activée (Email/Password)
- [ ] Google Sign-In activé
- [ ] SHA-1 ajouté pour Google Sign-In
- [ ] google-services.json placé dans android/app/

### **Code Flutter**
- [ ] Dépendances Firebase ajoutées dans pubspec.yaml
- [ ] Firebase initialisé dans main.dart
- [ ] FirebaseAuthService créé
- [ ] HybridAuthService créé
- [ ] UserProvider modifié
- [ ] Bouton Google Sign-In ajouté (optionnel)

### **Test**
- [ ] Login email/password fonctionne
- [ ] Signup crée bien les deux comptes
- [ ] Google Sign-In fonctionne
- [ ] Données synchronisées entre Django et Firebase

---

## 🐛 Résolution de problèmes

### **Erreur : "PlatformException(sign_in_failed)"**
→ Vérifiez que le SHA-1 est bien ajouté dans Firebase Console

### **Erreur : "Firebase not initialized"**
→ Vérifiez que `await Firebase.initializeApp()` est dans main.dart

### **Erreur : "User not found in Firestore"**
→ Le compte Firebase existe mais pas dans Firestore, relancez le signup

### **Google Sign-In ne s'affiche pas**
→ Vérifiez que google-services.json est à jour

---

## 📚 Ressources

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth/flutter/start)
- [Google Sign-In Flutter Plugin](https://pub.dev/packages/google_sign_in)
- [Firestore Documentation](https://firebase.google.com/docs/firestore/quickstart)

---

**Date de création** : 30 Mars 2026  
**Version** : 1.0  
**Projet** : SIADE Mobile App
