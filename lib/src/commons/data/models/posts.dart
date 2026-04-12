import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String? id; // ID Firestore du post
  String userId; // ID de l'utilisateur qui a publié
  String imagePoster; // URL de l'avatar de l'utilisateur
  String namePoster; // Nom de l'utilisateur
  String postLegend; // Texte du post
  List<String> postImages; // URLs des images du post
  
  // Compteurs d'interactions
  int likes;
  int shares;
  List<String> comments; // Liste des IDs de commentaires
  
  // Timestamps
  DateTime createdAt;
  DateTime? updatedAt;
  
  // États pour l'utilisateur courant
  bool isSaved;
  bool hasLiked;
  List<String> likedBy; // Liste des IDs d'utilisateurs qui ont liké
  Map<String, String> reactions; // {userId: 'like'|'love'|'haha'|'wow'|'sad'|'angry'}
  Map<String, dynamic>? resharedFrom;

  Post({
    this.id,
    required this.userId,
    required this.imagePoster,
    required this.namePoster,
    required this.postLegend,
    required this.postImages,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.createdAt,
    this.updatedAt,
    this.isSaved = false,
    this.hasLiked = false,
    List<String>? likedBy,
    Map<String, String>? reactions,
    this.resharedFrom,
  }) : likedBy = likedBy ?? [],
       reactions = reactions ?? {};

  // Getter pour le temps écoulé
  String get elapsedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Il y a 1 jour';
    } else if (difference.inDays < 30) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  // Getter pour le nombre de commentaires
  int get commentsNumber => comments.length;

  // Convertir un document Firestore en objet Post
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      imagePoster: data['imagePoster'] ?? '',
      namePoster: data['namePoster'] ?? '',
      postLegend: data['postLegend'] ?? '',
      postImages: List<String>.from(data['postImages'] ?? []),
      likes: data['likes'] ?? 0,
      shares: data['shares'] ?? 0,
      comments: List<String>.from(data['comments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isSaved: data['isSaved'] ?? false,
      hasLiked: data['hasLiked'] ?? false,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      reactions: Map<String, String>.from(
        (data['reactions'] as Map<dynamic, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      ),
      resharedFrom: data['resharedFrom'] != null
          ? Map<String, dynamic>.from(data['resharedFrom'] as Map)
          : null,
    );
  }

  // Convertir l'objet Post en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imagePoster': imagePoster,
      'namePoster': namePoster,
      'postLegend': postLegend,
      'postImages': postImages,
      'likes': likes,
      'shares': shares,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'likedBy': likedBy,
      'reactions': reactions,
      if (resharedFrom != null) 'resharedFrom': resharedFrom,
    };
  }

  // Créer une copie du post avec des modifications
  Post copyWith({
    String? id,
    String? userId,
    String? imagePoster,
    String? namePoster,
    String? postLegend,
    List<String>? postImages,
    int? likes,
    int? shares,
    List<String>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSaved,
    bool? hasLiked,
    List<String>? likedBy,
    Map<String, String>? reactions,
    Map<String, dynamic>? resharedFrom,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imagePoster: imagePoster ?? this.imagePoster,
      namePoster: namePoster ?? this.namePoster,
      postLegend: postLegend ?? this.postLegend,
      postImages: postImages ?? this.postImages,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSaved: isSaved ?? this.isSaved,
      hasLiked: hasLiked ?? this.hasLiked,
      likedBy: likedBy ?? this.likedBy,
      reactions: reactions ?? this.reactions,
      resharedFrom: resharedFrom ?? this.resharedFrom,
    );
  }
}

// Modèle pour les commentaires
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

  Comment({
    this.id,
    required this.postId,
    required this.userId,
    required this.userAvatar,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    List<String>? likedBy,
  }) : likedBy = likedBy ?? [];

  // Temps écoulé pour les commentaires
  String get elapsedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}j';
    } else {
      return '${(difference.inDays / 30).floor()}mois';
    }
  }

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      userName: data['userName'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userAvatar': userAvatar,
      'userName': userName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'likedBy': likedBy,
    };
  }
}

// Données de test (mock) - À migrer vers Firestore
// Exemple pour créer un post :
/*
final mockPost = Post(
  userId: 'user_id',
  imagePoster: 'assets/images/avatar_profile.png',
  namePoster: 'Sophie Martin',
  postLegend: 'Quelle journée incroyable! 🌅✨',
  postImages: ['url1', 'url2'],
  likes: 245,
  shares: 7,
  comments: [],
  createdAt: DateTime.now().subtract(Duration(hours: 2)),
  likedBy: [],
);
*/
