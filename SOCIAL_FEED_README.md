# Système de Fil d'Actualité - Documentation

## 🎯 Vue d'ensemble

Un système complet de fil d'actualité (type Facebook) a été implémenté avec Firebase Firestore. Les utilisateurs peuvent créer des posts, ajouter des images, liker, commenter et partager.

---

## ✨ Fonctionnalités Implémentées

### 1. **Création de Posts**
- ✅ Publier du texte et/ou des images
- ✅ Upload multiple d'images vers Firebase Storage
- ✅ Capture photo avec la caméra
- ✅ Prévisualisation des images avant publication
- ✅ Indicateur de progression pendant l'upload

**Utilisation :**
- Depuis la page d'accueil, cliquer sur le bouton pour créer un post
- Ajouter du texte dans le champ "Quoi de neuf?"
- Cliquer sur le bouton `+` pour ajouter des images
- Cliquer sur "Publier"

### 2. **Affichage du Feed**
- ✅ Flux en temps réel avec StreamBuilder
- ✅ Chargement automatique des nouveaux posts
- ✅ Tri par date (plus récents en premier)
- ✅ Affichage des images en carousel
- ✅ Gestion des images réseau avec cache

### 3. **Interactions sur les Posts**

#### Like/Unlike
- ✅ Liker un post (icône change de couleur)
- ✅ Compteur de likes en temps réel
- ✅ Enregistrement dans Firestore
- ✅ Vérification si l'utilisateur a déjà liké

#### Commentaires
- ✅ Page dédiée aux commentaires
- ✅ Ajouter un commentaire
- ✅ Supprimer ses propres commentaires
- ✅ Compteur de commentaires
- ✅ Affichage en temps réel des nouveaux commentaires

#### Partage
- ✅ Incrémenter le compteur de partages
- ✅ Notification de confirmation

#### Sauvegarde
- ✅ Sauvegarder un post dans les favoris
- ✅ Icône change d'apparence
- ✅ Enregistrement dans le profil utilisateur

---

## 📁 Structure du Code

### Modèles de Données

**`lib/src/commons/data/models/posts.dart`**
```dart
class Post {
  String? id;              // ID Firestore
  String userId;           // ID du créateur
  String imagePoster;      // Avatar de l'utilisateur
  String namePoster;       // Nom de l'utilisateur
  String postLegend;       // Texte du post
  List<String> postImages; // URLs des images
  int likes;               // Compteur de likes
  int shares;              // Compteur de partages
  List<String> comments;   // IDs des commentaires
  DateTime createdAt;      // Date de création
  List<String> likedBy;    // Liste des utilisateurs qui ont liké
  
  // Méthodes
  - fromFirestore()        // Convertir document Firestore en Post
  - toFirestore()          // Convertir Post en Map pour Firestore
  - copyWith()             // Créer une copie modifiée
}

class Comment {
  String? id;
  String postId;
  String userId;
  String userAvatar;
  String userName;
  String text;
  DateTime createdAt;
  int likes;
  List<String> likedBy;
}
```

### Services

**`lib/src/core/services/post_service.dart`**
```dart
class PostService {
  // CRUD Posts
  - createPost()           // Créer un nouveau post
  - updatePost()           // Modifier un post existant
  - deletePost()           // Supprimer un post
  - getPostsStream()       // Stream en temps réel de tous les posts
  - getUserPostsStream()   // Posts d'un utilisateur spécifique
  
  // Interactions Likes
  - likePost()             // Liker un post
  - unlikePost()           // Retirer le like
  - hasLikedPost()         // Vérifier si l'utilisateur a liké
  
  // Gestion Commentaires
  - addComment()           // Ajouter un commentaire
  - deleteComment()        // Supprimer un commentaire
  - getCommentsStream()    // Stream des commentaires d'un post
  - likeComment()          // Liker un commentaire
  - unlikeComment()        // Retirer le like d'un commentaire
  
  // Partages
  - sharePost()            // Incrémenter le compteur de partages
  
  // Sauvegarde
  - savePost()             // Ajouter aux favoris
  - unsavePost()           // Retirer des favoris
  - getSavedPostsStream()  // Posts sauvegardés de l'utilisateur
}
```

**`lib/src/core/services/storage_service.dart`**
```dart
class StorageService {
  - uploadPostImage()      // Upload une image de post
  - uploadMultipleImages() // Upload plusieurs images
  - uploadAvatarImage()    // Upload avatar utilisateur
  - deleteImageByUrl()     // Supprimer une image
}
```

### Pages & Widgets

**Pages :**
- `create_post_page.dart` - Créer un nouveau post
- `comments_page.dart` - Afficher et gérer les commentaires

**Widgets :**
- `feeds.dart` - Container du fil d'actualité avec StreamBuilder
- `posts.dart` - Widget d'affichage d'un post individuel

---

## 🔐 Règles de Sécurité Firestore

Les règles ont été configurées dans `firestore.rules` :

### Posts
- ✅ **Lecture** : Tous les utilisateurs authentifiés
- ✅ **Création** : Utilisateur authentifié, userId doit correspondre
- ✅ **Modification** : Propriétaire OU modification des compteurs uniquement
- ✅ **Suppression** : Propriétaire uniquement

### Commentaires
- ✅ **Lecture** : Tous les utilisateurs authentifiés
- ✅ **Création** : Utilisateur authentifié, userId doit correspondre
- ✅ **Modification** : Propriétaire OU modification des likes uniquement
- ✅ **Suppression** : Propriétaire uniquement

### Déploiement des règles
```bash
firebase deploy --only firestore:rules
```

---

## 🔧 Configuration Firebase Storage

### Étapes de Configuration

1. **Activer Firebase Storage**
   - Aller dans Firebase Console
   - Sélectionner le projet `siade-2026`
   - Cliquer sur "Storage" dans le menu latéral
   - Cliquer sur "Commencer" si ce n'est pas encore fait

2. **Configurer les règles de Storage**
   
   Dans Firebase Console > Storage > Rules, remplacer par :

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

3. **Publier les règles** : Cliquer sur "Publier"

---

## 📦 Dépendances Ajoutées

Les nouvelles dépendances ont été ajoutées dans `pubspec.yaml` :

```yaml
dependencies:
  firebase_storage: ^12.3.4  # Stockage des images
  image_picker: ^1.0.7       # Sélection d'images
  cached_network_image: ^3.3.1 # (déjà présent)
```

### Installation
```bash
flutter pub get
```

---

## 🚀 Démarrage

### 1. Installer les dépendances
```bash
flutter pub get
```

### 2. Déployer les règles Firestore
```bash
firebase deploy --only firestore:rules
```

### 3. Configurer Firebase Storage
- Activer Storage dans Firebase Console
- Configurer les règles (voir section ci-dessus)

### 4. Lancer l'application
```bash
flutter run
```

---

## 📱 Utilisation

### Créer un Post

1. Ouvrir l'application
2. Naviguer vers la section "Créer un post"
3. Taper le texte du post
4. (Optionnel) Cliquer sur le bouton `+` puis :
   - 📷 **Icône appareil photo** : Prendre une photo
   - 🖼️ **Icône image** : Sélectionner des images de la galerie
5. Les images sélectionnées s'affichent en grille
6. Cliquer sur ❌ sur une image pour la retirer
7. Cliquer sur **"Publier"**

### Interagir avec un Post

**Like :**
- Cliquer sur 👍 pour liker
- Cliquer à nouveau pour retirer le like

**Commenter :**
- Cliquer sur 💬 pour ouvrir la page des commentaires
- Taper un commentaire en bas
- Appuyer sur Entrée ou cliquer sur ➡️
- Supprimer votre commentaire via le menu ⋮

**Partager :**
- Cliquer sur 🔼 pour partager
- Le compteur s'incrémente

**Sauvegarder :**
- Cliquer sur 🔖 pour sauvegarder dans vos favoris
- Cliquer à nouveau pour retirer

---

## 🗄️ Structure Firestore

### Collections

**`posts/`**
```javascript
{
  userId: "user_id",
  imagePoster: "url_avatar",
  namePoster: "Nom Utilisateur",
  postLegend: "Texte du post...",
  postImages: ["url1", "url2"],
  likes: 0,
  shares: 0,
  comments: ["comment_id1", "comment_id2"],
  createdAt: Timestamp,
  updatedAt: Timestamp,
  likedBy: ["user_id1", "user_id2"]
}
```

**`comments/`**
```javascript
{
  postId: "post_id",
  userId: "user_id",
  userAvatar: "url_avatar",
  userName: "Nom Utilisateur",
  text: "Commentaire...",
  createdAt: Timestamp,
  likes: 0,
  likedBy: ["user_id1"]
}
```

**`users/` (champ ajouté)**
```javascript
{
  // ... autres champs
  savedPosts: ["post_id1", "post_id2"]
}
```

---

## 🐛 Dépannage

### Erreur : "User not authenticated"
**Solution :** L'utilisateur doit être connecté avec Firebase Auth

### Erreur : "Permission denied" lors de l'upload
**Solution :** Vérifier que Firebase Storage est activé et que les règles sont bien configurées

### Les images ne s'affichent pas
**Solution :** 
- Vérifier que les URLs sont valides
- Vérifier la connexion internet
- Vérifier les règles de Storage (lecture autorisée)

### Le feed ne se met pas à jour
**Solution :** 
- Vérifier que Firestore est bien configuré
- Vérifier les règles de sécurité
- Vérifier la console pour les erreurs

---

## 🎨 Personnalisation

### Modifier le design des posts
Éditer `lib/src/features/home/widgets/posts.dart`

### Modifier la page de création
Éditer `lib/src/features/socialnetwork/pages/create_post_page.dart`

### Modifier la page des commentaires
Éditer `lib/src/features/home/pages/comments_page.dart`

### Ajouter des réactions (au lieu de juste like)
Modifier `PostService.likePost()` et `Post.likedBy` pour inclure le type de réaction

---

## 📝 TODO / Améliorations Futures

- [ ] Système de notifications push pour les likes/commentaires
- [ ] Mentions d'utilisateurs (@username)
- [ ] Hashtags (#tag)
- [ ] Recherche de posts
- [ ] Filtres/tri du feed (populaires, récents, etc.)
- [ ] Stories (24h expiration)
- [ ] Réactions multiples (❤️, 😂, 😮, etc.)
- [ ] Partage vers d'autres apps
- [ ] Édition de posts
- [ ] Signalement de posts inappropriés
- [ ] Pagination du feed (lazy loading)

---

## 📞 Support

Pour toute question ou problème, consultez :
- Documentation Firebase : https://firebase.google.com/docs
- Documentation Flutter : https://flutter.dev/docs

---

**Date de création :** Avril 2026  
**Version :** 1.0.0  
**Firebase Project :** siade-2026
