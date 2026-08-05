import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../commons/data/models/posts.dart';

/// Service de gestion des posts (publications) sur le fil d'actualité
/// 
/// **Fonctionnalités :**
/// - Créer, modifier, supprimer des posts
/// - Like, unlike des posts
/// - Ajouter, supprimer des commentaires
/// - Partager des posts
/// - Flux en temps réel des posts
class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  // 🔥 Utiliser la base de données 'native-db' au lieu de 'default'
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );
  FirebaseFirestore get firestore => _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Délai au-delà duquel une écriture Firestore est abandonnée.
  ///
  /// Firestore ne lève pas d'exception quand le serveur refuse : il met
  /// l'écriture en attente et réessaie sans fin. Sans cette borne, l'écran de
  /// création reste bloqué sur son indicateur de chargement, sans message ni
  /// possibilité de revenir en arrière.
  static const Duration _delaiFirestore = Duration(seconds: 20);

  // Collections Firestore
  final String postsCollection = 'posts';
  final String commentsCollection = 'comments';
  final String usersCollection = 'users';

  /// Obtenir l'utilisateur courant
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => currentUser?.uid;

  // ========== GESTION DES POSTS ==========

  /// Créer un nouveau post
  Future<String?> createPost({
    required String postLegend,
    required List<String> postImages,
  }) async {
    try {
      print('🔵 [PostService] Début createPost()');
      print('🔵 [PostService] postLegend: $postLegend');
      print('🔵 [PostService] postImages count: ${postImages.length}');
      
      if (currentUserId == null) {
        print('❌ [PostService] Utilisateur non connecté');
        return null;
      }
      print('✅ [PostService] UserId: $currentUserId');

      // Récupérer les infos de l'utilisateur
      print('🔵 [PostService] Récupération des données utilisateur...');
      final userDoc = await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .get()
          .timeout(_delaiFirestore);
      
      if (!userDoc.exists) {
        print('⚠️ [PostService] Document utilisateur n\'existe pas, création avec données par défaut');
      }
      
      final userData = userDoc.data();
      print('🔵 [PostService] UserData: ${userData?.keys.toList()}');
      
      final userName = userData?['name'] ?? userData?['displayName'] ?? 'Utilisateur';
      final userPhoto = userData?['photo'] ?? userData?['photoURL'] ?? '';
      
      print('🔵 [PostService] Nom: $userName, Photo: ${userPhoto.isNotEmpty ? "Oui" : "Non"}');
      
      final post = Post(
        userId: currentUserId!,
        imagePoster: userPhoto,
        namePoster: userName,
        postLegend: postLegend,
        postImages: postImages,
        likes: 0,
        shares: 0,
        comments: [],
        createdAt: DateTime.now(),
        likedBy: [],
      );
      
      print('🔵 [PostService] Post object créé');
      print('🔵 [PostService] Conversion en Firestore...');
      
      final firestoreData = post.toFirestore();
      print('🔵 [PostService] Données Firestore: ${firestoreData.keys.toList()}');
      
      print('🔵 [PostService] Upload vers Firestore collection: $postsCollection');
      final docRef = await _firestore
          .collection(postsCollection)
          .add(firestoreData)
          .timeout(_delaiFirestore);

      print('✅ [PostService] Post créé avec succès! ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ [PostService] Erreur lors de la création du post:');
      print('❌ [PostService] Message: $e');
      print('❌ [PostService] Type: ${e.runtimeType}');
      print('❌ [PostService] StackTrace: $stackTrace');
      return null;
    }
  }

  /// Mettre à jour un post existant
  Future<bool> updatePost({
    required String postId,
    String? postLegend,
    List<String>? postImages,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (postLegend != null) updates['postLegend'] = postLegend;
      if (postImages != null) updates['postImages'] = postImages;
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection(postsCollection)
          .doc(postId)
          .update(updates);

      print('✅ Post mis à jour: $postId');
      return true;
    } catch (e) {
      print('❌ Erreur mise à jour post: $e');
      return false;
    }
  }

  /// Supprimer un post
  Future<bool> deletePost(String postId) async {
    try {
      // Supprimer d'abord tous les commentaires associés
      final commentsSnapshot = await _firestore
          .collection(commentsCollection)
          .where('postId', isEqualTo: postId)
          .get();

      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Supprimer le post
      await _firestore.collection(postsCollection).doc(postId).delete();

      print('✅ Post supprimé: $postId');
      return true;
    } catch (e) {
      print('❌ Erreur suppression post: $e');
      return false;
    }
  }

  /// Obtenir un flux en temps réel de tous les posts (triés par date décroissante)
  Stream<List<Post>> getPostsStream() {
    return _firestore
        .collection(postsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  /// Obtenir les posts d'un utilisateur spécifique
  Stream<List<Post>> getUserPostsStream(String userId) {
    return _firestore
        .collection(postsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  /// Obtenir un post spécifique par ID
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection(postsCollection).doc(postId).get();
      if (doc.exists) {
        return Post.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération post: $e');
      return null;
    }
  }

  // ========== INTERACTIONS : LIKES ==========

  /// Liker un post
  Future<bool> likePost(String postId) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection(postsCollection).doc(postId).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([currentUserId]),
      });

      print('✅ Post liké: $postId');
      return true;
    } catch (e) {
      print('❌ Erreur like post: $e');
      return false;
    }
  }

  /// Unliker un post
  Future<bool> unlikePost(String postId) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection(postsCollection).doc(postId).update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([currentUserId]),
      });

      print('✅ Post unliké: $postId');
      return true;
    } catch (e) {
      print('❌ Erreur unlike post: $e');
      return false;
    }
  }

  /// Vérifier si l'utilisateur courant a liké un post
  Future<bool> hasLikedPost(String postId) async {
    try {
      if (currentUserId == null) return false;

      final doc = await _firestore.collection(postsCollection).doc(postId).get();
      final data = doc.data();
      final likedBy = List<String>.from(data?['likedBy'] ?? []);
      
      return likedBy.contains(currentUserId);
    } catch (e) {
      print('❌ Erreur vérification like: $e');
      return false;
    }
  }

  /// Réagir à un post avec un emoji (like/love/haha/wow/sad/angry)
  Future<bool> reactToPost(String postId, String reactionType) async {
    try {
      if (currentUserId == null) return false;

      final doc = await _firestore.collection(postsCollection).doc(postId).get();
      final data = doc.data();
      final likedBy = List<String>.from(data?['likedBy'] ?? []);
      final alreadyReacted = likedBy.contains(currentUserId);

      if (alreadyReacted) {
        // Changer juste le type de réaction (sans modifier le compteur)
        await _firestore.collection(postsCollection).doc(postId).update({
          'reactions.$currentUserId': reactionType,
        });
      } else {
        // Nouvelle réaction → incrémenter likes
        await _firestore.collection(postsCollection).doc(postId).update({
          'reactions.$currentUserId': reactionType,
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }

      return true;
    } catch (e) {
      print('❌ Erreur reaction: $e');
      return false;
    }
  }

  /// Supprimer la réaction de l'utilisateur sur un post
  Future<bool> removeReaction(String postId) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection(postsCollection).doc(postId).update({
        'reactions.$currentUserId': FieldValue.delete(),
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([currentUserId]),
      });

      return true;
    } catch (e) {
      print('❌ Erreur remove reaction: $e');
      return false;
    }
  }

  // ========== INTERACTIONS : COMMENTAIRES ==========

  /// Ajouter un commentaire à un post
  Future<String?> addComment({
    required String postId,
    required String text,
  }) async {
    try {
      if (currentUserId == null) return null;

      // Récupérer les infos de l'utilisateur
      final userDoc = await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .get()
          .timeout(_delaiFirestore);
      final userData = userDoc.data();

      final comment = Comment(
        postId: postId,
        userId: currentUserId!,
        userAvatar: userData?['photo'] ?? '',
        userName: userData?['name'] ?? 'Utilisateur',
        text: text,
        createdAt: DateTime.now(),
        likedBy: [],
      );

      // Ajouter le commentaire
      final docRef = await _firestore
          .collection(commentsCollection)
          .add(comment.toFirestore());

      // Incrémenter le compteur de commentaires du post
      await _firestore.collection(postsCollection).doc(postId).update({
        'comments': FieldValue.arrayUnion([docRef.id]),
      });

      print('✅ Commentaire ajouté: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur ajout commentaire: $e');
      return null;
    }
  }

  /// Supprimer un commentaire
  Future<bool> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      // Supprimer le commentaire
      await _firestore.collection(commentsCollection).doc(commentId).delete();

      // Retirer l'ID du commentaire de la liste du post
      await _firestore.collection(postsCollection).doc(postId).update({
        'comments': FieldValue.arrayRemove([commentId]),
      });

      print('✅ Commentaire supprimé: $commentId');
      return true;
    } catch (e) {
      print('❌ Erreur suppression commentaire: $e');
      return false;
    }
  }

  /// Obtenir les commentaires d'un post en temps réel
  Stream<List<Comment>> getCommentsStream(String postId) {
    return _firestore
        .collection(commentsCollection)
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
      final comments =
          snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return comments;
    });
  }

  /// Liker un commentaire
  Future<bool> likeComment(String commentId) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection(commentsCollection).doc(commentId).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([currentUserId]),
      });

      return true;
    } catch (e) {
      print('❌ Erreur like commentaire: $e');
      return false;
    }
  }

  /// Unliker un commentaire
  Future<bool> unlikeComment(String commentId) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection(commentsCollection).doc(commentId).update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([currentUserId]),
      });

      return true;
    } catch (e) {
      print('❌ Erreur unlike commentaire: $e');
      return false;
    }
  }

  // ========== INTERACTIONS : PARTAGES ==========

  /// Républier un post (repost style Facebook)
  Future<String?> repostPost({
    required String originalPostId,
    String? comment,
  }) async {
    try {
      if (currentUserId == null) return null;

      // Récupérer le post original
      final origDoc = await _firestore.collection(postsCollection).doc(originalPostId).get();
      if (!origDoc.exists) return null;
      final origData = origDoc.data()!;

      // Récupérer les infos de l'utilisateur courant
      final userDoc = await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .get()
          .timeout(_delaiFirestore);
      final userData = userDoc.data();
      final userName  = userData?['name'] ?? userData?['displayName'] ?? 'Utilisateur';
      final userPhoto = userData?['photo'] ?? userData?['photoURL'] ?? '';

      // Construire le post de republication
      final repost = Post(
        userId:      currentUserId!,
        imagePoster: userPhoto,
        namePoster:  userName,
        postLegend:  comment ?? '',
        postImages:  [],
        likes:       0,
        shares:      0,
        comments:    [],
        createdAt:   DateTime.now(),
        likedBy:     [],
        resharedFrom: {
          'originalPostId':    originalPostId,
          'originalUserId':    origData['userId']     ?? '',
          'originalUserName':  origData['namePoster'] ?? '',
          'originalUserAvatar':origData['imagePoster']?? '',
          'originalLegend':    origData['postLegend'] ?? '',
          'originalImages':    List<String>.from(origData['postImages'] ?? []),
        },
      );

      // Créer le repost dans Firestore
      final docRef = await _firestore.collection(postsCollection).add(repost.toFirestore());

      // Incrémenter le compteur de partages du post original
      await _firestore.collection(postsCollection).doc(originalPostId).update({
        'shares': FieldValue.increment(1),
      });

      print('✅ Post republié: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur repost: $e');
      return null;
    }
  }

  /// Incrémenter le compteur de partages (bouton share icône)
  /// Stocke aussi l'uid dans sharedBy pour permettre le profil-feed
  Future<bool> sharePost(String postId) async {
    try {
      final uid = currentUserId;
      final Map<String, dynamic> update = {
        'shares': FieldValue.increment(1),
      };
      if (uid != null) {
        update['sharedBy'] = FieldValue.arrayUnion([uid]);
      }
      await _firestore.collection(postsCollection).doc(postId).update(update);
      print('✅ Post partagé: $postId');
      return true;
    } catch (e) {
      print('❌ Erreur partage post: $e');
      return false;
    }
  }

  // ========== ACTIVITÉ UTILISATEUR ==========

  /// Activités de l'utilisateur : ses propres posts (originaux + republications)
  /// et les posts sur lesquels il a commenté, sans limite de date.
  Stream<List<Post>> getUserInteractedPostsStream() {
    if (currentUserId == null) return Stream.value([]);

    // Stream 1 : mes propres posts (originaux ET republications)
    final myPostsStream = _firestore
        .collection(postsCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) => Post.fromFirestore(d)).toList());

    // Stream 2 : posts sur lesquels j'ai commenté (hors mes propres posts)
    final commentedStream = _firestore
        .collection(commentsCollection)
        .where('userId', isEqualTo: currentUserId)
        .limit(50)
        .snapshots()
        .asyncMap((snap) async {
      final postIds = snap.docs
          .map((d) => (d.data() as Map<String, dynamic>)['postId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (postIds.isEmpty) return <Post>[];
      final posts = <Post>[];
      for (var i = 0; i < postIds.length; i += 10) {
        final chunk = postIds.sublist(i, (i + 10).clamp(0, postIds.length));
        final q = await _firestore
            .collection(postsCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        posts.addAll(q.docs.map((d) => Post.fromFirestore(d)));
      }
      // Exclure les posts dont je suis l'auteur (déjà dans stream 1)
      return posts.where((p) => p.userId != currentUserId).toList();
    });

    return _mergeActivityStreams2(myPostsStream, commentedStream);
  }

  Stream<List<Post>> _mergeActivityStreams2(
    Stream<List<Post>> s1,
    Stream<List<Post>> s2,
  ) {
    final List<Post> _mine = [];
    final List<Post> _commented = [];
    late final StreamController<List<Post>> controller;

    void _emit() {
      final seen = <String, Post>{};
      for (final p in [..._mine, ..._commented]) {
        if (p.id != null) seen[p.id!] = p;
      }
      final sorted = seen.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) controller.add(sorted);
    }

    controller = StreamController<List<Post>>(
      onListen: () {
        s1.listen((v) { _mine..clear()..addAll(v); _emit(); },
            onError: controller.addError);
        s2.listen((v) { _commented..clear()..addAll(v); _emit(); },
            onError: controller.addError);
      },
      onCancel: () => controller.close(),
    );

    return controller.stream;
  }

  // ========== UTILISATEURS INTERAGIS ==========

  /// Retourne en temps réel les IDs des utilisateurs dont l'utilisateur
  /// connecté a aimé ou commenté les posts.
  Stream<Set<String>> getInteractedUserIdsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value({});

    // Stream 1 : posts que j'ai aimés → récupère les auteurs
    final likedStream = _firestore
        .collection(postsCollection)
        .where('likedBy', arrayContains: uid)
        .limit(30)
        .snapshots()
        .map((s) => s.docs
            .map((d) => (d.data())['userId'] as String? ?? '')
            .where((id) => id.isNotEmpty && id != uid)
            .toSet());

    // Stream 2 : posts que j'ai commentés → récupère les auteurs
    final commentedStream = _firestore
        .collection(commentsCollection)
        .where('userId', isEqualTo: uid)
        .limit(50)
        .snapshots()
        .asyncMap((snap) async {
          final postIds = snap.docs
              .map((d) => d.data()['postId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();
          if (postIds.isEmpty) return <String>{};
          final userIds = <String>{};
          for (var i = 0; i < postIds.length; i += 10) {
            final chunk = postIds.sublist(i, (i + 10).clamp(0, postIds.length));
            final q = await _firestore
                .collection(postsCollection)
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
            for (final d in q.docs) {
              final authorId = d.data()['userId'] as String? ?? '';
              if (authorId.isNotEmpty && authorId != uid) userIds.add(authorId);
            }
          }
          return userIds;
        });

    Set<String> _liked = {};
    Set<String> _commented = {};
    late StreamController<Set<String>> controller;

    void emit() {
      if (!controller.isClosed) controller.add({..._liked, ..._commented});
    }

    controller = StreamController<Set<String>>(
      onListen: () {
        likedStream.listen((v) { _liked = v; emit(); },
            onError: controller.addError);
        commentedStream.listen((v) { _commented = v; emit(); },
            onError: controller.addError);
      },
      onCancel: () => controller.close(),
    );

    return controller.stream;
  }

  // ========== SAUVEGARDE DE POSTS ==========

  /// Sauvegarder un post dans les favoris de l'utilisateur
  Future<bool> savePost(String postId) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection(usersCollection).doc(currentUserId).update({
        'savedPosts': FieldValue.arrayUnion([postId]),
      });

      print('✅ Post sauvegardé: $postId');
      return true;
    } catch (e) {
      print('❌ Erreur sauvegarde post: $e');
      return false;
    }
  }

  /// Retirer un post des favoris
  Future<bool> unsavePost(String postId) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection(usersCollection).doc(currentUserId).update({
        'savedPosts': FieldValue.arrayRemove([postId]),
      });

      print('✅ Post retiré des favoris: $postId');
      return true;
    } catch (e) {
      print('❌ Erreur retrait favoris: $e');
      return false;
    }
  }

  /// Obtenir les posts sauvegardés de l'utilisateur
  Stream<List<Post>> getSavedPostsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore.collection(usersCollection).doc(currentUserId).snapshots().asyncMap((userDoc) async {
      final savedPostIds = List<String>.from(userDoc.data()?['savedPosts'] ?? []);
      
      if (savedPostIds.isEmpty) return [];

      final posts = <Post>[];
      for (var postId in savedPostIds) {
        final post = await getPostById(postId);
        if (post != null) posts.add(post);
      }
      
      return posts;
    });
  }
}
