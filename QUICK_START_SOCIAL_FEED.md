# 🚀 Guide de Démarrage Rapide - Fil d'Actualité

## ✅ Ce qui a été fait

1. ✅ **Modèles de données** créés (Post, Comment)
2. ✅ **Services** créés (PostService, StorageService)
3. ✅ **Page de création** de posts avec upload d'images
4. ✅ **Feed en temps réel** avec StreamBuilder
5. ✅ **Interactions** (like, comment, share, save)
6. ✅ **Page de commentaires** complète
7. ✅ **Règles de sécurité Firestore** déployées
8. ✅ **Dépendances** installées

---

## 🔧 Configuration Finale Requise

### ⚠️ IMPORTANT : Activer Firebase Storage

**Étapes obligatoires :**

1. **Ouvrir Firebase Console**
   - Aller sur : https://console.firebase.google.com/project/siade-2026/storage

2. **Activer Storage**
   - Si vous voyez "Commencer", cliquer dessus
   - Choisir la localisation : `europe-west` (recommandé pour l'Europe)
   - Cliquer sur "Terminé"

3. **Configurer les règles de Storage**
   - Une fois Storage activé, aller dans l'onglet **"Rules"**
   - Remplacer le contenu par :

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Dossier des posts
    match /posts/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Dossier des avatars
    match /avatars/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

4. **Publier les règles**
   - Cliquer sur **"Publier"** en haut à droite

---

## 🎯 Tester l'Application

### 1. Lancer l'app
```bash
flutter run
```

### 2. Tester la création de post

1. Se connecter avec un compte (Firebase Auth doit être configuré)
2. Naviguer vers la page de création de post
3. Taper du texte : "Mon premier post! 🎉"
4. Cliquer sur le bouton `+` pour ajouter des images
5. Sélectionner 1-3 images
6. Cliquer sur **"Publier"**

**Résultat attendu :**
- Les images s'uploadent (vous verrez la progression dans les logs)
- Le post s'ajoute au feed automatiquement
- Vous verrez le post en haut du feed

### 3. Tester les interactions

**Like :**
- Cliquer sur 👍 → L'icône devient bleue, le compteur s'incrémente
- Cliquer à nouveau → L'icône redevient grise, le compteur décrémente

**Commentaire :**
- Cliquer sur 💬 → La page des commentaires s'ouvre
- Taper "Super post! 👍" en bas
- Appuyer sur Entrée ou cliquer sur ➡️
- Le commentaire apparaît dans la liste

**Partage :**
- Cliquer sur 🔼 → Un message "Post partagé!" apparaît
- Le compteur s'incrémente

**Sauvegarde :**
- Cliquer sur 🔖 → L'icône devient rose/pleine
- Le post est ajouté aux favoris de l'utilisateur

### 4. Vérifier dans Firestore

1. Aller sur : https://console.firebase.google.com/project/siade-2026/firestore
2. Vous devriez voir ces collections :
   - **`posts`** → Vos posts
   - **`comments`** → Les commentaires
   - **`users`** → Avec le champ `savedPosts` mis à jour

---

## 📸 Permissions Android

Pour que l'app puisse accéder à la caméra et à la galerie sur Android, vérifiez que ces permissions sont dans `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

---

## 🐛 Résolution de Problèmes

### Erreur : "User not authenticated"
**Cause :** Aucun utilisateur connecté  
**Solution :** Assurez-vous qu'un utilisateur est connecté via Firebase Auth

### Erreur : "Permission denied" lors de l'upload
**Cause :** Firebase Storage n'est pas activé ou les règles sont incorrectes  
**Solution :**
1. Activer Storage dans Firebase Console
2. Vérifier les règles de Storage (voir section ci-dessus)

### Les images ne s'affichent pas
**Cause :** URLs invalides ou problème de cache  
**Solution :**
1. Vérifier que les URLs commencent par `https://`
2. Vérifier la connexion internet
3. Hot restart : `flutter run --hot-restart`

### Le feed est vide
**Cause :** Aucun post créé OU règles Firestore bloquent l'accès  
**Solution :**
1. Créer un post de test
2. Vérifier dans Firestore Console si le post existe
3. Vérifier que les règles sont déployées : `firebase deploy --only firestore:rules`

### Erreur de compilation
**Cause :** Dépendances non installées  
**Solution :**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📊 Monitoring

### Vérifier les uploads dans Storage

1. Aller sur : https://console.firebase.google.com/project/siade-2026/storage
2. Naviguer dans le dossier `posts/`
3. Vous devriez voir les images uploadées organisées par `userId`

### Vérifier les documents dans Firestore

1. Aller sur : https://console.firebase.google.com/project/siade-2026/firestore
2. Collection `posts` → Voir tous les posts
3. Collection `comments` → Voir tous les commentaires

---

## 🎨 Personnalisation

### Modifier le nombre max d'images par post

Dans `create_post_page.dart`, modifier la méthode `_pickImages()` :

```dart
Future<void> _pickImages() async {
  try {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      limit: 5, // ← Changer ici (max 5 images)
    );
    // ...
  }
}
```

### Modifier l'apparence des posts

Éditer `lib/src/features/home/widgets/posts.dart` pour changer les couleurs, tailles, etc.

### Ajouter des réactions (au lieu de juste like)

1. Modifier le modèle `Post` pour ajouter un Map de réactions
2. Modifier `PostService` pour gérer les différents types de réactions
3. Créer un widget de sélection de réaction

---

## 📝 Prochaines Étapes

### Fonctionnalités à ajouter (optionnel)

1. **Notifications Push**
   - Notifier quand quelqu'un like/commente un post
   - Utiliser Firebase Cloud Messaging

2. **Pagination du Feed**
   - Charger 10 posts à la fois
   - Ajouter un bouton "Charger plus"

3. **Recherche**
   - Rechercher des posts par hashtag
   - Rechercher des utilisateurs

4. **Stories**
   - Posts éphémères (24h)
   - Collection séparée avec expiration automatique

5. **Mentions**
   - Mentionner d'autres utilisateurs avec @username
   - Créer des liens vers les profils

---

## ✅ Checklist de Vérification

Avant de tester :

- [ ] Firebase Storage est activé
- [ ] Les règles de Storage sont configurées
- [ ] Les règles Firestore sont déployées
- [ ] Les dépendances sont installées (`flutter pub get`)
- [ ] Un utilisateur est connecté (Firebase Auth)
- [ ] Les permissions Android sont configurées

---

## 📞 Commandes Utiles

```bash
# Installer les dépendances
flutter pub get

# Nettoyer le build
flutter clean

# Lancer l'app
flutter run

# Déployer les règles Firestore
firebase deploy --only firestore:rules

# Voir les logs en temps réel
flutter run --verbose
```

---

## 📖 Documentation Complète

Pour plus de détails, consultez : **`SOCIAL_FEED_README.md`**

---

**Tout est prêt! Il suffit d'activer Firebase Storage et de tester! 🎉**
