import 'package:cloud_firestore/cloud_firestore.dart';

class StoryComment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime createdAt;

  StoryComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.createdAt,
  });

  factory StoryComment.fromFirestore(Map<String, dynamic> data, String id) {
    return StoryComment(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class Story {
  String? id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String caption;
  final String imageUrl;   // Story image (may be empty if text-only)
  final DateTime createdAt;
  final DateTime expiresAt; // createdAt + 24h
  final List<String> viewedBy;
  List<StoryComment> comments;

  Story({
    this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.caption,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.comments = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Fraction du temps restant : 1.0 = vient d'être créée, 0.0 = expirée
  double get expiryProgress {
    final total = expiresAt.difference(createdAt).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    return (1.0 - elapsed / total).clamp(0.0, 1.0);
  }

  /// Temps restant lisible : "19h30m", "45m", "< 1m"
  String get timeRemaining {
    if (isExpired) return '';
    final remaining = expiresAt.difference(DateTime.now());
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    if (h >= 1) return m > 0 ? '${h}h${m}m' : '${h}h';
    if (m >= 1) return '${m}m';
    return '< 1m';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      caption: data['caption'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'caption': caption,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewedBy': viewedBy,
      };
}
